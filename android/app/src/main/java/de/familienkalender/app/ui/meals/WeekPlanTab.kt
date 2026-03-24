package de.familienkalender.app.ui.meals

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import de.familienkalender.app.data.remote.dto.DayPlan
import de.familienkalender.app.data.remote.dto.MealSlotResponse
import de.familienkalender.app.ui.common.SHORT_DATE_GERMAN
import de.familienkalender.app.ui.common.difficultyLabel
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.*

@Composable
fun WeekPlanTab(viewModel: MealsViewModel) {
    val weekPlan by viewModel.weekPlan.collectAsState()
    val currentWeekStart by viewModel.currentWeekStart.collectAsState()
    val recipes by viewModel.recipes.collectAsState()
    var showRecipePicker by remember { mutableStateOf<Pair<String, String>?>(null) } // date, slot
    var showCookDialog by remember { mutableStateOf<Pair<String, String>?>(null) } // date, slot

    Column(modifier = Modifier.fillMaxSize()) {
        // Week navigation
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { viewModel.previousWeek() }) {
                Icon(Icons.Default.ChevronLeft, "Vorherige Woche")
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "KW ${currentWeekStart.format(DateTimeFormatter.ofPattern("w", Locale.GERMAN))}",
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = "${currentWeekStart.format(SHORT_DATE_GERMAN)} – ${
                        currentWeekStart.plusDays(6).format(SHORT_DATE_GERMAN)
                    }",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            Row {
                TextButton(onClick = { viewModel.goToThisWeek() }) { Text("Heute") }
                IconButton(onClick = { viewModel.nextWeek() }) {
                    Icon(Icons.Default.ChevronRight, "Nächste Woche")
                }
            }
        }

        // Generate shopping list button
        Button(
            onClick = { viewModel.generateShoppingList() },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp)
        ) {
            Icon(Icons.Default.ShoppingCart, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Einkaufsliste generieren")
        }

        // Days
        val days = weekPlan?.days ?: emptyList()
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(days) { day ->
                DayRow(
                    day = day,
                    onSlotClick = { slot ->
                        val existing = if (slot == "lunch") day.lunch else day.dinner
                        if (existing == null) {
                            showRecipePicker = day.date to slot
                        }
                    },
                    onClearSlot = { slot -> viewModel.clearMealSlot(day.date, slot) },
                    onMarkCooked = { slot -> showCookDialog = day.date to slot }
                )
            }
        }
    }

    // Recipe picker dialog
    showRecipePicker?.let { (date, slot) ->
        RecipePickerDialog(
            recipes = recipes,
            onDismiss = { showRecipePicker = null },
            onSelect = { recipeId, servings ->
                viewModel.setMealSlot(date, slot, recipeId, servings)
                showRecipePicker = null
            }
        )
    }

    // Mark as cooked dialog
    showCookDialog?.let { (date, slot) ->
        MarkCookedDialog(
            onDismiss = { showCookDialog = null },
            onConfirm = { rating, notes ->
                viewModel.markAsCooked(date, slot, rating, notes)
                showCookDialog = null
            }
        )
    }
}

@Composable
private fun DayRow(
    day: DayPlan,
    onSlotClick: (String) -> Unit,
    onClearSlot: (String) -> Unit,
    onMarkCooked: (String) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp),
        shape = MaterialTheme.shapes.small,
        colors = CardDefaults.cardColors(containerColor = androidx.compose.ui.graphics.Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = "${day.weekday}, ${
                    try { LocalDate.parse(day.date).format(SHORT_DATE_GERMAN) }
                    catch (_: Exception) { day.date }
                }",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                SlotCard(
                    label = "Mittag",
                    slot = day.lunch,
                    modifier = Modifier.weight(1f),
                    onClick = { onSlotClick("lunch") },
                    onClear = { onClearSlot("lunch") },
                    onMarkCooked = { onMarkCooked("lunch") }
                )
                Spacer(modifier = Modifier.width(8.dp))
                SlotCard(
                    label = "Abend",
                    slot = day.dinner,
                    modifier = Modifier.weight(1f),
                    onClick = { onSlotClick("dinner") },
                    onClear = { onClearSlot("dinner") },
                    onMarkCooked = { onMarkCooked("dinner") }
                )
            }
        }
    }
}

@Composable
private fun SlotCard(
    label: String,
    slot: MealSlotResponse?,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
    onClear: () -> Unit,
    onMarkCooked: () -> Unit
) {
    Surface(
        modifier = modifier.clickable { onClick() },
        color = if (slot != null) MaterialTheme.colorScheme.primaryContainer
        else MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.small
    ) {
        if (slot == null) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(label, style = MaterialTheme.typography.bodySmall)
                    Icon(Icons.Default.Add, contentDescription = "Hinzufügen", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            Column(modifier = Modifier.padding(8.dp)) {
                Text(label, style = MaterialTheme.typography.labelSmall)
                Text(
                    text = slot.recipe.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                // Prep time
                val activeTime = slot.recipe.prepTimeActiveMinutes
                val passiveTime = slot.recipe.prepTimePassiveMinutes
                if (activeTime != null || passiveTime != null) {
                    Text(
                        text = buildString {
                            activeTime?.let { append("${it} Min aktiv") }
                            if (activeTime != null && passiveTime != null) append(" / ")
                            passiveTime?.let { append("${it} Min Wartezeit") }
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 10.sp
                    )
                }
                // Difficulty + servings
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = difficultyLabel(slot.recipe.difficulty),
                        fontSize = 10.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "${slot.servingsPlanned}P",
                        fontSize = 10.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                // "Schon lange nicht mehr" badge
                val longAgo = slot.recipe.lastCookedAt?.let { lastCooked ->
                    try {
                        val lastDate = LocalDate.parse(lastCooked.substring(0, 10))
                        ChronoUnit.DAYS.between(lastDate, LocalDate.now()) > 28
                    } catch (_: Exception) { false }
                } ?: false
                if (longAgo) {
                    Surface(
                        color = Color(0xFFFF8B00).copy(alpha = 0.2f),
                        shape = MaterialTheme.shapes.extraSmall
                    ) {
                        Text(
                            text = "Schon lange nicht mehr",
                            fontSize = 9.sp,
                            color = Color(0xFFFF8B00),
                            modifier = Modifier.padding(2.dp)
                        )
                    }
                }
                // Action buttons
                Row {
                    TextButton(onClick = onMarkCooked, contentPadding = PaddingValues(2.dp)) {
                        Text("Gekocht", fontSize = 10.sp)
                    }
                    TextButton(onClick = onClear, contentPadding = PaddingValues(2.dp)) {
                        Text("Entfernen", fontSize = 10.sp, color = MaterialTheme.colorScheme.error)
                    }
                }
            }
        }
    }
}

@Composable
private fun MarkCookedDialog(
    onDismiss: () -> Unit,
    onConfirm: (rating: Int?, notes: String?) -> Unit
) {
    var rating by remember { mutableIntStateOf(0) }
    var notes by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Als gekocht markieren") },
        text = {
            Column {
                Text("Bewertung (optional)", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    (1..5).forEach { star ->
                        IconButton(onClick = { rating = if (rating == star) 0 else star }) {
                            Icon(
                                if (star <= rating) Icons.Default.Star else Icons.Outlined.StarBorder,
                                contentDescription = "$star Sterne",
                                tint = if (star <= rating) Color(0xFFFF8B00) else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notizen (optional)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(onClick = {
                onConfirm(
                    if (rating > 0) rating else null,
                    notes.ifBlank { null }
                )
            }) {
                Text("Speichern")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Abbrechen") }
        }
    )
}
