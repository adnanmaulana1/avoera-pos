import 'dart:convert';
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Uji v0.7.0: lonceng pemberitahuan dari stok asli + Laporan Pajak
// dihitung dari rincian transaksi yang tercatat.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const dir = '/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
      final bytes = await File('$dir/$f').readAsBytes();
      roboto.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    final iconBytes = await File('$dir/MaterialIcons-Regular.otf').readAsBytes();
    icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await icons.load();
    // Huruf khas v0.12.0 ikut dimuat — tanpa ini judul/angka
    // jatuh ke font uji raksasa dan lebar teksnya mengecoh.
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  testWidgets('Lonceng stok + Laporan Pajak dari data asli', (tester) async {
    final tx = TxRecord(
      id: 'A-2001',
      total: 36800,
      method: 'Tunai',
      at: DateTime.now(),
      items: 2,
      subtotal: 32000,
      service: 1600,
      tax: 3200,
      branchId: 'c1',
    );
    SharedPreferences.setMockInitialValues({
      'avoera.settings.v1': '{"onboarded":true}',
      'avoera.tx.v1': jsonEncode([tx.toJson()]),
    });
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    expect(find.text('Rp36.800'), findsWidgets, reason: 'Beranda membaca transaksi yang ditanam');

    // Lonceng → pusat pemberitahuan: Bubuk Matcha stok 0 (data contoh).
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Pemberitahuan'), findsOneWidget);
    expect(find.text('Stok habis: Bubuk Matcha'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Laporan → Pajak: pajak terkumpul Rp3.200 dari transaksi tadi.
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Laporan')));
    await tester.pumpAndSettle();
    expect(find.text('Laporan Pajak'), findsOneWidget);
    await tester.tap(find.text('Laporan Pajak'));
    await tester.pumpAndSettle();
    expect(find.text('Pajak terkumpul'), findsOneWidget);
    expect(find.text('Rp3.200'), findsOneWidget, reason: 'Pajak harus dari rincian transaksi asli');
    // Rp36.800 muncul 2x: baris Total diterima + baris Tunai.
    expect(find.text('Rp36.800'), findsNWidgets(2), reason: 'Total diterima & total Tunai harus cocok');
  });
}
