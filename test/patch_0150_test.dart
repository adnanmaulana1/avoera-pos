// Tes v0.15.0 (diminta Adnan 2026-11-17): Margin Tipis,
// Laporan Pengunjung (+ catatan tamu di Pembayaran), pilihan
// Dine-in/Bungkus di Pembayaran yang sinkron dengan Kasir,
// Tutup Kasir (sesi), struk (susun + teks + ESC/POS), dan
// splash artwork baru (cukup: berkas aset terbaca & layar
// splash membangun). Cetak Bluetooth asli hanya bisa
// dibuktikan di perangkat Adnan — di sini logika byte-nya.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/ikon.dart';
import 'package:avoera_pos/screens/laporan_screen.dart';
import 'package:avoera_pos/screens/margin_tipis_screen.dart';
import 'package:avoera_pos/screens/pembayaran_screen.dart';
import 'package:avoera_pos/screens/pengunjung_screen.dart';
import 'package:avoera_pos/screens/sesi_kasir_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/struk.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Ingredient _bahan({String id = 'b1', String nama = 'Alpukat', int harga = 3000}) =>
    Ingredient(id: id, name: nama, stock: 50, unit: 'kg', minStock: 5, maxStock: 100, costPerUnit: harga);

MenuItem _menu({required String id, required String nama, required int hargaJual, List<RecipeLine>? resep}) => MenuItem(
      id: id,
      name: nama,
      category: 'Minuman',
      price: hargaJual,
      color: const Color(0xFF33691E),
      icon: Ikon.local_drink,
      isDrink: true,
      recipe: resep,
    );

TxRecord _tx(String id, DateTime at, {int total = 50000, String method = 'Tunai', String status = 'Lunas', String branchId = 'utama', int tamu = 0, List<TxLine> lines = const [], int diskon = 0, int subtotal = 0, int service = 0, int tax = 0}) =>
    TxRecord(id: id, total: total, method: method, at: at, items: 1, branchId: branchId, status: status, tamu: tamu, lines: lines, diskon: diskon, subtotal: subtotal, service: service, tax: tax);

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
  });

  Widget bungkus(Widget anak) => MaterialApp(theme: buildTheme(), home: anak);
  Widget bungkusHalaman(Widget anak) => MaterialApp(theme: buildTheme(), home: Scaffold(body: anak));

  Future<void> seretSampai(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
  }

  group('hitungMarginMenu', () {
    final bahan = [_bahan(id: 'b1', harga: 3000), _bahan(id: 'b2', nama: 'Susu', harga: 9000), _bahan(id: 'b3', nama: 'Gula', harga: 0)];
    final menuA = _menu(id: 'mA', nama: 'Menu A', hargaJual: 15000, resep: [RecipeLine(ingredientId: 'b1', qty: 0.2)]); // HPP 600 → 96%
    final menuB = _menu(id: 'mB', nama: 'Menu B', hargaJual: 10000, resep: [RecipeLine(ingredientId: 'b2', qty: 1)]); // HPP 9000 → 10%
    final menuC = _menu(id: 'mC', nama: 'Menu C', hargaJual: 8000); // tanpa resep
    final menuD = _menu(id: 'mD', nama: 'Menu D', hargaJual: 9000, resep: [RecipeLine(ingredientId: 'b3', qty: 1)]); // harga bahan kosong

    test('urut paling tipis dulu + status jujur', () {
      final hasil = hitungMarginMenu(menus: [menuA, menuB, menuC, menuD], ingredients: bahan);
      expect(hasil[0].menu.id, 'mB');
      expect(hasil[0].status, StatusMargin.terhitung);
      expect(hasil[0].persen, closeTo(10, 0.001));
      expect(hasil[1].menu.id, 'mA');
      expect(hasil[1].persen, closeTo(96, 0.001));
      final status = {for (final h in hasil) h.menu.id: h.status};
      expect(status['mC'], StatusMargin.tanpaResep);
      expect(status['mD'], StatusMargin.hargaBahanKosong);
    });

    test('jumlahTerjualPerMenu hanya Lunas dalam rentang & cabang', () {
      final kini = DateTime.now();
      final txs = [
        _tx('t1', kini, lines: [TxLine(nama: 'Menu B', qty: 5, total: 50000)]),
        _tx('t2', kini, status: 'Batal', lines: [TxLine(nama: 'Menu B', qty: 7, total: 70000)]),
        _tx('t3', kini, branchId: 'lain', lines: [TxLine(nama: 'Menu B', qty: 9, total: 90000)]),
      ];
      final j = jumlahTerjualPerMenu(transactions: txs, branchId: 'utama', dari: kini.subtract(const Duration(hours: 1)), sampai: kini.add(const Duration(hours: 1)));
      expect(j['Menu B'], 5);
    });
  });

  group('hitungPengunjung', () {
    test('hanya tamu > 0 yang tercatat; rata-rata & per hari benar', () {
      final kini = DateTime.now();
      final txs = [
        _tx('t1', kini, tamu: 4),
        _tx('t2', kini, tamu: 2),
        _tx('t3', kini, tamu: 0),
        _tx('t4', kini, status: 'Batal', tamu: 5),
        _tx('t5', kini, branchId: 'lain', tamu: 3),
      ];
      final h = hitungPengunjung(transactions: txs, branchId: 'utama', dari: kini.subtract(const Duration(hours: 1)), sampai: kini.add(const Duration(hours: 1)));
      expect(h.totalTamu, 6);
      expect(h.txTercatat, 2);
      expect(h.totalTransaksi, 3);
      expect(h.rataRata, closeTo(3, 0.001));
      expect(h.terbanyak, 4);
      expect(h.perHari.length, 1);
      expect(h.perHari.first.tamu, 6);
    });
  });

  group('layar laporan baru', () {
    testWidgets('MarginTipisScreen: hero = menu paling tipis + bagian belum terhitung', (tester) async {
      final kini = DateTime.now();
      final bahan = [_bahan(id: 'b2', nama: 'Susu', harga: 9000)];
      final menuB = _menu(id: 'mB', nama: 'Menu B', hargaJual: 10000, resep: [RecipeLine(ingredientId: 'b2', qty: 1)]);
      final menuC = _menu(id: 'mC', nama: 'Menu C', hargaJual: 8000);
      await tester.pumpWidget(bungkus(MarginTipisScreen(
        menus: [menuB, menuC],
        ingredients: bahan,
        transactions: [_tx('t1', kini, lines: [TxLine(nama: 'Menu B', qty: 5, total: 50000)])],
        branchId: 'utama',
        branchName: 'Cabang Utama',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Menu B'), findsWidgets);
      expect(find.text('10%'), findsWidgets);
      await seretSampai(tester, find.text('Belum bisa dihitung'));
      expect(find.text('Belum ada resep'), findsOneWidget);
    });

    testWidgets('PengunjungScreen: total & rata-rata tampil', (tester) async {
      final kini = DateTime.now();
      await tester.pumpWidget(bungkus(PengunjungScreen(
        transactions: [_tx('t1', kini, tamu: 4), _tx('t2', kini, tamu: 2), _tx('t3', kini, tamu: 0)],
        branchId: 'utama',
        branchName: 'Cabang Utama',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Total Pengunjung'), findsOneWidget);
      await seretSampai(tester, find.text('Dari 3 transaksi lunas pada periode ini'));
      expect(find.text('Dari 3 transaksi lunas pada periode ini'), findsOneWidget);
      expect(find.text('3 orang'), findsOneWidget); // rata-rata
    });

    testWidgets('LaporanScreen: tidak ada baris Segera; dua pintu baru memanggil callback', (tester) async {
      var margin = 0;
      var pengunjung = 0;
      await tester.pumpWidget(bungkusHalaman(LaporanScreen(
        transactions: const [],
        branchId: 'utama',
        tables: const [],
        onOpenRiwayat: () {},
        onOpenBulanan: () {},
        onOpenPajak: () {},
        onOpenPiutang: () {},
        onOpenLabaRugi: () {},
        onOpenNeraca: () {},
        onOpenArusKas: () {},
        onOpenArusStok: () {},
        onOpenPersediaan: () {},
        onOpenPembelian: () {},
        onOpenHutang: () {},
        onOpenPromo: () {},
        onOpenMarginTipis: () => margin++,
        onOpenPengunjung: () => pengunjung++,
      )));
      await tester.pumpAndSettle();
      await seretSampai(tester, find.text('Margin Tipis'));
      expect(find.text('Segera'), findsNothing);
      await tester.tap(find.text('Margin Tipis'));
      await tester.pump();
      expect(margin, 1);
      await seretSampai(tester, find.text('Laporan Pengunjung'));
      await tester.tap(find.text('Laporan Pengunjung'));
      await tester.pump();
      expect(pengunjung, 1);
    });
  });

  group('Pembayaran: tamu + jenis sinkron', () {
    Widget hostBayar(PembayaranScreen anak) {
      return MaterialApp(
        theme: buildTheme(),
        home: _HostBayar(anak: anak),
      );
    }

    PembayaranScreen layarBayar({String jenisAwal = 'Dine-in', String labelMeja = ''}) => PembayaranScreen(
          subtotal: 50000,
          service: 0,
          tax: 0,
          grandTotal: 50000,
          servicePercent: 0,
          taxPercent: 0,
          jenisAwal: jenisAwal,
          labelMeja: labelMeja,
          items: const [BarisBayar(nama: 'Alpukat Kocok', qty: 1, total: 50000)],
        );

    testWidgets('catat 2 tamu + ganti Bungkus→Dine-in terbawa pulang', (tester) async {
      await tester.pumpWidget(hostBayar(layarBayar(jenisAwal: 'Bungkus')));
      await tester.tap(find.text('Buka Bayar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Dine-in'), 150, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Dine-in'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Jumlah tamu'), 150, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      final tambah = find.widgetWithIcon(IconButton, Ikon.add);
      await tester.tap(tambah);
      await tester.pump();
      await tester.tap(tambah);
      await tester.pump();
      expect(find.text('2 orang'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Uang pas'), 150, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Uang pas'));
      await tester.pump();
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('HASIL metode=Tunai tamu=2 jenis=Dine-in'), findsOneWidget);
    });

    testWidgets('pesanan meja: jenis terkunci Dine-in + label meja tampil', (tester) async {
      await tester.pumpWidget(hostBayar(layarBayar(jenisAwal: 'Dine-in', labelMeja: 'Meja 3')));
      await tester.tap(find.text('Buka Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('Dine-in · Meja 3'), findsOneWidget);
      expect(find.text('Bungkus'), findsNothing);
      await tester.scrollUntilVisible(find.text('Uang pas'), 150, scrollable: find.byType(Scrollable).first);
      // Seret sedikit lagi: ubin bisa berhenti tepat di balik
      // bar bawah yang menempel.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uang pas'));
      await tester.pump();
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('HASIL metode=Tunai tamu=0 jenis=Dine-in'), findsOneWidget);
    });
  });

  group('Sesi Kasir', () {
    test('ringkasSesi: jendela waktu + cabang + pecahan tunai/QRIS + selisih', () {
      final buka = DateTime(2026, 11, 17, 8);
      final tutup = DateTime(2026, 11, 17, 22);
      final sesi = SesiKasir(branchId: 'utama', dibukaPada: buka, modalAwal: 100000, ditutupPada: tutup, tunaiFisik: 175000, pengeluaranLaci: 10000);
      final txs = [
        _tx('sebelum', buka.subtract(const Duration(minutes: 1))),
        _tx('tunai', buka.add(const Duration(hours: 1)), total: 50000),
        _tx('qris', buka.add(const Duration(hours: 2)), total: 30000, method: 'QRIS'),
        _tx('sesudah', tutup.add(const Duration(minutes: 1))),
        _tx('cabang-lain', buka.add(const Duration(hours: 1)), branchId: 'lain'),
      ];
      final keluar = [
        Pengeluaran(tanggal: buka.add(const Duration(hours: 3)), kategori: 'Lainnya', jumlah: 10000, branchId: 'utama'),
        Pengeluaran(tanggal: tutup.add(const Duration(days: 1)), kategori: 'Lainnya', jumlah: 5000, branchId: 'utama'),
      ];
      final r = ringkasSesi(sesi: sesi, transactions: txs, expenses: keluar);
      expect(r.jumlahTransaksi, 2);
      expect(r.totalTunai, 50000);
      expect(r.totalQris, 30000);
      expect(r.totalPenjualan, 80000);
      expect(r.totalPengeluaran, 10000);
      expect(sesi.tunaiSeharusnya(r), 140000);
      expect(sesi.selisih(r), 35000);
    });

    test('LocalStore: sesi + desain struk tersimpan & terbaca lagi', () async {
      SharedPreferences.setMockInitialValues({});
      await LocalStore.saveSesi([SesiKasir(branchId: 'utama', dibukaPada: DateTime(2026, 1, 1, 8), modalAwal: 1000)]);
      await LocalStore.saveStruk(DesainStruk(lebarKertas: 80));
      final data = await LocalStore.load();
      expect(data.sesi.length, 1);
      expect(data.sesi.first.modalAwal, 1000);
      final d = await LocalStore.loadStruk();
      expect(d.lebarKertas, 80);
    });

    test('SesiKasir JSON pulang-pergi utuh', () {
      final s = SesiKasir(branchId: 'utama', dibukaPada: DateTime(2026, 11, 17, 8, 30), modalAwal: 50000, namaKasir: 'Sari', ditutupPada: DateTime(2026, 11, 17, 22, 5), tunaiFisik: 90000, pengeluaranLaci: 5000, catatan: 'aman');
      final b = SesiKasir.fromJson(s.toJson());
      expect(b.id, s.id);
      expect(b.modalAwal, 50000);
      expect(b.namaKasir, 'Sari');
      expect(b.terbuka, isFalse);
      expect(b.tunaiFisik, 90000);
      expect(b.catatan, 'aman');
    });

    testWidgets('SesiKasirScreen: buka sesi lewat lembar', (tester) async {
      String? nama;
      int? modal;
      await tester.pumpWidget(bungkus(SesiKasirScreen(
        sesi: const [],
        transactions: const [],
        expenses: const [],
        branchId: 'utama',
        branchName: 'Cabang Utama',
        onBuka: (n, m) {
          nama = n;
          modal = m;
        },
        onTutup: (_, __, ___) {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Kasir Belum Dibuka'), findsOneWidget);
      await tester.tap(find.text('Buka Kasir'));
      await tester.pumpAndSettle();
      final kolom = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
      await tester.enterText(kolom.at(0), 'Sari');
      await tester.enterText(kolom.at(1), '50000');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(nama, 'Sari');
      expect(modal, 50000);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('SesiKasirScreen: sesi terbuka tampil ringkasan + tombol Tutup', (tester) async {
      final sesi = SesiKasir(branchId: 'utama', dibukaPada: DateTime.now().subtract(const Duration(hours: 2)), modalAwal: 100000, namaKasir: 'Sari');
      await tester.pumpWidget(bungkus(SesiKasirScreen(
        sesi: [sesi],
        transactions: [_tx('t1', DateTime.now(), total: 50000)],
        expenses: const [],
        branchId: 'utama',
        branchName: 'Cabang Utama',
        onBuka: (_, __) {},
        onTutup: (_, __, ___) {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Kasir Sedang Buka'), findsOneWidget);
      expect(find.text('Tutup Kasir'), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);
    });
  });

  group('Struk', () {
    TxRecord txStruk() => _tx('A-0123', DateTime(2026, 11, 17, 10, 30),
        total: 66700, subtotal: 58000, service: 2900, tax: 5800, tamu: 2, lines: [TxLine(nama: 'Alpukat Kocok Original', qty: 2, total: 36000), TxLine(nama: 'Alpukat Kocok Coklat', keterangan: 'Less sugar', qty: 1, total: 22000)]);

    test('susunStruk + teks: isi lengkap & lebar baris patuh 58mm', () {
      final desain = DesainStruk(teksHeader: 'Bikin Harimu Lebih Segar!', teksTambahan: 'WiFi: AvoreaGuest');
      final baris = susunStruk(tx: txStruk(), desain: desain, namaUsaha: 'Avoera Cafe & Resto', alamat: 'Jl. Poros No. 1', telepon: '0812-3456', branchName: 'Cabang Utama');
      final teks = strukKeTeks(baris, desain.lebarKarakter);
      expect(teks, contains('Avoera Cafe & Resto'));
      expect(teks, contains('Bikin Harimu Lebih Segar!'));
      expect(teks, contains('Jumlah tamu'));
      expect(teks, contains('TOTAL'));
      expect(teks, contains('Rp66.700'));
      expect(teks, contains('Terima kasih sudah berkunjung!'));
      expect(teks, contains('WiFi: AvoreaGuest'));
      for (final l in teks.split('\n')) {
        expect(l.length, lessThanOrEqualTo(32), reason: 'baris kepanjangan: "$l"');
      }
    });

    test('saklar desain bekerja: alamat/telepon/tamu bisa disembunyikan', () {
      final desain = DesainStruk(tampilAlamat: false, tampilTelepon: false, tampilTamu: false);
      final teks = strukKeTeks(
        susunStruk(tx: txStruk(), desain: desain, namaUsaha: 'Avoera', alamat: 'Jl. Poros', telepon: '0812', branchName: ''),
        desain.lebarKarakter,
      );
      expect(teks, isNot(contains('Jl. Poros')));
      expect(teks, isNot(contains('0812')));
      expect(teks, isNot(contains('Jumlah tamu')));
    });

    test('ESC/POS: mulai inisialisasi, akhiri potong, TOTAL tercetak tebal', () {
      final desain = DesainStruk();
      final bytes = strukKeEscPos(susunStruk(tx: txStruk(), desain: desain, namaUsaha: 'Avoera', alamat: '', telepon: '', branchName: ''), desain.lebarKarakter);
      expect(bytes.sublist(0, 2), [0x1B, 0x40]);
      expect(bytes.sublist(bytes.length - 3), [0x1D, 0x56, 0x01]);
      final sebagaiTeks = String.fromCharCodes(bytes.where((b) => b >= 32 && b < 127));
      expect(sebagaiTeks, contains('TOTAL'));
      expect(sebagaiTeks, contains('Rp66.700'));
    });

    test('DesainStruk JSON pulang-pergi utuh', () {
      final d = DesainStruk(tampilAlamat: false, teksFooter: 'Makasih!', lebarKertas: 80, namaPrinter: 'MTP-58', idPrinter: 'AA:BB');
      final b = DesainStruk.fromJson(d.toJson());
      expect(b.tampilAlamat, isFalse);
      expect(b.teksFooter, 'Makasih!');
      expect(b.lebarKertas, 80);
      expect(b.lebarKarakter, 48);
      expect(b.printerSiap, isTrue);
    });
  });

  group('splash artwork', () {
    test('berkas splash baru ada di aset branding', () {
      final f = File('/home/hatch/workspace/projects/avoera-pos/assets/branding/avorea-splash.png');
      expect(f.existsSync(), isTrue);
      expect(f.lengthSync(), greaterThan(100000));
    });
  });
}

/// Host penangkap hasil PembayaranScreen untuk tes.
class _HostBayar extends StatelessWidget {
  const _HostBayar({required this.anak});
  final PembayaranScreen anak;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final r = await Navigator.of(context).push<HasilBayar>(MaterialPageRoute(builder: (_) => anak));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('HASIL metode=${r?.metode} tamu=${r?.tamu} jenis=${r?.jenis}'), duration: const Duration(seconds: 30)));
              },
              child: const Text('Buka Bayar'),
            ),
          ],
        ),
      ),
    );
  }
}
