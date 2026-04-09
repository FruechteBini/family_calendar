import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/family/presentation/family_onboarding_screen.dart';
import '../features/today/presentation/today_screen_real.dart';
import '../features/calendar/presentation/calendar_screen_real.dart';
import '../features/todos/presentation/todo_list_screen.dart';
import '../features/meals/presentation/meals_screen.dart';
import '../features/members/presentation/members_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/info/presentation/info_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/notes/presentation/note_categories_screen.dart';
import '../features/notes/presentation/note_tags_screen.dart';
import '../features/knuspr/presentation/knuspr_screen.dart';
import '../features/recipes/presentation/recipe_detail_screen.dart';
import 'app_shell.dart';

/// Bridges Riverpod [authStateProvider] to GoRouter's [refreshListenable]
/// so the router re-evaluates redirects without being fully recreated.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final _authChangeNotifierProvider = Provider<_AuthChangeNotifier>((ref) {
  return _AuthChangeNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(_authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoginRoute = state.matchedLocation == '/login';
      final isFamilyRoute = state.matchedLocation == '/family-onboarding';

      // While loading, keep user on login screen
      if (authState.isLoading) {
        return isLoginRoute ? null : '/login';
      }

      final isAuth = authState.isAuthenticated;

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) {
        if (!authState.hasFamilyId) return '/family-onboarding';
        return '/today';
      }
      if (isAuth && !authState.hasFamilyId && !isFamilyRoute) {
        return '/family-onboarding';
      }
      if (isAuth && authState.hasFamilyId && isFamilyRoute) {
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/family-onboarding',
        builder: (context, state) => const FamilyOnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: '/todos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodoListScreen()),
          ),
          GoRoute(
            path: '/meals',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MealsScreen()),
          ),
          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotesScreen()),
          ),
          GoRoute(
            path: '/info',
            redirect: (context, state) => '/settings',
          ),
          GoRoute(
            path: '/app-info',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InfoScreen()),
          ),
          GoRoute(
            path: '/note-categories',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NoteCategoriesScreen()),
          ),
          GoRoute(
            path: '/note-tags',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NoteTagsScreen()),
          ),
          GoRoute(
            path: '/recipes/:id',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['id'] ?? '';
              final id = int.tryParse(idStr) ?? 0;
              return NoTransitionPage(child: RecipeDetailScreen(recipeId: id));
            },
          ),
          GoRoute(
            path: '/shopping',
            redirect: (context, state) => '/meals?tab=einkauf',
          ),
          GoRoute(
            path: '/knuspr',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KnusprScreen()),
          ),
          GoRoute(
            path: '/members',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MembersScreen()),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CategoriesScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
