package de.familienkalender.app.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

val SHORT_DATE_GERMAN: DateTimeFormatter = DateTimeFormatter.ofPattern("d. MMM", Locale.GERMAN)
val SHORT_DATE_YEAR_GERMAN: DateTimeFormatter = DateTimeFormatter.ofPattern("d. MMM yyyy", Locale.GERMAN)
val FULL_DATE_GERMAN: DateTimeFormatter = DateTimeFormatter.ofPattern("d. MMMM yyyy", Locale.GERMAN)
val TIME_FORMAT: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm")

@Composable
fun LoadingScreen() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

@Composable
fun ErrorScreen(message: String, onRetry: (() -> Unit)? = null) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = message, style = MaterialTheme.typography.bodyLarge)
            if (onRetry != null) {
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = onRetry) {
                    Text("Erneut versuchen")
                }
            }
        }
    }
}

@Composable
fun OfflineBanner() {
    Surface(
        color = Color(0xFFFFA726),
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "Offline – Änderungen werden bei Verbindung synchronisiert",
            color = Color.White,
            style = MaterialTheme.typography.bodySmall,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
        )
    }
}

@Composable
fun EmptyState(message: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

fun priorityColor(priority: String): Color = when (priority) {
    "high" -> Color(0xFFE53935)
    "medium" -> Color(0xFFFFA726)
    "low" -> Color(0xFF4CAF50)
    else -> Color.Gray
}

fun priorityLabel(priority: String): String = when (priority) {
    "high" -> "Hoch"
    "medium" -> "Mittel"
    "low" -> "Niedrig"
    else -> priority
}

fun difficultyLabel(difficulty: String): String = when (difficulty) {
    "easy" -> "Einfach"
    "medium" -> "Mittel"
    "hard" -> "Schwer"
    else -> difficulty
}

fun categoryLabel(category: String): String = when (category) {
    "kuehlregal" -> "Kühlregal"
    "obst_gemuese" -> "Obst & Gemüse"
    "trockenware" -> "Trockenware"
    "drogerie" -> "Drogerie"
    "sonstiges" -> "Sonstiges"
    else -> category
}

fun categoryEmoji(category: String): String = when (category) {
    "kuehlregal" -> "\uD83E\uDDCA"
    "obst_gemuese" -> "\uD83E\uDD55"
    "trockenware" -> "\uD83C\uDF3E"
    "drogerie" -> "\uD83D\uDC8A"
    "sonstiges" -> "\uD83D\uDCE6"
    else -> "\uD83D\uDCE6"
}

fun parseHexColor(hex: String?, fallback: Color = Color.Gray): Color =
    hex?.let {
        try { Color(android.graphics.Color.parseColor(it)) }
        catch (_: Exception) { fallback }
    } ?: fallback

fun parseEventDate(isoString: String): LocalDate? =
    try {
        LocalDateTime.parse(isoString, DateTimeFormatter.ISO_LOCAL_DATE_TIME).toLocalDate()
    } catch (_: Exception) {
        try { LocalDate.parse(isoString.substring(0, 10)) }
        catch (_: Exception) { null }
    }

fun formatDateTimeRange(start: String, end: String, allDay: Boolean): String =
    try {
        if (allDay) {
            "Ganztägig"
        } else {
            val s = LocalDateTime.parse(start, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            val e = LocalDateTime.parse(end, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            "${s.format(TIME_FORMAT)} – ${e.format(TIME_FORMAT)}"
        }
    } catch (_: Exception) { "" }
