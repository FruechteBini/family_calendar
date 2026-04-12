import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global voice UI state for the shell FAB and the voice command sheet.
enum VoiceState { idle, listening, processing }

final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);
