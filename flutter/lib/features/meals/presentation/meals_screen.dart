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
            toolbarHeight: 36,
            titleSpacing: 0,
            title: Text(
              'Essen',
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(38),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.only(left: 4, right: 4),
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelSmall,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    height: 36,
                    icon: Icon(Icons.calendar_view_week, size: 17),
                    text: 'Wochenplan',
                  ),
                  Tab(
                    height: 36,
                    icon: Icon(Icons.menu_book, size: 17),
                    text: 'Rezepte',
                  ),
                  Tab(
                    height: 36,
                    icon: Icon(Icons.kitchen, size: 17),
                    text: 'Vorrat',
                  ),
                  Tab(
                    height: 36,
                    icon: Icon(Icons.shopping_cart_outlined, size: 17),
                    text: 'Einkauf',
                  ),
                ],
              ),
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