// Cafenance App Widget Tests
// Updated to match the revenue/transaction management app structure

import 'package:flutter_test/flutter_test.dart';

import 'package:cafenance/main.dart' as app;

void main() {
  testWidgets('App loads and shows dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const app.CafenanceApp());

    // Wait for any async operations
    await tester.pumpAndSettle();

    // Verify that the app loads with the dashboard screen
    expect(find.text('Dashboard'), findsOneWidget);
    
    // Verify bottom navigation items are present
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Bottom navigation changes screens', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const app.CafenanceApp());
    await tester.pumpAndSettle();

    // Tap on Revenue tab
    await tester.tap(find.text('Revenue'));
    await tester.pumpAndSettle();
    
    // Verify we're on the Revenue screen
    expect(find.text('Revenue Report'), findsOneWidget);

    // Tap on Transactions tab
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    
    // Verify we're on the Transactions screen
    expect(find.text('Transactions'), findsWidgets);
  });
}
