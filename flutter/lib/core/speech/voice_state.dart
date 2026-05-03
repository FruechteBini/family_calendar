import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global voice UI state for the shell FAB and the voice command sheet.
enum VoiceState { idle, listening, processing }

final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);

/// When greater than zero, [AppShell] hides the global mic FAB (e.g. while a
/// note is created/edited or the share quick-capture sheet is open).
final voiceFabSuppressionCountProvider = StateProvider<int>((ref) => 0);

void suppressVoiceFab(Ref ref) {
  ref.read(voiceFabSuppressionCountProvider.notifier).state++;
}

void releaseVoiceFab(Ref ref) {
  final n = ref.read(voiceFabSuppressionCountProvider);
  if (n > 0) {
    ref.read(voiceFabSuppressionCountProvider.notifier).state = n - 1;
  }
}
