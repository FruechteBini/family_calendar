import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_service.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    final count = pendingCount.valueOrNull ?? 0;

    if (status == SyncStatus.idle && count == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(status, count),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing)
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(_icon(status, count), size: 14, color: _iconColor(status, count)),
          const SizedBox(width: 6),
          Text(
            _label(status, count),
            style: TextStyle(fontSize: 12, color: _iconColor(status, count)),
          ),
        ],
      ),
    );
  }

  Color _backgroundColor(SyncStatus status, int count) {
    if (status == SyncStatus.syncing) return Colors.blue.withOpacity(0.1);
    if (status == SyncStatus.error) return Colors.red.withOpacity(0.1);
    if (count > 0) return Colors.orange.withOpacity(0.1);
    return Colors.green.withOpacity(0.1);
  }

  Color _iconColor(SyncStatus status, int count) {
    if (status == SyncStatus.syncing) return Colors.blue;
    if (status == SyncStatus.error) return Colors.red;
    if (count > 0) return Colors.orange;
    return Colors.green;
  }

  IconData _icon(SyncStatus status, int count) {
    if (status == SyncStatus.error) return Icons.sync_problem;
    if (count > 0) return Icons.sync;
    return Icons.check_circle;
  }

  String _label(SyncStatus status, int count) {
    if (status == SyncStatus.syncing) return 'Synchronisiere...';
    if (status == SyncStatus.error) return 'Sync-Fehler';
    if (count > 0) return '$count ausstehend';
    return 'Synchronisiert';
  }
}
