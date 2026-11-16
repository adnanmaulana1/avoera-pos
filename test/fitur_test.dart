import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/screens/produk_screen.dart';
import 'package:avoera_pos/screens/stok_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// v0.8.0: saklar dapur, CRUD langsung di Stok, cari di Produk,
// angka besar Beranda menyesuaikan, simulasi dialog persen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

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

  Future<void> pumpWide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
  }

  Finder scrollPengaturan() => find.descendant(
        of: find.byType(PengaturanScreen),
        matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
      );

  testWidgets('Saklar dapur di Pengaturan menyembunyikan menu Dapur', (tester) async {
    await pumpWide(tester);
    expect(find.widgetWithText(ListTile, 'Dapur'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Pengaturan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Layar Dapur'), 120, scrollable: scrollPengaturan());
    await tester.pumpAndSettle();
    // Saklar kedua di seksi Fitur = Dapur (pertama = Meja).
    final saklarFitur = find.descendant(of: find.byType(PengaturanScreen), matching: find.byType(Switch));
    await tester.tap(saklarFitur.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Beranda'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Dapur'), findsNothing, reason: 'Dapur mati → hilang dari navigasi');
    expect(find.text('Menu Dijual'), findsOneWidget, reason: 'Kartu statistik ketiga jadi jumlah menu');
  });

  testWidgets('Stok Bahan: tambah bahan LANGSUNG di layar Stok', (tester) async {
    await pumpWide(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Stok Bahan'));
    await tester.pumpAndSettle();
    expect(find.byType(StokScreen), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(StokScreen), matching: find.byIcon(Icons.add)));
    await tester.pumpAndSettle();
    final kolom = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
    await tester.enterText(kolom.at(0), 'Susu UHT Uji');
    await tester.enterText(kolom.at(1), '10');
    await tester.enterText(kolom.at(2), 'liter');
    await tester.enterText(kolom.at(3), '2');
    await tester.enterText(kolom.at(4), '20');
    await tester.ensureVisible(find.text('Simpan Bahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Bahan'));
    await tester.pumpAndSettle();
    // Bahan baru ada di urutan terakhir — gulir sampai terlihat.
    await tester.scrollUntilVisible(
      find.text('Susu UHT Uji'),
      120,
      scrollable: find.descendant(
        of: find.byType(StokScreen),
        matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(StokScreen), matching: find.text('Susu UHT Uji')), findsOneWidget,
        reason: 'Bahan baru langsung tampil di layar Stok');
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Produk: kolom cari menyaring daftar', (tester) async {
    await pumpWide(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Produk'));
    await tester.pumpAndSettle();
    expect(find.byType(ProdukScreen), findsOneWidget);
    final cari = find.descendant(of: find.byType(ProdukScreen), matching: find.byType(TextField));
    await tester.enterText(cari, 'Tubruk');
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ProdukScreen), matching: find.text('Kopi Tubruk')), findsOneWidget);
    expect(find.descendant(of: find.byType(ProdukScreen), matching: find.text('Es Teh Manis')), findsNothing,
        reason: 'Produk lain tersaring keluar');
  });

  testWidgets('Produk: ketuk produk membuka editor menu', (tester) async {
    await pumpWide(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Produk'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(ProdukScreen), matching: find.text('Kopi Tubruk')));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Menu'), findsOneWidget, reason: 'Editor menu harus terbuka dari baris produk');
    expect(find.text('Foto Produk (boleh kosong)'), findsOneWidget, reason: 'Editor punya pilihan foto');
    // Tombol kembali sistem: formulir belum diubah → GuardBack
    // mengizinkan sheet tertutup langsung.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Ubah Menu'), findsNothing, reason: 'Sheet tertutup oleh tombol kembali');
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Formulir berubah + tombol kembali = peringatan dulu, tidak langsung tertutup', (tester) async {
    await pumpWide(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Produk'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(ProdukScreen), matching: find.text('Kopi Tubruk')));
    await tester.pumpAndSettle();
    // Ubah isi formulir → kotor.
    final kolomNama = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)).first;
    await tester.enterText(kolomNama, 'Kopi Tubruk Diubah');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Perubahan belum disimpan'), findsOneWidget, reason: 'Peringatan harus muncul');
    expect(find.text('Ubah Menu'), findsOneWidget, reason: 'Formulir TIDAK boleh langsung tertutup');
    await tester.tap(find.text('Tetap Mengisi'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Menu'), findsOneWidget, reason: 'Tetap di formulir sesudah memilih Tetap Mengisi');
    // Kali ini buang perubahan lewat dialognya.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Buang'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Menu'), findsNothing, reason: 'Sesudah Buang, formulir tertutup');
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Beranda: angka Rp123.456.789 tampil PENUH (tidak dibulatkan/dipotong)', (tester) async {
    final kini = DateTime.now().toIso8601String();
    SharedPreferences.setMockInitialValues({
      'avoera.settings.v1': '{"onboarded":true}',
      'avoera.tx.v1': '[{"id":"A-9001","total":123456789,"method":"Tunai","at":"$kini","items":3,"subtotal":123456789,"service":0,"tax":0,"branchId":"","uuid":"u-uji-1"}]',
    });
    await pumpWide(tester);
    expect(find.text('Rp123.456.789'), findsWidgets, reason: 'Angka besar harus tampil utuh di kartu penjualan/statistik');
  });

  testWidgets('Dialog Biaya Layanan menampilkan simulasi langsung', (tester) async {
    await pumpWide(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Pengaturan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Biaya Layanan'), 120, scrollable: scrollPengaturan());
    await tester.ensureVisible(find.text('Biaya Layanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biaya Layanan'));
    await tester.pumpAndSettle();
    expect(find.text('Simulasi di kasir'), findsOneWidget);
    expect(find.text('Pembeli membayar'), findsOneWidget);
    // Ubah 5% → 10%: pajak bawaan 10% → total contoh Rp120.000.
    final kolom = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(kolom, '10');
    await tester.pumpAndSettle();
    expect(find.textContaining('Biaya layanan (10%)'), findsOneWidget);
    expect(find.text('Rp120.000'), findsOneWidget, reason: 'Simulasi ikut berubah saat angka diketik');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Ganti tema di tengah jalan: judul seksi ikut berubah warna (tidak basi)', (tester) async {
    // Laporan Adnan 2026-11-14 20:13: sesudah pindah ke Gelap,
    // judul seksi Pengaturan tetap berwarna gelap → tak terlihat.
    // Akar: SectionTitle dibuat const dan membaca warna statis.
    await pumpWide(tester);
    expect(AppColors.gelap, isFalse);
    await tester.tap(find.widgetWithText(ListTile, 'Pengaturan'));
    await tester.pumpAndSettle();
    Color warnaJudul() => tester.widget<Text>(find.text('Sinkronisasi Online')).style!.color!;
    await tester.scrollUntilVisible(find.text('Sinkronisasi Online'), 200, scrollable: scrollPengaturan());
    await tester.pumpAndSettle();
    expect(warnaJudul(), AppColors.ink);
    await tester.scrollUntilVisible(
      find.descendant(of: find.byType(PengaturanScreen), matching: find.text('Gelap')),
      200,
      scrollable: scrollPengaturan(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(PengaturanScreen), matching: find.text('Gelap')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(AppColors.gelap, isTrue);
    await tester.scrollUntilVisible(find.text('Sinkronisasi Online'), 200, scrollable: scrollPengaturan());
    await tester.pumpAndSettle();
    expect(warnaJudul(), AppColors.ink, reason: 'Judul harus berwarna tinta mode gelap (terang)');
    expect(warnaJudul().computeLuminance(), greaterThan(0.7), reason: 'Judul harus terlihat jelas di atas latar gelap');
  });
}
