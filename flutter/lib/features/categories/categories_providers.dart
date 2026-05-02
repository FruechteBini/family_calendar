import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import 'data/category_repository.dart';
import 'domain/category.dart';

/// Alle sichtbaren Todo-/Kalender-Kategorien (persönliche des Nutzers + Familie).
final categoriesListProvider = FutureProvider<List<Category>>((ref) {
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return ref.watch(categoryRepositoryProvider).getCategories(scope: 'all');
});

/// Nur Familien-Kategorien (z. B. Kalenderfarben-Vorgaben in den Einstellungen).
final familyTodoCategoriesListProvider = FutureProvider<List<Category>>((ref) {
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return ref.watch(categoryRepositoryProvider).getCategories(scope: 'family');
});

/// Persönliche bzw. Familien-Todo-Kategorien für die Verwaltungs-Ansicht (Tabs).
final todoCategoriesScopeProvider =
    FutureProvider.family<List<Category>, bool>((ref, personal) {
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return ref.watch(categoryRepositoryProvider).getCategories(
        scope: personal ? 'personal' : 'family',
      );
});

void invalidateTodoCategoryCaches(WidgetRef ref) {
  ref.invalidate(categoriesListProvider);
  ref.invalidate(familyTodoCategoriesListProvider);
  ref.invalidate(todoCategoriesScopeProvider(true));
  ref.invalidate(todoCategoriesScopeProvider(false));
}
