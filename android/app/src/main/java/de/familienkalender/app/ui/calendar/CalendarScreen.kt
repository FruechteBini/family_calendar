package de.familienkalender.app.ui.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import de.familienkalender.app.FamilienkalenderApp
import de.familienkalender.app.data.local.db.dao.EventWithMembers
import de.familienkalender.app.data.remote.dto.toUpdate
import de.familienkalender.app.ui.common.*
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.util.*

@Composable
fun CalendarScreen(app: FamilienkalenderApp) {
    val viewModel: CalendarViewModel = viewModel(
        factory = CalendarViewModel.Factory(
            app.eventRepository, app.categoryRepository, app.memberRepository, app.todoRepository
        )
    )

    val currentMonth by viewModel.currentMonth.collectAsState()
    val selectedDate by viewModel.selectedDate.collectAsState()
    val events by viewModel.events.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val members by viewModel.members.collectAsState()
    val viewMode by viewModel.viewMode.collectAsState()
    val error by viewModel.error.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var editingEvent by remember { mutableStateOf<EventWithMembers?>(null) }
    val displayDate = selectedDate ?: LocalDate.now()

    Column(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        error?.let { msg ->
            Surface(
                color = MaterialTheme.colorScheme.errorContainer,
                shape = MaterialTheme.shapes.small,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 4.dp)
            ) {
                Text(
                    text = msg,
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
                )
            }
        }

        Surface(
            color = Color.White,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column {
                ViewModeSelector(viewMode) { viewModel.setViewMode(it) }
                NavigationHeader(viewMode, currentMonth, selectedDate) {
                    viewModel.navigateBack()
                } forward@ {
                    viewModel.navigateForward()
                } today@ {
                    viewModel.goToToday()
                }
                CalendarContent(viewMode, currentMonth, selectedDate, events) { viewModel.selectDate(it) }
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        DayEventList(
            displayDate = displayDate,
            events = events,
            onCreateClick = { showCreateDialog = true },
            onEventClick = { editingEvent = it }
        )
    }

    if (showCreateDialog) {
        EventEditDialog(
            categories = categories,
            members = members,
            initialDate = displayDate,
            onDismiss = { showCreateDialog = false },
            onSave = { request, todoTitles ->
                viewModel.createEvent(request, todoTitles)
                showCreateDialog = false
            }
        )
    }

    editingEvent?.let { event ->
        EventEditDialog(
            event = event,
            categories = categories,
            members = members,
            onDismiss = { editingEvent = null },
            onSave = { request, todoTitles ->
                viewModel.updateEvent(event.event.id, request.toUpdate())
                if (todoTitles.isNotEmpty()) {
                    viewModel.addTodosToEvent(event.event.id, request.start.take(10), todoTitles)
                }
                editingEvent = null
            },
            onDelete = {
                viewModel.deleteEvent(event.event.id)
                editingEvent = null
            }
        )
    }
}

// ── View Mode Selector ──────────────────────────────────────────

@Composable
private fun ViewModeSelector(viewMode: CalendarViewMode, onSelect: (CalendarViewMode) -> Unit) {
    SingleChoiceSegmentedButtonRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp)
    ) {
        CalendarViewMode.entries.forEachIndexed { idx, mode ->
            SegmentedButton(
                selected = viewMode == mode,
                onClick = { onSelect(mode) },
                shape = SegmentedButtonDefaults.itemShape(index = idx, count = CalendarViewMode.entries.size)
            ) { Text(mode.label) }
        }
    }
}

// ── Navigation Header ───────────────────────────────────────────

@Composable
private fun NavigationHeader(
    viewMode: CalendarViewMode,
    currentMonth: YearMonth,
    selectedDate: LocalDate?,
    onBack: () -> Unit,
    onForward: () -> Unit,
    onToday: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onBack) {
            Icon(Icons.Default.ChevronLeft, contentDescription = "Zurück")
        }
        Text(
            text = headerText(viewMode, currentMonth, selectedDate),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Medium
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onToday) {
                Text("Heute", color = MaterialTheme.colorScheme.primary)
            }
            IconButton(onClick = onForward) {
                Icon(Icons.Default.ChevronRight, contentDescription = "Vorwärts")
            }
        }
    }
}

private fun headerText(viewMode: CalendarViewMode, currentMonth: YearMonth, selectedDate: LocalDate?): String {
    val base = selectedDate ?: LocalDate.now()
    return when (viewMode) {
        CalendarViewMode.Month ->
            currentMonth.month.getDisplayName(TextStyle.FULL, Locale.GERMAN) + " " + currentMonth.year
        CalendarViewMode.Week -> {
            val mon = base.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            val sun = mon.plusDays(6)
            "${mon.format(SHORT_DATE_GERMAN)} – ${sun.format(SHORT_DATE_YEAR_GERMAN)}"
        }
        CalendarViewMode.ThreeDays ->
            "${base.format(SHORT_DATE_GERMAN)} – ${base.plusDays(2).format(SHORT_DATE_YEAR_GERMAN)}"
        CalendarViewMode.Day ->
            base.format(DateTimeFormatter.ofPattern("EEEE, d. MMMM", Locale.GERMAN))
    }
}

// ── Calendar Content ────────────────────────────────────────────

@Composable
private fun CalendarContent(
    viewMode: CalendarViewMode,
    currentMonth: YearMonth,
    selectedDate: LocalDate?,
    events: List<EventWithMembers>,
    onDateSelected: (LocalDate) -> Unit
) {
    when (viewMode) {
        CalendarViewMode.Month -> {
            WeekdayHeaders()
            MonthGrid(currentMonth, selectedDate, events, onDateSelected)
        }
        CalendarViewMode.Week -> {
            val monday = (selectedDate ?: LocalDate.now())
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            DayStrip((0..6).map { monday.plusDays(it.toLong()) }, selectedDate, events, onDateSelected)
        }
        CalendarViewMode.ThreeDays -> {
            val base = selectedDate ?: LocalDate.now()
            DayStrip((0..2).map { base.plusDays(it.toLong()) }, selectedDate, events, onDateSelected)
        }
        CalendarViewMode.Day -> { /* no strip */ }
    }
}

// ── Day Event List ──────────────────────────────────────────────

@Composable
private fun ColumnScope.DayEventList(
    displayDate: LocalDate,
    events: List<EventWithMembers>,
    onCreateClick: () -> Unit,
    onEventClick: (EventWithMembers) -> Unit
) {
    val dayEvents = events.filter { parseEventDate(it.event.start) == displayDate }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = displayDate.format(FULL_DATE_GERMAN),
            style = MaterialTheme.typography.titleSmall
        )
        IconButton(onClick = onCreateClick) {
            Icon(Icons.Default.Add, contentDescription = "Termin erstellen")
        }
    }

    if (dayEvents.isEmpty()) {
        Box(
            modifier = Modifier.fillMaxWidth().padding(40.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    Icons.Default.EventBusy,
                    contentDescription = null,
                    modifier = Modifier.size(40.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Keine Termine",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    } else {
        LazyColumn(modifier = Modifier.fillMaxWidth()) {
            items(dayEvents) { event ->
                EventItem(event = event, onClick = { onEventClick(event) })
            }
        }
    }
}

// ── Day Strip (Week / 3-day) ────────────────────────────────────

@Composable
private fun DayStrip(
    days: List<LocalDate>,
    selectedDate: LocalDate?,
    events: List<EventWithMembers>,
    onDateSelected: (LocalDate) -> Unit
) {
    val today = LocalDate.now()
    Column(modifier = Modifier.padding(horizontal = 4.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            days.forEach { date ->
                Text(
                    text = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.GERMAN),
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            days.forEach { date ->
                val dayEvents = events.filter { parseEventDate(it.event.start) == date }
                DayCell(
                    day = date.dayOfMonth,
                    isToday = date == today,
                    isSelected = date == selectedDate,
                    eventCount = dayEvents.size,
                    eventColors = dayEvents.mapNotNull { it.event.categoryColor }.distinct(),
                    modifier = Modifier
                        .weight(1f)
                        .aspectRatio(1f)
                        .clickable { onDateSelected(date) }
                )
            }
        }
    }
}

// ── Month Components ────────────────────────────────────────────

@Composable
private fun WeekdayHeaders() {
    val days = listOf("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So")
    Row(modifier = Modifier.fillMaxWidth()) {
        days.forEach { day ->
            Text(
                text = day,
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun MonthGrid(
    currentMonth: YearMonth,
    selectedDate: LocalDate?,
    events: List<EventWithMembers>,
    onDateSelected: (LocalDate) -> Unit
) {
    val firstDayOfMonth = currentMonth.atDay(1)
    val startOffset = firstDayOfMonth.dayOfWeek.value - 1
    val daysInMonth = currentMonth.lengthOfMonth()
    val today = LocalDate.now()

    Column(modifier = Modifier.padding(4.dp)) {
        var dayCounter = 1 - startOffset
        for (week in 0..5) {
            if (dayCounter > daysInMonth) break
            Row(modifier = Modifier.fillMaxWidth()) {
                for (dow in 0..6) {
                    if (dayCounter < 1 || dayCounter > daysInMonth) {
                        Box(modifier = Modifier.weight(1f).aspectRatio(1f))
                    } else {
                        val date = currentMonth.atDay(dayCounter)
                        val dayEvents = events.filter { parseEventDate(it.event.start) == date }
                        DayCell(
                            day = dayCounter,
                            isToday = date == today,
                            isSelected = date == selectedDate,
                            eventCount = dayEvents.size,
                            eventColors = dayEvents.mapNotNull { it.event.categoryColor }.distinct(),
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clickable { onDateSelected(date) }
                        )
                    }
                    dayCounter++
                }
            }
        }
    }
}

@Composable
private fun DayCell(
    day: Int,
    isToday: Boolean,
    isSelected: Boolean,
    eventCount: Int,
    eventColors: List<String>,
    modifier: Modifier = Modifier
) {
    val bgColor = when {
        isSelected -> MaterialTheme.colorScheme.primary
        isToday -> MaterialTheme.colorScheme.primaryContainer
        else -> Color.Transparent
    }
    val textColor = when {
        isSelected -> MaterialTheme.colorScheme.onPrimary
        else -> MaterialTheme.colorScheme.onSurface
    }

    Box(
        modifier = modifier.padding(2.dp).clip(CircleShape).background(bgColor),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = day.toString(), color = textColor, fontSize = 14.sp)
            if (eventCount > 0) {
                Row(horizontalArrangement = Arrangement.Center) {
                    eventColors.take(3).forEach { color ->
                        Box(
                            modifier = Modifier
                                .size(5.dp)
                                .clip(CircleShape)
                                .background(parseHexColor(color, MaterialTheme.colorScheme.primary))
                                .padding(1.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EventItem(event: EventWithMembers, onClick: () -> Unit) {
    val categoryColor = parseHexColor(event.event.categoryColor, MaterialTheme.colorScheme.primary)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp)
            .clickable { onClick() },
        shape = MaterialTheme.shapes.small,
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(start = 0.dp, end = 14.dp, top = 14.dp, bottom = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(44.dp)
                    .clip(MaterialTheme.shapes.extraSmall)
                    .background(categoryColor)
            )
            Spacer(modifier = Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = event.event.title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
                )
                val timeText = formatDateTimeRange(event.event.start, event.event.end, event.event.allDay)
                if (timeText.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = timeText,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            if (event.members.isNotEmpty()) {
                Spacer(modifier = Modifier.width(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy((-4).dp)) {
                    event.members.take(3).forEach { member ->
                        Text(text = member.avatarEmoji, fontSize = 20.sp)
                    }
                }
            }
        }
    }
}

