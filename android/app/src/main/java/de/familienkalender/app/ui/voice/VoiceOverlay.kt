package de.familienkalender.app.ui.voice

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import de.familienkalender.app.data.remote.dto.VoiceCommandResponse

@Composable
fun VoiceFab(
    state: VoiceUiState,
    onClick: () -> Unit
) {
    val pulseAnim = rememberInfiniteTransition(label = "pulse")
    val scale by pulseAnim.animateFloat(
        initialValue = 1f,
        targetValue = 1.15f,
        animationSpec = infiniteRepeatable(tween(600), RepeatMode.Reverse),
        label = "pulseScale"
    )

    val fabColor = when (state.state) {
        VoiceState.LISTENING -> MaterialTheme.colorScheme.error
        VoiceState.PROCESSING -> MaterialTheme.colorScheme.tertiary
        else -> MaterialTheme.colorScheme.primaryContainer
    }

    FloatingActionButton(
        onClick = onClick,
        containerColor = fabColor,
        modifier = if (state.state == VoiceState.LISTENING) Modifier.scale(scale) else Modifier
    ) {
        when (state.state) {
            VoiceState.LISTENING -> Icon(Icons.Default.Mic, "Aufnahme läuft", tint = Color.White)
            VoiceState.PROCESSING -> CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp, color = Color.White)
            else -> Icon(Icons.Default.Mic, "Sprachbefehl")
        }
    }
}

@Composable
fun VoiceListeningOverlay(
    state: VoiceUiState,
    onCancel: () -> Unit
) {
    if (state.state == VoiceState.LISTENING || state.state == VoiceState.PROCESSING) {
        Dialog(onDismissRequest = onCancel) {
            Card(
                shape = RoundedCornerShape(20.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    if (state.state == VoiceState.LISTENING) {
                        val pulseAnim = rememberInfiniteTransition(label = "mic")
                        val micScale by pulseAnim.animateFloat(
                            initialValue = 1f, targetValue = 1.3f,
                            animationSpec = infiniteRepeatable(tween(500), RepeatMode.Reverse),
                            label = "micScale"
                        )
                        Icon(
                            Icons.Default.Mic, "Mikrofon",
                            modifier = Modifier.size(64.dp).scale(micScale),
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(Modifier.height(16.dp))
                        Text("Ich höre zu…", style = MaterialTheme.typography.titleMedium)
                        if (state.partialText.isNotBlank()) {
                            Spacer(Modifier.height(8.dp))
                            Text(state.partialText, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                        }
                    } else {
                        CircularProgressIndicator(modifier = Modifier.size(48.dp))
                        Spacer(Modifier.height(16.dp))
                        Text("Wird verarbeitet…", style = MaterialTheme.typography.titleMedium)
                        if (state.finalText.isNotBlank()) {
                            Spacer(Modifier.height(8.dp))
                            Text("\"${state.finalText}\"", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    OutlinedButton(onClick = onCancel) { Text("Abbrechen") }
                }
            }
        }
    }
}

@Composable
fun VoiceResultDialog(
    result: VoiceCommandResponse,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Sprachbefehl", fontWeight = FontWeight.Bold) },
        text = {
            Column {
                Text(result.summary, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                result.actions.forEach { action ->
                    Row(
                        modifier = Modifier.padding(vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val icon = when {
                            action.type.contains("event") -> Icons.Default.Event
                            action.type.contains("todo") -> Icons.Default.CheckCircle
                            action.type.contains("recipe") -> Icons.Default.Restaurant
                            action.type.contains("meal") -> Icons.Default.Fastfood
                            action.type.contains("shopping") -> Icons.Default.ShoppingCart
                            action.type.contains("pantry") -> Icons.Default.Kitchen
                            else -> Icons.Default.Done
                        }
                        val success = action.result?.get("success") != false
                        Icon(icon, action.type, modifier = Modifier.size(20.dp), tint = if (success) Color(0xFF00875A) else MaterialTheme.colorScheme.error)
                        Spacer(Modifier.width(8.dp))
                        Text(
                            action.type.replace("_", " ").replaceFirstChar { it.uppercase() },
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("OK") } }
    )
}

@Composable
fun VoiceTextFallbackDialog(
    onDismiss: () -> Unit,
    onSend: (String) -> Unit
) {
    var text by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Textbefehl") },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                label = { Text("Was soll ich tun?") },
                placeholder = { Text("z.B. Am Montag um 14 Uhr Meeting") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4
            )
        },
        confirmButton = {
            TextButton(
                onClick = { if (text.isNotBlank()) onSend(text) },
                enabled = text.isNotBlank()
            ) { Text("Senden") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen") } }
    )
}
