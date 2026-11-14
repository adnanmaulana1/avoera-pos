import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/onboarding_screen.dart' show hashPin;
import 'package:avoera_pos/screens/pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// v0.8.0: gerbang PIN kasir — Kasir terkunci sampai PIN benar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'avoera.settings.v1': '{"onboarded":true,"pinHash":"${hashPin('1234')}"}',
    });
  });

  setUpAll(() async {
    const dir = '/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
      roboto.addFont(Future.value(ByteData.view((await File('$dir/$f').readAsBytes()).buffer)));
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(Future.value(ByteData.view((await File('$dir/MaterialIcons-Regular.otf').readAsBytes()).buffer)));
    await icons.load();
  });

  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Kasir')));
    await tester.pumpAndSettle();
  }

  Finder tombolPin(String d) => find.descendant(of: find.byType(PinGateScreen), matching: find.text(d));

  testWidgets('Kasir terkunci PIN — PIN benar membuka kasir', (tester) async {
    await pumpPhone(tester);
    expect(find.byType(PinGateScreen), findsOneWidget, reason: 'Gerbang PIN harus tampil');
    expect(find.text('Kasir Terkunci'), findsOneWidget);
    expect(find.text('Cari menu…'), findsNothing, reason: 'Kasir belum boleh terbuka');

    for (final d in ['1', '2', '3', '4']) {
      await tester.tap(tombolPin(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(PinGateScreen), findsNothing, reason: 'PIN benar harus membuka gerbang');
    expect(find.text('Cari menu…'), findsOneWidget, reason: 'Kasir terbuka sesudah PIN benar');
  });

  testWidgets('PIN salah penuh (6 angka) ditolak & dikosongkan', (tester) async {
    await pumpPhone(tester);
    for (final d in ['9', '9', '9', '9', '9', '9']) {
      await tester.tap(tombolPin(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('PIN salah'), findsOneWidget);
    expect(find.byType(PinGateScreen), findsOneWidget, reason: 'Tetap terkunci sesudah PIN salah');
    await tester.pump(const Duration(milliseconds: 600));
  });
}
