import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Regresi bug dari HP (2026-11-14): sheet keranjang di HP tidak bereaksi —
// tombol +/−/Hapus mengubah data tapi tampilan diam, karena isi sheet
// tidak pernah digambar ulang. Tes ini meniru persis jari pengguna:
// tambah menu → buka keranjang → ubah jumlah → hapus → bayar → dapur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

  // Muat font Roboto asli: font bawaan tes jauh lebih lebar daripada
  // Roboto, bikin dialog pembayaran terlihat meluber padahal di HP
  // asli pas (terverifikasi: tanpa font ini overflow 28px, dengan
  // font ini bersih).
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
    // Huruf khas v0.12.0 ikut dimuat — tanpa ini judul/angka
    // jatuh ke font uji raksasa dan lebar teksnya mengecoh.
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  Finder inSheet(Finder inner) => find.descendant(of: find.byType(BottomSheet), matching: inner);

  Future<void> tambahPaketDariKartu(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Paket Hemat Kopi + Roti'),
      120,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paket Hemat Kopi + Roti'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();
  }

  testWidgets('Sheet keranjang HP: +/−/Hapus langsung mengubah tampilan', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Aplikasi membuka di Beranda — pindah ke Kasir dulu.
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Kasir')));
    await tester.pumpAndSettle();

    await tambahPaketDariKartu(tester);
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();

    // Isi awal: 1 item, total Rp36.800 (32.000 + 5% + 10%).
    expect(inSheet(find.text('Paket Hemat Kopi + Roti')), findsOneWidget);
    expect(inSheet(find.text('Rp36.800')), findsOneWidget);

    // Ketuk + → jumlah jadi 2 dan total ikut naik. Ini yang dulu diam.
    await tester.tap(inSheet(find.widgetWithIcon(IconButton, Icons.add)));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('2')), findsOneWidget, reason: 'Jumlah harus berubah jadi 2');
    expect(inSheet(find.text('Rp73.600')), findsOneWidget, reason: 'Total harus ikut berubah');

    // Ketuk − → kembali 1.
    await tester.tap(inSheet(find.widgetWithIcon(IconButton, Icons.remove)));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Rp36.800')), findsOneWidget, reason: 'Total harus turun lagi');

    // Hapus → panel menyatakan keranjang kosong.
    await tester.tap(inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    expect(inSheet(find.textContaining('Keranjang masih kosong')), findsOneWidget, reason: 'Item harus hilang dari sheet');
  });

  testWidgets('Bayar dari sheet HP: pesanan masuk dapur', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Aplikasi membuka di Beranda — pindah ke Kasir dulu.
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Kasir')));
    await tester.pumpAndSettle();

    await tambahPaketDariKartu(tester);
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();

    expect(find.text('Pembayaran'), findsOneWidget);
    await tester.tap(find.text('Uang pas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dapur').last);
    await tester.pumpAndSettle();
    expect(find.text('Paket Hemat Kopi + Roti'), findsOneWidget, reason: 'Pesanan terbayar harus tampil di dapur');
  });
}
