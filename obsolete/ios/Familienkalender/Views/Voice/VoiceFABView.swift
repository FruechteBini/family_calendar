import SwiftUI

struct VoiceFABView: View {
    let viewModel: VoiceCommandViewModel

    @State private var showResultSheet = false
    @State private var showTextInput = false
    @State private var textCommand = ""
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            fabButton
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .sheet(isPresented: $showResultSheet, onDismiss: {
            viewModel.reset()
        }) {
            VoiceResultSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Sprachbefehl eingeben", isPresented: $showTextInput) {
            TextField("z.B. Erstelle einen Termin morgen um 15 Uhr", text: $textCommand)
            Button("Senden") {
                let text = textCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                textCommand = ""
                if !text.isEmpty {
                    Task {
                        await viewModel.sendCommand(text: text)
                    }
                }
            }
            Button("Abbrechen", role: .cancel) {
                textCommand = ""
            }
        } message: {
            Text("Spracherkennung nicht verfügbar. Gib deinen Befehl als Text ein.")
        }
        .onChange(of: viewModel.result) { _, newValue in
            if newValue != nil {
                showResultSheet = true
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if newValue != nil && viewModel.result == nil {
                showResultSheet = true
            }
        }
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button {
            handleTap()
        } label: {
            fabIcon
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(fabColor, in: Circle())
                .scaleEffect(viewModel.isListening ? pulseScale : 1.0)
                .shadow(color: fabColor.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(viewModel.isProcessing)
        .sensoryFeedback(.impact, trigger: viewModel.isListening)
        .onChange(of: viewModel.isListening) { _, listening in
            if listening {
                startPulseAnimation()
            } else {
                pulseScale = 1.0
            }
        }
        .accessibilityLabel(accessibilityText)
    }

    private var fabIcon: some View {
        Group {
            if viewModel.isProcessing {
                ProgressView()
                    .tint(.white)
                    .controlSize(.regular)
            } else if viewModel.isListening {
                Image(systemName: "stop.fill")
            } else {
                Image(systemName: "mic.fill")
            }
        }
    }

    private var fabColor: Color {
        if viewModel.isProcessing {
            return Color(.systemGray3)
        } else if viewModel.isListening {
            return .appDanger
        } else {
            return .appPrimary
        }
    }

    private var accessibilityText: String {
        if viewModel.isProcessing {
            return "Sprachbefehl wird verarbeitet"
        } else if viewModel.isListening {
            return "Aufnahme beenden"
        } else {
            return "Sprachbefehl starten"
        }
    }

    // MARK: - Actions

    private func handleTap() {
        if !viewModel.speechAvailable {
            showTextInput = true
        } else {
            viewModel.toggleListening()
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.15
        }
    }
}

// MARK: - Listening Overlay

struct VoiceListeningOverlay: View {
    let viewModel: VoiceCommandViewModel

    var body: some View {
        if viewModel.isListening || viewModel.isProcessing {
            VStack(spacing: 16) {
                Spacer()

                VStack(spacing: 12) {
                    if viewModel.isListening {
                        listeningIndicator
                    } else if viewModel.isProcessing {
                        processingIndicator
                    }

                    if !viewModel.transcript.isEmpty {
                        Text("„\(viewModel.transcript)"")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(duration: 0.4), value: viewModel.isListening)
            .animation(.spring(duration: 0.4), value: viewModel.isProcessing)
        }
    }

    private var listeningIndicator: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    AudioBar(index: i)
                }
            }
            .frame(height: 32)

            Text("Ich höre zu …")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.appDanger)
        }
    }

    private var processingIndicator: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.large)
                .tint(.appPrimary)

            Text("Wird verarbeitet …")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.appPrimary)
        }
    }
}

// MARK: - Audio Bar Animation

private struct AudioBar: View {
    let index: Int
    @State private var height: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.appDanger)
            .frame(width: 4, height: height)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.3...0.6))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1)
                ) {
                    height = CGFloat.random(in: 12...28)
                }
            }
    }
}
