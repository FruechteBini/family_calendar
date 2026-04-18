import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

final recipeDetailProvider = FutureProvider.family<Recipe, int>((ref, id) async {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});
