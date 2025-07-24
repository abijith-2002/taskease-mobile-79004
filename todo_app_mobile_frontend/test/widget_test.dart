import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app_mobile_frontend/main.dart';

void main() {
  testWidgets('Shows main screens and empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    // Look for the Tasks AppBar title and add FAB.
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Should display the empty state (since no tasks)
    expect(find.text('Nothing to do. Tap + to add a task!'), findsOneWidget);

    // Switch tab and show empty completed state
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('No completed tasks.'), findsOneWidget);
  });
}
