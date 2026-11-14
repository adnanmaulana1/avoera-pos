import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// AUDIT FUNGSI menyeluruh (diminta Adnan 2026-11-14): setiap tombol dan
// alur utama disentuh seperti jari pengguna, bukan cuma dibaca kodenya.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
  }

  Future<void> tambahLewatKartu(WidgetTester tester, String namaMenu) async {
    await tester.scrollUntilVisible(
      find.text(namaMenu),
      120,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(namaMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();
  }

  testWidgets('Audit: cari menu & filter kategori bekerja', (tester) async {
    await pumpPhone(tester);
    await tester.enterText(find.byType(TextField).first, 'matcha');
    await tester.pumpAndSettle();
    expect(find.text('Matcha Latte'), findsOneWidget);
    expect(find.text('Americano'), findsNothing, reason: 'Hasil cari harus menyaring menu lain');

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Nasi Ayam Geprek'), findsOneWidget);
    expect(find.text('Americano'), findsNothing, reason: 'Filter Makanan harus menyembunyikan minuman');
  });

  testWidgets('Audit: sheet varian — ukuran Besar, Less sugar, jumlah 2', (tester) async {
    await pumpPhone(tester);
    await tester.scrollUntilVisible(
      find.text('Matcha Latte'),
      120,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matcha Latte'));
    await tester.pumpAndSettle();

    await tester.tap(inSheet(find.text('Besar (+Rp4.000)')));
    await tester.pumpAndSettle();
    expect(find.text('Tambah · Rp26.000'), findsOneWidget, reason: 'Harga Besar = 22.000 + 4.000');

    await tester.tap(inSheet(find.widgetWithIcon(IconButton, Icons.add)));
    await tester.pumpAndSettle();
    expect(find.text('Tambah · Rp52.000'), findsOneWidget, reason: 'Jumlah 2 harus melipatgandakan harga tombol');

    await tester.tap(inSheet(find.text('Less sugar')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Besar · Less sugar')), findsOneWidget, reason: 'Varian pilihan harus tertulis di keranjang');
    expect(inSheet(find.text('2')), findsOneWidget);
  });

  testWidgets('Audit: tambah cepat makanan tidak pakai varian gula', (tester) async {
    await pumpPhone(tester);
    await tester.scrollUntilVisible(
      find.text('Nasi Goreng Kampung'),
      120,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    final kartu = find.ancestor(of: find.text('Nasi Goreng Kampung'), matching: find.byType(Material)).first;
    await tester.tap(find.descendant(of: kartu, matching: find.widgetWithIcon(IconButton, Icons.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Reguler')), findsOneWidget, reason: 'Makanan cukup varian Reguler');
    expect(inSheet(find.textContaining('Gula')), findsNothing, reason: 'Dulu makanan ikut tertulis Gula normal — itu bug');
  });

  testWidgets('Audit: bayar tunai — tombol terkunci, ketik nominal, kembalian benar', (tester) async {
    await pumpPhone(tester);
    await tambahLewatKartu(tester, 'Paket Hemat Kopi + Roti');
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();

    final proses = find.widgetWithText(FilledButton, 'Proses Bayar');
    expect(tester.widget<FilledButton>(proses).onPressed, isNull, reason: 'Belum pilih uang → Proses Bayar harus terkunci');

    final kolom = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(kolom, '50000');
    await tester.pumpAndSettle();
    expect(find.text('Kembalian: Rp13.200'), findsOneWidget, reason: '50.000 − 36.800 = 13.200');
    expect(tester.widget<FilledButton>(proses).onPressed, isNotNull, reason: 'Nominal cukup → tombol terbuka');

    await tester.tap(proses);
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
  });

  testWidgets('Audit: bayar QRIS lolos sampai dapur', (tester) async {
    await pumpPhone(tester);
    await tambahLewatKartu(tester, 'Caffe Latte');
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QRIS'));
    await tester.pumpAndSettle();
    expect(find.text('Tampilkan QR ini ke pelanggan'), findsOneWidget);
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dapur').last);
    await tester.pumpAndSettle();
    expect(find.text('Caffe Latte'), findsWidgets, reason: 'Pesanan QRIS harus masuk tiket dapur');
  });

  testWidgets('Audit: pilih meja → bayar → kartu meja mencerminkan tagihan', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.text('Meja').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('Aktif: Meja 1'), findsOneWidget, reason: 'Ketukan kartu harus memilih meja');
    // Tombolnya ada di bawah daftar meja — gulir sampai terlihat dulu.
    await tester.scrollUntilVisible(find.text('Pakai Meja 1 & Buka Kasir'), 100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pakai Meja 1 & Buka Kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Meja 1'), findsWidgets, reason: 'Kasir harus menunjukkan meja terpilih');

    await tambahLewatKartu(tester, 'Paket Hemat Kopi + Roti');
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Meja 1')), findsOneWidget, reason: 'Chip keranjang harus Meja 1');
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang pas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meja').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Pelanggan · Rp36.800'), findsOneWidget,
        reason: 'Dulu kartu meja diam di Rp0 walau sudah pesan & bayar — itu bug');
  });

  testWidgets('Audit: dapur — majukan status sampai pesanan hilang', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.text('Dapur').last);
    await tester.pumpAndSettle();

    Finder kartu1042() => find.ancestor(of: find.text('A-1042'), matching: find.byType(AppCard));
    // Kartu berpindah kolom tiap status maju — gulir dulu sebelum ketuk,
    // kalau tidak ketukannya mendarat di luar layar.
    Future<void> maju(String label) async {
      await tester.scrollUntilVisible(find.text('A-1042'), 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: kartu1042(), matching: find.text(label)));
      await tester.pumpAndSettle();
    }

    await maju('Mulai Masak');
    expect(find.descendant(of: kartu1042(), matching: find.text('Tandai Selesai')), findsOneWidget,
        reason: 'Sesudah Mulai Masak, tombol harus jadi Tandai Selesai');

    await maju('Tandai Selesai');
    expect(find.descendant(of: kartu1042(), matching: find.text('Sudah Diantar')), findsOneWidget);

    await maju('Sudah Diantar');
    expect(find.text('A-1042'), findsNothing, reason: 'Sesudah diantar, pesanan selesai & hilang dari dapur');
  });

  testWidgets('Audit: stok — filter Habis & Aman menyaring dengan benar', (tester) async {
    await pumpPhone(tester);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Stok Bahan')));
    await tester.pumpAndSettle();
    // 'Habis'/'Aman' juga teks chip status di kartu bahan — ketuk chip filternya.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Habis'));
    await tester.pumpAndSettle();
    expect(find.text('Bubuk Matcha'), findsOneWidget);
    expect(find.text('Beras'), findsNothing, reason: 'Filter Habis harus menyembunyikan bahan aman');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Aman'));
    await tester.pumpAndSettle();
    expect(find.text('Beras'), findsOneWidget);
    expect(find.text('Bubuk Matcha'), findsNothing, reason: 'Filter Aman harus menyembunyikan bahan habis');
  });
}
