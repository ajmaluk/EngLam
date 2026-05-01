// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:englam/main.dart';
import 'package:englam/app_settings.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final settings = AppSettings(
      themeMode: AppThemeMode.system,
      keyboardHeightFactor: 0.58,
      showKeyBorders: false,
      layoutMode: KeyboardLayoutMode.translit,
      isMalayalamMode: true,
    );
    await tester.pumpWidget(EngLamApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('EngLam'), findsOneWidget);
    expect(find.text('abc → മലയാളം'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('അക്ഷരങ്ങൾ'), findsOneWidget);
    expect(find.text('കൈയ്യക്ഷാരം'), findsOneWidget);
    expect(find.text('Try in app'), findsOneWidget);

    final tile = find.text('കൈയ്യക്ഷാരം');
    await tester.tap(tile, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(settings.layoutMode, KeyboardLayoutMode.handwriting);
  });
}
