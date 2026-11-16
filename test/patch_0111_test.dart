// Tes v0.10.11 — perbaikan Riwayat Transaksi (permintaan
// Adnan 2026-11-16 00:22, 7 poin): saringan metode terpisah
// dari periode, kolom pencarian, label total dinamis, badge
// hanya untuk status luar biasa, subjudul ringkas.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/riwayat_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TxRecord txContoh({
  required String id,
  required int total,
  required String method,
  required DateTime at,
  List<TxLine> lines = const [],
  String status = 'Lunas',
}) =>
    TxRecord(
      id: id,
      total: total,
      method: method,
      at: at,
      items: lines.isEmpty ? 1 : lines.length,
      subtotal: total,
      branchId: 'c1',
      lines: lines,
      status: status,
    );

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
    // Huruf khas v0.12.0 ikut dimuat — tanpa ini judul/angka
    // jatuh ke font uji raksasa dan lebar teksnya mengecoh.
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  group('Fungsi murni v0.10.11', () {
    final t = txContoh(id: 'A-1045', total: 52900, method: 'Tunai', at: DateTime(2026, 11, 15, 12, 10));

    test('txCocokCari: nomor, nominal bertitik, nominal polos, kosong', () {
      expect(txCocokCari(t, 'a-104'), isTrue, reason: 'nomor tak peka huruf');
      expect(txCocokCari(t, 'A-1045'), isTrue);
      expect(txCocokCari(t, '52.900'), isTrue, reason: 'nominal bertitik menemukan total 52900');
      expect(txCocokCari(t, '529'), isTrue);
      expect(txCocokCari(t, '999'), isFalse);
      expect(txCocokCari(t, 'B-2000'), isFalse);
      expect(txCocokCari(t, ''), isTrue);
      expect(txCocokCari(t, '   '), isTrue);
    });

    test('labelTotalRiwayat mengikuti metode, periode, rentang', () {
      expect(labelTotalRiwayat(filter: 0, metode: 'Semua'), 'Total semua transaksi');
      expect(labelTotalRiwayat(filter: 1, metode: 'Semua'), 'Total semua transaksi hari ini');
      expect(labelTotalRiwayat(filter: 3, metode: 'QRIS'), 'Total transaksi QRIS bulan ini');
      expect(labelTotalRiwayat(filter: 2, metode: 'Tunai'), 'Total transaksi Tunai minggu ini');
      expect(labelTotalRiwayat(filter: 0, metode: 'Semua', labelRentang: '10 – 15 Nov 2026'), 'Total semua transaksi · 10 – 15 Nov 2026');
      expect(labelTotalRiwayat(filter: 0, metode: 'Tunai', labelRentang: '15 Nov 2026'), 'Total transaksi Tunai · 15 Nov 2026');
    });

    test('badgeStatusTx: Lunas tanpa badge, luar biasa ber-badge', () {
      expect(badgeStatusTx(t), isNull);
      expect(badgeStatusTx(txContoh(id: 'A-1', total: 1, method: 'Tunai', at: DateTime(2026), status: 'Batal'))!.label, 'Batal');
      expect(badgeStatusTx(txContoh(id: 'A-2', total: 1, method: 'QRIS', at: DateTime(2026), status: 'Refund'))!.label, 'Refund');
      expect(badgeStatusTx(txContoh(id: 'A-3', total: 1, method: 'Tunai', at: DateTime(2026), status: 'Belum bayar'))!.label, 'Belum bayar');
    });

    test('TxRecord JSON: status ikut tersimpan; data lama terbaca Lunas', () {
      final batal = txContoh(id: 'A-9', total: 10, method: 'Tunai', at: DateTime(2026, 11, 15), status: 'Batal');
      expect(TxRecord.fromJson(batal.toJson()).status, 'Batal');
      final lama = Map<String, dynamic>.from(batal.toJson())..remove('status');
      expect(TxRecord.fromJson(lama).status, 'Lunas');
    });
  });

  testWidgets('Riwayat v0.10.11: cari menyaring, metode memisah label, badge Batal tampil', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    DateTime jam(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    final txs = [
      txContoh(id: 'A-1045', total: 52900, method: 'QRIS', at: jam(12, 10), lines: [TxLine(nama: 'Alpukat Kocok Keju', qty: 1, total: 52900)]),
      txContoh(id: 'A-1046', total: 94645, method: 'Tunai', at: jam(12, 11), lines: [TxLine(nama: 'Alpukat Kocok Coklat', qty: 1, total: 94645)]),
      txContoh(id: 'A-1047', total: 27830, method: 'Tunai', at: jam(12, 32), status: 'Batal', lines: [TxLine(nama: 'Alpukat Kocok Original', qty: 1, total: 27830)]),
    ];
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: RiwayatScreen(transactions: txs, branchId: 'c1', branchName: 'Pusat')),
    );
    await tester.pumpAndSettle();

    // Badge: hanya baris Batal yang ber-badge.
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Lunas'), findsNothing);

    // Cari berdasarkan nomor → dua baris lain hilang.
    await tester.enterText(find.byType(TextField), 'A-1046');
    await tester.pumpAndSettle();
    expect(find.text('Alpukat Kocok Coklat'), findsOneWidget);
    expect(find.text('Alpukat Kocok Keju'), findsNothing);
    expect(find.text('Alpukat Kocok Original'), findsNothing);

    // Cari berdasarkan nominal bertitik.
    await tester.enterText(find.byType(TextField), '52.900');
    await tester.pumpAndSettle();
    expect(find.text('Alpukat Kocok Keju'), findsOneWidget);
    expect(find.text('Alpukat Kocok Coklat'), findsNothing);

    // Hapus pencarian lewat tombol silang di kolom cari.
    await tester.tap(find.descendant(of: find.byType(TextField), matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.text('Alpukat Kocok Coklat'), findsOneWidget);
    expect(find.text('Alpukat Kocok Original'), findsOneWidget);

    // Saringan metode di barisnya sendiri: ketuk chip 'Tunai'
    // (dibedakan dari label 'Tunai' di kartu total lewat tipe
    // widgetnya) → baris QRIS hilang + label total berubah.
    await tester.tap(find.byWidgetPredicate((w) => w is AppChip && w.label == 'Tunai'));
    await tester.pumpAndSettle();
    expect(find.text('Alpukat Kocok Keju'), findsNothing);
    expect(find.text('Total transaksi Tunai'), findsOneWidget);
  });
}
