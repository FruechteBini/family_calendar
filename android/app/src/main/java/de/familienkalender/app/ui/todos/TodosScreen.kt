package de.familienkalender.app.ui.todos

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import de.familienkalender.app.FamilienkalenderApp
import de.familienkalender.app.data.local.db.dao.TodoWithDetails
import de.familienkalender.app.data.local.db.entity.SubtodoEntity
import de.familienkalender.app.data.remote.dto.ProposalResponse
import de.familienkalender.app.data.remote.dto.TodoUpdate
import de.familienkalender.app.ui.common.SHORT_DATE_GERMAN
import de.familienkalender.app.ui.common.priorityColor
import de.familienkalender.app.ui.common.priorityLabel
import java.time.LocalDate

@Composable
fun TodosScreen(app: FamilienkalenderApp) {
    val viewModel: TodosViewModel = viewModel(
        factory = TodosViewModel.Factory(
            app.todoRepository, app.categoryRepository, app.memberRepository
        )
    )

    val todos by viewModel.filteredTodos.collectAsState()
    val filter by viewModel.filter.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val members by viewModel.members.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var editingTodo by remember { mutableStateOf<TodoWithDetails?>(null) }
    var addSubTodoParent by remember { mutableStateOf<TodoWithDetails?>(null) }
    var proposalsTodo by remember { mutableStateOf<TodoWithDetails?>(null) }
    var proposalsList by remember { mutableStateOf<List<ProposalResponse>>(emptyList()) }

    Box(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Column(modifier = Modifier.fillMaxSize()) {
            Surface(color = Color.White, modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("high", "medium", "low").forEach { priority ->
                        FilterChip(
                            selected = filter.priority == priority,
                            onClick = { viewModel.togglePriority(priority) },
                            label = { Text(priorityLabel(priority), fontSize = 12.sp) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = priorityColor(priority).copy(alpha = 0.15f),
                                selectedLabelColor = priorityColor(priority)
                            ),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }
                    FilterChip(
                        selected = filter.completed != false,
                        onClick = { viewModel.toggleShowCompleted() },
                        label = { Text("Erledigt", fontSize = 12.sp) },
                        shape = RoundedCornerShape(10.dp)
                    )
                }
            }

            if (todos.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize().weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.TaskAlt,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "Keine Aufgaben",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxWidth().weight(1f),
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    items(todos, key = { it.todo.id }) { todo ->
                        TodoItem(
                            todo = todo,
                            onToggleComplete = { viewModel.toggleComplete(todo.todo.id) },
                            onClick = { editingTodo = todo },
                            onDelete = { viewModel.deleteTodo(todo.todo.id) },
                            onAddSubTodo = { addSubTodoParent = todo },
                            onProposeDate = {
                                proposalsTodo = todo
                                proposalsList = emptyList()
                            },
                            getSubtodos = { viewModel.getSubtodos(todo.todo.id) },
                            onToggleSubtodo = { subtodoId -> viewModel.toggleComplete(subtodoId) }
                        )
                    }
                }
            }
        }

        FloatingActionButton(
            onClick = { showCreateDialog = true },
            containerColor = MaterialTheme.colorScheme.primary,
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Aufgabe erstellen")
        }
    }

    if (showCreateDialog) {
        TodoEditDialog(
            categories = categories,
            members = members,
            onDismiss = { showCreateDialog = false },
            onSave = { request ->
                viewModel.createTodo(request)
                showCreateDialog = false
            }
        )
    }

    editingTodo?.let { todo ->
        TodoEditDialog(
            todo = todo,
            categories = categories,
            members = members,
            onDismiss = { editingTodo = null },
            onSave = { request ->
                viewModel.updateTodo(
                    todo.todo.id,
                    TodoUpdate(
                        title = request.title,
                        description = request.description,
                        priority = request.priority,
                        dueDate = request.dueDate,
                        categoryId = request.categoryId,
                        requiresMultiple = request.requiresMultiple,
                        memberIds = request.memberIds
                    )
                )
                editingTodo = null
            },
            onDelete = {
                viewModel.deleteTodo(todo.todo.id)
                editingTodo = null
            }
        )
    }

    // Add Sub-Todo Dialog
    addSubTodoParent?.let { parent ->
        var subTitle by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { addSubTodoParent = null },
            title = { Text("Unteraufgabe hinzufügen") },
            text = {
                OutlinedTextField(
                    value = subTitle,
                    onValueChange = { subTitle = it },
                    label = { Text("Titel") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (subTitle.isNotBlank()) {
                            viewModel.addSubTodo(parent.todo.id, subTitle)
                            addSubTodoParent = null
                        }
                    },
                    enabled = subTitle.isNotBlank()
                ) { Text("Hinzufügen") }
            },
            dismissButton = { TextButton(onClick = { addSubTodoParent = null }) { Text("Abbrechen") } }
        )
    }

    // Full proposal dialog
    proposalsTodo?.let { todo ->
        // Load proposals when dialog opens
        LaunchedEffect(todo.todo.id) {
            proposalsList = viewModel.getProposals(todo.todo.id)
        }
        ProposalDetailDialog(
            todoTitle = todo.todo.title,
            proposals = proposalsList,
            currentMemberId = app.tokenManager.memberId.takeIf { it > 0 },
            onDismiss = { proposalsTodo = null },
            onCreateProposal = { date, message ->
                viewModel.proposeDate(todo.todo.id, date, message)
                proposalsTodo = null
            },
            onRespond = { proposalId, response, message, counterDate ->
                viewModel.respondToProposal(proposalId, response, message, counterDate) {
                    proposalsTodo = null
                }
            }
        )
    }
}

@Composable
private fun TodoItem(
    todo: TodoWithDetails,
    onToggleComplete: () -> Unit,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    onAddSubTodo: () -> Unit,
    onProposeDate: () -> Unit,
    getSubtodos: () -> kotlinx.coroutines.flow.Flow<List<SubtodoEntity>>,
    onToggleSubtodo: (Int) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val subtodos by getSubtodos().collectAsState(initial = emptyList())
    val priorityColor = priorityColor(todo.todo.priority)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp)
            .clickable { onClick() },
        shape = MaterialTheme.shapes.small,
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = todo.todo.completed,
                    onCheckedChange = { onToggleComplete() }
                )
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = todo.todo.title,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        textDecoration = if (todo.todo.completed) TextDecoration.LineThrough else null
                    )
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Priority badge
                        Surface(
                            color = priorityColor.copy(alpha = 0.15f),
                            shape = MaterialTheme.shapes.small
                        ) {
                            Text(
                                text = priorityLabel(todo.todo.priority),
                                color = priorityColor,
                                fontSize = 11.sp,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                        // Due date
                        todo.todo.dueDate?.let { date ->
                            val formatted = try {
                                LocalDate.parse(date).format(SHORT_DATE_GERMAN)
                            } catch (_: Exception) { date }
                            Text(
                                text = formatted,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        // Category
                        todo.todo.categoryIcon?.let { icon ->
                            Text(text = icon, fontSize = 14.sp)
                        }
                    }
                }
                // Member avatars
                Row {
                    todo.members.take(3).forEach { member ->
                        Text(text = member.avatarEmoji, fontSize = 16.sp)
                    }
                }
                // Propose date icon (available on all todos with multiple members)
                if (todo.members.size > 1 || todo.todo.requiresMultiple) {
                    IconButton(onClick = onProposeDate) {
                        Icon(
                            Icons.Default.CalendarMonth,
                            contentDescription = "Terminvorschlag",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                // Add subtodo
                IconButton(onClick = onAddSubTodo) {
                    Icon(
                        Icons.Default.Add,
                        contentDescription = "Unteraufgabe",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                // Subtodo expand
                if (subtodos.isNotEmpty()) {
                    IconButton(onClick = { expanded = !expanded }) {
                        Icon(
                            if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                            contentDescription = "Unteraufgaben"
                        )
                    }
                }
            }

            // Subtodos
            if (expanded && subtodos.isNotEmpty()) {
                Column(modifier = Modifier.padding(start = 40.dp)) {
                    subtodos.forEach { subtodo ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(
                                checked = subtodo.completed,
                                onCheckedChange = { onToggleSubtodo(subtodo.id) }
                            )
                            Text(
                                text = subtodo.title,
                                style = MaterialTheme.typography.bodyMedium,
                                textDecoration = if (subtodo.completed) TextDecoration.LineThrough else null
                            )
                        }
                    }
                }
            }
        }
    }
}
