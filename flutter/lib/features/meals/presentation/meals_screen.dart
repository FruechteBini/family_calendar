import 'package:flutter/material.dart';
import '../../recipes/presentation/recipe_list_screen.dart';
import '../../pantry/presentation/pantry_screen.dart';
import 'week_plan_screen.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Essen',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.02 * 14,
            ),
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeekPlanScreen(),
            RecipeListScreen(),
            PantryScreen(),
          ],
        ),
      ),
    );
  }
}