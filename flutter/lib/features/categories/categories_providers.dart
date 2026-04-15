import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/category_repository.dart';
import 'domain/category.dart';

/// Gemeinsamer Cache für `/api/categories` (Todos, Kalender, Vorgaben).
final categoriesListProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});
