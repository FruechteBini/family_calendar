package de.familienkalender.app.ui.todos

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import de.familienkalender.app.data.local.db.dao.TodoWithDetails
import de.familienkalender.app.data.local.db.entity.CategoryEntity
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.remote.dto.TodoCreate

@Composable
fun TodoEditDialog(
    todo: TodoWithDetails? = null,
    categories: List<CategoryEntity>,
    members: List<FamilyMemberEntity>,
    onDismiss: () -> Unit,
    onSave: (TodoCreate) -> Unit,
    onDelete: (() -> Unit)? = null
) {
    val isEdit = todo != null
    var title by remember { mutableStateOf(todo?.todo?.title ?: "") }
    var description by remember { mutableStateOf(todo?.todo?.description ?: "") }
    var priority by remember { mutableStateOf(todo?.todo?.priority ?: "medium") }
    var dueDate by remember { mutableStateOf(todo?.todo?.dueDate ?: "") }
    var selectedCategoryId by remember { mutableStateOf(todo?.todo?.categoryId) }
    var requiresMultiple by remember { mutableStateOf(todo?.todo?.requiresMultiple ?: false) }
    var selectedMemberIds by remember {
        mutableStateOf(todo?.members?.map { it.id }?.toSet() ?: emptySet())
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (isEdit) "Todo bearbeiten" else "Neues Todo") },
        text = {
            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .fillMaxWidth()
            ) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Titel") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Beschreibung") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2
                )
                Spacer(modifier = Modifier.height(12.dp))

                Text("Priorität", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("high" to "Hoch", "medium" to "Mittel", "low" to "Niedrig").forEach { (value, label) ->
                        FilterChip(
                            selected = priority == value,
                            onClick = { priority = value },
                            label = { Text(label) }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = dueDate,
                    onValueChange = { dueDate = it },
                    label = { Text("Fällig am (YYYY-MM-DD)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(12.dp))

                Text("Kategorie", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    categories.forEach { cat ->
                        FilterChip(
                            selected = selectedCategoryId == cat.id,
                            onClick = {
                                selectedCategoryId = if (selectedCategoryId == cat.id) null else cat.id
                            },
                            label = { Text("${cat.icon} ${cat.name}") }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Checkbox(checked = requiresMultiple, onCheckedChange = { requiresMultiple = it })
                    Text("Mehrere Personen benötigt")
                }
                Spacer(modifier = Modifier.height(8.dp))

                Text("Mitglieder", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    members.forEach { member ->
                        FilterChip(
                            selected = member.id in selectedMemberIds,
                            onClick = {
                                selectedMemberIds = if (member.id in selectedMemberIds) {
                                    selectedMemberIds - member.id
                                } else {
                                    selectedMemberIds + member.id
                                }
                            },
                            label = { Text("${member.avatarEmoji} ${member.name}") }
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onSave(
                        TodoCreate(
                            title = title,
                            description = description.ifBlank { null },
                            priority = priority,
                            dueDate = dueDate.ifBlank { null },
                            categoryId = selectedCategoryId,
                            requiresMultiple = requiresMultiple,
                            memberIds = selectedMemberIds.toList()
                        )
                    )
                },
                enabled = title.isNotBlank()
            ) {
                Text("Speichern")
            }
        },
        dismissButton = {
            Row {
                if (onDelete != null) {
                    TextButton(onClick = onDelete) {
                        Text("Löschen", color = MaterialTheme.colorScheme.error)
                    }
                }
                TextButton(onClick = onDismiss) {
                    Text("Abbrechen")
                }
            }
        }
    )
}
