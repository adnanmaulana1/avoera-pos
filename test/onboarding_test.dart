import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/onboarding_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Uji wizard pertama (v0.7.0): pemasangan baru WAJIB lewat
// onboarding SVG + wizard cabang pertama sebelum masuk aplikasi.
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
  });

  testWidgets('Wizard pertama: onboarding → atur cabang → masuk Beranda', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Animasi melayang onboarding berjalan terus — di fase ini
    // pakai pump berdurasi, bukan pumpAndSettle (tidak akan diam).
    Future<void> langkah() async {
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    await tester.pumpWidget(const KasirFnbApp());
    await langkah();

    // Halaman perkenalan pertama dengan gambar SVG.
    expect(find.byType(SvgPicture), findsOneWidget, reason: 'Onboarding harus menampilkan SVG');
    expect(find.text('Kasir Cepat untuk Cafe & Resto'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await langkah();
    expect(find.text('Penjualan Terpantau Tiap Hari'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await langkah();
    expect(find.text('Siap Multi-Cabang'), findsOneWidget);

    await tester.tap(find.text('Atur Cabang Pertama'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai Berjualan'), findsOneWidget);

    final kolom = find.byType(TextField);
    await tester.enterText(kolom.at(0), 'Kopi Uji');
    await tester.enterText(kolom.at(1), 'Cabang Uji');
    await tester.enterText(kolom.at(2), '1234');
    await tester.enterText(kolom.at(3), '9999');
    await tester.tap(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi PIN tidak sama.'), findsOneWidget, reason: 'PIN beda harus ditolak');

    await tester.enterText(kolom.at(3), '1234');
    await tester.tap(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();

    // Masuk aplikasi: Beranda dengan chip cabang dari wizard.
    expect(find.text('Penjualan hari ini'), findsOneWidget);
    expect(find.text('Cabang Uji'), findsOneWidget);

    final data = await LocalStore.load();
    expect(data.settings.onboarded, isTrue);
    expect(data.settings.businessName, 'Kopi Uji');
    expect(data.settings.branches.single.name, 'Cabang Uji');
    expect(data.settings.pinHash, hashPin('1234'));
    expect(data.settings.pinHash.contains('1234'), isFalse, reason: 'PIN mentah tidak boleh tersimpan');
  });
}
