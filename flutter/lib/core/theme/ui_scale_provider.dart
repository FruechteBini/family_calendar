import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'ui_scale_factor';
const double defaultUiScale = 1.0;
const double minUiScale = 0.75;
const double maxUiScale = 1.0;

final uiScaleProvider = AsyncNotifierProvider<UiScaleNotifier, double>(
  UiScaleNotifier.new,
);

class UiScaleNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_prefsKey) ?? defaultUiScale;
    } on PlatformException {
      return defaultUiScale;
    }
  }

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(minUiScale, maxUiScale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, clamped);
    } on PlatformException {
      // Persist failed, still update in-memory.
    }
    state = AsyncData(clamped);
  }

  Future<void> resetScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } on PlatformException {
      // ignore
    }
    state = const AsyncData(defaultUiScale);
  }
}
