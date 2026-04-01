import 'package:flutter/material.dart';
import '../../recipes/presentation/recipe_list_screen.dart';
import '../../shopping/presentation/shopping_list_screen.dart';
import '../../pantry/presentation/pantry_screen.dart';
import 'week_plan_screen.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kueche'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.calendar_view_week), text: 'Wochenplan'),
              Tab(icon: Icon(Icons.menu_book), text: 'Rezepte'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Einkauf'),
              Tab(icon: Icon(Icons.kitchen), text: 'Vorrat'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeekPlanScreen(),
            RecipeListScreen(),
            ShoppingListScreen(),
            PantryScreen(),
          ],
        ),
      ),
    );
  }
}
