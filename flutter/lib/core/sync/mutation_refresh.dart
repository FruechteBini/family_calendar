import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_shell.dart';
import '../../features/calendar/presentation/today_screen_real.dart';
import '../../features/categories/categories_providers.dart';
import '../../features/members/presentation/members_screen.dart';
import '../../features/notes/data/note_category_repository.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/notifications/presentation/widgets/notification_level_picker.dart';
import '../../features/recipes/presentation/recipe_list_screen.dart';
import '../../features/shopping/presentation/shopping_list_screen_real.dart';
import '../../features/todos/presentation/todo_list_refresh.dart';
import 'sync_service.dart';

/// After destructive or structural mutations, bump this so providers that
/// [ref.watch(syncTickProvider)] refetch (calendar month, pantry, week plan, …).
void bumpGlobalDataRefresh(WidgetRef ref) {
  ref.read(syncTickProvider.notifier).state++;
}

/// Refetch lists that do not depend on [syncTickProvider] (todos, categories, …).
void refreshAfterMutation(WidgetRef ref) {
  bumpGlobalDataRefresh(ref);
  ref.read(todoListRefreshTriggerProvider.notifier).state++;
  ref.invalidate(categoriesListProvider);
  ref.invalidate(membersListProvider);
  ref.invalidate(todayEventsProvider);
  ref.invalidate(todayTodosProvider);
  ref.invalidate(todayMembersProvider);
  invalidateAllNotesScopes(ref);
  invalidateNoteCategoryCaches(ref);
  ref.invalidate(recipesProvider);
  ref.invalidate(recipeTagsForFilterProvider);
  ref.invalidate(recipeCategoriesListProvider);
  ref.invalidate(recipeSuggestionsProvider);
  ref.invalidate(noteTagsListProvider);
  ref.invalidate(notificationLevelsListProvider);
  ref.invalidate(pendingProposalsProvider);
  ref.invalidate(shoppingListProvider);
}
