import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_tab_swipe_scope.dart';
import '../../pantry/presentation/pantry_screen_real.dart';
import '../../recipes/presentation/recipe_list_screen.dart';
import '../../shopping/presentation/shopping_list_screen_real.dart';
import 'week_plan_screen.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  static const int _tabEinkauf = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    final initialIndex = tabParam == 'einkauf' ? _tabEinkauf : 0;

    return DefaultTabController(
      key: ValueKey('meals_tabs_$initialIndex'),
      length: 4,
      initialIndex: initialIndex,
      child: MainTabSwipeScope(
        child: Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Essen',
              style: theme.appBarTheme.titleTextStyle,
            ),
            bottom: TabBar(
              isScrollable: true,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05 * 12,
              ),
              unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 0.05 * 12,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.calendar_view_week), text: 'Wochenplan'),
                Tab(icon: Icon(Icons.menu_book), text: 'Rezepte'),
                Tab(icon: Icon(Icons.kitchen), text: 'Vorrat'),
                Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Einkaufsliste'),
              ],
            ),
          ),
          body: const MainTabSwipePageEdges(
            child: TabBarView(
              children: [
                WeekPlanScreen(),
                RecipeListScreen(),
                PantryScreen(),
                ShoppingListScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}