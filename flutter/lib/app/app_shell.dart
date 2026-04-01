import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/domain/todo.dart';
import '../features/ai/presentation/voice_fab.dart';

final pendingProposalsProvider = FutureProvider<List<Proposal>>((ref) async {
  return ref.watch(todoRepositoryProvider).getPendingProposals();
});

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/calendar')) return 0;
    if (location.startsWith('/todos')) return 1;
    if (location.startsWith('/meals')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final pendingProposals = ref.watch(pendingProposalsProvider);
    final proposalCount = pendingProposals.valueOrNull?.length ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/calendar');
            case 1:
              context.go('/todos');
            case 2:
              context.go('/meals');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: proposalCount > 0,
              label: Text('$proposalCount'),
              child: const Icon(Icons.checklist_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: proposalCount > 0,
              label: Text('$proposalCount'),
              child: const Icon(Icons.checklist),
            ),
            label: 'Aufgaben',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Kueche',
          ),
        ],
      ),
      floatingActionButton: const VoiceFAB(),
    );
  }
}
