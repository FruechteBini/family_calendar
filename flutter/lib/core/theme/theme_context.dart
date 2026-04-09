import 'package:flutter/material.dart';

import 'app_theme.dart';

extension FamilienThemeContext on BuildContext {
  /// Primary-style gradient (Navigation-Pille, PrimaryButton, …).
  LinearGradient get accentLinearGradient {
    final ext = Theme.of(this).extension<FamilienThemeTokens>();
    if (ext != null) return ext.accentGradient;
    final cs = Theme.of(this).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [cs.primaryContainer, cs.primary],
    );
  }
}
