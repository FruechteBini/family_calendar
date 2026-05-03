import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:familienkalender/app/app_shell.dart';
import 'package:familienkalender/core/speech/voice_state.dart';
import 'package:familienkalender/features/todos/domain/todo.dart';

void main() {
  setUpAll(() {
    // Allow GoogleFonts to attempt runtime fetching. In the test environment
    // the HTTP request will fail silently and the font will fall back to the
    // default sans-serif, which is fine for widget tests.
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  /// Builds a [ProviderScope] wrapping a [MaterialApp.router] whose GoRouter
  /// uses [AppShell] as a shell route – exactly like the real app.
  Widget buildTestWidget({
    String initialLocation = '/today',
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) =>
                  const _PlaceholderScreen(label: 'Today'),
            ),
            GoRoute(
              path: '/calendar',
              builder: (context, state) =>
                  const _PlaceholderScreen(label: 'Calendar'),
            ),
            GoRoute(
              path: '/todos',
              builder: (context, state) =>
                  const _PlaceholderScreen(label: 'Todos'),
            ),
            GoRoute(
              path: '/meals',
              builder: (context, state) =>
                  const _PlaceholderScreen(label: 'Meals'),
            ),
            GoRoute(
              path: '/notes',
              builder: (context, state) =>
                  const _PlaceholderScreen(label: 'Notes'),
            ),
            GoRoute(
              path: '/shopping',
              redirect: (context, state) => '/meals?tab=einkauf',
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const _SettingsBackTestScreen(),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        // Avoid hitting the real TodoRepository / Dio / AuthProvider chain.
        pendingProposalsProvider.overrideWith((ref) async => <Proposal>[]),
        // Keep voice FAB in idle state (no side-effects).
        voiceStateProvider.overrideWith((ref) => VoiceState.idle),
        ...overrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Voice FAB runs a repeating animation — [pumpAndSettle] never completes.
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  // ── Render tests ─────────────────────────────────────────────────────

  testWidgets('AppShell renders without crashing', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await pumpShell(tester);

    // App bar title
    expect(find.text('Familienherd'), findsOneWidget);

    // All bottom-nav labels (rendered upper-case by _NavItem)
    expect(find.text('HEUTE'), findsOneWidget);
    expect(find.text('KALENDER'), findsOneWidget);
    expect(find.text('TODOS'), findsOneWidget);
    expect(find.text('ESSEN'), findsOneWidget);
    expect(find.text('NOTIZEN'), findsOneWidget);

    // Voice FAB mic icon
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('AppShell shows correct child for /today', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/today'));
    await pumpShell(tester);
    expect(find.text('Today Screen'), findsOneWidget);
  });

  testWidgets('AppShell shows correct child for /calendar', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/calendar'));
    await pumpShell(tester);
    expect(find.text('Calendar Screen'), findsOneWidget);
  });

  testWidgets('AppShell shows correct child for /todos', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/todos'));
    await pumpShell(tester);
    expect(find.text('Todos Screen'), findsOneWidget);
  });

  testWidgets('AppShell shows correct child for /meals', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/meals'));
    await pumpShell(tester);
    expect(find.text('Meals Screen'), findsOneWidget);
  });

  testWidgets('/shopping redirects to meals shell', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/shopping'));
    await pumpShell(tester);
    expect(find.text('Meals Screen'), findsOneWidget);
  });

  // ── Navigation tests ────────────────────────────────────────────────

  testWidgets('Tapping KALENDER navigates to /calendar', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/today'));
    await pumpShell(tester);

    expect(find.text('Today Screen'), findsOneWidget);

    await tester.tap(find.text('KALENDER'));
    await pumpShell(tester);

    expect(find.text('Calendar Screen'), findsOneWidget);
  });

  testWidgets('Tapping TODOS navigates to /todos', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/today'));
    await pumpShell(tester);

    await tester.tap(find.text('TODOS'));
    await pumpShell(tester);

    expect(find.text('Todos Screen'), findsOneWidget);
  });

  testWidgets('Tapping ESSEN navigates to /meals', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/today'));
    await pumpShell(tester);

    await tester.tap(find.text('ESSEN'));
    await pumpShell(tester);

    expect(find.text('Meals Screen'), findsOneWidget);
  });

  testWidgets('Tapping HEUTE navigates back to /today', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/calendar'));
    await pumpShell(tester);

    await tester.tap(find.text('HEUTE'));
    await pumpShell(tester);

    expect(find.text('Today Screen'), findsOneWidget);
  });

  testWidgets('Navigating through all tabs in sequence', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/today'));
    await pumpShell(tester);

    const tabOrder = ['KALENDER', 'TODOS', 'ESSEN', 'NOTIZEN'];
    const expectedScreens = [
      'Calendar Screen',
      'Todos Screen',
      'Meals Screen',
      'Notes Screen',
    ];

    for (var i = 0; i < tabOrder.length; i++) {
      await tester.tap(find.text(tabOrder[i]));
      await pumpShell(tester);
      expect(find.text(expectedScreens[i]), findsOneWidget);
    }
  });

  // ── Proposal badge test ─────────────────────────────────────────────

  testWidgets('Badge appears on TODOS when proposals exist', (tester) async {
    final proposals = List.generate(
      3,
      (i) => Proposal(
        id: i + 1,
        todoId: 1,
        proposerId: 1,
        proposedDate: DateTime.now(),
        status: 'pending',
      ),
    );

    await tester.pumpWidget(
      buildTestWidget(
        overrides: [
          pendingProposalsProvider.overrideWith((ref) async => proposals),
        ],
      ),
    );
    await pumpShell(tester);

    // The Badge widget should be present (one per proposal count label)
    expect(find.text('3'), findsOneWidget);
  });

  // ── Voice FAB test ──────────────────────────────────────────────────

  testWidgets('Voice FAB mic icon is present', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await pumpShell(tester);

    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('Android system back from settings returns to main tab',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/settings'));
    await pumpShell(tester);
    expect(find.text('Settings Test'), findsOneWidget);

    await tester.pageBack();
    await pumpShell(tester);

    expect(find.text('Today Screen'), findsOneWidget);
  });

  testWidgets('Android system back closes dialog before leaving screen',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialLocation: '/settings'));
    await pumpShell(tester);

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('In dialog'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('In dialog'), findsNothing);
    expect(find.text('Settings Test'), findsOneWidget);

    await tester.pageBack();
    await pumpShell(tester);
    expect(find.text('Today Screen'), findsOneWidget);
  });
}

// ── Helper widget ──────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$label Screen')),
    );
  }
}

class _SettingsBackTestScreen extends StatelessWidget {
  const _SettingsBackTestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Settings Test'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('In dialog'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open dialog'),
            ),
          ],
        ),
      ),
    );
  }
}
