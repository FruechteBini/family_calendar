package de.familienkalender.app.ui.navigation

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import de.familienkalender.app.FamilienkalenderApp
import de.familienkalender.app.data.remote.dto.PendingProposalDetail
import de.familienkalender.app.data.remote.dto.ProposalRespondRequest
import de.familienkalender.app.ui.calendar.CalendarScreen
import de.familienkalender.app.ui.categories.CategoriesScreen
import de.familienkalender.app.ui.common.ProposalRespondDialog
import de.familienkalender.app.ui.common.SHORT_DATE_YEAR_GERMAN
import de.familienkalender.app.ui.common.TIME_FORMAT
import de.familienkalender.app.ui.meals.MealsScreen
import de.familienkalender.app.ui.members.MembersScreen
import de.familienkalender.app.ui.settings.SettingsScreen
import de.familienkalender.app.ui.theme.Teal
import de.familienkalender.app.ui.todos.TodosScreen
import de.familienkalender.app.ui.voice.*
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

sealed class Screen(val route: String, val title: String, val icon: ImageVector, val selectedIcon: ImageVector) {
    data object Calendar : Screen("calendar", "Kalender", Icons.Outlined.CalendarMonth, Icons.Filled.CalendarMonth)
    data object Todos : Screen("todos", "Aufgaben", Icons.Outlined.CheckCircle, Icons.Filled.CheckCircle)
    data object Meals : Screen("meals", "Küche", Icons.Outlined.Restaurant, Icons.Filled.Restaurant)
    data object Members : Screen("members", "Familie", Icons.Outlined.People, Icons.Filled.People)
    data object Settings : Screen("settings", "Einstellungen", Icons.Outlined.Settings, Icons.Filled.Settings)
    data object Categories : Screen("categories", "Kategorien", Icons.Outlined.Category, Icons.Filled.Category)
}

private val bottomNavItems = listOf(Screen.Calendar, Screen.Todos, Screen.Meals)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppNavigation(app: FamilienkalenderApp, onLogout: () -> Unit) {
    val navController = rememberNavController()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var pendingProposals by remember { mutableStateOf<List<PendingProposalDetail>>(emptyList()) }
    var showPendingDialog by remember { mutableStateOf(false) }

    val voiceViewModel: VoiceViewModel = viewModel(
        factory = VoiceViewModel.Factory(app.aiRepository)
    )
    val voiceState by voiceViewModel.uiState.collectAsState()
    var showVoiceTextFallback by remember { mutableStateOf(false) }

    val micPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            voiceViewModel.startListening(context)
        } else {
            showVoiceTextFallback = true
        }
    }

    LaunchedEffect(Unit) {
        pendingProposals = app.todoRepository.getPendingProposals()
    }

    val refreshPending: () -> Unit = {
        scope.launch {
            pendingProposals = app.todoRepository.getPendingProposals()
        }
    }

    Scaffold(
        topBar = {
            val navBackStackEntry by navController.currentBackStackEntryAsState()
            val currentRoute = navBackStackEntry?.destination?.route
            val title = when (currentRoute) {
                Screen.Calendar.route -> Screen.Calendar.title
                Screen.Todos.route -> Screen.Todos.title
                Screen.Meals.route -> Screen.Meals.title
                Screen.Members.route -> Screen.Members.title
                Screen.Settings.route -> Screen.Settings.title
                Screen.Categories.route -> Screen.Categories.title
                else -> "Familienkalender"
            }
            val isTopLevel = currentRoute in bottomNavItems.map { it.route }

            TopAppBar(
                title = {
                    Text(
                        title,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 20.sp
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    actionIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface
                ),
                navigationIcon = {
                    if (!isTopLevel) {
                        IconButton(onClick = { navController.navigateUp() }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Zurück")
                        }
                    }
                },
                actions = {
                    BadgedBox(
                        badge = {
                            if (pendingProposals.isNotEmpty()) {
                                Badge(containerColor = MaterialTheme.colorScheme.secondary) {
                                    Text(pendingProposals.size.toString())
                                }
                            }
                        }
                    ) {
                        IconButton(onClick = {
                            refreshPending()
                            showPendingDialog = true
                        }) {
                            Icon(Icons.Outlined.Notifications, contentDescription = "Terminvorschläge")
                        }
                    }
                    IconButton(onClick = {
                        navController.navigate(Screen.Members.route) { launchSingleTop = true }
                    }) {
                        Icon(Icons.Outlined.People, contentDescription = "Familie")
                    }
                    IconButton(onClick = {
                        navController.navigate(Screen.Settings.route) { launchSingleTop = true }
                    }) {
                        Icon(Icons.Outlined.Settings, contentDescription = "Einstellungen")
                    }
                }
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = Color.White,
                tonalElevation = 0.dp
            ) {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination

                bottomNavItems.forEach { screen ->
                    val selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true
                    NavigationBarItem(
                        icon = {
                            Icon(
                                if (selected) screen.selectedIcon else screen.icon,
                                contentDescription = screen.title
                            )
                        },
                        label = {
                            Text(
                                screen.title,
                                fontSize = 11.sp,
                                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal
                            )
                        },
                        selected = selected,
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Teal,
                            selectedTextColor = Teal,
                            indicatorColor = Teal.copy(alpha = 0.12f),
                            unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                            unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                        ),
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        },
        floatingActionButton = {
            VoiceFab(
                state = voiceState,
                onClick = {
                    if (voiceState.state == VoiceState.LISTENING) {
                        voiceViewModel.stopListening()
                    } else {
                        val hasMicPermission = ContextCompat.checkSelfPermission(
                            context, Manifest.permission.RECORD_AUDIO
                        ) == PackageManager.PERMISSION_GRANTED

                        if (hasMicPermission) {
                            voiceViewModel.startListening(context)
                        } else {
                            micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                        }
                    }
                }
            )
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Calendar.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Calendar.route) { CalendarScreen(app) }
            composable(Screen.Todos.route) { TodosScreen(app) }
            composable(Screen.Meals.route) { MealsScreen(app) }
            composable(Screen.Members.route) { MembersScreen(app) }
            composable(Screen.Settings.route) { SettingsScreen(app, onLogout) }
            composable(Screen.Categories.route) { CategoriesScreen(app) }
        }
    }

    VoiceListeningOverlay(
        state = voiceState,
        onCancel = { voiceViewModel.reset() }
    )

    if (voiceState.state == VoiceState.RESULT && voiceState.result != null) {
        VoiceResultDialog(
            result = voiceState.result!!,
            onDismiss = { voiceViewModel.reset() }
        )
    }

    if (voiceState.state == VoiceState.ERROR && voiceState.error != null) {
        AlertDialog(
            onDismissRequest = { voiceViewModel.reset() },
            title = { Text("Sprachbefehl") },
            text = { Text(voiceState.error!!) },
            confirmButton = { TextButton(onClick = { voiceViewModel.reset() }) { Text("OK") } }
        )
    }

    if (showVoiceTextFallback) {
        VoiceTextFallbackDialog(
            onDismiss = { showVoiceTextFallback = false },
            onSend = { text ->
                showVoiceTextFallback = false
                voiceViewModel.sendTextCommand(text)
            }
        )
    }

    if (showPendingDialog) {
        PendingProposalsDialog(
            proposals = pendingProposals,
            onDismiss = { showPendingDialog = false },
            onRespond = { proposalId, response, message, counterDate ->
                scope.launch {
                    app.todoRepository.respondToProposal(
                        proposalId,
                        ProposalRespondRequest(response = response, message = message, counterDate = counterDate)
                    )
                    pendingProposals = app.todoRepository.getPendingProposals()
                }
            }
        )
    }
}

@Composable
private fun PendingProposalsDialog(
    proposals: List<PendingProposalDetail>,
    onDismiss: () -> Unit,
    onRespond: (proposalId: Int, response: String, message: String?, counterDate: String?) -> Unit
) {
    var respondingTo by remember { mutableStateOf<PendingProposalDetail?>(null) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(4.dp),
            shape = RoundedCornerShape(20.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Offene Terminvorschläge", style = MaterialTheme.typography.titleLarge)
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Schließen")
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                if (proposals.isEmpty()) {
                    Text(
                        "Keine offenen Terminvorschläge.",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                } else {
                    Column(
                        modifier = Modifier
                            .weight(1f, fill = false)
                            .verticalScroll(rememberScrollState())
                    ) {
                        proposals.forEach { proposal ->
                            PendingProposalRow(
                                proposal = proposal,
                                onRespond = { respondingTo = proposal }
                            )
                            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onDismiss) { Text("Schließen") }
                }
            }
        }
    }

    respondingTo?.let { proposal ->
        ProposalRespondDialog(
            proposerName = proposal.proposer.name,
            proposedDateIso = proposal.proposedDate,
            onDismiss = { respondingTo = null },
            onRespond = { response, message, counterDate ->
                onRespond(proposal.id, response, message, counterDate)
                respondingTo = null
            }
        )
    }
}

@Composable
private fun PendingProposalRow(
    proposal: PendingProposalDetail,
    onRespond: () -> Unit
) {
    val dateFormatted = try {
        val dt = LocalDateTime.parse(proposal.proposedDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
        "${dt.format(SHORT_DATE_YEAR_GERMAN)} ${dt.format(TIME_FORMAT)}"
    } catch (_: Exception) { proposal.proposedDate }

    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(proposal.todoTitle, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
            Text(
                "${proposal.proposer.name}: $dateFormatted",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            if (!proposal.message.isNullOrBlank()) {
                Text(
                    "\"${proposal.message}\"",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Spacer(modifier = Modifier.width(8.dp))
        FilledTonalButton(
            onClick = onRespond,
            shape = RoundedCornerShape(10.dp)
        ) { Text("Antworten") }
    }
}
