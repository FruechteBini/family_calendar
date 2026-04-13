import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';

/// Horizontal swipe between bottom-nav main tabs
/// ([/today], [/calendar], [/todos], [/meals], [/notes]).
///
/// Uses [onHorizontalDragEnd] so vertical lists and [RefreshIndicator] stay
/// unaffected. Nested horizontal scrollables (e.g. [TabBarView]) receive the
/// drag first; use [MainTabSwipePageEdges] on those to cross at the first/last page.
class MainTabSwipeScope extends StatelessWidget {
  final Widget child;

  const MainTabSwipeScope({super.key, required this.child});

  static const _mainPaths = ['/today', '/calendar', '/todos', '/meals', '/notes'];

  static int? _mainIndex(String location) {
    if (location.startsWith('/today')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location == '/todos' || location.startsWith('/todos?')) return 2;
    if (location.startsWith('/meals')) return 3;
    if (location.startsWith('/notes')) return 4;
    return null;
  }

  static void _goToAdjacent(BuildContext context, WidgetRef ref, int delta) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _mainIndex(loc);
    if (i == null) return;
    final next = i + delta;
    if (next < 0 || next >= _mainPaths.length) return;
    final path = _mainPaths[next];
    ref.read(lastMainTabLocationProvider.notifier).state = path;
    context.go(path);
  }

  /// When a nested horizontal [PageView] / [TabBarView] is at the **first** page
  /// and the user keeps swiping to the previous side (right in LTR).
  static void tryCrossToPreviousMain(BuildContext context, WidgetRef ref) =>
      _goToAdjacent(context, ref, -1);

  /// When at the **last** page and the user swipes toward the next side (left in LTR).
  static void tryCrossToNextMain(BuildContext context, WidgetRef ref) =>
      _goToAdjacent(context, ref, 1);

  void _onHorizontalDragEnd(BuildContext context, WidgetRef ref, DragEndDetails d) {
    final v = d.primaryVelocity;
    if (v == null) return;
    // LTR: swipe right (finger moves right) → previous main tab; swipe left → next.
    const threshold = 400;
    if (v > threshold) {
      _goToAdjacent(context, ref, -1);
    } else if (v < -threshold) {
      _goToAdjacent(context, ref, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) => _onHorizontalDragEnd(context, ref, d),
          child: child,
        );
      },
    );
  }
}

/// Listens for horizontal overscroll on a [TabBarView]/[PageView] at the first or
/// last page and switches the main bottom-nav tab.
class MainTabSwipePageEdges extends StatelessWidget {
  final Widget child;

  const MainTabSwipePageEdges({super.key, required this.child});

  bool _onNotification(BuildContext context, WidgetRef ref, ScrollNotification n) {
    if (n.metrics.axis != Axis.horizontal) return false;
    if (n is! OverscrollNotification) return false;
    const minMag = 20.0;
    if (n.overscroll.abs() < minMag) return false;
    final atStart = n.metrics.pixels <= n.metrics.minScrollExtent + 1;
    final atEnd = n.metrics.pixels >= n.metrics.maxScrollExtent - 1;
    // Dragging toward "previous" page (right in LTR) at first tab → negative overscroll at min extent.
    if (atStart && n.overscroll < 0) {
      MainTabSwipeScope.tryCrossToPreviousMain(context, ref);
    } else if (atEnd && n.overscroll > 0) {
      MainTabSwipeScope.tryCrossToNextMain(context, ref);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (n) => _onNotification(context, ref, n),
          child: child,
        );
      },
    );
  }
}
