import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/utils/date_utils.dart' as utils;
import '../../../shared/utils/app_time_picker.dart';
import '../../../core/api/api_client.dart';

final _pendingProvider = FutureProvider<List<Proposal>>((ref) {
  return ref.watch(todoRepositoryProvider).getPendingProposals();
});

class ProposalSheet extends ConsumerWidget {
  const ProposalSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposals = ref.watch(_pendingProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text('Terminvorschläge', style: theme.textTheme.titleMedium)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: proposals.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('Keine offenen Vorschläge'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: list.length,
                        itemBuilder: (_, i) => _ProposalTile(
                          proposal: list[i],
                          onRespond: () => ref.invalidate(_pendingProvider),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Fehler: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProposalTile extends ConsumerWidget {
  final Proposal proposal;
  final VoidCallback onRespond;

  const _ProposalTile({required this.proposal, required this.onRespond});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(proposal.todoTitle ?? 'Todo #${proposal.todoId}', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Von ${proposal.proposerName ?? '?'} am ${utils.AppDateUtils.formatDateTime(proposal.proposedDate)}',
              style: theme.textTheme.bodySmall,
            ),
            if (proposal.message != null) ...[
              const SizedBox(height: 4),
              Text(proposal.message!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _respond(context, ref, 'rejected'),
                  child: const Text('Ablehnen'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showCounterDialog(context, ref),
                  child: const Text('Gegenvorschlag'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _respond(context, ref, 'accepted'),
                  child: const Text('Annehmen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(todoRepositoryProvider).respondToProposal(
            proposal.id,
            response: status,
          );
      onRespond();
      if (context.mounted) showAppToast(context, message: status == 'accepted' ? 'Angenommen' : 'Abgelehnt', type: ToastType.success);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _showCounterDialog(BuildContext context, WidgetRef ref) async {
    DateTime counterDate = DateTime.now();
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Gegenvorschlag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDateTimePicker(ctx, counterDate);
                  if (picked != null) setDialogState(() => counterDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Datum & Uhrzeit'),
                  child: Text(utils.AppDateUtils.formatDateTime(counterDate)),
                ),
              ),
              const SizedBox(height: 12),
              LabeledMultilineTextField(
                label: 'Nachricht',
                controller: messageController,
                hintText: 'Optional — Kurzer Hinweis zum Gegenvorschlag …',
                minLines: 3,
                maxLines: 6,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Senden')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(todoRepositoryProvider).respondToProposal(
        proposal.id,
        response: 'rejected',
        counterDate: counterDate,
        message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
      );
      onRespond();
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

Future<DateTime?> showDateTimePicker(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
  );
  if (date == null) return null;
  if (!context.mounted) return null;
  final time = await showAppTimePicker(
    context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
