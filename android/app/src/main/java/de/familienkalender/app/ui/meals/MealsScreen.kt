package de.familienkalender.app.ui.meals

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import de.familienkalender.app.FamilienkalenderApp
import java.time.format.DateTimeFormatter

private data class MealTab(val title: String, val icon: ImageVector)

private val mealTabs = listOf(
    MealTab("Wochenplan", Icons.Outlined.CalendarViewWeek),
    MealTab("Rezepte", Icons.Outlined.MenuBook),
    MealTab("Einkauf", Icons.Outlined.ShoppingCart),
    MealTab("Vorrat", Icons.Outlined.Kitchen)
)

@Composable
fun MealsScreen(app: FamilienkalenderApp) {
    val viewModel: MealsViewModel = viewModel(
        factory = MealsViewModel.Factory(
            app.mealPlanRepository, app.recipeRepository, app.shoppingRepository,
            app.retrofitClient.cookidooApi, app.aiRepository
        )
    )
    val pantryViewModel: PantryViewModel = viewModel(
        factory = PantryViewModel.Factory(app.pantryRepository)
    )

    var selectedTab by remember { mutableIntStateOf(0) }
    var showAiDialog by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Surface(color = Color.White, modifier = Modifier.fillMaxWidth()) {
            ScrollableTabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color.White,
                contentColor = MaterialTheme.colorScheme.primary,
                edgePadding = 0.dp,
                indicator = { tabPositions ->
                    if (selectedTab < tabPositions.size) {
                        TabRowDefaults.SecondaryIndicator(
                            modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                            height = 3.dp,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                divider = {}
            ) {
                mealTabs.forEachIndexed { index, tab ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Text(
                                tab.title,
                                fontSize = 13.sp,
                                fontWeight = if (selectedTab == index) FontWeight.SemiBold else FontWeight.Normal
                            )
                        },
                        icon = {
                            Icon(tab.icon, contentDescription = tab.title, modifier = Modifier.size(20.dp))
                        },
                        selectedContentColor = MaterialTheme.colorScheme.primary,
                        unselectedContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        when (selectedTab) {
            0 -> WeekPlanTab(viewModel, onOpenAiDialog = { showAiDialog = true })
            1 -> RecipesTab(viewModel)
            2 -> ShoppingTab(viewModel)
            3 -> PantryTab(pantryViewModel)
        }
    }

    if (showAiDialog) {
        val currentWeekStart by viewModel.currentWeekStart.collectAsState()
        val weekStr = currentWeekStart.format(DateTimeFormatter.ISO_LOCAL_DATE)

        val aiVm: AiMealPlanViewModel = viewModel(
            key = "ai_$weekStr",
            factory = AiMealPlanViewModel.Factory(app.aiRepository, weekStr)
        )

        AiMealPlanDialog(
            viewModel = aiVm,
            onDismiss = { showAiDialog = false },
            onConfirmed = { mealIds ->
                viewModel.setUndoMealIds(mealIds)
                viewModel.refreshAll()
                showAiDialog = false
            }
        )
    }
}
