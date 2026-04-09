import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_repository.dart';
import '../logic/note_quick_capture.dart';
import 'notes_screen.dart';

String? extractTextFromSharedMedia(List<SharedMediaFile> files) {
  for (final f in files) {
    switch (f.type) {
      case SharedMediaType.url:
      case SharedMediaType.text:
        if (f.path.isNotEmpty) return f.path;
        break;
      case SharedMediaType.image:
      case SharedMediaType.video:
      case SharedMediaType.file:
        break;
    }
  }
  return null;
}

bool get _canReceiveShare =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Listens for Android/iOS share intents (text / URL) and creates a family note.
class NoteShareIntentListener extends ConsumerStatefulWidget {
  final Widget child;

  const NoteShareIntentListener({super.key, required this.child});

  @override
  ConsumerState<NoteShareIntentListener> createState() =>
      _NoteShareIntentListenerState();
}

class _NoteShareIntentListenerState extends ConsumerState<NoteShareIntentListener> {
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _started = false;
  String? _lastShareRaw;
  DateTime? _lastShareAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started || !mounted) return;
    if (!_canReceiveShare) return;
    _started = true;

    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      await _handleShare(initial);
    } catch (_) {}

    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (list) {
        unawaited(_handleShare(list));
      },
      onError: (_) {},
    );
  }

  Future<void> _handleShare(List<SharedMediaFile> list) async {
    if (list.isEmpty || !mounted) return;
    final raw = extractTextFromSharedMedia(list);
    try {
      await ReceiveSharingIntent.instance.reset();
    } catch (_) {}
    if (raw == null || raw.trim().isEmpty) return;
    final trimmed = raw.trim();
    final now = DateTime.now();
    if (_lastShareRaw == trimmed &&
        _lastShareAt != null &&
        now.difference(_lastShareAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastShareRaw = trimmed;
    _lastShareAt = now;

    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated || !auth.hasFamilyId) return;

    ref.read(notesScopeProvider.notifier).state = NotesScope.family;
    ref.read(routerProvider).go('/notes');

    final repo = ref.read(noteRepositoryProvider);
    final payload = buildQuickNotePayload(raw, isPersonal: false);
    try {
      await repo.createNote(payload);
      ref.invalidate(notesListProvider);
      showAppToastGlobal(
        message: 'In Familien-Notizen gespeichert',
        type: ToastType.success,
      );
    } on ApiException catch (e) {
      showAppToastGlobal(message: e.message, type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
