import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/domain/todo.dart';
import '../features/ai/presentation/voice_fab.dart';
import '../core/theme/colors.dart';

final pendingProposalsProvider = FutureProvider<List<Proposal>>((ref) async {
  return ref.watch(todoRepositoryProvider).getPendingProposals();
});

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/today')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/todos')) return 2;
    if (location.startsWith('/meals')) return 3;
    if (location.startsWith('/shopping')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final pendingProposals = ref.watch(pendingProposalsProvider);
    final proposalCount = pendingProposals.valueOrNull?.length ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final navBgColor = isDark
        ? StitchColorsDark.surfaceContainerLow
        : StitchColorsLight.surfaceContainerLow;

    return Scaffold(
      body: child,
      bottomNavigationBar: _StitchNavBar(
        selectedIndex: index,
        proposalCount: proposalCount,
        backgroundColor: navBgColor,
        primaryColor: colorScheme.primary,
        onSurfaceVariant: colorScheme.onSurfaceVariant,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/today');
            case 1:
              context.go('/calendar');
            case 2:
              context.go('/todos');
            case 3:
              context.go('/meals');
            case 4:
              context.go('/shopping');
          }
        },
      ),
      floatingActionButton: const VoiceFAB(),
    );
  }
}

class _StitchNavBar extends StatelessWidget {
  final int selectedIndex;
  final int proposalCount;
  final Color backgroundColor;
  final Color primaryColor;
  final Color onSurfaceVariant;
  final ValueChanged<int> onDestinationSelected;

  const _StitchNavBar({
    required this.selectedIndex,
    required this.proposalCount,
    required this.backgroundColor,
    required this.primaryColor,
    required this.onSurfaceVariant,
    required this.onDestinationSelected,
  });

  static const _items = [
    (icon: Icons.today_outlined, activeIcon: Icons.today, label: 'Heute'),
    (icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Kalender'),
    (icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt, label: 'Aufgaben'),
    (icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant, label: 'Essen'),
    (icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Einkauf'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == selectedIndex;
              final showBadge = i == 2 && proposalCount > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDestinationSelected(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(32),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        showBadge
                            ? Badge(
                                label: Text('$proposalCount'),
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected ? primaryColor : onSurfaceVariant,
                                  size: 22,
                                ),
                              )
                            : Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? primaryColor : onSurfaceVariant,
                                size: 22,
                              ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? primaryColor : onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
