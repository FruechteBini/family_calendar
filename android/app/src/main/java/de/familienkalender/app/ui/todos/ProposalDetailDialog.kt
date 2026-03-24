package de.familienkalender.app.ui.todos

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import de.familienkalender.app.data.remote.dto.ProposalResponse
import de.familienkalender.app.data.remote.dto.ProposalResponseItem
import de.familienkalender.app.ui.common.ProposalRespondDialog
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * Full proposal timeline for a specific todo.
 * Shows existing proposals, lets the current user create a new one,
 * and respond (accept / reject / counter) to pending ones.
 *
 * @param todoTitle  Human-readable title shown in the dialog header.
 * @param proposals  All proposals already loaded for this todo.
 * @param currentMemberId  The logged-in member's ID so we can hide "respond" on own proposals.
 * @param onDismiss  Close without action.
 * @param onCreateProposal  User wants to submit a new proposal (date ISO, optional message).
 * @param onRespond  User responds to an existing proposal (proposalId, response, message, counterDate?).
 */
@Composable
fun ProposalDetailDialog(
    todoTitle: String,
    proposals: List<ProposalResponse>,
    currentMemberId: Int?,
    onDismiss: () -> Unit,
    onCreateProposal: (date: String, message: String?) -> Unit,
    onRespond: (proposalId: Int, response: String, message: String?, counterDate: String?) -> Unit
) {
    var showNewProposalForm by remember { mutableStateOf(false) }
    var respondingTo by remember { mutableStateOf<ProposalResponse?>(null) }

    Dialog(onDismissRequest = onDismiss) {
        Card(modifier = Modifier.fillMaxWidth().padding(4.dp)) {
            Column(modifier = Modifier.padding(16.dp)) {
                // ── Header ────────────────────────────────────────
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Terminvorschläge", style = MaterialTheme.typography.titleLarge)
                        Text(todoTitle, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Schließen")
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // ── Scrollable proposal list ───────────────────────
                Column(
                    modifier = Modifier
                        .weight(1f, fill = false)
                        .verticalScroll(rememberScrollState())
                        .fillMaxWidth()
                ) {
                    if (proposals.isEmpty()) {
                        Text(
                            "Noch keine Terminvorschläge.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    } else {
                        proposals.forEach { proposal ->
                            ProposalCard(
                                proposal = proposal,
                                currentMemberId = currentMemberId,
                                onRespond = { respondingTo = proposal }
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }

                    // ── New proposal form (inline) ─────────────────
                    if (showNewProposalForm) {
                        HorizontalDivider()
                        Spacer(modifier = Modifier.height(8.dp))
                        NewProposalForm(
                            onCancel = { showNewProposalForm = false },
                            onSubmit = { date, message ->
                                onCreateProposal(date, message)
                                showNewProposalForm = false
                            }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // ── Footer buttons ─────────────────────────────────
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End)
                ) {
                    TextButton(onClick = onDismiss) { Text("Schließen") }
                    if (!showNewProposalForm) {
                        Button(onClick = { showNewProposalForm = true }) {
                            Text("Neuer Vorschlag")
                        }
                    }
                }
            }
        }
    }

    // ── Respond dialog (overlay) ───────────────────────────────
    respondingTo?.let { proposal ->
        ProposalRespondDialog(
            proposerName = proposal.proposer.name,
            proposedDateIso = proposal.proposedDate,
            onDismiss = { respondingTo = null },
            onRespond = { response, message, counterDate ->
                onRespond(proposal.id, response, message, counterDate)
                respondingTo = null
            }
        )
    }
}

// ── Single proposal card ──────────────────────────────────────

@Composable
private fun ProposalCard(
    proposal: ProposalResponse,
    currentMemberId: Int?,
    onRespond: () -> Unit
) {
    val statusColor = when (proposal.status) {
        "accepted" -> MaterialTheme.colorScheme.tertiary
        "rejected" -> MaterialTheme.colorScheme.error
        else -> MaterialTheme.colorScheme.primary
    }
    val statusLabel = when (proposal.status) {
        "accepted" -> "Angenommen"
        "rejected" -> "Abgelehnt"
        "superseded" -> "Ersetzt"
        else -> "Ausstehend"
    }

    val dateFormatted = try {
        LocalDateTime.parse(proposal.proposedDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            .format(DateTimeFormatter.ofPattern("EE, d. MMM yyyy HH:mm", Locale.GERMAN))
    } catch (_: Exception) { proposal.proposedDate }

    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(12.dp).fillMaxWidth()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = proposal.proposer.name,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = dateFormatted,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
                Surface(
                    color = statusColor.copy(alpha = 0.15f),
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = statusLabel,
                        color = statusColor,
                        fontSize = 11.sp,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }
            }

            if (!proposal.message.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "\"${proposal.message}\"",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Response summary
            if (proposal.responses.isNotEmpty()) {
                Spacer(modifier = Modifier.height(6.dp))
                HorizontalDivider()
                Spacer(modifier = Modifier.height(4.dp))
                proposal.responses.forEach { resp ->
                    ResponseRow(resp)
                }
            }

            // Respond button — only for pending proposals not created by self
            if (proposal.status == "pending" && proposal.proposer.id != currentMemberId) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    OutlinedButton(onClick = onRespond) {
                        Text("Antworten")
                    }
                }
            }
        }
    }
}

@Composable
private fun ResponseRow(resp: ProposalResponseItem) {
    val icon = when (resp.response) {
        "accepted" -> Icons.Default.Check
        "rejected" -> Icons.Default.Close
        else -> Icons.Default.Send
    }
    val color = when (resp.response) {
        "accepted" -> MaterialTheme.colorScheme.tertiary
        "rejected" -> MaterialTheme.colorScheme.error
        else -> MaterialTheme.colorScheme.primary
    }
    Row(
        modifier = Modifier.padding(vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(14.dp))
        Text(resp.member.name, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium)
        if (!resp.message.isNullOrBlank()) {
            Text("– ${resp.message}", style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// ── New proposal form ─────────────────────────────────────────

@Composable
private fun NewProposalForm(
    onCancel: () -> Unit,
    onSubmit: (date: String, message: String?) -> Unit
) {
    var date by remember { mutableStateOf("") }
    var time by remember { mutableStateOf("09:00") }
    var message by remember { mutableStateOf("") }

    Column(modifier = Modifier.fillMaxWidth()) {
        Text("Neuer Terminvorschlag", style = MaterialTheme.typography.titleSmall)
        Spacer(modifier = Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = date,
                onValueChange = { date = it },
                label = { Text("Datum (JJJJ-MM-TT)") },
                singleLine = true,
                modifier = Modifier.weight(1f)
            )
            OutlinedTextField(
                value = time,
                onValueChange = { time = it },
                label = { Text("Zeit") },
                singleLine = true,
                modifier = Modifier.width(90.dp)
            )
        }
        Spacer(modifier = Modifier.height(6.dp))
        OutlinedTextField(
            value = message,
            onValueChange = { message = it },
            label = { Text("Nachricht (optional)") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 2
        )
        Spacer(modifier = Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End), modifier = Modifier.fillMaxWidth()) {
            TextButton(onClick = onCancel) { Text("Abbrechen") }
            Button(
                onClick = { onSubmit("${date}T${time}:00", message.ifBlank { null }) },
                enabled = date.isNotBlank()
            ) { Text("Senden") }
        }
    }
}

