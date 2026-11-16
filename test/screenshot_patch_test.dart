import 'dart:io';
import 'dart:ui' as ui;

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/export.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/produk_screen.dart';
import 'package:avoera_pos/screens/riwayat_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bukti visual patch v0.8.1 lanjutan — PNG disimpan ke
// ~/workspace/avoera-screenshots/ untuk dibedah induk:
// (a) bukaan pertama mode terang, (b) dialog Edit Harga Massal
// terang & gelap, (c) chip kategori Produk tanpa centang,
// (d) layar pratinjau laporan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const folder = '/home/hatch/workspace/avoera-screenshots';

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

  Future<void> bukaDialogHargaMassal(WidgetTester tester, String mode) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Produk'), findsOneWidget, reason: 'Menu ⋯ harus terbuka (mode $mode)');
    await tester.tap(find.text('Edit Harga Massal'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'Dialog Edit Harga Massal harus tampil (mode $mode)');
    expect(find.text('Terapkan'), findsOneWidget);
  }

  void aturLayar(WidgetTester tester) {
    tester.view.physicalSize = const Size(780, 1688); // 390x844 @2x
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  Future<void> tangkap(WidgetTester tester, RenderRepaintBoundary boundary, String nama) async {
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('$folder/$nama.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  /// Kunci boundary pembungkus DI ATAS MaterialApp tiap adegan —
  /// hanya boundary di atas Navigator yang memuat overlay
  /// (dialog & rute dorong) dalam gambar tangkapan.
  final kunciAkar = GlobalKey();

  Future<void> tangkapLayar(WidgetTester tester, String nama) async {
    final boundary = kunciAkar.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tangkap(tester, boundary, nama);
  }

  testWidgets('Screenshot: (a) bukaan pertama terang + (c) chip Produk + (b) dialog dua mode + (d) pratinjau', (tester) async {
    // ---------- (a) Bukaan pertama: tanpa simpanan tema ----------
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    aturLayar(tester);
    await tester.pumpWidget(RepaintBoundary(key: kunciAkar, child: const KasirFnbApp()));
    await tester.pumpAndSettle();
    expect(AppColors.gelap, isFalse, reason: 'Bukaan pertama wajib terang');
    await tangkapLayar(tester, 'patch081-a-bukaan-pertama-terang');

    // ---------- Adegan Produk mandiri (b & c) ----------
    Widget adeganProduk() => RepaintBoundary(
          key: kunciAkar,
          child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: ProdukScreen(
                menus: seedMenus(),
                onAdd: (_) {},
                onChanged: () {},
                onDelete: (_) {},
                branchName: 'Cabang Utama',
                ingredients: seedIngredients(),
                onBulkPrice: (_) {},
                onImport: (_) {},
              ),
            ),
          ),
        );

    // (c) Chip kategori Produk — terang.
    await tester.pumpWidget(adeganProduk());
    await tester.pumpAndSettle();
    await tangkapLayar(tester, 'patch081-c-chip-produk-terang');

    // (b-terang) Dialog Edit Harga Massal — terang.
    await bukaDialogHargaMassal(tester, 'terang');
    await tangkapLayar(tester, 'patch081-b-harga-massal-terang');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // (b-gelap) Dialog yang sama — gelap. WAJIB ditutup lagi
    // sesudahnya: rute dialog menempel di Navigator yang dipakai
    // ulang pumpWidget berikutnya dan akan menutupi layar.
    AppColors.gelap = true;
    await tester.pumpWidget(adeganProduk());
    await tester.pumpAndSettle();
    await bukaDialogHargaMassal(tester, 'gelap');
    await tangkapLayar(tester, 'patch081-b-harga-massal-gelap');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    AppColors.gelap = false;

    // ---------- (d) Pratinjau laporan ----------
    final tx = [
      TxRecord(id: 'A-2001', total: 36800, method: 'Tunai', at: DateTime.now(), items: 2, subtotal: 32000, service: 1600, tax: 3200, branchId: 'c1'),
      TxRecord(id: 'A-2002', total: 24000, method: 'QRIS', at: DateTime.now(), items: 1, subtotal: 21000, service: 900, tax: 2100, branchId: 'c1'),
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        key: kunciAkar,
        child: MaterialApp(
          theme: buildTheme(),
          home: RiwayatScreen(transactions: tx, branchId: 'c1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TombolEkspor));
    await tester.pumpAndSettle();
    expect(find.text('Bagikan PDF'), findsOneWidget, reason: 'Pratinjau harus tampil untuk ditangkap');
    await tangkapLayar(tester, 'patch081-d-pratinjau-laporan');
  });
}
