package de.familienkalender.app.ui.meals

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import de.familienkalender.app.data.remote.dto.CookidooCollection
import de.familienkalender.app.data.remote.dto.CookidooRecipeBrief
import de.familienkalender.app.data.remote.dto.CookidooRecipeDetail
import de.familienkalender.app.ui.common.difficultyLabel

@Composable
fun CookidooBrowserDialog(
    viewModel: MealsViewModel,
    onDismiss: () -> Unit
) {
    val collections by viewModel.cookidooCollections.collectAsState()
    val shoppingList by viewModel.cookidooShoppingList.collectAsState()
    val isLoading by viewModel.cookidooLoading.collectAsState()
    val importStatus by viewModel.cookidooImportStatus.collectAsState()

    var selectedCollection by remember { mutableStateOf<CookidooCollection?>(null) }
    var previewRecipe by remember { mutableStateOf<CookidooRecipeDetail?>(null) }

    LaunchedEffect(Unit) { viewModel.loadCookidoo() }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(4.dp),
            shape = MaterialTheme.shapes.large
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = previewRecipe?.name
                            ?: selectedCollection?.name
                            ?: "Aus Cookidoo importieren",
                        style = MaterialTheme.typography.titleLarge
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Schließen")
                    }
                }

                if (isLoading) {
                    Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                } else {
                    val currentPreview = previewRecipe
                    val currentCollection = selectedCollection
                    when {
                        currentPreview != null -> CookidooPreview(
                            detail = currentPreview,
                            importStatus = importStatus[currentPreview.cookidooId],
                            onBack = { previewRecipe = null },
                            onImport = { viewModel.importFromCookidoo(currentPreview.cookidooId) }
                        )
                        currentCollection != null -> CookidooCollectionView(
                            collection = currentCollection,
                            importStatus = importStatus,
                            onBack = { selectedCollection = null },
                            onPreview = { id -> viewModel.loadCookidooDetail(id) { previewRecipe = it } },
                            onImport = { id -> viewModel.importFromCookidoo(id) }
                        )
                        else -> CookidooMainView(
                            collections = collections,
                            shoppingList = shoppingList,
                            importStatus = importStatus,
                            onSelectCollection = { selectedCollection = it },
                            onPreview = { id -> viewModel.loadCookidooDetail(id) { previewRecipe = it } },
                            onImport = { id -> viewModel.importFromCookidoo(id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CookidooMainView(
    collections: List<CookidooCollection>,
    shoppingList: List<CookidooRecipeBrief>,
    importStatus: Map<String, String>,
    onSelectCollection: (CookidooCollection) -> Unit,
    onPreview: (String) -> Unit,
    onImport: (String) -> Unit
) {
    LazyColumn(modifier = Modifier.heightIn(max = 500.dp)) {
        if (shoppingList.isNotEmpty()) {
            item {
                Text(
                    "Deine Cookidoo-Einkaufsliste",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }
            items(shoppingList) { recipe ->
                CookidooRecipeRow(
                    name = recipe.name,
                    thumbnail = recipe.thumbnail,
                    timeMin = recipe.totalTime?.let { it / 60 },
                    status = importStatus[recipe.cookidooId],
                    onClick = { onPreview(recipe.cookidooId) },
                    onImport = { onImport(recipe.cookidooId) }
                )
            }
            item { HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp)) }
        }

        item {
            Text("Sammlungen", style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(vertical = 8.dp))
        }
        items(collections) { col ->
            val count = col.chapters.sumOf { it.recipes.size }
            Card(
                modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp).clickable { onSelectCollection(col) }
            ) {
                Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(col.name, fontWeight = FontWeight.Medium)
                        Text("$count Rezepte", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Icon(Icons.Default.ChevronRight, contentDescription = null)
                }
            }
        }
    }
}

@Composable
private fun CookidooCollectionView(
    collection: CookidooCollection,
    importStatus: Map<String, String>,
    onBack: () -> Unit,
    onPreview: (String) -> Unit,
    onImport: (String) -> Unit
) {
    Column {
        TextButton(onClick = onBack) {
            Icon(Icons.Default.ArrowBack, contentDescription = null)
            Spacer(modifier = Modifier.width(4.dp))
            Text("Zurück")
        }
        LazyColumn(modifier = Modifier.heightIn(max = 460.dp)) {
            collection.chapters.forEach { chapter ->
                if (chapter.recipes.isEmpty()) return@forEach
                item {
                    Text(
                        chapter.name,
                        style = MaterialTheme.typography.labelLarge,
                        modifier = Modifier.padding(vertical = 6.dp)
                    )
                }
                items(chapter.recipes) { recipe ->
                    CookidooRecipeRow(
                        name = recipe.name,
                        thumbnail = recipe.thumbnail,
                        timeMin = recipe.totalTime?.let { it / 60 },
                        status = importStatus[recipe.cookidooId],
                        onClick = { onPreview(recipe.cookidooId) },
                        onImport = { onImport(recipe.cookidooId) }
                    )
                }
            }
        }
    }
}

@Composable
private fun CookidooPreview(
    detail: CookidooRecipeDetail,
    importStatus: String?,
    onBack: () -> Unit,
    onImport: () -> Unit
) {
    Column {
        TextButton(onClick = onBack) {
            Icon(Icons.Default.ArrowBack, contentDescription = null)
            Spacer(modifier = Modifier.width(4.dp))
            Text("Zurück")
        }
        LazyColumn(modifier = Modifier.heightIn(max = 460.dp)) {
            detail.image?.let { imageUrl ->
                item {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = detail.name,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp)
                            .clip(MaterialTheme.shapes.medium)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(vertical = 4.dp)) {
                    detail.difficulty?.let {
                        Surface(color = MaterialTheme.colorScheme.primaryContainer, shape = MaterialTheme.shapes.small) {
                            Text(difficultyLabel(it), fontSize = 11.sp, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                        }
                    }
                    detail.servingSize?.let {
                        Text("$it Portionen", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    detail.activeTime?.let {
                        Text("${it / 60}' aktiv", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            if (detail.ingredients.isNotEmpty()) {
                item {
                    Text(
                        "Zutaten (${detail.ingredients.size})",
                        style = MaterialTheme.typography.titleSmall,
                        modifier = Modifier.padding(vertical = 6.dp)
                    )
                }
                items(detail.ingredients) { ing ->
                    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp)) {
                        Text("• ${ing.name}", modifier = Modifier.weight(1f))
                        ing.description?.takeIf { it.isNotBlank() }?.let {
                            Text(it, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
            item {
                Spacer(modifier = Modifier.height(12.dp))
                Button(
                    onClick = onImport,
                    enabled = importStatus != "loading" && importStatus != "done",
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        when (importStatus) {
                            "loading" -> "Importiere..."
                            "done" -> "✓ Importiert"
                            else -> "In meine Rezepte importieren"
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun CookidooRecipeRow(
    name: String,
    thumbnail: String?,
    timeMin: Int?,
    status: String?,
    onClick: () -> Unit,
    onImport: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        if (thumbnail != null) {
            AsyncImage(
                model = thumbnail,
                contentDescription = name,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(52.dp)
                    .clip(MaterialTheme.shapes.small)
            )
        } else {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .background(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.shapes.small),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Restaurant,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(name, style = MaterialTheme.typography.bodyMedium)
            timeMin?.let { Text("$it Min", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        OutlinedButton(
            onClick = onImport,
            enabled = status != "loading" && status != "done",
            modifier = Modifier.defaultMinSize(minWidth = 80.dp)
        ) {
            Text(
                when (status) {
                    "loading" -> "..."
                    "done" -> "✓"
                    else -> "Import"
                },
                fontSize = 12.sp
            )
        }
    }
}
