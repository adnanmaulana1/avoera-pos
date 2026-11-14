
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avoera_pos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Penyimpanan lokal perlu contoh kosong supaya muat data tidak menggantung.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App kasir tampil dengan layar kasir', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Aplikasi membuka di Beranda — pindah ke Kasir lewat sidebar.
    await tester.tap(find.widgetWithText(ListTile, 'Kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Kasir'), findsWidgets);
    expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
  });
}
