import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api/api_client.dart';
import '../core/family/family_profile.dart';
import '../core/theme/colors.dart';
import '../core/sync/sync_service.dart';
import '../core/speech/speech_service.dart';
import '../core/speech/voice_state.dart';
import '../features/ai/data/ai_repository.dart';
import '../features/ai/domain/ai_models.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/domain/todo.dart';
import '../shared/widgets/toast.dart';

// ── Providers ────────────────────────────────────────────────────────────

final pendingProposalsProvider = FutureProvider<List<Proposal>>((ref) async {
  try {
    return await ref.watch(todoRepositoryProvider).getPendingProposals();
  } catch (_) {
    return [];
  }
});

/// Last primary tab (/today, /calendar, /todos, /meals, /notes) before opening secondary
/// routes (settings, members, …). Used when the shell back button has no stack to pop.
final lastMainTabLocationProvider = StateProvider<String>((ref) => '/today');
// Primary tabs: /today, /calendar, /todos, /meals, /notes

// ── App Shell ────────────────────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  void _dismissPopups(BuildContext context) {
    // Bottom sheets/dialogs can be attached to either the nearest Navigator
    // (e.g. inside a ShellRoute) or the root navigator. Close both.
    final navs = <NavigatorState>[
      Navigator.of(context),
      Navigator.of(context, rootNavigator: true),
    ];

    for (final nav in navs) {
      nav.popUntil((route) => route is! PopupRoute);
    }
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/today')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/todos')) return 2;
    if (location.startsWith('/meals')) return 3;
    if (location.startsWith('/notes')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final pendingProposals = ref.watch(pendingProposalsProvider);
    final proposalCount = pendingProposals.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: const _FamilienherdAppBar(),
      body: child,
      bottomNavigationBar: _GlassmorphismNavBar(
        selectedIndex: index,
        proposalCount: proposalCount,
        onDestinationSelected: (i) {
          _dismissPopups(context);
          final path = switch (i) {
            0 => '/today',
            1 => '/calendar',
            2 => '/todos',
            3 => '/meals',
            4 => '/notes',
            _ => '/today',
          };
          ref.read(lastMainTabLocationProvider.notifier).state = path;
          context.go(path);
        },
      ),
      floatingActionButton: const _FamilienherdVoiceFAB(),
      floatingActionButtonLocation: const _VoiceFABLocation(),
    );
  }
}

// ── 8.2 Top App Bar ─────────────────────────────────────────────────────

class _FamilienherdAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _FamilienherdAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(88);

  bool _isTopLevelTab(String location) {
    final todosMain =
        location == '/todos' || location.startsWith('/todos?');
    return location.startsWith('/today') ||
        location.startsWith('/calendar') ||
        todosMain ||
        location.startsWith('/meals') ||
        location.startsWith('/notes');
  }

  void _goBackToMenu(BuildContext context) {
    // Close any open bottom sheets/dialogs first.
    Navigator.of(context, rootNavigator: true).popUntil((r) => r is! PopupRoute);

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    // If there is no navigation stack (e.g. direct deep link), go to the main menu.
    context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final showBack = !_isTopLevelTab(location);

    return const _FamilyAwareTopBar();
  }
}

class _FamilyAwareTopBar extends ConsumerWidget {
  const _FamilyAwareTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).matchedLocation;
    final isTodosList =
        location == '/todos' || location.startsWith('/todos?');
    final showBack = !location.startsWith('/today') &&
        !location.startsWith('/calendar') &&
        !isTodosList &&
        !location.startsWith('/meals') &&
        !location.startsWith('/notes');

    final familyInfo = ref.watch(familyInfoProvider);
    final familyName = familyInfo.valueOrNull?.name ?? 'Familienherd';

    final avatarPathAsync = ref.watch(familyAvatarPathProvider);
    final avatarPath = avatarPathAsync.valueOrNull;
    final avatarFile = (avatarPath != null && avatarPath.isNotEmpty)
        ? FileImage(File(avatarPath))
        : null;

    void goBackToMenu() {
      Navigator.of(context, rootNavigator: true).popUntil((r) => r is! PopupRoute);
      final router = GoRouter.of(context);
      final loc = GoRouterState.of(context).matchedLocation;

      if (loc.startsWith('/members') || loc.startsWith('/categories')) {
        context.go('/settings');
        return;
      }
      if (router.canPop()) {
        router.pop();
        return;
      }
      // Opened with context.go (no stack), e.g. deep link — return to settings
      if (loc.startsWith('/notification-settings') ||
          loc.startsWith('/google-sync') ||
          loc.startsWith('/app-info')) {
        context.go('/settings');
        return;
      }
      if (loc.startsWith('/settings')) {
        context.go(ref.read(lastMainTabLocationProvider));
        return;
      }
      if (loc.startsWith('/knuspr') || loc.startsWith('/recipes/')) {
        context.go('/meals');
        return;
      }
      if (loc.startsWith('/events/')) {
        context.go(ref.read(lastMainTabLocationProvider));
        return;
      }
      if (loc.startsWith('/todos/')) {
        context.go('/todos');
        return;
      }
      context.go('/today');
    }

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                if (showBack)
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: goBackToMenu,
                      hoverColor: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppColors.radiusFull),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primaryContainer,
                        width: 2,
                      ),
                      color: AppColors.surfaceContainerHigh,
                      image: avatarFile != null
                          ? DecorationImage(image: avatarFile, fit: BoxFit.cover)
                          : null,
                    ),
                    child: avatarFile == null
                        ? const Icon(
                            Icons.family_restroom,
                            color: AppColors.onSurface,
                            size: 20,
                          )
                        : null,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    familyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.getFont(
                      'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((r) => r is! PopupRoute);
                      context.go('/settings');
                    },
                    hoverColor: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppColors.radiusFull),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.settings,
                        color: cs.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 8.1 Glassmorphism Bottom Navigation Bar ──────────────────────────────

class _GlassmorphismNavBar extends StatelessWidget {
  final int selectedIndex;
  final int proposalCount;
  final ValueChanged<int> onDestinationSelected;

  const _GlassmorphismNavBar({
    required this.selectedIndex,
    required this.proposalCount,
    required this.onDestinationSelected,
  });

  static const _items = [
    (icon: Icons.today, label: 'Heute'),
    (icon: Icons.calendar_month, label: 'Kalender'),
    (icon: Icons.assignment, label: 'Todos'),
    (icon: Icons.restaurant, label: 'Essen'),
    (icon: Icons.note_alt_outlined, label: 'Notizen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.80),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppColors.radiusXL),
          topRight: Radius.circular(AppColors.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.surface.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppColors.radiusXL),
          topRight: Radius.circular(AppColors.radiusXL),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final isSelected = i == selectedIndex;
                  final showBadge = i == 2 && proposalCount > 0;

                  return Expanded(
                    child: _NavItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      showBadge: showBadge,
                      badgeCount: proposalCount,
                      onTap: () => onDestinationSelected(i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item (with press scale animation) ───────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showBadge;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.showBadge,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ACTIVE → surface (on primaryContainer pill)
    // INACTIVE + HOVER → primary
    // INACTIVE → surfaceContainerHighest
    final Color color;
    if (widget.isSelected) {
      color = AppColors.surface;
    } else if (_isHovered) {
      color = cs.primary;
    } else {
      color = AppColors.surfaceContainerHighest;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _isPressed ? 0.9 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSelected ? 20 : 0,
              vertical: widget.isSelected ? 8 : 0,
            ),
            decoration: widget.isSelected
                ? BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppColors.radiusFull),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.showBadge
                    ? Badge(
                        label: Text('${widget.badgeCount}'),
                        child: Icon(
                          widget.icon,
                          color: color,
                          size: 24,
                        ),
                      )
                    : Icon(
                        widget.icon,
                        color: color,
                        size: 24,
                      ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      widget.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.getFont(
                        'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.05,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Voice FAB Location ──────────────────────────────────────────────────

/// Custom FAB location: bottom-left, 32px from left edge, 16px above
/// the bottom navigation bar content area.
class _VoiceFABLocation extends FloatingActionButtonLocation {
  const _VoiceFABLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    // Keep this aligned with the standard FAB "endFloat" margins,
    // but mirrored to the left side.
    const double leftMargin = 16.0;
    const double bottomMargin = 16.0;

    // Position relative to the content area (above the bottom nav bar).
    final double contentBottom = geometry.contentBottom;
    final Size fabSize = geometry.floatingActionButtonSize;

    return Offset(
      leftMargin,
      contentBottom - bottomMargin - fabSize.height,
    );
  }
}

// ── 8.3 Voice FAB (Floating Action Button) ──────────────────────────────

class _FamilienherdVoiceFAB extends ConsumerStatefulWidget {
  const _FamilienherdVoiceFAB();

  @override
  ConsumerState<_FamilienherdVoiceFAB> createState() =>
      _FamilienherdVoiceFABState();
}

class _FamilienherdVoiceFABState
    extends ConsumerState<_FamilienherdVoiceFAB>
    with SingleTickerProviderStateMixin {
  static const double _fabSize = 56.0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final voiceState = ref.watch(voiceStateProvider);

    // Determine target scale: hover → 1.1, press → 0.95, default → 1.0
    double targetScale = 1.0;
    if (_isPressed) {
      targetScale = 0.95;
    } else if (_isHovered) {
      targetScale = 1.1;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(end: targetScale),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _handleTap(context, ref);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: SizedBox(
            width: _fabSize,
            height: _fabSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring — LISTENING state only
                if (voiceState == VoiceState.listening)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: _fabSize * _pulseAnimation.value,
                        height: _fabSize * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      );
                    },
                  ),

                // Main FAB — 64×64 rounded-full
                Container(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // IDLE: amber gradient, LISTENING: error, PROCESSING: tertiary
                    gradient: voiceState == VoiceState.idle
                        ? AppColors.amberGradient
                        : null,
                    color: voiceState == VoiceState.listening
                        ? AppColors.error
                        : voiceState == VoiceState.processing
                            ? AppColors.tertiary
                            : null,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.08),
                        blurRadius: 40,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Icon(
                    // PROCESSING: hourglass_top, otherwise: mic
                    voiceState == VoiceState.processing
                        ? Icons.hourglass_top
                        : Icons.mic,
                    color: AppColors.onSecondary,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
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
      builder: (_) => const _VoiceCommandSheet(),
    );
  }
}

// ── Voice Command Sheet ──────────────────────────────────────────────────

class _VoiceCommandSheet extends ConsumerStatefulWidget {
  const _VoiceCommandSheet();

  @override
  ConsumerState<_VoiceCommandSheet> createState() =>
      _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends ConsumerState<_VoiceCommandSheet> {
  bool _isProcessing = false;
  bool _isListening = false;
  /// True until the first mic session has started or failed (avoids a flash before auto-start).
  bool _voiceUiLoading = true;
  /// When true, a final STT result after [stopListening] should not trigger auto-send.
  bool _manualMicStopRequested = false;
  String _transcript = '';
  VoiceCommandResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSpeechInput();
    });
  }

  @override
  void dispose() {
    ref.read(speechServiceProvider).stopListening();
    if (ref.read(voiceStateProvider) == VoiceState.listening) {
      ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
    }
    super.dispose();
  }

  Future<void> _showMicSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mikrofon'),
        content: const Text(
          'Ohne Mikrofonzugriff funktioniert die Spracherkennung nicht. '
          'Bitte erlaube den Zugriff in den App-Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopListeningManual() async {
    final speech = ref.read(speechServiceProvider);
    _manualMicStopRequested = true;
    await speech.stopListening();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _transcript = '';
      _voiceUiLoading = false;
    });
    ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
  }

  Future<void> _startSpeechInput() async {
    if (_isListening || _isProcessing) return;

    final speech = ref.read(speechServiceProvider);
    _manualMicStopRequested = false;
    setState(() {
      _transcript = '';
      _voiceUiLoading = true;
    });

    final perm = await speech.requestMicrophoneIfNeeded();
    if (!mounted) return;

    if (perm == MicrophonePermissionStatus.permanentlyDenied) {
      if (mounted) setState(() => _voiceUiLoading = false);
      await _showMicSettingsDialog();
      return;
    }
    if (perm != MicrophonePermissionStatus.granted) {
      if (mounted) setState(() => _voiceUiLoading = false);
      showAppToast(
        context,
        message: 'Mikrofonzugriff verweigert.',
        type: ToastType.error,
      );
      return;
    }

    final ok = await speech.ensureInitialized(
      onError: (message) {
        if (!mounted) return;
        showAppToast(
          context,
          message: message,
          type: ToastType.error,
        );
      },
    );
    if (!mounted) return;

    if (!ok) {
      if (mounted) setState(() => _voiceUiLoading = false);
      showAppToast(
        context,
        message: 'Spracherkennung ist auf diesem Gerät nicht verfügbar.',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isListening = true;
      _voiceUiLoading = false;
    });
    ref.read(voiceStateProvider.notifier).state = VoiceState.listening;

    try {
      await speech.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _transcript = text);
          if (!isFinal) return;

          speech.stopListening();

          if (_manualMicStopRequested) {
            _manualMicStopRequested = false;
            setState(() => _isListening = false);
            ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
            return;
          }

          final trimmed = text.trim();
          setState(() => _isListening = false);
          ref.read(voiceStateProvider.notifier).state = VoiceState.idle;

          if (trimmed.isEmpty) {
            if (mounted) setState(() => _transcript = '');
            return;
          }

          if (mounted) setState(() => _transcript = '');
          _sendCommand(trimmed);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceUiLoading = false;
      });
      ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
      showAppToast(
        context,
        message: 'Spracherkennung konnte nicht gestartet werden.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _sendCommand(String text) async {
    if (text.trim().isEmpty) return;

    await ref.read(speechServiceProvider).stopListening();
    if (mounted && _isListening) {
      setState(() => _isListening = false);
    }
    ref.read(voiceStateProvider.notifier).state = VoiceState.processing;

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final result = await ref
          .read(aiRepositoryProvider)
          .voiceCommand(text: text.trim());
      if (mounted) setState(() => _result = result);

      // If something was mutated server-side (event/todo/shopping/etc), force a sync + refresh.
      final hasSuccessfulAction = result.success ||
          result.actions.any((a) => a.success);
      if (hasSuccessfulAction) {
        try {
          await ref.read(syncServiceProvider).sync();
        } catch (_) {
          // Sync is best-effort here; UI will still show server result next refresh.
        }
        if (mounted) {
          ref.read(syncTickProvider.notifier).state++;
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusXL),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Row(
            children: [
              Text(
                'Sprachassistent',
                style: GoogleFonts.getFont(
                  'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.onSurface),
                onPressed: () async {
                  await ref.read(speechServiceProvider).stopListening();
                  ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Processing indicator
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(color: cs.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Verarbeite Befehl...',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          // Result display
          if (_result != null) ...[
            if (_result!.summary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _result!.success
                        ? cs.primaryContainer.withOpacity(0.15)
                        : AppColors.error.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusDefault),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _result!.success
                            ? Icons.check_circle
                            : Icons.error,
                        color: _result!.success
                            ? cs.primary
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _result!.summary!,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ..._result!.actions.map(
              (action) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  action.success ? Icons.check : Icons.close,
                  color: action.success
                      ? cs.primary
                      : AppColors.error,
                  size: 20,
                ),
                title: Text(
                  _actionLabel(action.type),
                  style: const TextStyle(color: AppColors.onSurface),
                ),
                subtitle: action.message != null
                    ? Text(
                        action.message!,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _result = null);
                      _startSpeechInput();
                    },
                    child: const Text('Neuer Befehl'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fertig'),
                  ),
                ),
              ],
            ),
          ],

          // Nur Sprache: Auto-Start beim Öffnen; Transkript + Stopp (kein Textfeld).
          if (!_isProcessing && _result == null) ...[
            if (_voiceUiLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _transcript.isEmpty
                          ? 'Zuhören…'
                          : '„$_transcript“',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _stopListeningManual,
                      icon: const Icon(Icons.stop),
                      label: const Text('Beenden'),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic_none,
                      size: 48,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _startSpeechInput,
                      child: const Text('Erneut sprechen'),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _actionLabel(String type) {
    const labels = {
      'create_event': 'Termin erstellt',
      'create_recurring_event': 'Serientermin erstellt',
      'create_todo': 'Aufgabe erstellt',
      'create_recipe': 'Rezept erstellt',
      'set_meal_slot': 'Essensplan belegt',
      'add_shopping_item': 'Einkaufsartikel hinzugefügt',
      'add_pantry_items': 'Vorrat aktualisiert',
      'generate_meal_plan': 'KI-Essensplan erstellt',
      'update_event': 'Termin aktualisiert',
      'update_todo': 'Aufgabe aktualisiert',
      'complete_todo': 'Aufgabe erledigt',
      'delete_event': 'Termin gelöscht',
      'delete_todo': 'Aufgabe gelöscht',
      'send_to_knuspr': 'Einkaufsliste an Knuspr gesendet',
    };
    return labels[type] ?? type;
  }
}
