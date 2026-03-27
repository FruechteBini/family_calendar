package de.familienkalender.app.ui.voice

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import de.familienkalender.app.data.remote.dto.VoiceCommandResponse
import de.familienkalender.app.data.repository.AiRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

enum class VoiceState { IDLE, LISTENING, PROCESSING, RESULT, ERROR }

data class VoiceUiState(
    val state: VoiceState = VoiceState.IDLE,
    val partialText: String = "",
    val finalText: String = "",
    val result: VoiceCommandResponse? = null,
    val error: String? = null
)

class VoiceViewModel(
    private val aiRepository: AiRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(VoiceUiState())
    val uiState: StateFlow<VoiceUiState> = _uiState

    private var speechRecognizer: SpeechRecognizer? = null

    fun startListening(context: Context) {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            _uiState.value = VoiceUiState(state = VoiceState.ERROR, error = "Spracherkennung nicht verfügbar")
            return
        }

        _uiState.value = VoiceUiState(state = VoiceState.LISTENING)

        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}

                override fun onPartialResults(partialResults: Bundle?) {
                    val partial = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull() ?: ""
                    _uiState.value = _uiState.value.copy(partialText = partial)
                }

                override fun onResults(results: Bundle?) {
                    val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull() ?: ""
                    if (text.isNotBlank()) {
                        _uiState.value = _uiState.value.copy(finalText = text, state = VoiceState.PROCESSING)
                        sendCommand(text)
                    } else {
                        _uiState.value = VoiceUiState(state = VoiceState.ERROR, error = "Kein Text erkannt")
                    }
                }

                override fun onError(error: Int) {
                    val msg = when (error) {
                        SpeechRecognizer.ERROR_NO_MATCH -> "Kein Text erkannt"
                        SpeechRecognizer.ERROR_NETWORK -> "Netzwerkfehler"
                        SpeechRecognizer.ERROR_AUDIO -> "Audiofehler"
                        else -> "Fehler ($error)"
                    }
                    _uiState.value = VoiceUiState(state = VoiceState.ERROR, error = msg)
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "de-DE")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        speechRecognizer?.startListening(intent)
    }

    fun sendTextCommand(text: String) {
        _uiState.value = VoiceUiState(state = VoiceState.PROCESSING, finalText = text)
        sendCommand(text)
    }

    private fun sendCommand(text: String) {
        viewModelScope.launch {
            aiRepository.voiceCommand(text).fold(
                onSuccess = { response ->
                    _uiState.value = _uiState.value.copy(state = VoiceState.RESULT, result = response)
                },
                onFailure = { e ->
                    _uiState.value = _uiState.value.copy(state = VoiceState.ERROR, error = e.message ?: "Befehl fehlgeschlagen")
                }
            )
        }
    }

    fun stopListening() {
        speechRecognizer?.stopListening()
    }

    fun reset() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        _uiState.value = VoiceUiState()
    }

    override fun onCleared() {
        speechRecognizer?.destroy()
        super.onCleared()
    }

    class Factory(
        private val aiRepository: AiRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return VoiceViewModel(aiRepository) as T
        }
    }
}
