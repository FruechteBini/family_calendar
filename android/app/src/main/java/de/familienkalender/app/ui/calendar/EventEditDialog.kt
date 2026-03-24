package de.familienkalender.app.ui.calendar

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import de.familienkalender.app.data.local.db.dao.EventWithMembers
import de.familienkalender.app.data.local.db.entity.CategoryEntity
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.remote.dto.EventCreate
import de.familienkalender.app.ui.common.TIME_FORMAT
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Composable
fun EventEditDialog(
    event: EventWithMembers? = null,
    categories: List<CategoryEntity>,
    members: List<FamilyMemberEntity>,
    initialDate: LocalDate? = null,
    onDismiss: () -> Unit,
    onSave: (EventCreate, List<String>) -> Unit,
    onDelete: (() -> Unit)? = null
) {
    val isEdit = event != null
    var title by remember { mutableStateOf(event?.event?.title ?: "") }
    var description by remember { mutableStateOf(event?.event?.description ?: "") }
    var allDay by remember { mutableStateOf(event?.event?.allDay ?: false) }
    var selectedCategoryId by remember { mutableStateOf(event?.event?.categoryId) }
    var selectedMemberIds by remember {
        mutableStateOf(event?.members?.map { it.id }?.toSet() ?: emptySet())
    }
    var todoTitles by remember { mutableStateOf<List<String>>(emptyList()) }

    val defaultStart = initialDate?.atTime(9, 0) ?: LocalDateTime.now().withMinute(0)
    val defaultEnd = defaultStart.plusHours(1)

    var startDate by remember {
        mutableStateOf(
            event?.event?.start?.substring(0, 10)
                ?: defaultStart.format(DateTimeFormatter.ISO_LOCAL_DATE)
        )
    }
    var startTime by remember {
        mutableStateOf(
            event?.event?.start?.let {
                try { LocalDateTime.parse(it, DateTimeFormatter.ISO_LOCAL_DATE_TIME).format(TIME_FORMAT) }
                catch (_: Exception) { "09:00" }
            } ?: defaultStart.format(TIME_FORMAT)
        )
    }
    var endDate by remember {
        mutableStateOf(
            event?.event?.end?.substring(0, 10)
                ?: defaultEnd.format(DateTimeFormatter.ISO_LOCAL_DATE)
        )
    }
    var endTime by remember {
        mutableStateOf(
            event?.event?.end?.let {
                try { LocalDateTime.parse(it, DateTimeFormatter.ISO_LOCAL_DATE_TIME).format(TIME_FORMAT) }
                catch (_: Exception) { "10:00" }
            } ?: defaultEnd.format(TIME_FORMAT)
        )
    }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(4.dp),
            shape = MaterialTheme.shapes.large
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                // Title bar
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        if (isEdit) "Termin bearbeiten" else "Neuer Termin",
                        style = MaterialTheme.typography.titleLarge
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Schließen")
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Scrollable content
                Column(
                    modifier = Modifier
                        .weight(1f, fill = false)
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
                    Spacer(modifier = Modifier.height(8.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = allDay, onCheckedChange = { allDay = it })
                        Text("Ganztägig")
                    }

                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = startDate, onValueChange = { startDate = it },
                            label = { Text("Startdatum") }, singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        if (!allDay) {
                            OutlinedTextField(
                                value = startTime, onValueChange = { startTime = it },
                                label = { Text("Zeit") }, singleLine = true,
                                modifier = Modifier.width(90.dp)
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = endDate, onValueChange = { endDate = it },
                            label = { Text("Enddatum") }, singleLine = true,
                            modifier = Modifier.weight(1f)
                        )
                        if (!allDay) {
                            OutlinedTextField(
                                value = endTime, onValueChange = { endTime = it },
                                label = { Text("Zeit") }, singleLine = true,
                                modifier = Modifier.width(90.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    Text("Kategorie", style = MaterialTheme.typography.labelMedium)
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        categories.forEach { cat ->
                            FilterChip(
                                selected = selectedCategoryId == cat.id,
                                onClick = { selectedCategoryId = if (selectedCategoryId == cat.id) null else cat.id },
                                label = { Text("${cat.icon} ${cat.name}") }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Mitglieder", style = MaterialTheme.typography.labelMedium)
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        members.forEach { member ->
                            FilterChip(
                                selected = member.id in selectedMemberIds,
                                onClick = {
                                    selectedMemberIds = if (member.id in selectedMemberIds)
                                        selectedMemberIds - member.id
                                    else selectedMemberIds + member.id
                                },
                                label = { Text("${member.avatarEmoji} ${member.name}") }
                            )
                        }
                    }

                    // ── Todos ─────────────────────────────────────────────
                    Spacer(modifier = Modifier.height(12.dp))
                    HorizontalDivider()
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Todos zum Termin", style = MaterialTheme.typography.titleSmall)
                        TextButton(onClick = {
                            val list = todoTitles.toMutableList()
                            list.add("")
                            todoTitles = list
                        }) {
                            Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Todo hinzufügen")
                        }
                    }
                    for (idx in todoTitles.indices) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            OutlinedTextField(
                                value = todoTitles[idx],
                                onValueChange = { new ->
                                    val list = todoTitles.toMutableList()
                                    list[idx] = new
                                    todoTitles = list
                                },
                                label = { Text("Todo-Titel") },
                                singleLine = true,
                                modifier = Modifier.weight(1f)
                            )
                            IconButton(onClick = {
                                val list = todoTitles.toMutableList()
                                list.removeAt(idx)
                                todoTitles = list
                            }) {
                                Icon(Icons.Default.Close, contentDescription = "Entfernen",
                                    tint = MaterialTheme.colorScheme.error)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Action buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (onDelete != null) {
                        TextButton(onClick = onDelete) {
                            Text("Löschen", color = MaterialTheme.colorScheme.error)
                        }
                    }
                    TextButton(onClick = onDismiss) { Text("Abbrechen") }
                    Button(
                        onClick = {
                            val startStr = if (allDay) "${startDate}T00:00:00" else "${startDate}T${startTime}:00"
                            val endStr = if (allDay) "${endDate}T23:59:59" else "${endDate}T${endTime}:00"
                            onSave(
                                EventCreate(
                                    title = title,
                                    description = description.ifBlank { null },
                                    start = startStr,
                                    end = endStr,
                                    allDay = allDay,
                                    categoryId = selectedCategoryId,
                                    memberIds = selectedMemberIds.toList()
                                ),
                                todoTitles
                            )
                        },
                        enabled = title.isNotBlank()
                    ) { Text("Speichern") }
                }
            }
        }
    }
}
