import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';

class TodoPreferences {
  final bool requireSubtodosComplete;
  final bool autoCompleteParent;

  const TodoPreferences({
    this.requireSubtodosComplete = false,
    this.autoCompleteParent = false,
  });

  TodoPreferences copyWith({
    bool? requireSubtodosComplete,
    bool? autoCompleteParent,
  }) {
    return TodoPreferences(
      requireSubtodosComplete:
          requireSubtodosComplete ?? this.requireSubtodosComplete,
      autoCompleteParent: autoCompleteParent ?? this.autoCompleteParent,
    );
  }
}

const _kRequireSubtodos = 'todo_require_subtodos_complete';
const _kAutoCompleteParent = 'todo_auto_complete_parent';

class TodoPreferencesNotifier extends AsyncNotifier<TodoPreferences> {
  @override
  Future<TodoPreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(Endpoints.authPreferences);
      final data = response.data as Map<String, dynamic>;
      final req = data['require_subtodos_complete'] as bool? ?? false;
      final auto = data['auto_complete_parent'] as bool? ?? false;
      await prefs.setBool(_kRequireSubtodos, req);
      await prefs.setBool(_kAutoCompleteParent, auto);
      return TodoPreferences(
        requireSubtodosComplete: req,
        autoCompleteParent: auto,
      );
    } catch (_) {
      return TodoPreferences(
        requireSubtodosComplete: prefs.getBool(_kRequireSubtodos) ?? false,
        autoCompleteParent: prefs.getBool(_kAutoCompleteParent) ?? false,
      );
    }
  }

  Future<void> setRequireSubtodosComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRequireSubtodos, value);
    final prev = state.valueOrNull ?? const TodoPreferences();
    state = AsyncData(prev.copyWith(requireSubtodosComplete: value));
    try {
      await ref.read(dioProvider).patch(
            Endpoints.authPreferences,
            data: {'require_subtodos_complete': value},
          );
    } catch (_) {
      // Keep local value; server sync can retry on next load
    }
  }

  Future<void> setAutoCompleteParent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoCompleteParent, value);
    final prev = state.valueOrNull ?? const TodoPreferences();
    state = AsyncData(prev.copyWith(autoCompleteParent: value));
    try {
      await ref.read(dioProvider).patch(
            Endpoints.authPreferences,
            data: {'auto_complete_parent': value},
          );
    } catch (_) {
      // Keep local value
    }
  }

  /// Refresh from server (e.g. after login).
  void refreshFromServer() {
    ref.invalidateSelf();
  }
}

final todoPreferencesProvider =
    AsyncNotifierProvider<TodoPreferencesNotifier, TodoPreferences>(
  TodoPreferencesNotifier.new,
);
