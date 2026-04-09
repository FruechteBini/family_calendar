import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'colors.dart';

const _prefsKey = 'accent_seed_color';

/// Persists the user-chosen accent (türkis by default). Drives [ColorScheme.primary]
/// and related roles (Navigation, +‑FAB-Bereich, Buttons, …).
final accentSeedColorProvider =
    AsyncNotifierProvider<AccentSeedColorNotifier, Color>(
  AccentSeedColorNotifier.new,
);

class AccentSeedColorNotifier extends AsyncNotifier<Color> {
  @override
  Future<Color> build() async {
    // On Android the shared_preferences Pigeon channel is not ready until after
    // the first frame is rasterized; early getInstance() throws channel-error.
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    return _loadFromPrefs();
  }

  Future<Color> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_prefsKey);
      if (v == null) return AppColors.primary;
      return Color(v);
    } on PlatformException {
      return AppColors.primary;
    }
  }

  Future<void> setAccent(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, _colorToArgb(color));
    } on PlatformException {
      // Still update in-memory theme; persistence unavailable.
    }
    state = AsyncData(color);
  }

  Future<void> resetAccent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } on PlatformException {
      // ignore
    }
    state = const AsyncData(AppColors.primary);
  }

  static int _colorToArgb(Color c) {
    final a = (c.a * 255.0).round() & 0xff;
    final r = (c.r * 255.0).round() & 0xff;
    final g = (c.g * 255.0).round() & 0xff;
    final b = (c.b * 255.0).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}
