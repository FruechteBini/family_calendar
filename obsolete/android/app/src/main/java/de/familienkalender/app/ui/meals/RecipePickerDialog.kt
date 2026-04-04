package de.familienkalender.app.ui.meals

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import de.familienkalender.app.data.local.db.dao.RecipeWithIngredients
import de.familienkalender.app.ui.common.difficultyLabel

@Composable
fun RecipePickerDialog(
    recipes: List<RecipeWithIngredients>,
    onDismiss: () -> Unit,
    onSelect: (recipeId: Int, servings: Int) -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedServings by remember { mutableIntStateOf(4) }

    val filtered = recipes.filter {
        searchQuery.isBlank() || it.recipe.title.contains(searchQuery, ignoreCase = true)
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Rezept wählen") },
        text = {
            Column(modifier = Modifier.height(400.dp)) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    label = { Text("Suchen...") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Portionen:", modifier = Modifier.padding(top = 12.dp))
                    listOf(2, 4, 6).forEach { s ->
                        FilterChip(
                            selected = selectedServings == s,
                            onClick = { selectedServings = s },
                            label = { Text("$s") }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))

                LazyColumn {
                    items(filtered) { recipe ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 2.dp)
                                .clickable { onSelect(recipe.recipe.id, selectedServings) }
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text(
                                    text = recipe.recipe.title,
                                    fontWeight = FontWeight.Medium
                                )
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text(
                                        text = difficultyLabel(recipe.recipe.difficulty),
                                        fontSize = 12.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    recipe.recipe.prepTimeActiveMinutes?.let {
                                        Text(
                                            text = "${it} Min",
                                            fontSize = 12.sp,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                    Text(
                                        text = "${recipe.recipe.cookCount}x gekocht",
                                        fontSize = 12.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Abbrechen") }
        }
    )
}
