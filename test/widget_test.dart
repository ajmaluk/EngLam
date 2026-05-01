// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:englam/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EngLamApp());
    await tester.pumpAndSettle();

    expect(find.text('EngLam Keyboard'), findsOneWidget);
    expect(find.text('Activate Keyboard'), findsWidgets);
    expect(find.text('Select Keyboard'), findsWidgets);
    expect(find.text('Try in app'), findsOneWidget);
  });
}
