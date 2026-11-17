import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pembayaran_screen.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avoera_pos/ikon.dart';

// AUDIT FUNGSI menyeluruh (diminta Adnan 2026-11-14): setiap tombol dan
// alur utama disentuh seperti jari pengguna, bukan cuma dibaca kodenya.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

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

  Future<void> pumpPhone(WidgetTester tester, {bool keKasir = true}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Aplikasi kini membuka di Beranda — tes kasir pindah dulu ke Kasir.
    if (keKasir) {
      await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Kasir')));
      await tester.pumpAndSettle();
    }
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

  testWidgets('Audit: navigasi HP — menu utama di bawah, lainnya di sidebar geser', (tester) async {
    await pumpPhone(tester, keKasir: false);
    // Bar bawah 5 tombol: Beranda, Kasir, Produk, Dapur + Lainnya
    // (Produk masuk bar pada v0.7.0; Meja pindah ke drawer).
    final bar = tester.widget<BarNavigasiBawah>(find.byType(BarNavigasiBawah));
    expect(bar.items.length, 5, reason: 'Bar bawah harus berisi Beranda, Kasir, Produk, Dapur, Lainnya');
    expect(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Produk')), findsOneWidget);
    expect(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Pengaturan')), findsNothing,
        reason: 'Pengaturan tidak lagi di bar bawah');

    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Lainnya')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('MENU LAINNYA')), findsOneWidget);
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('Meja')), findsOneWidget,
        reason: 'Meja kini tinggal di drawer');
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Pengaturan')));
    await tester.pumpAndSettle();
    // v0.8.0: Usaha jadi kartu profil — nama usaha tampil di kartu itu.
    expect(find.text('Avoera Cafe & Resto'), findsOneWidget, reason: 'Pengaturan harus terbuka dari drawer (kartu profil usaha)');
    // Selama di menu drawer, sorotan bar bawah jatuh ke 'Lainnya'.
    expect(tester.widget<BarNavigasiBawah>(find.byType(BarNavigasiBawah)).selectedIndex, 4);
  });

  testWidgets('Audit: Beranda — penjualan ASLI muncul sesudah checkout', (tester) async {
    await pumpPhone(tester, keKasir: false);
    expect(find.text('Penjualan hari ini'), findsOneWidget);
    expect(find.text('Rp0'), findsWidgets, reason: 'Belum ada penjualan → Rp0');

    await tester.tap(find.text('Buka Kasir'));
    await tester.pumpAndSettle();
    await tambahLewatKartu(tester, 'Paket Hemat Kopi + Roti');
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();
    // Halaman bayar v0.15.0 lebih panjang (seksi Jenis + Tamu) —
    // ubin nominal kini di bawah lipatan, gulir dulu.
    await tester.scrollUntilVisible(find.text('Uang pas'), 150, scrollable: find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang pas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Beranda')));
    await tester.pumpAndSettle();
    expect(find.text('Penjualan 8 Hari Terakhir'), findsOneWidget, reason: 'Grafik penjualan harus tampil di Beranda');
    // Di atas lipatan: total penjualan + rata-rata sama-sama
    // Rp36.800 (1 transaksi).
    expect(find.text('Rp36.800'), findsAtLeastNWidgets(2), reason: 'Beranda harus menampilkan penjualan asli dari checkout tadi');
    // Kartu Transaksi Terbaru ada di bawah lipatan — gulir dulu,
    // barisnya harus membawa nominal yang sama. (Jarak gulir
    // diperbesar di v0.12.0: huruf Jakarta lebih ramping, isi
    // Beranda lebih pendek, jadi angka ringkasan harus benar-
    // benar keluar layar supaya tinggal baris transaksinya.)
    await tester.drag(find.byType(ListView).first, const Offset(0, -1100));
    await tester.pumpAndSettle();
    expect(find.text('Transaksi Terbaru'), findsOneWidget);
    // Baris transaksi memakai angka 14px; angka ringkasan di
    // atasnya 22px dan sejak huruf Jakarta (v0.12.0) keduanya
    // bisa tampil bersamaan — sasar yang 14px.
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == 'Rp36.800' && w.style?.fontSize == 14),
      findsOneWidget,
      reason: 'Baris transaksi terbaru harus tampil di Beranda',
    );
    final loaded = await LocalStore.load();
    expect(loaded.transactions.length, 1);
    expect(loaded.transactions.single.total, 36800);
  });

  testWidgets('Audit: fitur meja bisa dimatikan dari Pengaturan', (tester) async {
    await pumpPhone(tester, keKasir: false);
    Finder inBar(Finder inner) => find.descendant(of: find.byType(BarNavigasiBawah), matching: inner);
    Finder inDrawer(Finder inner) => find.descendant(of: find.byType(Drawer), matching: inner);

    // Awalnya Meja ada di drawer (sejak v0.7.0 bar bawah berisi
    // Produk; Meja pindah ke sidebar geser).
    await tester.tap(inBar(find.text('Lainnya')));
    await tester.pumpAndSettle();
    expect(inDrawer(find.text('Meja')), findsOneWidget, reason: 'Awalnya Meja ada di drawer');
    await tester.tapAt(const Offset(370, 400));
    await tester.pumpAndSettle();

    // Ke Pengaturan lewat drawer, matikan saklar Manajemen Meja.
    await tester.tap(inBar(find.text('Lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Pengaturan')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manajemen Meja'), 120, scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect((await LocalStore.load()).settings.tablesEnabled, isFalse, reason: 'Saklar harus tersimpan');

    // Drawer: Meja hilang total. Bar bawah: Dapur tetap ada.
    // Kasir: tanpa Pilih Meja.
    expect(inBar(find.text('Dapur')), findsOneWidget);
    await tester.tap(inBar(find.text('Lainnya')));
    await tester.pumpAndSettle();
    expect(inDrawer(find.text('Meja')), findsNothing, reason: 'Meja harus hilang dari semua navigasi saat mati');
    await tester.tapAt(const Offset(370, 400));
    await tester.pumpAndSettle();
    await tester.tap(inBar(find.text('Kasir')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Meja'), findsNothing, reason: 'Kasir tidak menawarkan meja saat fitur mati');

    // Nyalakan lagi → Meja kembali ke drawer.
    await tester.tap(inBar(find.text('Lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Pengaturan')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Manajemen Meja'), 120, scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect((await LocalStore.load()).settings.tablesEnabled, isTrue);
    await tester.tap(inBar(find.text('Lainnya')));
    await tester.pumpAndSettle();
    expect(inDrawer(find.text('Meja')), findsOneWidget, reason: 'Meja kembali ke drawer saat fitur dinyalakan');
  });

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

    await tester.tap(inSheet(find.widgetWithIcon(IconButton, Ikon.add)));
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
    await tester.tap(find.descendant(of: kartu, matching: find.widgetWithIcon(IconButton, Ikon.add)));
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

    final proses = find.widgetWithText(PrimaryButton, 'Proses Bayar');
    expect(tester.widget<PrimaryButton>(proses).onPressed, isNull, reason: 'Belum pilih uang → Proses Bayar harus terkunci');

    final kolom = find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(TextField));
    await tester.scrollUntilVisible(kolom, 150, scrollable: find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.enterText(kolom, '50000');
    await tester.pumpAndSettle();
    expect(find.text('Kembalian: Rp13.200'), findsOneWidget, reason: '50.000 − 36.800 = 13.200');
    expect(tester.widget<PrimaryButton>(proses).onPressed, isNotNull, reason: 'Nominal cukup → tombol terbuka');

    await tester.tap(proses);
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);
    // Siram timer dispose controller dialog (500ms).
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Audit: bayar QRIS lolos sampai dapur', (tester) async {
    await pumpPhone(tester);
    await tambahLewatKartu(tester, 'Caffe Latte');
    await tester.tap(find.text('Lihat Keranjang'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Bayar Sekarang')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('QRIS'), 150, scrollable: find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('QRIS'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tampilkan QR ini ke pelanggan'), 150, scrollable: find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(Scrollable)).first);
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
    // Ke layar Meja lewat drawer (Meja tidak lagi di bar bawah).
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Meja')));
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
    await tester.scrollUntilVisible(find.text('Uang pas'), 150, scrollable: find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang pas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    // Ke layar Meja lewat drawer (Meja tidak lagi di bar bawah).
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Meja')));
    await tester.pumpAndSettle();
    // Nama & nominal kini dua baris terpisah di kartu meja.
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Rp36.800'), findsOneWidget,
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
    // Stok Bahan kini di sidebar geser: buka lewat tombol Lainnya.
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Stok Bahan')));
    await tester.pumpAndSettle();
    // 'Habis'/'Aman' juga teks chip status di kartu bahan — ketuk chip filternya.
    await tester.tap(find.widgetWithText(AppChip, 'Habis'));
    await tester.pumpAndSettle();
    expect(find.text('Bubuk Matcha'), findsOneWidget);
    expect(find.text('Beras'), findsNothing, reason: 'Filter Habis harus menyembunyikan bahan aman');

    await tester.tap(find.widgetWithText(AppChip, 'Aman'));
    await tester.pumpAndSettle();
    expect(find.text('Beras'), findsOneWidget);
    expect(find.text('Bubuk Matcha'), findsNothing, reason: 'Filter Aman harus menyembunyikan bahan habis');
  });
}
