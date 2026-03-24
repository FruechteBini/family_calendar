package de.familienkalender.app.ui.members

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import de.familienkalender.app.FamilienkalenderApp
import de.familienkalender.app.data.local.db.entity.FamilyMemberEntity
import de.familienkalender.app.data.remote.dto.FamilyMemberCreate
import de.familienkalender.app.data.remote.dto.FamilyMemberUpdate
import de.familienkalender.app.ui.common.parseHexColor

@Composable
fun MembersScreen(app: FamilienkalenderApp) {
    val viewModel: MembersViewModel = viewModel(
        factory = MembersViewModel.Factory(app.memberRepository)
    )

    val members by viewModel.members.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var editingMember by remember { mutableStateOf<FamilyMemberEntity?>(null) }

    Box(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        if (members.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Default.People,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "Keine Familienmitglieder",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(members) { member ->
                    MemberCard(
                        member = member,
                        onEdit = { editingMember = member },
                        onDelete = { viewModel.delete(member.id) }
                    )
                }
            }
        }

        FloatingActionButton(
            onClick = { showCreateDialog = true },
            containerColor = MaterialTheme.colorScheme.primary,
            shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.PersonAdd, contentDescription = "Mitglied hinzufügen")
        }
    }

    if (showCreateDialog) {
        MemberEditDialog(
            onDismiss = { showCreateDialog = false },
            onSave = { name, color, emoji ->
                viewModel.create(FamilyMemberCreate(name, color, emoji))
                showCreateDialog = false
            }
        )
    }

    editingMember?.let { member ->
        MemberEditDialog(
            member = member,
            onDismiss = { editingMember = null },
            onSave = { name, color, emoji ->
                viewModel.update(member.id, FamilyMemberUpdate(name, color, emoji))
                editingMember = null
            }
        )
    }
}

@Composable
private fun MemberCard(
    member: FamilyMemberEntity,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    val memberColor = parseHexColor(member.color, MaterialTheme.colorScheme.primary)

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(containerColor = androidx.compose.ui.graphics.Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(CircleShape)
                    .background(memberColor.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Text(text = member.avatarEmoji, fontSize = 26.sp)
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = member.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(2.dp))
                Box(
                    modifier = Modifier
                        .size(width = 24.dp, height = 4.dp)
                        .clip(CircleShape)
                        .background(memberColor)
                )
            }
            IconButton(onClick = onEdit) {
                Icon(Icons.Default.Edit, contentDescription = "Bearbeiten", tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Löschen", tint = MaterialTheme.colorScheme.error)
            }
        }
    }
}

@Composable
private fun MemberEditDialog(
    member: FamilyMemberEntity? = null,
    onDismiss: () -> Unit,
    onSave: (name: String, color: String, emoji: String) -> Unit
) {
    var name by remember { mutableStateOf(member?.name ?: "") }
    var selectedColor by remember { mutableStateOf(member?.color ?: "#0052CC") }
    var selectedEmoji by remember { mutableStateOf(member?.avatarEmoji ?: "\uD83D\uDC64") }

    val colors = listOf("#0052CC", "#00875A", "#DE350B", "#FF8B00", "#6554C0",
        "#00B8D9", "#36B37E", "#FF5630", "#FFAB00", "#172B4D")
    val emojis = listOf("\uD83D\uDC64", "\uD83D\uDC68", "\uD83D\uDC69", "\uD83D\uDC67", "\uD83D\uDC66",
        "\uD83D\uDC76", "\uD83E\uDDD3", "\uD83E\uDDD4", "\uD83D\uDC71", "\uD83E\uDDD1",
        "\uD83D\uDE3A", "\uD83D\uDC36")

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (member != null) "Mitglied bearbeiten" else "Neues Mitglied") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(12.dp))

                Text("Avatar", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    emojis.take(6).forEach { emoji ->
                        FilterChip(
                            selected = selectedEmoji == emoji,
                            onClick = { selectedEmoji = emoji },
                            label = { Text(emoji, fontSize = 18.sp) }
                        )
                    }
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    emojis.drop(6).forEach { emoji ->
                        FilterChip(
                            selected = selectedEmoji == emoji,
                            onClick = { selectedEmoji = emoji },
                            label = { Text(emoji, fontSize = 18.sp) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                Text("Farbe", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    colors.take(5).forEach { color ->
                        ColorChip(color, selectedColor == color) { selectedColor = color }
                    }
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    colors.drop(5).forEach { color ->
                        ColorChip(color, selectedColor == color) { selectedColor = color }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onSave(name, selectedColor, selectedEmoji) },
                enabled = name.isNotBlank()
            ) { Text("Speichern") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen") } }
    )
}

@Composable
private fun ColorChip(hex: String, selected: Boolean, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = {
            Box(
                modifier = Modifier
                    .size(16.dp)
                    .clip(CircleShape)
                    .background(parseHexColor(hex, MaterialTheme.colorScheme.primary))
            )
        }
    )
}
