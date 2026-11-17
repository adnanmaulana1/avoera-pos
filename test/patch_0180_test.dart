// Tes v0.18.0 (diminta Adnan 2026-11-17): ganti nama
// Avoera → Avorea di semua tampilan. Nama usaha tersimpan
// yang masih bawaan lama ikut bermigrasi; nama kustom
// pemilik tidak disentuh.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/splash_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  test('konstanta nama sudah Avorea', () {
    expect(appName, 'Avorea POS');
    expect(AppSettings().businessName, 'Avorea Cafe & Resto');
    expect(AppSettings.fromJson(const {}).businessName, 'Avorea Cafe & Resto');
  });

  testWidgets('label splash memakai nama baru', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('AVOREA POS · BY WEBTALES STUDIO'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('migrasi: nama usaha bawaan lama berganti sendiri', (tester) async {
    SharedPreferences.setMockInitialValues({
      'avoera.settings.v1': '{"onboarded":true,"businessName":"Avoera Cafe & Resto"}',
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    final data = await LocalStore.load();
    expect(data.settings.businessName, 'Avorea Cafe & Resto');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('nama usaha kustom pemilik TIDAK disentuh', (tester) async {
    SharedPreferences.setMockInitialValues({
      'avoera.settings.v1': '{"onboarded":true,"businessName":"Warung Berkah Saya"}',
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    final data = await LocalStore.load();
    expect(data.settings.businessName, 'Warung Berkah Saya');
    await tester.pump(const Duration(seconds: 5));
  });
}
