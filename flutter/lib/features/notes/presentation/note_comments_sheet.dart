import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';

class NoteCommentsSheet extends ConsumerStatefulWidget {
  final Note note;

  const NoteCommentsSheet({super.key, required this.note});

  @override
  ConsumerState<NoteCommentsSheet> createState() => _NoteCommentsSheetState();
}

class _NoteCommentsSheetState extends ConsumerState<NoteCommentsSheet> {
  final _controller = TextEditingController();
  late Note _note;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final n = await ref.read(noteRepositoryProvider).getNote(_note.id);
      if (mounted) setState(() => _note = n);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(noteRepositoryProvider).addComment(_note.id, text);
      _controller.clear();
      await _reload();
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Kommentare',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _note.comments.length,
                  itemBuilder: (_, i) {
                    final c = _note.comments[i];
                    final name = c.member?.name ?? 'Mitglied';
                    final emoji = c.member?.avatarEmoji ?? '👤';
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(emoji),
                      ),
                      title: Text(name),
                      subtitle: Text(c.content),
                      trailing: Text(
                        _formatTime(c.createdAt),
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Kommentar schreiben…',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final d = t.toLocal();
    return '${d.day}.${d.month}. ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
