package de.familienkalender.app.ui.meals

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarViewWeek
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.ShoppingCart
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

private data class MealTab(val title: String, val icon: ImageVector)

private val mealTabs = listOf(
    MealTab("Wochenplan", Icons.Outlined.CalendarViewWeek),
    MealTab("Rezepte", Icons.Outlined.MenuBook),
    MealTab("Einkauf", Icons.Outlined.ShoppingCart)
)

@Composable
fun MealsScreen(app: FamilienkalenderApp) {
    val viewModel: MealsViewModel = viewModel(
        factory = MealsViewModel.Factory(
            app.mealPlanRepository, app.recipeRepository, app.shoppingRepository,
            app.retrofitClient.cookidooApi
        )
    )

    var selectedTab by remember { mutableIntStateOf(0) }

    Column(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Surface(color = Color.White, modifier = Modifier.fillMaxWidth()) {
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color.White,
                contentColor = MaterialTheme.colorScheme.primary,
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
            0 -> WeekPlanTab(viewModel)
            1 -> RecipesTab(viewModel)
            2 -> ShoppingTab(viewModel)
        }
    }
}
