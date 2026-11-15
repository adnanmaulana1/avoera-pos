import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/produk_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/sync.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Patch gabungan v0.10.1 (permintaan Adnan 2026-11-15):
// 1) sheet bisa ditutup 3 cara (X, ketuk luar, tombol kembali),
// 2) X di editor kotor memicu dialog buang perubahan,
// 3) Pemberitahuan: pill kategori + tombol tandai semua terbaca,
// 4) kartu Beranda membuka halamannya.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
  }

  testWidgets('Sheet opname tertutup tiga cara: X, ketuk luar, kembali', (tester) async {
    await pumpApp(tester, size: const Size(1280, 800));
    await tester.tap(find.text('Stok Bahan').last);
    await tester.pumpAndSettle();

    // Cara 1: tombol X.
    await tester.tap(find.text('Opname'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Opname Stok')), findsOneWidget);
    await tester.tap(inSheet(find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    // Cara 2: ketuk di luar area sheet.
    await tester.tap(find.text('Opname'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tapAt(const Offset(640, 40));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    // Cara 3: tombol kembali sistem.
    await tester.tap(find.text('Opname'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('X di editor kotor memicu dialog buang perubahan', (tester) async {
    await pumpApp(tester, size: const Size(1280, 800));
    final awal = await LocalStore.load();
    final bahan = awal.ingredients.first;
    await tester.tap(find.text('Stok Bahan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(bahan.name).first);
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Ubah Bahan')), findsOneWidget);
    await tester.enterText(inSheet(find.byType(TextField)).first, 'Nama Diubah');
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.text('Perubahan belum disimpan'), findsOneWidget);
    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Pemberitahuan: pill kategori menyaring, tombol menandai terbaca', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await tester.tap(find.byTooltip('Pemberitahuan'));
    await tester.pumpAndSettle();
    expect(find.text('Pemberitahuan'), findsWidgets);
    // Data contoh punya bahan di bawah batas minimum -> notifikasi
    // stok pasti ada, lengkap dengan pill + tombolnya.
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Stok'), findsOneWidget);
    expect(find.text('Tandai semua terbaca'), findsOneWidget);
    expect(find.textContaining('Stok kritis'), findsWidgets);
    // Saring ke kategori Stok: isinya tetap notifikasi stok.
    await tester.tap(find.text('Stok'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stok kritis'), findsWidgets);
    // Tandai semua terbaca -> tombol hilang (tidak ada yang belum dibaca).
    await tester.tap(find.text('Tandai semua terbaca'));
    await tester.pumpAndSettle();
    expect(find.text('Tandai semua terbaca'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Kartu Beranda membuka halamannya', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    // Kartu penjualan (hero) -> Riwayat Transaksi.
    await tester.tap(find.text('Penjualan hari ini'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Kartu statistik Transaksi -> Riwayat Transaksi juga.
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Kartu grafik -> halaman Laporan.
    await tester.ensureVisible(find.text('Penjualan 8 Hari Terakhir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penjualan 8 Hari Terakhir'));
    await tester.pumpAndSettle();
    expect(find.text('Laporan'), findsWidgets);
    expect(find.text('Ringkasan pemilik · angka asli dari kasir cabang ini.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });

  test('idHantuDiServer: hanya id dikenal yang hilang lokal', () {
    // b dikenal & hilang lokal -> hantu. c di server tapi belum
    // dikenal (barang perangkat lain) -> TIDAK disentuh.
    expect(
      idHantuDiServer(idServer: {'a', 'b', 'c'}, idLokal: {'a'}, idDikenal: {'a', 'b'}),
      ['b'],
    );
    // Belum pernah sinkron (dikenal kosong) -> tidak ada yang dihapus.
    expect(idHantuDiServer(idServer: {'a', 'b'}, idLokal: {}, idDikenal: {}), isEmpty);
    // Masih ada di lokal -> bukan hantu.
    expect(idHantuDiServer(idServer: {'a'}, idLokal: {'a'}, idDikenal: {'a'}), isEmpty);
  });

  testWidgets('Kepala Produk menyusut saat digulir, pill tetap menempel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
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
    await tester.pumpAndSettle();
    // Ukuran diukur dari wadah di dalam kepala (sliver sendiri
    // bukan RenderBox).
    Finder wadah(Finder kepala) => find.descendant(of: kepala, matching: find.byType(Container)).first;
    final kepala = find.byType(SliverPersistentHeader);
    expect(tester.getSize(wadah(kepala.first)).height, 168);
    // Gulir jauh: kepala menyusut ke baris ringkas, pill kategori
    // (kepala kedua) tetap menempel setinggi 50.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getSize(wadah(kepala.first)).height, 58);
    expect(tester.getSize(wadah(kepala.at(1))).height, 50);
    expect(find.text('Semua'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Hapus produk memunculkan toast penegas', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    final awal = await LocalStore.load();
    final menu = awal.menus.first;
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Produk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(menu.name).first);
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Hapus')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('dihapus'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Tarik ke bawah menampilkan shimmer', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await tester.timedDrag(find.byType(ListView).first, const Offset(0, 340), const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ShimmerSkeleton), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  // Keluhan Adnan 2026-11-15 21:49: "belum sampai bawah sudah
  // kerefresh" — penyegaran kini HANYA jalan saat jari dilepas
  // sesudah tarikan mencapai ambang penuh, bukan di tengah
  // tarikan.
  testWidgets('Tarikan jauh belum menyegar sebelum jari dilepas', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    final gestur = await tester.startGesture(tester.getCenter(find.byType(ListView).first));
    for (var i = 0; i < 6; i++) {
      await gestur.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(ShimmerSkeleton), findsNothing, reason: 'Jari masih menahan: penyegaran tidak boleh jalan di tengah tarikan');
    await gestur.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShimmerSkeleton), findsOneWidget, reason: 'Sesudah dilepas dalam keadaan siap, penyegaran jalan');
    await tester.pump(const Duration(seconds: 2));
  });

  // Keputusan Adnan 2026-11-15 12:04: shimmer HANYA untuk
  // tarikan jauh yang disengaja — tarikan kecil saat menggulir
  // biasa tidak boleh menyalakan apa-apa.
  testWidgets('Tarikan kecil TIDAK menampilkan shimmer', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await tester.timedDrag(find.byType(ListView).first, const Offset(0, 60), const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShimmerSkeleton), findsNothing, reason: 'Tarikan 60px tidak boleh memicu penyegaran');
    await tester.pump(const Duration(seconds: 2));
  });

  // v0.10.4: gestur harus DIMULAI di puncak. Menggulir dari
  // tengah lalu jari kelewat menarik melewati puncak dalam
  // gestur yang sama TIDAK boleh memicu — itu tarikan tidak
  // sengaja saat menggulir biasa.
  testWidgets('Tarikan mulai dari tengah TIDAK menampilkan shimmer', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    // Gulir turun dulu (konten bergerak, posisi tidak di puncak).
    await tester.timedDrag(find.byType(ListView).first, const Offset(0, -300), const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    // Gestur baru mulai dari tengah: kembali ke puncak lalu
    // kelewat jauh — tetap tidak boleh memicu.
    await tester.timedDrag(find.byType(ListView).first, const Offset(0, 520), const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShimmerSkeleton), findsNothing, reason: 'Gestur mulai dari tengah tidak boleh memicu walau kelewat jauh');
    await tester.pump(const Duration(seconds: 2));
  });
}
