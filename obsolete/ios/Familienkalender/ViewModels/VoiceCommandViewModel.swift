import Foundation
import Speech
import AVFoundation

@Observable
@MainActor
final class VoiceCommandViewModel {

    // MARK: - State

    var isListening: Bool = false
    var isProcessing: Bool = false
    var transcript: String = ""
    var result: VoiceCommandResponse?
    var errorMessage: String?

    var speechAvailable: Bool {
        SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))?.isAvailable ?? false
    }

    // MARK: - Dependencies

    private let aiRepo: AIRepository

    @ObservationIgnored
    private var audioEngine: AVAudioEngine?
    @ObservationIgnored
    private var recognitionTask: SFSpeechRecognitionTask?
    @ObservationIgnored
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored
    private var silenceTimer: Timer?

    init(aiRepo: AIRepository) {
        self.aiRepo = aiRepo
    }

    // MARK: - Toggle

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            Task { await startListening() }
        }
    }

    // MARK: - Send Command

    func sendCommand(text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        do {
            result = try await aiRepo.voiceCommand(text: text)
        } catch {
            errorMessage = "Sprachbefehl fehlgeschlagen: \(error.localizedDescription)"
        }
        isProcessing = false
    }

    // MARK: - Speech Recognition

    func startListening() async {
        errorMessage = nil
        result = nil
        transcript = ""

        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            errorMessage = "Spracherkennung nicht erlaubt. Bitte in den Einstellungen aktivieren."
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio-Session konnte nicht gestartet werden: \(error.localizedDescription)"
            return
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE")),
              recognizer.isAvailable else {
            errorMessage = "Spracherkennung fuer Deutsch nicht verfuegbar."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            errorMessage = "Audio-Engine konnte nicht gestartet werden: \(error.localizedDescription)"
            cleanupAudio()
            return
        }

        isListening = true
        resetSilenceTimer()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.resetSilenceTimer()

                    if result.isFinal {
                        self.finishListening()
                    }
                }

                if let error, self.isListening {
                    self.errorMessage = "Erkennungsfehler: \(error.localizedDescription)"
                    self.finishListening()
                }
            }
        }
    }

    func stopListening() {
        finishListening()
    }

    func reset() {
        transcript = ""
        result = nil
        errorMessage = nil
        isProcessing = false
        if isListening {
            stopListening()
        }
    }

    // MARK: - Private

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finishListening()
            }
        }
    }

    private func finishListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        cleanupAudio()
        isListening = false

        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            Task { await sendCommand(text: text) }
        }
    }

    private func cleanupAudio() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
