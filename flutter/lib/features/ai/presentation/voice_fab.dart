import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_repository.dart';
import '../domain/ai_models.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

enum VoiceState { idle, listening, processing }

final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);

class VoiceFAB extends ConsumerWidget {
  const VoiceFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceStateProvider);

    return FloatingActionButton(
      heroTag: 'voiceFab',
      onPressed: () => _handleTap(context, ref),
      backgroundColor: state == VoiceState.listening
          ? Colors.red
          : state == VoiceState.processing
              ? Colors.orange
              : null,
      child: Icon(
        state == VoiceState.listening
            ? Icons.mic
            : state == VoiceState.processing
                ? Icons.hourglass_top
                : Icons.mic_none,
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    final state = ref.read(voiceStateProvider);
    if (state == VoiceState.processing) return;
    _showVoiceDialog(context, ref);
  }

  void _showVoiceDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VoiceCommandSheet(),
    );
  }
}

class _VoiceCommandSheet extends ConsumerStatefulWidget {
  const _VoiceCommandSheet();

  @override
  ConsumerState<_VoiceCommandSheet> createState() => _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends ConsumerState<_VoiceCommandSheet> {
  final _textController = TextEditingController();
  bool _isListening = false;
  bool _isProcessing = false;
  VoiceCommandResult? _result;
  String _transcript = '';

  // Speech recognition would use speech_to_text package here.
  // For cross-platform compatibility, we provide a text fallback.

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _transcript = '';
      _result = null;
    });
    ref.read(voiceStateProvider.notifier).state = VoiceState.listening;

    // In production, use speech_to_text package:
    // final speech = SpeechToText();
    // final available = await speech.initialize();
    // if (available) {
    //   speech.listen(
    //     onResult: (result) => setState(() => _transcript = result.recognizedWords),
    //     localeId: 'de_DE',
    //     pauseFor: Duration(seconds: 5),
    //   );
    // }

    // Fallback: Show text input
    setState(() => _isListening = false);
    ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
  }

  Future<void> _sendCommand(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
      _result = null;
    });
    ref.read(voiceStateProvider.notifier).state = VoiceState.processing;

    try {
      final result = await ref.read(aiRepositoryProvider).voiceCommand(text: text.trim());
      setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('Sprachassistent', style: theme.textTheme.titleLarge)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // Voice animation / status
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.mic, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Hoere zu...', style: theme.textTheme.bodyLarge),
                      if (_transcript.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_transcript, style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Verarbeite Befehl...'),
                    ],
                  ),
                ),

              // Result display
              if (_result != null)
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_result!.summary != null) ...[
                          Card(
                            color: _result!.success
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    _result!.success ? Icons.check_circle : Icons.error,
                                    color: _result!.success ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_result!.summary!)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ..._result!.actions.map((action) => ListTile(
                              dense: true,
                              leading: Icon(
                                action.success ? Icons.check : Icons.close,
                                color: action.success ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              title: Text(_actionLabel(action.type)),
                              subtitle: action.message != null ? Text(action.message!) : null,
                            )),
                      ],
                    ),
                  ),
                ),

              // Text input (fallback / always available)
              if (!_isListening && !_isProcessing && _result == null)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('Tippe auf das Mikrofon oder gib Text ein',
                          style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    ],
                  ),
                ),

              const Spacer(),

              // Input bar
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.red : null,
                    ),
                    onPressed: _isProcessing ? null : _startListening,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Befehl eingeben...',
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) {
                        _sendCommand(text);
                        _textController.clear();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _sendCommand(_textController.text);
                            _textController.clear();
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _actionLabel(String type) {
    const labels = {
      'create_event': 'Termin erstellt',
      'create_recurring_event': 'Serientermin erstellt',
      'create_todo': 'Aufgabe erstellt',
      'create_recipe': 'Rezept erstellt',
      'set_meal_slot': 'Essensplan belegt',
      'add_shopping_item': 'Einkaufsartikel hinzugefuegt',
      'add_pantry_items': 'Vorrat aktualisiert',
      'generate_meal_plan': 'KI-Essensplan erstellt',
      'update_event': 'Termin aktualisiert',
      'update_todo': 'Aufgabe aktualisiert',
      'complete_todo': 'Aufgabe erledigt',
      'delete_event': 'Termin geloescht',
      'delete_todo': 'Aufgabe geloescht',
    };
    return labels[type] ?? type;
  }
}
