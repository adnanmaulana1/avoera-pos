import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modul Gudang (v0.10.0): barang masuk menambah stok + tercatat,
// opname mengoreksi stok + tercatat, penjualan beresep tercatat
// sebagai mutasi 'jual', dan riwayatnya bisa dibuka.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Font asli wajib dimuat: font bawaan tes terlalu lebar dan
  // memicu overflow palsu di layar kasir/dialog.
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

  Finder inSheet(Finder inner) => find.descendant(of: find.byType(BottomSheet), matching: inner);
  Finder inTopSheet(Finder inner) => find.descendant(of: find.byType(BottomSheet).last, matching: inner);

  test('MutasiStok bolak-balik JSON utuh', () {
    final m = MutasiStok(
      ingredientId: 'b1',
      namaBahan: 'Gula',
      jenis: 'masuk',
      jumlah: 5,
      stokSesudah: 25,
      satuan: 'kg',
      catatan: 'Beli di Toko Berkah',
      waktu: DateTime(2026, 11, 15, 8, 30),
    );
    final lagi = MutasiStok.fromJson(m.toJson());
    expect(lagi.ingredientId, 'b1');
    expect(lagi.namaBahan, 'Gula');
    expect(lagi.jenis, 'masuk');
    expect(lagi.jumlah, 5);
    expect(lagi.stokSesudah, 25);
    expect(lagi.satuan, 'kg');
    expect(lagi.catatan, 'Beli di Toko Berkah');
    expect(lagi.waktu, DateTime(2026, 11, 15, 8, 30));
  });

  testWidgets('Barang masuk & opname tercatat dan mengubah stok', (tester) async {
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final awal = await LocalStore.load();
    final bahan = awal.ingredients.first;
    final stokAwal = bahan.stock;

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stok Bahan').last);
    await tester.pumpAndSettle();
    expect(find.text('Barang Masuk'), findsOneWidget);

    // --- Barang masuk +5 ---
    await tester.tap(find.text('Barang Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Pilih bahan…')));
    await tester.pumpAndSettle();
    await tester.tap(inTopSheet(find.text(bahan.name)));
    await tester.pumpAndSettle();
    await tester.enterText(inSheet(find.byType(TextField)).at(0), '5');
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Simpan Barang Masuk')));
    await tester.pumpAndSettle();

    var data = await LocalStore.load();
    expect(data.ingredients.firstWhere((i) => i.id == bahan.id).stock, stokAwal + 5, reason: 'Stok harus bertambah 5');
    expect(data.mutasi.any((m) => m.jenis == 'masuk' && m.ingredientId == bahan.id && m.jumlah == 5), isTrue, reason: 'Mutasi masuk harus tercatat');

    // --- Opname: fisik = stok sekarang - 2 ---
    final stokNow = stokAwal + 5;
    await tester.tap(find.text('Opname'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Pilih bahan…')));
    await tester.pumpAndSettle();
    await tester.tap(inTopSheet(find.text(bahan.name)));
    await tester.pumpAndSettle();
    await tester.enterText(inSheet(find.byType(TextField)).at(0), '${stokNow - 2}');
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Simpan Opname')));
    await tester.pumpAndSettle();

    data = await LocalStore.load();
    expect(data.ingredients.firstWhere((i) => i.id == bahan.id).stock, stokNow - 2, reason: 'Stok harus mengikuti hasil opname');
    expect(data.mutasi.any((m) => m.jenis == 'opname' && m.ingredientId == bahan.id && (m.jumlah + 2).abs() < 0.001), isTrue, reason: 'Mutasi opname −2 harus tercatat');

    // --- Riwayat menampilkan keduanya ---
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Mutasi Stok'), findsOneWidget);
    expect(find.text(bahan.name), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Penjualan beresep tercatat sebagai mutasi jual', (tester) async {
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Bahan khusus stok 10: bahan contoh pertama stoknya 0,85 —
    // kurang dari kebutuhan resep 1, dan aplikasi menahan stok
    // di 0 (tidak pernah minus), jadi tidak cocok untuk uji ini.
    final gula = Ingredient(name: 'Gula Uji', stock: 10, unit: 'kg', minStock: 1, maxStock: 50);
    final ings = [gula, ...seedIngredients().skip(1)];
    const stokAwal = 10.0;
    final menus = seedMenus();
    menus.first.recipe = [RecipeLine(ingredientId: gula.id, qty: 1)];
    await LocalStore.saveIngredients(ings);
    await LocalStore.saveMenus(menus);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Kasir')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(menus.first.name));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang pas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    final data = await LocalStore.load();
    expect(data.ingredients.firstWhere((i) => i.id == gula.id).stock, stokAwal - 1, reason: 'Stok harus terpotong 1 dari resep');
    expect(data.mutasi.any((m) => m.jenis == 'jual' && m.ingredientId == gula.id && m.jumlah == -1), isTrue, reason: 'Mutasi jual harus tercatat');
    await tester.pump(const Duration(seconds: 5));
  });
}
