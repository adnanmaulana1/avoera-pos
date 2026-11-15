// Tes v0.10.9 — rombak desain Riwayat Transaksi (permintaan
// Adnan 2026-11-15 23:17): saringan satu baris + ikon
// kalender, kelompok per tanggal, nama produk sebagai judul,
// badge Lunas, daftar padat berdivider, rincian Tunai/QRIS
// di kartu total.
//
// Diperbarui v0.10.11 (permintaan Adnan 2026-11-16 00:22):
// badge Lunas HILANG dari baris biasa, "+N lainnya" menjadi
// "+N" di sebelah nama produk, subjudul = 'id · jam', label
// kartu total dinamis, ada tombol kembali + kolom pencarian.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/riwayat_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TxRecord txContoh({required String id, required int total, required String method, required DateTime at, List<TxLine> lines = const [], int items = 1}) => TxRecord(
      id: id,
      total: total,
      method: method,
      at: at,
      items: items,
      subtotal: total,
      service: 0,
      tax: 0,
      branchId: 'c1',
      lines: lines,
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
  });

  group('Fungsi murni Riwayat', () {
    test('ringkasanProdukTx: satu produk, banyak produk, data lama', () {
      final at = DateTime(2026, 11, 15, 10, 0);
      final satu = txContoh(id: 'A-1', total: 1000, method: 'Tunai', at: at, lines: [TxLine(nama: 'Alpukat Kocok', qty: 2, total: 1000)]);
      expect(ringkasanProdukTx(satu), 'Alpukat Kocok');
      final banyak = txContoh(
        id: 'A-2',
        total: 2000,
        method: 'QRIS',
        at: at,
        lines: [TxLine(nama: 'Alpukat Kocok', qty: 1, total: 1000), TxLine(nama: 'Es Teh', qty: 1, total: 500), TxLine(nama: 'Roti Bakar', qty: 1, total: 500)],
      );
      expect(ringkasanProdukTx(banyak), 'Alpukat Kocok');
      expect(jumlahTambahanTx(banyak), 2);
      expect(jumlahTambahanTx(satu), 0);
      final lama = txContoh(id: 'A-3', total: 3000, method: 'Tunai', at: at, items: 4);
      expect(ringkasanProdukTx(lama), '4 item');
    });

    test('kelompokTxPerHari + labelHariTx', () {
      final now = DateTime(2026, 11, 15, 22, 0); // Minggu
      final a = txContoh(id: 'A-1', total: 1, method: 'Tunai', at: DateTime(2026, 11, 15, 9, 0));
      final b = txContoh(id: 'A-2', total: 1, method: 'Tunai', at: DateTime(2026, 11, 15, 12, 0));
      final c = txContoh(id: 'A-3', total: 1, method: 'Tunai', at: DateTime(2026, 11, 14, 12, 0));
      final d = txContoh(id: 'A-4', total: 1, method: 'Tunai', at: DateTime(2026, 11, 10, 12, 0));
      final grup = kelompokTxPerHari([a, b, c, d]);
      expect(grup.length, 3);
      expect(grup.values.first.length, 2);
      expect(labelHariTx(DateTime(2026, 11, 15), now), 'Hari ini · Min, 15 Nov 2026');
      expect(labelHariTx(DateTime(2026, 11, 14), now), 'Kemarin · Sab, 14 Nov 2026');
      expect(labelHariTx(DateTime(2026, 11, 10), now), 'Sel, 10 Nov 2026');
    });
  });

  testWidgets('Riwayat baru: kelompok hari, nama produk, tanpa badge Lunas, rincian metode', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final txs = [
      txContoh(
        id: 'A-1043',
        total: 27830,
        method: 'Tunai',
        at: DateTime(now.year, now.month, now.day, 12, 32),
        lines: [TxLine(nama: 'Alpukat Kocok Original', qty: 1, total: 27830)],
      ),
      txContoh(
        id: 'A-1044',
        total: 94645,
        method: 'QRIS',
        at: DateTime(now.year, now.month, now.day, 12, 11),
        lines: [TxLine(nama: 'Alpukat Kocok Coklat', qty: 1, total: 80000), TxLine(nama: 'Es Teh Manis', qty: 1, total: 14645)],
        items: 2,
      ),
      txContoh(id: 'A-0900', total: 50000, method: 'Tunai', at: now.subtract(const Duration(days: 1)), items: 2),
    ];
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: RiwayatScreen(transactions: txs, branchId: 'c1', branchName: 'Pusat')),
    );
    await tester.pumpAndSettle();

    // Saringan: tidak ada lagi chip teks "Pilih Tanggal";
    // kalender berupa ikon.
    expect(find.text('Pilih Tanggal'), findsNothing);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    // Semua chip periode + metode tetap ada.
    for (final label in ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua Metode', 'Tunai', 'QRIS']) {
      expect(find.text(label), findsWidgets, reason: 'chip $label ada');
    }

    // Header kelompok + subtotal hari.
    expect(find.textContaining('Hari ini ·'), findsOneWidget);
    expect(find.textContaining('Kemarin ·'), findsOneWidget);
    expect(find.text('Rp122.475'), findsOneWidget, reason: 'subtotal hari ini di header kelompok');

    // Judul baris = nama produk dengan "+N" di sebelahnya;
    // subjudul = 'id · jam' (tanpa metode); data lama judul
    // 'N item' + subjudul id-nya.
    expect(find.text('Alpukat Kocok Original'), findsOneWidget);
    expect(find.text('Alpukat Kocok Coklat'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('A-1043 · 12:32'), findsOneWidget);
    expect(find.text('2 item'), findsOneWidget);
    expect(find.textContaining('A-0900 ·'), findsOneWidget);

    // v0.10.11: baris biasa TANPA badge 'Lunas' sama sekali.
    expect(find.text('Lunas'), findsNothing);

    // App bar: tombol kembali ada; label total dinamis.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Total semua transaksi'), findsOneWidget);
    expect(find.text('Cari no. transaksi atau nominal'), findsOneWidget);

    // Kartu total: total + rincian per metode (dibatasi ke
    // kartu pertama supaya tidak tertukar jumlah baris).
    final kartuTotal = find.byType(AppCard).first;
    expect(find.descendant(of: kartuTotal, matching: find.text('Rp172.475')), findsOneWidget);
    expect(find.descendant(of: kartuTotal, matching: find.text('Tunai')), findsOneWidget);
    expect(find.descendant(of: kartuTotal, matching: find.text('Rp77.830')), findsOneWidget);
    expect(find.descendant(of: kartuTotal, matching: find.text('QRIS')), findsOneWidget);
    expect(find.descendant(of: kartuTotal, matching: find.text('Rp94.645')), findsOneWidget);

    // Ada garis pemisah tipis (kartu total + antarbaris).
    expect(find.byType(Divider), findsWidgets);
  });
}
