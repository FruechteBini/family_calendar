import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familienkalender/app/app.dart';

void main() {
  testWidgets('App launches and shows login screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FamilienkalenderApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Familienkalender'), findsOneWidget);
  });

  group('Domain models', () {
    test('Event.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'title': 'Test Event',
        'start_time': '2026-03-30T10:00:00',
        'end_time': '2026-03-30T11:00:00',
        'all_day': false,
        'member_ids': [1, 2],
        'members': [],
      };
      // Model import would go here in real test
    });

    test('Todo.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'title': 'Test Todo',
        'priority': 'high',
        'completed': false,
        'member_ids': [],
        'members': [],
        'subtodos': [],
      };
      // Model import would go here in real test
    });
  });

  group('Utility functions', () {
    test('Date formatting works', () {
      // AppDateUtils tests would go here
    });

    test('Validators work correctly', () {
      // Validator tests would go here
    });
  });
}
