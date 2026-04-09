import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../data/meal_repository.dart';
import '../domain/meal_plan.dart';

/// Loads the current week plan (Mon–Sun) from the backend.
///
/// Invalidate this provider after changes (set/clear slot, mark cooked, AI confirm/undo).
final weekPlanProvider = FutureProvider<MealPlan>((ref) async {
  // Re-fetch after any mutation that bumps the global sync tick.
  ref.watch(syncTickProvider);
  return ref.watch(mealRepositoryProvider).getWeekPlan();
});

