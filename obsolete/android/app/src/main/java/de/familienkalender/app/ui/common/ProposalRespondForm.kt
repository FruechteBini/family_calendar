package de.familienkalender.app.ui.common

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * Shared dialog for responding to a proposal (accept / reject / counter-proposal).
 * Used in both the global pending proposals dialog and the per-todo proposal detail dialog.
 */
@Composable
fun ProposalRespondDialog(
    proposerName: String,
    proposedDateIso: String,
    onDismiss: () -> Unit,
    onRespond: (response: String, message: String?, counterDate: String?) -> Unit
) {
    var message by remember { mutableStateOf("") }
    var counterDate by remember { mutableStateOf("") }
    var counterTime by remember { mutableStateOf("09:00") }
    var mode by remember { mutableStateOf("") }

    val dateFormatted = try {
        LocalDateTime.parse(proposedDateIso, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            .format(DateTimeFormatter.ofPattern("d. MMMM yyyy HH:mm", Locale.GERMAN))
    } catch (_: Exception) { proposedDateIso }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Auf Vorschlag antworten") },
        text = {
            Column {
                Text("Vorschlag von $proposerName:", style = MaterialTheme.typography.labelMedium)
                Text(dateFormatted, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(12.dp))

                SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                    listOf(
                        "accepted" to "Annehmen",
                        "rejected" to "Ablehnen",
                        "counter" to "Gegenvorschlag"
                    ).forEachIndexed { idx, (value, label) ->
                        SegmentedButton(
                            selected = mode == value,
                            onClick = { mode = value },
                            shape = SegmentedButtonDefaults.itemShape(idx, 3)
                        ) { Text(label, fontSize = 11.sp) }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = message,
                    onValueChange = { message = it },
                    label = { Text("Nachricht (optional)") },
                    modifier = Modifier.fillMaxWidth()
                )

                if (mode == "counter") {
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = counterDate,
                            onValueChange = { counterDate = it },
                            label = { Text("Datum (JJJJ-MM-TT)") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = counterTime,
                            onValueChange = { counterTime = it },
                            label = { Text("Zeit") },
                            singleLine = true,
                            modifier = Modifier.width(90.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val cd = if (mode == "counter" && counterDate.isNotBlank())
                        "${counterDate}T${counterTime}:00" else null
                    val responseValue = if (mode == "counter") "rejected" else mode
                    onRespond(responseValue, message.ifBlank { null }, cd)
                },
                enabled = mode.isNotEmpty() && (mode != "counter" || counterDate.isNotBlank())
            ) { Text("Senden") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen") } }
    )
}
