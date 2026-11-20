// Tes v0.23.0 (pilihan Adnan 2026-11-21: bangun Batal/Refund
// dulu): status transaksi bisa diubah dari Detail Transaksi,
// stok bahan kembali, dan uang yang dihitung di mana pun
// hanya dari transaksi Lunas.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/ikon.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/detail_transaksi_screen.dart';
import 'package:avoera_pos/screens/riwayat_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/widgets.dart';
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
    final lucide = FontLoader('Lucide');
    lucide.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/Lucide.ttf').readAsBytes()).buffer)));
    await lucide.load();
  });

  TxRecord txUji({String status = 'Lunas', int total = 50000}) => TxRecord(
        id: 'A-2001',
        total: total,
        method: 'Tunai',
        at: DateTime.now(),
        items: 1,
        subtotal: total,
        branchId: 'c1',
        uuid: 'u-uji-1',
        status: status,
        lines: [TxLine(nama: 'Kopi Uji', qty: 1, total: 50000)],
      );

  test('denganStatus: semua kolom tetap, status berubah, JSON ikut', () {
    final asal = txUji();
    final batal = asal.denganStatus('Batal');
    expect(batal.status, 'Batal');
    expect(batal.id, asal.id);
    expect(batal.uuid, asal.uuid);
    expect(batal.total, asal.total);
    expect(batal.lines.single.nama, 'Kopi Uji');
    expect(TxRecord.fromJson(batal.toJson()).status, 'Batal');
    expect(asal.status, 'Lunas', reason: 'aslinya tidak ikut berubah');
  });

  testWidgets('Detail: transaksi Lunas menampilkan aksi Refund & Batalkan; Refund memanggil callback', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    String? statusBaru;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => DetailTransaksiScreen(tx: txUji(), onUbahStatusTx: (t, s) => statusBaru = s),
            )),
            child: const Text('Buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Lunas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Refund Transaksi'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Batalkan Transaksi'), findsOneWidget);
    await tester.tap(find.text('Refund Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Refund Transaksi?'), findsOneWidget);
    expect(find.textContaining('Stok bahan dari resep pesanan ini dikembalikan'), findsOneWidget);
    await tester.tap(find.text('Ya, Refund'));
    await tester.pumpAndSettle();
    expect(statusBaru, 'Refund');
    // Halaman Detail tertutup sesudah konfirmasi.
    expect(find.byType(DetailTransaksiScreen), findsNothing);
  });

  testWidgets('Detail: transaksi Batal ber-badge Batal, ada catatan, tanpa tombol kelola', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DetailTransaksiScreen(tx: txUji(status: 'Batal'), onUbahStatusTx: (t, s) {}),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Batal'), findsOneWidget);
    expect(find.textContaining('tidak dihitung di omzet'), findsOneWidget);
    expect(find.text('Kelola Transaksi'), findsNothing);
    expect(find.text('Refund Transaksi'), findsNothing);
  });

  testWidgets('Riwayat: total hanya menghitung yang Lunas, baris Batal tetap tampil ber-badge', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: RiwayatScreen(
        transactions: [txUji(), txUji(status: 'Batal', total: 30000)],
        branchId: 'c1',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Batal'), findsOneWidget, reason: 'badge baris batal tampil');
    expect(find.text('Rp50.000'), findsWidgets, reason: 'total = yang lunas saja');
    expect(find.text('Rp80.000'), findsNothing, reason: 'total tidak menjumlah yang batal');
  });

  testWidgets('ujung ke ujung: jual menu beresep → stok berkurang → batalkan → stok pulih & status tersimpan', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    await LocalStore.saveIngredients([
      Ingredient(id: 'b-uji', name: 'Biji Uji', stock: 10, unit: 'gram', minStock: 1, maxStock: 100, costPerUnit: 100),
    ]);
    await LocalStore.saveMenus([
      MenuItem(
        id: 'm-uji',
        name: 'Kopi Uji',
        category: 'Kopi',
        price: 10000,
        color: Colors.brown,
        icon: Ikon.coffee,
        recipe: [RecipeLine(ingredientId: 'b-uji', qty: 2)],
      ),
    ]);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Ke Kasir, tambah menu, bayar tunai uang pas.
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Kasir')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Kopi Uji'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Kopi Uji'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Uang pas'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Uang pas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    var data = await LocalStore.load();
    expect(data.transactions.single.status, 'Lunas');
    expect(data.ingredients.single.stock, 8, reason: 'resep 2 gram terpotong dari 10');
    // Ke Beranda → Riwayat lewat kartu statistik.
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Beranda')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Lihat Semua'), 200, scrollable: find.byType(Scrollable).first);
    // Geser sedikit lagi: tombol bisa berhenti tepat di
    // belakang bar navigasi bawah.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Semua'));
    await tester.pumpAndSettle();
    expect(find.byType(RiwayatScreen), findsOneWidget);
    await tester.tap(find.text('Kopi Uji'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailTransaksiScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Batalkan Transaksi'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Batalkan Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan Transaksi?'), findsOneWidget);
    await tester.tap(find.text('Ya, Batalkan'));
    await tester.pumpAndSettle();
    // Kembali di Riwayat: badge Batal tampil, total jadi Rp0.
    expect(find.byType(RiwayatScreen), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    data = await LocalStore.load();
    expect(data.transactions.single.status, 'Batal');
    expect(data.ingredients.single.stock, 10, reason: 'stok kembali penuh sesudah dibatalkan');
    expect(data.mutasi.any((m) => m.jenis == 'batal' && m.jumlah == 2), isTrue, reason: 'mutasi pengembalian tercatat');
    await tester.pump(const Duration(seconds: 30));
  });
}
