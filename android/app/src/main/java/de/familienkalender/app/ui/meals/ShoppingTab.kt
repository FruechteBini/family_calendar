package de.familienkalender.app.ui.meals

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import de.familienkalender.app.data.local.db.entity.ShoppingItemEntity
import de.familienkalender.app.data.remote.dto.ShoppingItemCreate
import de.familienkalender.app.ui.common.categoryEmoji
import de.familienkalender.app.ui.common.categoryLabel

private enum class ShoppingViewMode { Category, Recipe, AiSort }

@Composable
fun ShoppingTab(viewModel: MealsViewModel) {
    val shoppingList by viewModel.shoppingList.collectAsState()
    val recipes by viewModel.recipes.collectAsState()
    val isSorting by viewModel.isSorting.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }
    var viewMode by remember { mutableStateOf(ShoppingViewMode.Category) }

    Box(modifier = Modifier.fillMaxSize()) {
        if (shoppingList == null) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    "Keine aktive Einkaufsliste.\nGehe zum Wochenplan und generiere eine.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            val items = shoppingList!!.items
            val totalCount = items.size
            val checkedCount = items.count { it.checked }

            Column(modifier = Modifier.fillMaxSize()) {
                // Progress
                LinearProgressIndicator(
                    progress = { if (totalCount > 0) checkedCount.toFloat() / totalCount else 0f },
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
                )
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "$checkedCount / $totalCount erledigt",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    // Toggle
                    SingleChoiceSegmentedButtonRow {
                        SegmentedButton(
                            selected = viewMode == ShoppingViewMode.Category,
                            onClick = { viewMode = ShoppingViewMode.Category },
                            shape = SegmentedButtonDefaults.itemShape(0, 2)
                        ) { Text("Kategorie") }
                        SegmentedButton(
                            selected = viewMode == ShoppingViewMode.Recipe,
                            onClick = { viewMode = ShoppingViewMode.Recipe },
                            shape = SegmentedButtonDefaults.itemShape(1, 2)
                        ) { Text("Rezept") }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = { viewModel.aiSortShopping() },
                        enabled = !isSorting
                    ) {
                        if (isSorting) {
                            CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp)
                        } else {
                            Text("🤖 KI-Sortieren")
                        }
                    }
                    OutlinedButton(
                        onClick = { viewModel.clearShoppingList() },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error)
                    ) {
                        Text("Leeren")
                    }
                }

                val sortedByStore = shoppingList?.list?.sortedByStore
                if (sortedByStore != null) {
                    Text(
                        "Sortiert nach: $sortedByStore",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 2.dp)
                    )
                }

                when (viewMode) {
                    ShoppingViewMode.Category, ShoppingViewMode.AiSort -> {
                        val sortedItems = if (sortedByStore != null) {
                            items.sortedWith(compareBy({ it.storeSection ?: "" }, { it.sortOrder ?: Int.MAX_VALUE }))
                        } else items
                        val groupKey: (ShoppingItemEntity) -> String = if (sortedByStore != null) {
                            { it.storeSection ?: it.category }
                        } else {
                            { it.category }
                        }
                        CategoryView(
                            items = sortedItems,
                            onCheck = { viewModel.checkShoppingItem(it) },
                            onDelete = { viewModel.deleteShoppingItem(it) }
                        )
                    }
                    ShoppingViewMode.Recipe -> RecipeView(
                        items = items,
                        recipeNames = recipes.associate { it.recipe.id to it.recipe.title },
                        onCheck = { viewModel.checkShoppingItem(it) },
                        onDelete = { viewModel.deleteShoppingItem(it) }
                    )
                }
            }
        }

        FloatingActionButton(
            onClick = { showAddDialog = true },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Artikel hinzufügen")
        }
    }

    if (showAddDialog) {
        AddShoppingItemDialog(
            onDismiss = { showAddDialog = false },
            onSave = { request ->
                viewModel.addShoppingItem(request)
                showAddDialog = false
            }
        )
    }
}

// ── Category view (original) ──────────────────────────────────

@Composable
private fun CategoryView(
    items: List<ShoppingItemEntity>,
    onCheck: (Int) -> Unit,
    onDelete: (Int) -> Unit
) {
    val grouped = items.groupBy { it.category }
    val categoryOrder = listOf("kuehlregal", "obst_gemuese", "trockenware", "drogerie", "sonstiges")

    LazyColumn(modifier = Modifier.fillMaxSize()) {
        categoryOrder.forEach { category ->
            val categoryItems = grouped[category] ?: return@forEach
            item {
                Text(
                    text = "${categoryEmoji(category)} ${categoryLabel(category)}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 16.dp, top = 12.dp, bottom = 4.dp)
                )
            }
            items(categoryItems, key = { it.id }) { item ->
                ShoppingItemRow(item = item, onCheck = { onCheck(item.id) }, onDelete = { onDelete(item.id) })
            }
        }
    }
}

// ── Recipe view (new) ─────────────────────────────────────────

@Composable
private fun RecipeView(
    items: List<ShoppingItemEntity>,
    recipeNames: Map<Int, String>,
    onCheck: (Int) -> Unit,
    onDelete: (Int) -> Unit
) {
    // Group: recipe items by recipeId, manual items together
    val recipeGroups = items
        .filter { it.source == "recipe" && it.recipeId != null }
        .groupBy { it.recipeId!! }
    val manualItems = items.filter { it.source != "recipe" || it.recipeId == null }

    LazyColumn(modifier = Modifier.fillMaxSize()) {
        recipeGroups.forEach { (recipeId, recipeItems) ->
            val recipeName = recipeNames[recipeId] ?: "Rezept #$recipeId"
            val checkedCount = recipeItems.count { it.checked }
            item {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "🍽 $recipeName",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "$checkedCount/${recipeItems.size}",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            items(recipeItems, key = { it.id }) { item ->
                ShoppingItemRow(item = item, onCheck = { onCheck(item.id) }, onDelete = { onDelete(item.id) })
            }
        }

        if (manualItems.isNotEmpty()) {
            item {
                Text(
                    text = "✏️ Manuell hinzugefügt",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 16.dp, top = 12.dp, bottom = 4.dp)
                )
            }
            items(manualItems, key = { it.id }) { item ->
                ShoppingItemRow(item = item, onCheck = { onCheck(item.id) }, onDelete = { onDelete(item.id) })
            }
        }
    }
}

// ── Shared row ────────────────────────────────────────────────

@Composable
private fun ShoppingItemRow(
    item: ShoppingItemEntity,
    onCheck: () -> Unit,
    onDelete: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Checkbox(checked = item.checked, onCheckedChange = { onCheck() })
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.name,
                textDecoration = if (item.checked) TextDecoration.LineThrough else null,
                style = MaterialTheme.typography.bodyMedium
            )
            val detail = buildString {
                item.amount?.let { append(it) }
                item.unit?.let {
                    if (isNotEmpty()) append(" ")
                    append(it)
                }
            }
            if (detail.isNotBlank()) {
                Text(text = detail, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (item.source == "manual") {
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Löschen", tint = MaterialTheme.colorScheme.error)
            }
        }
    }
}

// ── Add dialog ────────────────────────────────────────────────

@Composable
private fun AddShoppingItemDialog(onDismiss: () -> Unit, onSave: (ShoppingItemCreate) -> Unit) {
    var name by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var unit by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("sonstiges") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Artikel hinzufügen") },
        text = {
            Column {
                OutlinedTextField(
                    value = name, onValueChange = { name = it },
                    label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = amount, onValueChange = { amount = it },
                        label = { Text("Menge") }, singleLine = true, modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = unit, onValueChange = { unit = it },
                        label = { Text("Einheit") }, singleLine = true, modifier = Modifier.weight(1f)
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text("Kategorie", style = MaterialTheme.typography.labelMedium)
                listOf(
                    "kuehlregal" to "Kühlregal", "obst_gemuese" to "Obst & Gemüse",
                    "trockenware" to "Trockenware", "drogerie" to "Drogerie", "sonstiges" to "Sonstiges"
                ).forEach { (value, label) ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        RadioButton(selected = category == value, onClick = { category = value })
                        Text(label)
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onSave(ShoppingItemCreate(name = name, amount = amount.ifBlank { null }, unit = unit.ifBlank { null }, category = category)) },
                enabled = name.isNotBlank()
            ) { Text("Hinzufügen") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen") } }
    )
}
