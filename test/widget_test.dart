import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:avoera_pos/main.dart';

void main() {
  testWidgets('App kasir tampil dengan layar kasir', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    expect(find.text('Kasir'), findsWidgets);
    expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
  });
}
