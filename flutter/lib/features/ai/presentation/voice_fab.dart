import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import 'voice_assistant_sheet.dart';

enum VoiceState { idle, listening, processing }

final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);

class VoiceFAB extends ConsumerWidget {
  const VoiceFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.amberGradient,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: AppColors.onSecondary,
          size: 30,
        ),
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
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantSheet(),
    );
  }
}
