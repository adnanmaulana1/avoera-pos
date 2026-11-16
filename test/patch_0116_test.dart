// Tes v0.10.16 — Laporan Laba Rugi (diminta Adnan 2026-11-16):
// hitungan murni (pendapatan lunas saja, HPP dari resep, baris
// tak dikenal jujur dihitung, biaya per kategori, rugi minus),
// rupiah negatif, JSON Pengeluaran, dan layar + formulir
// tambah pengeluaran.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/laba_rugi_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avoera_pos/ikon.dart';

Ingredient _bahan() => Ingredient(id: 'b1', name: 'Biji Kopi', stock: 1000, unit: 'gram', minStock: 10, maxStock: 2000, costPerUnit: 200);

MenuItem _menu() => MenuItem(
      id: 'm1',
      name: 'Es Kopi',
      category: 'Kopi',
      price: 15000,
      color: const Color(0xFF4E342E),
      icon: Ikon.coffee,
      isDrink: true,
      recipe: [RecipeLine(ingredientId: 'b1', qty: 10)], // HPP 10 × 200 = 2.000
    );

TxRecord _tx(String id, int total, DateTime at, {String status = 'Lunas', String branchId = 'b1', List<TxLine> lines = const []}) =>
    TxRecord(id: id, total: total, method: 'Tunai', at: at, items: 1, branchId: branchId, status: status, lines: lines);

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
    // Huruf khas v0.12.0 ikut dimuat — tanpa ini judul/angka
    // jatuh ke font uji raksasa dan lebar teksnya mengecoh.
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  group('hitungLabaRugi', () {
    final nov = DateTime(2026, 11, 10);
    HasilLabaRugi hitung() => hitungLabaRugi(
          transactions: [
            _tx('A-1', 45000, nov, lines: [TxLine(nama: 'Es Kopi', qty: 3, total: 45000)]),
            _tx('A-2', 30000, nov, lines: [TxLine(nama: 'Es Kopi', qty: 2, total: 30000)]),
            _tx('A-3', 99999, nov, status: 'Batal', lines: [TxLine(nama: 'Es Kopi', qty: 9, total: 99999)]),
            _tx('A-4', 88888, DateTime(2026, 10, 5), lines: [TxLine(nama: 'Es Kopi', qty: 8, total: 88888)]),
            _tx('A-5', 77777, nov, branchId: 'b2', lines: [TxLine(nama: 'Es Kopi', qty: 7, total: 77777)]),
            _tx('A-6', 20000, nov), // transaksi lama tanpa rincian
            _tx('A-7', 10000, nov, lines: [TxLine(nama: 'Menu Hilang', qty: 1, total: 10000)]),
          ],
          menus: [_menu()],
          ingredients: [_bahan()],
          expenses: [
            Pengeluaran(id: 'p1', tanggal: nov, kategori: 'Sewa', jumlah: 1000000, branchId: 'b1'),
            Pengeluaran(id: 'p2', tanggal: nov, kategori: 'Gaji', jumlah: 500000, branchId: 'b1'),
            Pengeluaran(id: 'p3', tanggal: DateTime(2026, 10, 2), kategori: 'Sewa', jumlah: 200000, branchId: 'b1'),
            Pengeluaran(id: 'p4', tanggal: nov, kategori: 'Sewa', jumlah: 300000, branchId: 'b2'),
          ],
          branchId: 'b1',
          dari: DateTime(2026, 11, 1),
          sampai: DateTime(2026, 11, 30),
        );

    test('pendapatan hanya transaksi lunas di cabang & periode ini', () {
      final h = hitung();
      expect(h.pendapatan, 45000 + 30000 + 20000 + 10000);
      expect(h.jumlahTx, 4);
    });

    test('HPP dari resep × jumlah terjual', () {
      expect(hitung().hpp, 5 * 2000);
    });

    test('baris tak dikenal & transaksi lama terhitung jujur', () {
      final h = hitung();
      expect(h.barisTakDikenal, 1);
      expect(h.adaTxTanpaRincian, isTrue);
    });

    test('biaya per kategori terurut terbesar dulu; laba bisa minus', () {
      final h = hitung();
      expect(h.totalBiaya, 1500000);
      expect(h.rincianBiaya, [('Sewa', 1000000), ('Gaji', 500000)]);
      expect(h.labaKotor, 105000 - 10000);
      expect(h.labaBersih, 95000 - 1500000);
      expect(h.labaBersih, lessThan(0));
    });

    test('periode kosong = semua nol, margin 0', () {
      final h = hitungLabaRugi(
        transactions: const [],
        menus: [_menu()],
        ingredients: [_bahan()],
        expenses: const [],
        branchId: 'b1',
        dari: DateTime(2026, 11, 1),
        sampai: DateTime(2026, 11, 30),
      );
      expect(h.pendapatan, 0);
      expect(h.labaBersih, 0);
      expect(h.marginKotor, 0);
    });
  });

  test('rupiah menangani nilai negatif', () {
    expect(rupiah(-1405000), '-Rp1.405.000');
    expect(rupiah(15000), 'Rp15.000');
    expect(rupiah(0), 'Rp0');
  });

  test('Pengeluaran JSON pulang-pergi utuh', () {
    final e = Pengeluaran(id: 'p9', tanggal: DateTime(2026, 11, 3, 9, 30), kategori: 'Sewa', keterangan: 'Ruko', jumlah: 750000, branchId: 'b1');
    final b = Pengeluaran.fromJson(e.toJson());
    expect(b.id, 'p9');
    expect(b.kategori, 'Sewa');
    expect(b.keterangan, 'Ruko');
    expect(b.jumlah, 750000);
    expect(b.branchId, 'b1');
    expect(b.tanggal, DateTime(2026, 11, 3, 9, 30));
  });

  testWidgets('Layar laba rugi: hero, rincian, peringatan, tambah pengeluaran', (tester) async {
    final kini = DateTime.now();
    Pengeluaran? ditambah;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: LabaRugiScreen(
          transactions: [
            _tx('A-1', 45000, kini, lines: [TxLine(nama: 'Es Kopi', qty: 3, total: 45000)]),
            _tx('A-7', 10000, kini, lines: [TxLine(nama: 'Menu Hilang', qty: 1, total: 10000)]),
          ],
          menus: [_menu()],
          ingredients: [_bahan()],
          expenses: [Pengeluaran(id: 'p1', tanggal: kini, kategori: 'Sewa', keterangan: 'Ruko', jumlah: 1000000, branchId: 'b1')],
          branchId: 'b1',
          branchName: 'Cabang Utama',
          onAddExpense: (e) => ditambah = e,
          onEditExpense: (_) {},
          onDeleteExpense: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Pendapatan 55.000 − HPP 6.000 − sewa 1.000.000 = rugi.
    expect(find.text('Rugi Bersih'), findsWidgets);
    expect(find.text('Pendapatan'), findsOneWidget);
    expect(find.text('2 transaksi lunas'), findsOneWidget);
    expect(find.textContaining('Sebagian modal bahan belum bisa dihitung'), findsOneWidget);
    // Bagian biaya ada di bawah lipatan layar uji — seret
    // daftarnya sampai terlihat (scrollUntilVisible rapuh di
    // layar ini: target ganda + Scrollable menyamping chip).
    for (var i = 0; i < 8 && find.text('Tambah Pengeluaran').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(find.text('Sewa'), findsWidgets);
    await tester.tap(find.text('Tambah Pengeluaran'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan Pengeluaran'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '0'), '250000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Pengeluaran'));
    await tester.pumpAndSettle();
    expect(ditambah, isNotNull);
    expect(ditambah!.jumlah, 250000);
    expect(ditambah!.kategori, 'Lainnya');
    expect(ditambah!.branchId, 'b1');
    await tester.pump(const Duration(milliseconds: 600));
  });
}
