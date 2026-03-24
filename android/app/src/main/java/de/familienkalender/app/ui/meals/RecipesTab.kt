package de.familienkalender.app.ui.meals

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import de.familienkalender.app.data.local.db.dao.RecipeWithIngredients
import de.familienkalender.app.data.remote.dto.IngredientCreate
import de.familienkalender.app.data.remote.dto.RecipeCreate
import de.familienkalender.app.data.remote.dto.RecipeUpdate
import de.familienkalender.app.ui.common.difficultyLabel

private data class IngredientInput(val name: String, val amount: String, val unit: String)

@Composable
fun RecipesTab(viewModel: MealsViewModel) {
    val recipes by viewModel.recipes.collectAsState()
    val cookidooAvailable by viewModel.cookidooAvailable.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    var showCreateDialog by remember { mutableStateOf(false) }
    var detailRecipe by remember { mutableStateOf<RecipeWithIngredients?>(null) }
    var editingRecipe by remember { mutableStateOf<RecipeWithIngredients?>(null) }
    var showCookidooBrowser by remember { mutableStateOf(false) }

    val filtered = recipes.filter {
        searchQuery.isBlank() || it.recipe.title.contains(searchQuery, ignoreCase = true)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    label = { Text("Rezept suchen...") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                if (cookidooAvailable) {
                    IconButton(onClick = { showCookidooBrowser = true }) {
                        Icon(Icons.Default.Download, contentDescription = "Cookidoo")
                    }
                }
            }

            if (filtered.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Keine Rezepte", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else {
                LazyColumn {
                    items(filtered, key = { it.recipe.id }) { recipe ->
                        RecipeCard(
                            recipe = recipe,
                            onClick = { detailRecipe = recipe },
                            onDelete = { viewModel.deleteRecipe(recipe.recipe.id) }
                        )
                    }
                }
            }
        }

        FloatingActionButton(
            onClick = { showCreateDialog = true },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Rezept erstellen")
        }
    }

    if (showCreateDialog) {
        RecipeFormDialog(
            onDismiss = { showCreateDialog = false },
            onSave = { request ->
                viewModel.createRecipe(request)
                showCreateDialog = false
            }
        )
    }

    detailRecipe?.let { recipe ->
        RecipeDetailDialog(
            recipe = recipe,
            onDismiss = { detailRecipe = null },
            onEdit = {
                editingRecipe = recipe
                detailRecipe = null
            }
        )
    }

    editingRecipe?.let { recipe ->
        RecipeFormDialog(
            existing = recipe,
            onDismiss = { editingRecipe = null },
            onSave = { request ->
                viewModel.updateRecipe(recipe.recipe.id, RecipeUpdate(
                    title = request.title,
                    servings = request.servings,
                    prepTimeActiveMinutes = request.prepTimeActiveMinutes,
                    prepTimePassiveMinutes = request.prepTimePassiveMinutes,
                    difficulty = request.difficulty,
                    notes = request.notes,
                    ingredients = request.ingredients
                ))
                editingRecipe = null
            }
        )
    }

    if (showCookidooBrowser) {
        CookidooBrowserDialog(
            viewModel = viewModel,
            onDismiss = { showCookidooBrowser = false }
        )
    }
}

// ── Recipe Card ───────────────────────────────────────────────

@Composable
private fun RecipeCard(
    recipe: RecipeWithIngredients,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var showDeleteConfirm by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp)
            .clickable { onClick() },
        shape = MaterialTheme.shapes.small,
        colors = CardDefaults.cardColors(containerColor = androidx.compose.ui.graphics.Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            // Thumbnail
            if (recipe.recipe.imageUrl != null) {
                AsyncImage(
                    model = recipe.recipe.imageUrl,
                    contentDescription = recipe.recipe.title,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .width(80.dp)
                        .height(80.dp)
                        .clip(RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp))
                )
            } else {
                Box(
                    modifier = Modifier
                        .width(80.dp)
                        .height(80.dp)
                        .background(
                            MaterialTheme.colorScheme.surfaceVariant,
                            RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Restaurant,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = recipe.recipe.title,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium
                    )
                    if (recipe.recipe.source == "cookidoo") {
                        Surface(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = MaterialTheme.shapes.extraSmall
                        ) {
                            Text(
                                "Cookidoo",
                                fontSize = 10.sp,
                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(difficultyLabel(recipe.recipe.difficulty), fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("${recipe.recipe.servings}P", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    recipe.recipe.prepTimeActiveMinutes?.let {
                        Text("${it}' aktiv", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Text(
                    "${recipe.recipe.cookCount}x gekocht" +
                        (recipe.recipe.lastCookedAt?.take(10)?.let { " · zuletzt $it" } ?: ""),
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            IconButton(onClick = { showDeleteConfirm = true }) {
                Icon(Icons.Default.Delete, contentDescription = "Löschen", tint = MaterialTheme.colorScheme.error)
            }
        }
    }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("Rezept löschen?") },
            text = { Text("\"${recipe.recipe.title}\" wirklich löschen?") },
            confirmButton = {
                Button(
                    onClick = { onDelete(); showDeleteConfirm = false },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) { Text("Löschen") }
            },
            dismissButton = { TextButton(onClick = { showDeleteConfirm = false }) { Text("Abbrechen") } }
        )
    }
}

// ── Recipe Detail Dialog ──────────────────────────────────────

@Composable
private fun RecipeDetailDialog(
    recipe: RecipeWithIngredients,
    onDismiss: () -> Unit,
    onEdit: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = MaterialTheme.shapes.large
        ) {
            Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                // Hero image
                if (recipe.recipe.imageUrl != null) {
                    AsyncImage(
                        model = recipe.recipe.imageUrl,
                        contentDescription = recipe.recipe.title,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp)
                            .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                    )
                }

                Column(modifier = Modifier.padding(16.dp)) {
                    // Title row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(recipe.recipe.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                            if (recipe.recipe.source == "cookidoo") {
                                Surface(
                                    color = MaterialTheme.colorScheme.primaryContainer,
                                    shape = MaterialTheme.shapes.extraSmall,
                                    modifier = Modifier.padding(top = 4.dp)
                                ) {
                                    Text("Cookidoo", fontSize = 11.sp, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                                }
                            }
                        }
                        IconButton(onClick = onDismiss) {
                            Icon(Icons.Default.Close, contentDescription = "Schließen")
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Stats row
                    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        StatChip(label = difficultyLabel(recipe.recipe.difficulty))
                        StatChip(label = "${recipe.recipe.servings} Port.")
                        recipe.recipe.prepTimeActiveMinutes?.let { StatChip(label = "${it}' aktiv") }
                        recipe.recipe.prepTimePassiveMinutes?.let { StatChip(label = "${it}' passiv") }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Cook stats
                    Surface(
                        color = MaterialTheme.colorScheme.secondaryContainer,
                        shape = MaterialTheme.shapes.small,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Text("${recipe.recipe.cookCount}× gekocht", fontSize = 13.sp)
                            recipe.recipe.lastCookedAt?.take(10)?.let {
                                Text("Zuletzt: $it", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSecondaryContainer)
                            }
                        }
                    }

                    // Notes
                    recipe.recipe.notes?.takeIf { it.isNotBlank() }?.let { notes ->
                        Spacer(modifier = Modifier.height(12.dp))
                        Text("Notizen", style = MaterialTheme.typography.titleSmall)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(notes, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }

                    // Ingredients
                    if (recipe.ingredients.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        Text("Zutaten (${recipe.ingredients.size})", style = MaterialTheme.typography.titleSmall)
                        Spacer(modifier = Modifier.height(4.dp))
                        recipe.ingredients.forEach { ing ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 2.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("• ${ing.name}", modifier = Modifier.weight(1f))
                                val qty = buildString {
                                    ing.amount?.let { a ->
                                        append(if (a == a.toInt().toFloat()) a.toInt().toString() else a.toString())
                                        append(" ")
                                    }
                                    ing.unit?.let { append(it) }
                                }.trim()
                                if (qty.isNotBlank()) {
                                    Text(qty, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Actions
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        TextButton(onClick = onDismiss) { Text("Schließen") }
                        Spacer(modifier = Modifier.width(8.dp))
                        Button(onClick = onEdit) {
                            Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Bearbeiten")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StatChip(label: String) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.small
    ) {
        Text(label, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp))
    }
}

// ── Recipe Form Dialog ────────────────────────────────────────

@Composable
private fun RecipeFormDialog(
    existing: RecipeWithIngredients? = null,
    onDismiss: () -> Unit,
    onSave: (RecipeCreate) -> Unit
) {
    val isEdit = existing != null
    var title by remember { mutableStateOf(existing?.recipe?.title ?: "") }
    var servings by remember { mutableStateOf(existing?.recipe?.servings?.toString() ?: "4") }
    var prepTimeActive by remember { mutableStateOf(existing?.recipe?.prepTimeActiveMinutes?.toString() ?: "") }
    var prepTimePassive by remember { mutableStateOf(existing?.recipe?.prepTimePassiveMinutes?.toString() ?: "") }
    var difficulty by remember { mutableStateOf(existing?.recipe?.difficulty ?: "medium") }
    var notes by remember { mutableStateOf(existing?.recipe?.notes ?: "") }
    var ingredients by remember {
        mutableStateOf(
            existing?.ingredients?.map { IngredientInput(it.name, it.amount?.toString() ?: "", it.unit ?: "") } ?: emptyList()
        )
    }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(8.dp),
            shape = MaterialTheme.shapes.large
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Text(
                    if (isEdit) "Rezept bearbeiten" else "Neues Rezept",
                    style = MaterialTheme.typography.headlineSmall
                )
                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = title, onValueChange = { title = it },
                    label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = servings, onValueChange = { servings = it },
                        label = { Text("Portionen") }, singleLine = true, modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = prepTimeActive, onValueChange = { prepTimeActive = it },
                        label = { Text("Min aktiv") }, singleLine = true, modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = prepTimePassive, onValueChange = { prepTimePassive = it },
                        label = { Text("Min passiv") }, singleLine = true, modifier = Modifier.weight(1f)
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))

                Text("Schwierigkeit", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf("easy" to "Einfach", "medium" to "Mittel", "hard" to "Aufwendig").forEach { (v, l) ->
                        FilterChip(selected = difficulty == v, onClick = { difficulty = v }, label = { Text(l) })
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = notes, onValueChange = { notes = it },
                    label = { Text("Notizen") }, modifier = Modifier.fillMaxWidth(), minLines = 2
                )
                Spacer(modifier = Modifier.height(12.dp))

                // Ingredients header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Zutaten", style = MaterialTheme.typography.titleSmall)
                    TextButton(onClick = {
                        val list = ingredients.toMutableList()
                        list.add(IngredientInput("", "", ""))
                        ingredients = list
                    }) {
                        Icon(Icons.Default.Add, contentDescription = null)
                        Text("Hinzufügen")
                    }
                }

                for (idx in ingredients.indices) {
                    val (ingName, ingAmount, ingUnit) = ingredients[idx]
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = ingName,
                            onValueChange = { new ->
                                val list = ingredients.toMutableList()
                                list[idx] = ingredients[idx].copy(name = new)
                                ingredients = list
                            },
                            label = { Text("Zutat") },
                            singleLine = true,
                            modifier = Modifier.weight(2f)
                        )
                        OutlinedTextField(
                            value = ingAmount,
                            onValueChange = { new ->
                                val list = ingredients.toMutableList()
                                list[idx] = ingredients[idx].copy(amount = new)
                                ingredients = list
                            },
                            label = { Text("Menge") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = ingUnit,
                            onValueChange = { new ->
                                val list = ingredients.toMutableList()
                                list[idx] = ingredients[idx].copy(unit = new)
                                ingredients = list
                            },
                            label = { Text("Einheit") },
                            singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(onClick = {
                            val list = ingredients.toMutableList()
                            list.removeAt(idx)
                            ingredients = list
                        }) {
                            Icon(Icons.Default.Close, contentDescription = "Entfernen", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = onDismiss) { Text("Abbrechen") }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = {
                            onSave(RecipeCreate(
                                title = title,
                                servings = servings.toIntOrNull() ?: 4,
                                prepTimeActiveMinutes = prepTimeActive.toIntOrNull(),
                                prepTimePassiveMinutes = prepTimePassive.toIntOrNull(),
                                difficulty = difficulty,
                                notes = notes.ifBlank { null },
                                ingredients = ingredients.filter { it.name.isNotBlank() }.map { ing ->
                                    IngredientCreate(name = ing.name, amount = ing.amount.toFloatOrNull(), unit = ing.unit.ifBlank { null })
                                }
                            ))
                        },
                        enabled = title.isNotBlank()
                    ) { Text(if (isEdit) "Speichern" else "Erstellen") }
                }
            }
        }
    }
}
