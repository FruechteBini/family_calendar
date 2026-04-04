package de.familienkalender.app.ui.meals

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import de.familienkalender.app.data.remote.dto.*

private val WEEKDAYS = listOf("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So")
private val SLOTS = listOf("lunch" to "Mittag", "dinner" to "Abend")

@Composable
fun AiMealPlanDialog(
    viewModel: AiMealPlanViewModel,
    onDismiss: () -> Unit,
    onConfirmed: (List<Int>) -> Unit
) {
    val state by viewModel.uiState.collectAsState()

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.9f),
            shape = RoundedCornerShape(20.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("🤖 KI-Essensplan", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, "Schließen")
                    }
                }

                Spacer(Modifier.height(12.dp))

                when (state.step) {
                    AiStep.LOADING -> LoadingContent()
                    AiStep.CONFIG -> ConfigStep(state, viewModel)
                    AiStep.GENERATING -> GeneratingContent()
                    AiStep.PREVIEW -> PreviewStep(state, viewModel, onDismiss, onConfirmed)
                    AiStep.ERROR -> ErrorContent(state.error, onRetry = { viewModel.backToConfig() })
                }
            }
        }
    }
}

@Composable
private fun LoadingContent() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator()
            Spacer(Modifier.height(12.dp))
            Text("Lade verfügbare Rezepte…")
        }
    }
}

@Composable
private fun GeneratingContent() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator()
            Spacer(Modifier.height(12.dp))
            Text("Claude denkt nach…", style = MaterialTheme.typography.bodyLarge)
            Text("Das kann bis zu 30 Sekunden dauern.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ErrorContent(error: String?, onRetry: () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.Error, "Fehler", tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(48.dp))
            Spacer(Modifier.height(8.dp))
            Text(error ?: "Ein Fehler ist aufgetreten", textAlign = TextAlign.Center)
            Spacer(Modifier.height(12.dp))
            Button(onClick = onRetry) { Text("Zurück") }
        }
    }
}

@Composable
private fun ConfigStep(state: AiMealPlanUiState, viewModel: AiMealPlanViewModel) {
    Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
        Text("Welche Slots sollen gefüllt werden?", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(8.dp))

        state.availableDates.forEachIndexed { dayIdx, date ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(WEEKDAYS.getOrElse(dayIdx) { "" }, modifier = Modifier.width(32.dp), fontWeight = FontWeight.Bold)
                SLOTS.forEach { (slotKey, slotLabel) ->
                    val slotId = "$date|$slotKey"
                    val isOccupied = state.occupiedSlots.contains(slotId)
                    val isSelected = state.selectedSlots.contains(slotId)
                    val color = when {
                        isOccupied -> MaterialTheme.colorScheme.surfaceVariant
                        isSelected -> MaterialTheme.colorScheme.primaryContainer
                        else -> MaterialTheme.colorScheme.surface
                    }
                    Card(
                        modifier = Modifier
                            .weight(1f)
                            .padding(horizontal = 2.dp)
                            .clickable(enabled = !isOccupied) {
                                viewModel.toggleSlot(slotId)
                            },
                        colors = CardDefaults.cardColors(containerColor = color),
                        shape = RoundedCornerShape(6.dp),
                        border = if (isSelected) CardDefaults.outlinedCardBorder() else null
                    ) {
                        Text(
                            if (isOccupied) "belegt" else slotLabel,
                            modifier = Modifier.padding(6.dp),
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center,
                            color = if (isOccupied) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        if (state.cookidooAvailable) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Switch(
                    checked = state.includeCookidoo,
                    onCheckedChange = { viewModel.setIncludeCookidoo(it) }
                )
                Spacer(Modifier.width(8.dp))
                Text("Cookidoo-Rezepte einbeziehen")
            }
            Spacer(Modifier.height(8.dp))
        }

        Text("Portionen", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        Slider(
            value = state.servings.toFloat(),
            onValueChange = { viewModel.setServings(it.toInt()) },
            valueRange = 1f..12f,
            steps = 10
        )
        Text("${state.servings} Portionen", style = MaterialTheme.typography.bodySmall)

        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = state.preferences,
            onValueChange = { viewModel.setPreferences(it) },
            label = { Text("Wünsche (optional)") },
            placeholder = { Text("z.B. vegetarisch, leicht, saisonal") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 2,
            maxLines = 3
        )

        Spacer(Modifier.height(16.dp))
        Button(
            onClick = { viewModel.generate() },
            enabled = state.selectedSlots.isNotEmpty(),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("🤖 Generieren (${state.selectedSlots.size} Slots)")
        }
    }
}

@Composable
private fun PreviewStep(
    state: AiMealPlanUiState,
    viewModel: AiMealPlanViewModel,
    onDismiss: () -> Unit,
    onConfirmed: (List<Int>) -> Unit
) {
    var showReasoning by remember { mutableStateOf(false) }

    Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
        Text("KI-Vorschlag", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(8.dp))

        state.preview?.suggestions?.forEach { suggestion ->
            Card(
                modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
                shape = RoundedCornerShape(8.dp)
            ) {
                Row(modifier = Modifier.padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(suggestion.recipeTitle, fontWeight = FontWeight.Medium)
                        Text(
                            "${suggestion.date} · ${if (suggestion.slot == "lunch") "Mittag" else "Abend"}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    val sourceColor = when (suggestion.source) {
                        "cookidoo" -> Color(0xFF6554C0)
                        "new" -> Color(0xFFFF8B00)
                        else -> Color(0xFF00875A)
                    }
                    SuggestionChip(
                        onClick = {},
                        label = { Text(suggestion.source, style = MaterialTheme.typography.labelSmall) },
                        colors = SuggestionChipDefaults.suggestionChipColors(containerColor = sourceColor.copy(alpha = 0.15f))
                    )
                }
            }
        }

        Spacer(Modifier.height(8.dp))

        if (state.preview?.reasoning != null) {
            OutlinedButton(onClick = { showReasoning = true }, modifier = Modifier.fillMaxWidth()) {
                Text("💡 Begründung anzeigen")
            }
            Spacer(Modifier.height(8.dp))
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            OutlinedButton(onClick = { viewModel.backToConfig() }, modifier = Modifier.weight(1f)) {
                Text("Zurück")
            }
            OutlinedButton(onClick = { viewModel.generate() }, modifier = Modifier.weight(1f)) {
                Text("Neu generieren")
            }
            Button(
                onClick = {
                    viewModel.confirm { mealIds -> onConfirmed(mealIds) }
                },
                modifier = Modifier.weight(1f),
                enabled = !state.isConfirming
            ) {
                if (state.isConfirming) {
                    CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp)
                } else {
                    Text("Bestätigen")
                }
            }
        }
    }

    if (showReasoning && state.preview?.reasoning != null) {
        AlertDialog(
            onDismissRequest = { showReasoning = false },
            title = { Text("KI-Begründung") },
            text = { Text(state.preview.reasoning) },
            confirmButton = { TextButton(onClick = { showReasoning = false }) { Text("OK") } }
        )
    }
}
