import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_repository.dart';
import '../../domain/notification_level.dart';

final _levelsProvider = FutureProvider<List<NotificationLevel>>((ref) async {
  return ref.watch(notificationRepositoryProvider).listLevels();
});

class NotificationLevelPicker extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool allowNone;

  const NotificationLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowNone = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(_levelsProvider);
    return levelsAsync.when(
      data: (levels) {
        final sorted = [...levels]..sort((a, b) => a.position.compareTo(b.position));
        final defaultId = sorted.where((e) => e.isDefault).map((e) => e.id).cast<int?>().firstWhere(
              (e) => e != null,
              orElse: () => null,
            );
        final current = value ?? defaultId;
        return DropdownButtonFormField<int?>(
          isExpanded: true,
          value: current,
          decoration: const InputDecoration(
            labelText: 'Push-Dringlichkeit',
            prefixIcon: Icon(Icons.notifications_outlined),
          ),
          items: [
            if (allowNone)
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Keine'),
              ),
            for (final lvl in sorted)
              DropdownMenuItem<int?>(
                value: lvl.id,
                child: Text(lvl.name),
              ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => DropdownButtonFormField<int?>(
        isExpanded: true,
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Stufen werden geladen…'),
          ),
        ],
        onChanged: null,
        decoration: InputDecoration(
          labelText: 'Push-Dringlichkeit',
          prefixIcon: Icon(Icons.notifications_outlined),
        ),
      ),
      error: (e, _) => DropdownButtonFormField<int?>(
        isExpanded: true,
        items: const [
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Stufen konnten nicht geladen werden'),
          ),
        ],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Push-Dringlichkeit',
          prefixIcon: Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}

