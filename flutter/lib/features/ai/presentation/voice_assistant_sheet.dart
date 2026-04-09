import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_context.dart';

/// Internal states for the voice assistant overlay.
enum _VoiceAssistantState { listening, result }

/// Sample confirmed action for the result view.
class _ConfirmedAction {
  final String typeLabel;
  final String description;
  final String meta;

  const _ConfirmedAction({
    required this.typeLabel,
    required this.description,
    required this.meta,
  });
}

/// A modal bottom sheet / overlay that shows the voice assistant UI.
///
/// Use via [showModalBottomSheet] with [isScrollControlled: true] and
/// [backgroundColor: Colors.transparent].
///
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => const VoiceAssistantSheet(),
/// );
/// ```
class VoiceAssistantSheet extends StatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with TickerProviderStateMixin {
  _VoiceAssistantState _state = _VoiceAssistantState.listening;
  late AnimationController _waveformController;
  late AnimationController _pulseController;

  /// Simulated transcript text that appears during the listening demo.
  String _transcript = '';

  /// Guard so the demo timer is only scheduled once.
  bool _demoScheduled = false;

  /// Sample confirmed actions shown in the result state.
  static const List<_ConfirmedAction> _sampleActions = [
    _ConfirmedAction(
      typeLabel: 'EVENT ERSTELLT',
      description: 'Arzttermin morgen 15:00',
      meta: '12. Mai 2024, 15:00-16:00',
    ),
    _ConfirmedAction(
      typeLabel: 'TODO ERSTELLT',
      description: 'Einkaufsliste aktualisieren',
      meta: '3 Artikel hinzugefügt',
    ),
    _ConfirmedAction(
      typeLabel: 'EINKAUFSLISTE',
      description: 'Milch, Brot, Eier hinzugefügt',
      meta: 'Wocheneinkauf',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Waveform animation – continuous, smooth loop.
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Pulse animation for the "LISTENING…" label.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scheduleDemoTransition();
  }

  /// Schedules a timed demo that simulates voice input → result transition.
  void _scheduleDemoTransition() {
    if (_demoScheduled) return;
    _demoScheduled = true;

    // After 2 s show a simulated transcript.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _state == _VoiceAssistantState.listening) {
        setState(() {
          _transcript = 'Erstelle einen Termin morgen um 15 Uhr';
        });
      }
    });

    // After 4.5 s transition to the result state.
    Future.delayed(const Duration(seconds: 4, milliseconds: 500), () {
      if (mounted && _state == _VoiceAssistantState.listening) {
        setState(() {
          _state = _VoiceAssistantState.result;
        });
      }
    });
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Date formatting ──────────────────────────────────────────────────

  /// Returns the current date formatted as "Wochentag, D. Monat" in German.
  String _formatCurrentDate() {
    final now = DateTime.now();
    const weekdays = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]}';
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _VoiceAssistantState.listening => _buildListeningOverlay(),
      _VoiceAssistantState.result => _buildResultSheet(),
    };
  }

  // ── LISTENING STATE ──────────────────────────────────────────────────

  Widget _buildListeningOverlay() {
    final accent = Theme.of(context).colorScheme.primary;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          color: AppColors.surface.withOpacity(0.85),
          child: SafeArea(
            child: Column(
              children: [
                // Close button – top-right.
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spacing4),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.onSurfaceVariant,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Date / context line.
                Text(
                  _formatCurrentDate(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                ),

                const SizedBox(height: AppColors.spacing8),

                // Waveform visualisation.
                SizedBox(
                  height: 120,
                  width: 280,
                  child: AnimatedBuilder(
                    animation: _waveformController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _WaveformPainter(
                          animationValue: _waveformController.value,
                          color: accent,
                          barCount: 24,
                          barWidth: 4,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppColors.spacing4),

                // Pulsing "LISTENING…" label.
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.5 + 0.5 * _pulseController.value,
                      child: Text(
                        'LISTENING...',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  letterSpacing: 0.1,
                                ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppColors.spacing6),

                // Transcript area.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacing8,
                  ),
                  child: Text(
                    _transcript.isNotEmpty
                        ? '"$_transcript"'
                        : 'Sag etwas...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _transcript.isNotEmpty
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── RESULT STATE ─────────────────────────────────────────────────────

  Widget _buildResultSheet() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppColors.radiusLarge),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.surface.withOpacity(0.95),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppColors.spacing6,
                right: AppColors.spacing6,
                top: AppColors.spacing3,
                bottom: AppColors.spacing4 +
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle.
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppColors.spacing6),
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header – "Aktionen bestätigt".
                  Text(
                    'Aktionen bestätigt',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppColors.spacing4),

                  // Confirmation icon – 48×48 check_circle.
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: cs.primary,
                  ),

                  const SizedBox(height: AppColors.spacing6),

                  // Action list (spacing 16 px between items).
                  ..._sampleActions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppColors.spacing4,
                      ),
                      child: _ActionItem(action: action),
                    ),
                  ),

                  const SizedBox(height: AppColors.spacing6),

                  // "Fertig" – full-width primary gradient button.
                  SizedBox(
                    width: double.infinity,
                    child: _FullWidthPrimaryButton(
                      label: 'Fertig',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const SizedBox(height: AppColors.spacing4),

                  // "Rückgängig machen" – text-only link.
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Rückgängig machen',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppColors.spacing2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Waveform painter – animated vertical bars.
// ═══════════════════════════════════════════════════════════════════════

class _WaveformPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final int barCount;
  final double barWidth;

  _WaveformPainter({
    required this.animationValue,
    required this.color,
    required this.barCount,
    required this.barWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 4.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final startX = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;

    for (var i = 0; i < barCount; i++) {
      // Varying heights via layered sine waves with per-bar phase offset.
      final phase = i * 0.45;
      final normalisedHeight = (sin(animationValue * 2 * pi + phase) * 0.3 +
              sin(animationValue * 2 * pi + phase * 1.7) * 0.2 +
              0.5)
          .clamp(0.1, 1.0);

      final barHeight = normalisedHeight * size.height * 0.85;
      final x = startX + i * (barWidth + gap);
      final y = centerY - barHeight / 2;

      // Opacity scales with height for a more dynamic feel.
      final paint = Paint()
        ..color = color.withOpacity(0.5 + 0.5 * normalisedHeight)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════
// Single confirmed-action row.
// ═══════════════════════════════════════════════════════════════════════

class _ActionItem extends StatelessWidget {
  final _ConfirmedAction action;

  const _ActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppColors.spacing4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppColors.radiusDefault),
      ),
      child: Row(
        children: [
          // 24×24 rounded-full status icon.
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: cs.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: AppColors.spacing3),

          // Text column.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label – UPPERCASE, primary.
                Text(
                  action.typeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                  ),
                ),
                const SizedBox(height: 2),
                // Description.
                Text(
                  action.description,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                // Meta info.
                Text(
                  action.meta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Full-width primary gradient button (pill-shaped).
// ═══════════════════════════════════════════════════════════════════════

class _FullWidthPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _FullWidthPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_FullWidthPrimaryButton> createState() =>
      _FullWidthPrimaryButtonState();
}

class _FullWidthPrimaryButtonState extends State<_FullWidthPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final onPrimaryContainer = Theme.of(context).colorScheme.onPrimaryContainer;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: context.accentLinearGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing8,
            vertical: AppColors.spacing4,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
