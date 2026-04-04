package de.familienkalender.app.ui.meals

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import de.familienkalender.app.data.local.db.entity.PantryItemEntity
import de.familienkalender.app.data.remote.dto.PantryAlertItem
import de.familienkalender.app.data.remote.dto.PantryItemCreate
import de.familienkalender.app.data.remote.dto.PantryItemUpdate

@Composable
fun PantryTab(viewModel: PantryViewModel) {
    val items by viewModel.items.collectAsState(initial = emptyList())
    val alerts by viewModel.alerts.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    var showAddDialog by remember { mutableStateOf(false) }
    var editingItem by remember { mutableStateOf<PantryItemEntity?>(null) }

    LaunchedEffect(Unit) { viewModel.refresh() }

    Column(modifier = Modifier.fillMaxSize()) {
        if (alerts.isNotEmpty()) {
            PantryAlertBanner(
                alerts = alerts,
                onAddToShopping = { viewModel.alertToShopping(it) },
                onDismiss = { viewModel.dismissAlert(it) }
            )
        }

        PantryQuickAddBar(
            onAdd = { name, amount, unit, category, expiry ->
                viewModel.addItem(PantryItemCreate(name, amount, unit, category, expiry))
            }
        )

        if (isLoading && items.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (items.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Vorratskammer ist leer", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        } else {
            val grouped = items.groupBy { it.category }
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                grouped.forEach { (category, categoryItems) ->
                    item {
                        Text(
                            categoryLabel(category),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(top = 12.dp, bottom = 4.dp)
                        )
                    }
                    items(categoryItems, key = { it.id }) { item ->
                        PantryItemRow(
                            item = item,
                            onEdit = { editingItem = item },
                            onDelete = { viewModel.deleteItem(item.id) }
                        )
                    }
                }
            }
        }
    }

    if (showAddDialog) {
        PantryFormDialog(
            item = null,
            onDismiss = { showAddDialog = false },
            onSave = { create ->
                viewModel.addItem(create)
                showAddDialog = false
            },
            onUpdate = { _, _ -> }
        )
    }

    editingItem?.let { item ->
        PantryFormDialog(
            item = item,
            onDismiss = { editingItem = null },
            onSave = { _ -> },
            onUpdate = { id, update ->
                viewModel.updateItem(id, update)
                editingItem = null
            }
        )
    }
}

@Composable
private fun PantryAlertBanner(
    alerts: List<PantryAlertItem>,
    onAddToShopping: (Int) -> Unit,
    onDismiss: (Int) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                "⚠️ ${alerts.size} Warnung(en)",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onErrorContainer
            )
            Spacer(Modifier.height(4.dp))
            alerts.take(5).forEach { alert ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "${alert.name} — ${alert.reason}",
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.weight(1f),
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                    IconButton(
                        onClick = { onAddToShopping(alert.id) },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(Icons.Default.ShoppingCart, "Zur Einkaufsliste", Modifier.size(16.dp))
                    }
                    IconButton(
                        onClick = { onDismiss(alert.id) },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(Icons.Default.Close, "Verwerfen", Modifier.size(16.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun PantryQuickAddBar(
    onAdd: (String, Double?, String?, String, String?) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var unit by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("sonstiges") }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            placeholder = { Text("Artikel…") },
            modifier = Modifier.weight(1f),
            singleLine = true,
            shape = RoundedCornerShape(10.dp)
        )
        OutlinedTextField(
            value = amount,
            onValueChange = { amount = it },
            placeholder = { Text("Menge") },
            modifier = Modifier.width(70.dp),
            singleLine = true,
            shape = RoundedCornerShape(10.dp)
        )
        OutlinedTextField(
            value = unit,
            onValueChange = { unit = it },
            placeholder = { Text("Einh.") },
            modifier = Modifier.width(60.dp),
            singleLine = true,
            shape = RoundedCornerShape(10.dp)
        )
        FilledIconButton(
            onClick = {
                if (name.isNotBlank()) {
                    val amountVal = amount.toDoubleOrNull()
                    onAdd(name, amountVal, unit.ifBlank { null }, category, null)
                    name = ""; amount = ""; unit = ""
                }
            },
            shape = RoundedCornerShape(10.dp)
        ) {
            Icon(Icons.Default.Add, "Hinzufügen")
        }
    }
}

@Composable
private fun PantryItemRow(
    item: PantryItemEntity,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    val statusColor = when {
        item.isExpiringSoon -> MaterialTheme.colorScheme.error
        item.isLowStock -> Color(0xFFFF8B00)
        else -> Color(0xFF00875A)
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        onClick = onEdit
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .clip(CircleShape)
                    .background(statusColor)
            )
            Spacer(Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(item.name, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                val details = buildList {
                    if (item.amount != null) {
                        add("${item.amount}${item.unit?.let { " $it" } ?: ""}")
                    }
                    if (item.expiryDate != null) add("MHD: ${item.expiryDate}")
                }
                if (details.isNotEmpty()) {
                    Text(
                        details.joinToString(" · "),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                Icon(Icons.Default.Delete, "Löschen", Modifier.size(18.dp), tint = MaterialTheme.colorScheme.error)
            }
        }
    }
}

@Composable
private fun PantryFormDialog(
    item: PantryItemEntity?,
    onDismiss: () -> Unit,
    onSave: (PantryItemCreate) -> Unit,
    onUpdate: (Int, PantryItemUpdate) -> Unit
) {
    var name by remember { mutableStateOf(item?.name ?: "") }
    var amount by remember { mutableStateOf(item?.amount?.toString() ?: "") }
    var unit by remember { mutableStateOf(item?.unit ?: "") }
    var category by remember { mutableStateOf(item?.category ?: "sonstiges") }
    var expiryDate by remember { mutableStateOf(item?.expiryDate ?: "") }
    var minStock by remember { mutableStateOf(item?.minStock?.toString() ?: "") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (item == null) "Artikel hinzufügen" else "Artikel bearbeiten") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(value = amount, onValueChange = { amount = it }, label = { Text("Menge") }, singleLine = true, modifier = Modifier.weight(1f))
                    OutlinedTextField(value = unit, onValueChange = { unit = it }, label = { Text("Einheit") }, singleLine = true, modifier = Modifier.weight(1f))
                }
                OutlinedTextField(value = expiryDate, onValueChange = { expiryDate = it }, label = { Text("Ablaufdatum (YYYY-MM-DD)") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = minStock, onValueChange = { minStock = it }, label = { Text("Mindestbestand") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = {
            TextButton(onClick = {
                if (item == null) {
                    onSave(PantryItemCreate(name, amount.toDoubleOrNull(), unit.ifBlank { null }, category, expiryDate.ifBlank { null }, minStock.toDoubleOrNull()))
                } else {
                    onUpdate(item.id, PantryItemUpdate(name.ifBlank { null }, amount.toDoubleOrNull(), unit.ifBlank { null }, category.ifBlank { null }, expiryDate.ifBlank { null }, minStock.toDoubleOrNull()))
                }
            }) { Text("Speichern") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen") } }
    )
}

private fun categoryLabel(cat: String) = when (cat) {
    "kuehlregal" -> "🧊 Kühlregal"
    "obst_gemuese" -> "🥬 Obst & Gemüse"
    "trockenware" -> "🌾 Trockenware"
    "drogerie" -> "🧴 Drogerie"
    else -> "📦 Sonstiges"
}
