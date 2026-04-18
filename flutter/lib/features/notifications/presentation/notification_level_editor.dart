import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/sync/mutation_refresh.dart';
import '../../../shared/widgets/toast.dart';
import '../data/notification_repository.dart';
import '../domain/notification_level.dart';

class NotificationLevelEditor extends ConsumerStatefulWidget {
  final NotificationLevel? level;
  const NotificationLevelEditor({super.key, this.level});

  @override
  ConsumerState<NotificationLevelEditor> createState() => _NotificationLevelEditorState();
}

class _NotificationLevelEditorState extends ConsumerState<NotificationLevelEditor> {
  late final TextEditingController _name;
  late List<int> _minutes;
  bool _isDefault = false;
  bool _saving = false;

  bool get _isEditing => widget.level != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.level?.name ?? '');
    _minutes = [...(widget.level?.remindersMinutes ?? const <int>[])];
    _isDefault = widget.level?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addMinutes() async {
    final controller = TextEditingController();
    final added = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zeitpunkt hinzufügen'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minuten im Voraus',
            helperText: 'Beispiele: 10080 (1 Woche), 1440 (1 Tag), 240 (4 Stunden), 0 (Zum Termin)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
    if (added == null) return;
    if (added < 0) return;
    setState(() {
      _minutes = ({..._minutes, added}).toList()..sort((a, b) => b.compareTo(a));
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppToast(context, message: 'Name erforderlich', type: ToastType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      if (_isEditing) {
        await repo.updateLevel(
          id: widget.level!.id,
          name: name,
          remindersMinutes: _minutes,
          isDefault: _isDefault,
        );
      } else {
        await repo.createLevel(
          NotificationLevel(
            id: 0,
            name: name,
            position: 999,
            remindersMinutes: _minutes,
            isDefault: _isDefault,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stufe löschen?'),
        content: Text('Soll "${widget.level!.name}" wirklich gelöscht werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(notificationRepositoryProvider).deleteLevel(widget.level!.id);
      refreshAfterMutation(ref);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Stufe bearbeiten' : 'Neue Stufe'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Als Standard verwenden'),
              value: _isDefault,
              onChanged: _saving ? null : (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _minutes.isEmpty ? 'Keine Zeitpunkte' : 'Zeitpunkte (${_minutes.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : _addMinutes,
                  icon: const Icon(Icons.add),
                  label: const Text('Hinzufügen'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_minutes.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Unwichtig: keine Push-Erinnerungen.'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in _minutes)
                    InputChip(
                      label: Text(_formatMinutes(m)),
                      onDeleted: _saving
                          ? null
                          : () => setState(() => _minutes = _minutes.where((x) => x != m).toList()),
                    )
                ],
              ),
          ],
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: const Text('Löschen'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Speichern'),
        ),
      ],
    );
  }

  static String _formatMinutes(int m) {
    if (m == 0) return 'Zum Termin';
    if (m % (60 * 24 * 7) == 0) return '${m ~/ (60 * 24 * 7)} Woche(n) vorher';
    if (m % (60 * 24) == 0) return '${m ~/ (60 * 24)} Tag(e) vorher';
    if (m % 60 == 0) return '${m ~/ 60} Stunde(n) vorher';
    return '$m min vorher';
  }
}

