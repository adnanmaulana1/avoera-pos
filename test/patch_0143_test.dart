import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Patch v0.14.3 (keluhan Adnan 2026-11-17): pemberitahuan yang
// sudah dibaca lahir lagi sebagai belum dibaca sesudah refresh.
// Akar: penjaga duplikat lama hanya menolak bila salinan BELUM
// dibaca masih ada. Obat: satu kunci = satu pemberitahuan per
// episode keadaan (tersimpan di LocalStore), berakhir hanya
// bila keadaannya benar-benar pulih.
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
    final lucide = FontLoader('Lucide');
    lucide.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/Lucide.ttf').readAsBytes()).buffer)));
    await lucide.load();
  });

  testWidgets('Pemberitahuan terbaca TIDAK lahir lagi sesudah aplikasi dibuka ulang', (tester) async {
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();

    // Data contoh punya bahan kritis -> ada pemberitahuan stok
    // yang belum dibaca, tombol tandai tampil.
    await tester.tap(find.byTooltip('Pemberitahuan'));
    await tester.pumpAndSettle();
    expect(find.text('Tandai semua terbaca'), findsOneWidget);
    await tester.tap(find.text('Tandai semua terbaca'));
    await tester.pumpAndSettle();
    expect(find.text('Tandai semua terbaca'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Buka ulang aplikasi dengan data tersimpan yang sama —
    // pemeriksaan stok berjalan lagi dari awal, meniru refresh.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pemberitahuan'));
    await tester.pumpAndSettle();
    // Tidak ada lagi yang belum dibaca: salinan baru TIDAK lahir.
    expect(find.text('Tandai semua terbaca'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
  });
}
