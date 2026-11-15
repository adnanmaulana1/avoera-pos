// Tes v0.10.12 — pembaruan yang menawari diri sendiri +
// pemasang yang bisa jalan (perintah Adnan 2026-11-16 00:43,
// sesudah uji 0.10.11 di HP-nya: unduhan sukses tapi pemasang
// gagal dibuka karena izin pasang Android belum ada, dan
// tawaran pembaruan harusnya muncul otomatis).
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/beranda_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      roboto.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    await icons.load();
  });

  group('perluTawaranUpdate', () {
    test('versi baru belum pernah ditawarkan → tawarkan', () {
      expect(perluTawaranUpdate(kodeTersedia: 38, buildSaatIni: 37, kodeTawaranTerakhir: 0), isTrue);
      expect(perluTawaranUpdate(kodeTersedia: 38, buildSaatIni: 37, kodeTawaranTerakhir: 37), isTrue);
    });
    test('sudah ditawarkan / bukan versi baru → jangan', () {
      expect(perluTawaranUpdate(kodeTersedia: 38, buildSaatIni: 37, kodeTawaranTerakhir: 38), isFalse, reason: 'sekali per versi');
      expect(perluTawaranUpdate(kodeTersedia: 37, buildSaatIni: 37, kodeTawaranTerakhir: 0), isFalse);
      expect(perluTawaranUpdate(kodeTersedia: 36, buildSaatIni: 37, kodeTawaranTerakhir: 0), isFalse);
    });
  });

  group('DialogUnduhUpdate v0.10.12', () {
    final info = InfoUpdate(kode: 38, nama: '0.10.12', urlApk: 'https://contoh/aplikasi.apk', catatan: 'Perbaikan pemasang.');

    Future<void> bukaDialog(WidgetTester tester, {required Future<String> Function(File) pasangFn, Future<File?> Function(InfoUpdate, void Function(double?))? unduhFn}) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => DialogUnduhUpdate(
                    info: info,
                    unduhFn: unduhFn ?? (i, cb) async {
                      cb(1);
                      return File('/tmp/avoera-38.apk');
                    },
                    pasangFn: pasangFn,
                  ),
                ),
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();
    }

    testWidgets('perlu izin → panduan tampil; ketuk Pasang sesudah izin → dialog menutup', (tester) async {
      var hasil = 'perlu-izin';
      await bukaDialog(tester, pasangFn: (f) async => hasil);
      expect(find.textContaining('izin sekali saja'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pasang'), findsOneWidget);
      // Pengguna pulang dari halaman izin → coba pasang lagi.
      hasil = 'dibuka';
      await tester.tap(find.widgetWithText(FilledButton, 'Pasang'));
      await tester.pumpAndSettle();
      expect(find.byType(DialogUnduhUpdate), findsNothing, reason: 'pemasang terbuka → dialog selesai');
    });

    testWidgets('pemasang gagal → pesan + Coba Lagi (tanpa unduh ulang)', (tester) async {
      var unduhan = 0;
      await bukaDialog(
        tester,
        pasangFn: (f) async => 'gagal',
        unduhFn: (i, cb) async {
          unduhan++;
          cb(1);
          return File('/tmp/avoera-38.apk');
        },
      );
      expect(find.textContaining('pemasang tidak bisa dibuka'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Coba Lagi'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Coba Lagi'));
      await tester.pumpAndSettle();
      expect(unduhan, 1, reason: 'mencoba lagi tidak mengunduh ulang');
    });

    testWidgets('unduhan gagal → pesan gagal unduh', (tester) async {
      await bukaDialog(tester, pasangFn: (f) async => 'dibuka', unduhFn: (i, cb) async => null);
      expect(find.textContaining('Unduhan gagal'), findsOneWidget);
    });
  });

  testWidgets('Banner Beranda kini DI BAWAH sapaan (bukan paling atas)', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: BerandaScreen(
          businessName: 'Avorea',
          branch: Branch(id: 'c1', name: 'Cabang Utama'),
          branches: [Branch(id: 'c1', name: 'Cabang Utama')],
          transactions: const [],
          kitchenActive: 0,
          kitchenEnabled: true,
          menuCount: 20,
          syncStatus: StatusSinkron.belumDiatur,
          onSyncTap: () {},
          tablesEnabled: true,
          tablesOccupied: 0,
          tablesTotal: 0,
          noticeCount: 0,
          onOpenKasir: () {},
          onNavigate: (_) {},
          onManageTables: () {},
          onManageIngredients: () {},
          onSwitchBranch: (_) {},
          onOpenNotices: () {},
          onOpenRiwayat: () {},
          infoUpdate: InfoUpdate(kode: 38, nama: '0.10.12', urlApk: 'https://contoh/a.apk', catatan: 'Catatan rilis.'),
          onTapUpdate: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final sapaan = find.textContaining('Selamat');
    final banner = find.text('Ada versi baru — v0.10.12');
    expect(sapaan, findsOneWidget);
    expect(banner, findsOneWidget);
    expect(tester.getTopLeft(banner).dy, greaterThan(tester.getTopLeft(sapaan).dy), reason: 'banner di bawah sapaan');
  });
}
