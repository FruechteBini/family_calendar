import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to force [todosProvider] to refetch (see [todo_list_screen.dart]).
final todoListRefreshTriggerProvider = StateProvider<int>((ref) => 0);
