// Tes v0.10.6 — halaman Detail Transaksi + filter tanggal di
// Riwayat (permintaan Adnan 2026-11-15 21:49) dan rincian item
// yang kini disimpan di TxRecord.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/detail_transaksi_screen.dart';
import 'package:avoera_pos/screens/riwayat_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TxRecord txContoh({required String id, required DateTime at, List<TxLine> lines = const []}) => TxRecord(
      id: id,
      total: 50000,
      method: 'Tunai',
      at: at,
      items: lines.isEmpty ? 2 : lines.fold(0, (a, l) => a + l.qty),
      subtotal: 45000,
      service: 2000,
      tax: 3000,
      branchId: 'c1',
      lines: lines,
    );

Future<void> pumpRiwayat(WidgetTester tester, List<TxRecord> txs) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: RiwayatScreen(transactions: txs, branchId: 'c1', branchName: 'Pusat'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Font asli wajib dimuat: font uji bawaan lebar sehingga
  // dialog pemilih tanggal bawaan Flutter meluap palsu.
  setUpAll(() async {
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold']) {
      roboto.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    await icons.load();
  });

  group('Filter rentang tanggal (fungsi murni)', () {
    test('txDalamRentang: batas inklusif, hari akhir penuh', () {
      final r = DateTimeRange(start: DateTime(2026, 11, 10), end: DateTime(2026, 11, 12));
      expect(txDalamRentang(DateTime(2026, 11, 10, 0, 1), r), isTrue);
      expect(txDalamRentang(DateTime(2026, 11, 12, 23, 59), r), isTrue, reason: 'Hari terakhir dihitung penuh');
      expect(txDalamRentang(DateTime(2026, 11, 13, 0, 0), r), isFalse);
      expect(txDalamRentang(DateTime(2026, 11, 9, 23, 59), r), isFalse);
      expect(txDalamRentang(DateTime(2026, 11, 11), null), isTrue, reason: 'Rentang null = semua waktu');
    });

    test('TxRecord JSON: rincian item ikut tersimpan & terbaca lagi', () {
      final tx = txContoh(
        id: 'A-1',
        at: DateTime(2026, 11, 15, 10, 30),
        lines: [TxLine(nama: 'Alpukat Kocok', keterangan: 'Gula aren', qty: 2, total: 30000)],
      );
      final lagi = TxRecord.fromJson(tx.toJson());
      expect(lagi.lines.length, 1);
      expect(lagi.lines.single.nama, 'Alpukat Kocok');
      expect(lagi.lines.single.keterangan, 'Gula aren');
      expect(lagi.lines.single.qty, 2);
      // Data lama tanpa kunci lines tidak boleh gagal dibaca.
      final lama = Map<String, dynamic>.from(tx.toJson())..remove('lines');
      expect(TxRecord.fromJson(lama).lines, isEmpty);
    });
  });

  group('Detail Transaksi', () {
    testWidgets('Ketuk baris Riwayat membuka detail berisi rincian item & uang', (tester) async {
      final txBaru = txContoh(
        id: 'A-2001',
        at: DateTime.now(),
        lines: [TxLine(nama: 'Alpukat Kocok', keterangan: 'Gula aren', qty: 2, total: 30000)],
      );
      final txLama = txContoh(id: 'A-1999', at: DateTime.now());
      await pumpRiwayat(tester, [txBaru, txLama]);

      await tester.tap(find.text('A-2001 · Tunai'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailTransaksiScreen), findsOneWidget);
      expect(find.text('Alpukat Kocok'), findsOneWidget);
      expect(find.text('Gula aren'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('Lunas'), findsOneWidget);
      expect(find.text('Rincian Pembayaran'), findsOneWidget);
      expect(find.text('Cabang Pusat'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('A-1999 · Tunai'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailTransaksiScreen), findsOneWidget);
      expect(find.textContaining('sebelum rincian item disimpan'), findsOneWidget);
      expect(find.text('2 item'), findsOneWidget);
    });
  });

  group('Filter tanggal di Riwayat', () {
    testWidgets('Pilih tanggal hari ini menyaring transaksi lama keluar', (tester) async {
      final now = DateTime.now();
      final txHariIni = txContoh(id: 'A-BARU', at: now);
      final txLama = txContoh(id: 'A-LAMA', at: now.subtract(const Duration(days: 10)));
      await pumpRiwayat(tester, [txHariIni, txLama]);
      expect(find.text('A-BARU · Tunai'), findsOneWidget);
      expect(find.text('A-LAMA · Tunai'), findsOneWidget);

      await tester.tap(find.text('Pilih Tanggal'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);

      // Pilih hari ini sebagai awal & akhir rentang.
      final selHari = find.descendant(of: find.byType(DateRangePickerDialog), matching: find.text('${now.day}'));
      await tester.tap(selHari.first);
      await tester.pumpAndSettle();
      await tester.tap(selHari.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('A-BARU · Tunai'), findsOneWidget);
      expect(find.text('A-LAMA · Tunai'), findsNothing, reason: 'Transaksi 10 hari lalu tersaring keluar oleh rentang hari ini');
      expect(find.text('Hapus Tanggal'), findsOneWidget);

      // Hapus saringan → semua tampil lagi.
      await tester.tap(find.text('Hapus Tanggal'));
      await tester.pumpAndSettle();
      expect(find.text('A-LAMA · Tunai'), findsOneWidget);
    });
  });
}
