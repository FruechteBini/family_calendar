import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/family/presentation/family_onboarding_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/todos/presentation/todo_list_screen.dart';
import '../features/meals/presentation/meals_screen.dart';
import '../features/members/presentation/members_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/calendar',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final isAuth = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isFamilyRoute = state.matchedLocation == '/family-onboarding';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) {
        if (!authState.hasFamilyId) return '/family-onboarding';
        return '/calendar';
      }
      if (isAuth && !authState.hasFamilyId && !isFamilyRoute) {
        return '/family-onboarding';
      }
      if (isAuth && authState.hasFamilyId && isFamilyRoute) {
        return '/calendar';
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
