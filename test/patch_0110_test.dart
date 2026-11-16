// Tes v0.11.0 — UPDATE BESAR (diminta Adnan 2026-11-16):
// semua laporan yang dulu 'Segera' dibangun: Neraca, Arus
// Kas, Arus Stok, Persediaan, Pembelian, Hutang (model +
// CRUD), Promo & Diskon (hitung + alur kasir). Tes hitungan
// murni + layar utama tiap fitur + alur promo ujung ke ujung.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/arus_kas_screen.dart';
import 'package:avoera_pos/screens/arus_stok_screen.dart';
import 'package:avoera_pos/screens/hutang_screen.dart';
import 'package:avoera_pos/screens/kasir_screen.dart';
import 'package:avoera_pos/screens/laporan_screen.dart';
import 'package:avoera_pos/screens/neraca_screen.dart';
import 'package:avoera_pos/screens/pembelian_screen.dart';
import 'package:avoera_pos/screens/persediaan_screen.dart';
import 'package:avoera_pos/screens/pin_screen.dart';
import 'package:avoera_pos/screens/promo_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Ingredient _bahan({String id = 'b1', String nama = 'Alpukat', double stok = 50, int harga = 3000, double min = 5}) =>
    Ingredient(id: id, name: nama, stock: stok, unit: 'kg', minStock: min, maxStock: 100, costPerUnit: harga);

MenuItem _menu() => MenuItem(
      id: 'm1',
      name: 'Jus Alpukat',
      category: 'Minuman',
      price: 15000,
      color: const Color(0xFF33691E),
      icon: Icons.local_drink,
      isDrink: true,
      recipe: [RecipeLine(ingredientId: 'b1', qty: 0.2)],
    );

TxRecord _tx(String id, int total, DateTime at, {String method = 'Tunai', String status = 'Lunas', String branchId = 'utama', List<TxLine> lines = const [], int diskon = 0, String promoNama = ''}) =>
    TxRecord(id: id, total: total, method: method, at: at, items: 1, branchId: branchId, status: status, lines: lines, diskon: diskon, promoNama: promoNama);

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
  });

  group('hitungDiskonPromo', () {
    final persen10 = Promo(id: 'p1', nama: 'Sepuluh', jenis: 'persen', nilai: 10);
    test('null / nonaktif / subtotal 0 → 0', () {
      expect(hitungDiskonPromo(null, 100000), 0);
      expect(hitungDiskonPromo(persen10.salin(aktif: false), 100000), 0);
      expect(hitungDiskonPromo(persen10, 0), 0);
    });
    test('persen dihitung dari subtotal, dibulatkan', () {
      expect(hitungDiskonPromo(persen10, 100000), 10000);
      expect(hitungDiskonPromo(Promo(nama: 'X', jenis: 'persen', nilai: 33), 10000), 3300);
    });
    test('nominal dibatasi subtotal', () {
      expect(hitungDiskonPromo(Promo(nama: 'X', jenis: 'nominal', nilai: 20000), 15000), 15000);
      expect(hitungDiskonPromo(Promo(nama: 'X', jenis: 'nominal', nilai: 5000), 15000), 5000);
    });
    test('syarat minimum belanja belum terpenuhi → 0', () {
      final p = Promo(nama: 'X', jenis: 'persen', nilai: 50, minBelanja: 100000);
      expect(hitungDiskonPromo(p, 99999), 0);
      expect(hitungDiskonPromo(p, 100000), 50000);
    });
    test('persen di atas 100 dijepit ke subtotal', () {
      expect(hitungDiskonPromo(Promo(nama: 'X', jenis: 'persen', nilai: 150), 40000), 40000);
    });
  });

  group('TxRecord diskon JSON', () {
    test('round-trip membawa diskon & nama promo', () {
      final t = _tx('A-1', 27000, DateTime(2026, 11, 16), diskon: 3000, promoNama: 'Promo Uji');
      final balik = TxRecord.fromJson(t.toJson());
      expect(balik.diskon, 3000);
      expect(balik.promoNama, 'Promo Uji');
      expect(balik.total, 27000);
    });
    test('JSON lama tanpa kolom diskon → 0 dan kosong', () {
      final j = _tx('A-1', 27000, DateTime(2026, 11, 16)).toJson()
        ..remove('diskon')
        ..remove('promoNama');
      final balik = TxRecord.fromJson(j);
      expect(balik.diskon, 0);
      expect(balik.promoNama, '');
    });
  });

  group('Hutang', () {
    final tgl = DateTime(2026, 11, 10);
    test('JSON round-trip lengkap termasuk tanggal opsional', () {
      final h = Hutang(tanggal: tgl, kreditur: 'Toko Makmur', keterangan: 'Bahan', jumlah: 200000, jatuhTempo: DateTime(2026, 11, 30), branchId: 'utama');
      final balik = Hutang.fromJson(h.toJson());
      expect(balik.kreditur, 'Toko Makmur');
      expect(balik.jumlah, 200000);
      expect(balik.jatuhTempo, DateTime(2026, 11, 30));
      expect(balik.lunas, isFalse);
      expect(balik.tanggalLunas, isNull);
    });
    test('terlambat hanya bila belum lunas & lewat jatuh tempo', () {
      final h = Hutang(tanggal: tgl, kreditur: 'X', jumlah: 1000, jatuhTempo: DateTime(2026, 11, 12));
      expect(h.terlambat(DateTime(2026, 11, 12)), isFalse);
      expect(h.terlambat(DateTime(2026, 11, 13)), isTrue);
      expect(h.salin(lunas: true).terlambat(DateTime(2026, 12, 1)), isFalse);
    });
    test('totalHutangBelumLunas menyaring lunas, cabang & tanggal', () {
      final daftar = [
        Hutang(tanggal: tgl, kreditur: 'A', jumlah: 100000, branchId: 'utama'),
        Hutang(tanggal: tgl, kreditur: 'B', jumlah: 50000, lunas: true, branchId: 'utama'),
        Hutang(tanggal: tgl, kreditur: 'C', jumlah: 70000, branchId: 'lain'),
        Hutang(tanggal: DateTime(2026, 12, 1), kreditur: 'D', jumlah: 90000, branchId: 'utama'),
        Hutang(tanggal: tgl, kreditur: 'E', jumlah: 30000, branchId: ''),
      ];
      expect(totalHutangBelumLunas(daftar, branchId: 'utama', tanggal: DateTime(2026, 11, 16)), 130000);
    });
  });

  group('nilaiPersediaan', () {
    test('total = stok × harga pokok, terurut nilai terbesar', () {
      final (total, rincian) = nilaiPersediaan([
        _bahan(id: 'b1', nama: 'Alpukat', stok: 50, harga: 3000),
        _bahan(id: 'b2', nama: 'Susu', stok: 10, harga: 20000),
        _bahan(id: 'b3', nama: 'Gula', stok: 0, harga: 15000),
      ]);
      expect(total, 350000);
      expect(rincian.first.bahan.name, 'Susu');
      expect(rincian.last.nilai, 0);
    });
  });

  group('hitungNeraca', () {
    final tgl = DateTime(2026, 11, 16);
    HasilNeraca hitung() => hitungNeraca(
          transactions: [
            _tx('A-1', 500000, tgl),
            _tx('A-2', 300000, tgl, method: 'QRIS'),
            _tx('A-3', 100000, tgl, status: 'Belum bayar'),
            _tx('A-4', 999000, DateTime(2026, 11, 20)), // sesudah tanggal posisi
            _tx('A-5', 7000, tgl, branchId: 'lain'),
          ],
          menus: [_menu()],
          ingredients: [_bahan(stok: 50, harga: 3000)],
          expenses: [Pengeluaran(tanggal: tgl, kategori: 'Sewa', jumlah: 50000, branchId: 'utama')],
          hutang: [
            Hutang(tanggal: tgl, kreditur: 'A', jumlah: 200000, branchId: 'utama'),
            Hutang(tanggal: tgl, kreditur: 'B', jumlah: 999000, lunas: true, branchId: 'utama'),
          ],
          branchId: 'utama',
          tanggal: tgl,
        );
    test('komponen aktiva benar', () {
      final h = hitung();
      expect(h.kasTunai, 450000);
      expect(h.saldoQris, 300000);
      expect(h.nilaiPersediaan, 150000);
      expect(h.piutang, 100000);
      expect(h.jumlahPiutang, 1);
      expect(h.totalAktiva, 1000000);
    });
    test('pasiva: utang belum lunas + laba ditahan + modal penyeimbang → seimbang', () {
      final h = hitung();
      expect(h.utang, 200000);
      expect(h.pendapatanKumulatif, 800000);
      expect(h.labaDitahan, 750000);
      expect(h.modalPenyeimbang, 50000);
      expect(h.totalPasiva, 1000000);
      expect(h.seimbang, isTrue);
    });
  });

  group('hitungArusKas', () {
    final dari = DateTime(2026, 11, 1);
    final sampai = DateTime(2026, 11, 30);
    test('masuk, keluar, saldo awal & akhir konsisten', () {
      final h = hitungArusKas(
        transactions: [
          _tx('A-0', 100000, DateTime(2026, 10, 15)),
          _tx('A-1', 200000, DateTime(2026, 11, 5)),
          _tx('A-2', 50000, DateTime(2026, 11, 6), method: 'QRIS'),
          _tx('A-3', 999000, DateTime(2026, 12, 5)),
        ],
        expenses: [Pengeluaran(tanggal: DateTime(2026, 11, 7), kategori: 'Gaji', jumlah: 30000, branchId: 'utama')],
        mutasi: [MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'masuk', jumlah: 2, stokSesudah: 52, satuan: 'kg', waktu: DateTime(2026, 11, 8))],
        ingredients: [_bahan(harga: 10000)],
        hutang: [
          Hutang(tanggal: DateTime(2026, 11, 9), kreditur: 'Baru', jumlah: 300000, branchId: 'utama'),
          Hutang(tanggal: DateTime(2026, 10, 2), kreditur: 'Lama', jumlah: 40000, lunas: true, tanggalLunas: DateTime(2026, 11, 10), branchId: 'utama'),
        ],
        branchId: 'utama',
        dari: dari,
        sampai: sampai,
      );
      expect(h.masukTunai, 200000);
      expect(h.masukQris, 50000);
      expect(h.hutangBaru, 300000);
      expect(h.pembelianBahan, 20000);
      expect(h.biayaOperasional, 30000);
      expect(h.rincianBiaya, [('Gaji', 30000)]);
      expect(h.bayarHutang, 40000);
      // Saldo awal: tunai sebelum periode 100rb + hutang baru
      // sebelum periode 40rb (hutang 'Lama' dibuat Oktober).
      expect(h.saldoAwal, 140000);
      expect(h.arusBersih, 460000);
      expect(h.saldoAkhir, 600000);
    });
  });

  group('ringkasArusStok & ringkasPembelian', () {
    final mutasi = [
      MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'masuk', jumlah: 10, stokSesudah: 60, satuan: 'kg', waktu: DateTime(2026, 11, 3)),
      MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'jual', jumlah: -3, stokSesudah: 57, satuan: 'kg', waktu: DateTime(2026, 11, 4)),
      MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'opname', jumlah: -1, stokSesudah: 56, satuan: 'kg', waktu: DateTime(2026, 11, 5)),
      MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'edit', jumlah: 0.5, stokSesudah: 56.5, satuan: 'kg', waktu: DateTime(2026, 11, 6)),
      MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'masuk', jumlah: 99, stokSesudah: 155, satuan: 'kg', waktu: DateTime(2026, 10, 1)),
    ];
    test('arus stok per bahan: masuk, terpakai dibalik positif, bersih', () {
      final r = ringkasArusStok(mutasi, dari: DateTime(2026, 11, 1), sampai: DateTime(2026, 11, 30));
      expect(r.length, 1);
      expect(r.single.masuk, 10);
      expect(r.single.terpakai, 3);
      expect(r.single.opname, -1);
      expect(r.single.edit, 0.5);
      expect(r.single.perubahanBersih, 6.5);
      expect(r.single.peristiwa, 4);
    });
    test('pembelian hanya barang masuk dalam periode, dinilai harga kini', () {
      final h = ringkasPembelian(mutasi, [_bahan(harga: 3000)], dari: DateTime(2026, 11, 1), sampai: DateTime(2026, 11, 30));
      expect(h.entri.length, 1);
      expect(h.totalNilai, 30000);
      expect(h.perBahan.single.$3, 10);
      expect(h.perBahan.single.$4, 30000);
    });
  });

  Widget bungkus(Widget anak) => MaterialApp(theme: buildTheme(), home: anak);

  /// Layar yang merupakan HALAMAN di dalam cangkang (bukan
  /// Scaffold sendiri) wajib dibungkus Scaffold di tes, sama
  /// seperti di aplikasi — kalau tidak, InkWell/TextField
  /// kehilangan leluhur Material.
  Widget bungkusHalaman(Widget anak) => MaterialApp(theme: buildTheme(), home: Scaffold(body: anak));
  Finder diSheet(Finder f) => find.descendant(of: find.byType(BottomSheet), matching: f);

  /// Seret ListView ke atas sampai [target] terbangun (daftar
  /// malas tidak membangun isi di bawah lipatan layar).
  Future<void> seretSampai(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
  }

  group('layar laporan baru', () {
    testWidgets('Neraca tampil seimbang dengan rincian persediaan', (tester) async {
      await tester.pumpWidget(bungkus(NeracaScreen(
        transactions: [_tx('A-1', 500000, DateTime(2026, 11, 16)), _tx('A-2', 300000, DateTime(2026, 11, 16), method: 'QRIS')],
        menus: [_menu()],
        ingredients: [_bahan(stok: 50, harga: 3000)],
        expenses: [Pengeluaran(tanggal: DateTime(2026, 11, 16), kategori: 'Sewa', jumlah: 50000, branchId: 'utama')],
        hutang: [Hutang(tanggal: DateTime(2026, 11, 16), kreditur: 'A', jumlah: 200000, branchId: 'utama')],
        branchId: 'utama',
        branchName: 'Cabang Utama',
      )));
      await tester.pump();
      expect(find.text('Rp900.000'), findsWidgets);
      expect(find.textContaining('SEIMBANG'), findsOneWidget);
      expect(find.text('Kas Tunai'), findsOneWidget);
      await seretSampai(tester, find.text('Alpukat'));
      expect(find.text('Alpukat'), findsOneWidget);
      await seretSampai(tester, find.text('Modal Pemilik'));
      expect(find.text('Modal Pemilik'), findsOneWidget);
    });

    testWidgets('Arus Kas tampil dengan saldo akhir', (tester) async {
      await tester.pumpWidget(bungkus(ArusKasScreen(
        transactions: [_tx('A-1', 200000, DateTime.now())],
        expenses: const [],
        mutasi: const [],
        ingredients: const [],
        hutang: const [],
        branchId: 'utama',
        branchName: 'Cabang Utama',
      )));
      await tester.pump();
      expect(find.text('Uang Masuk'), findsOneWidget);
      expect(find.text('Rp200.000'), findsWidgets);
      await seretSampai(tester, find.text('Saldo Akhir Periode'));
      expect(find.text('Saldo Akhir Periode'), findsOneWidget);
    });

    testWidgets('Persediaan: saring Habis menyisakan bahan habis saja', (tester) async {
      await tester.pumpWidget(bungkus(PersediaanScreen(ingredients: [
        _bahan(id: 'b1', nama: 'Alpukat', stok: 50, harga: 3000),
        _bahan(id: 'b2', nama: 'Susu', stok: 0, harga: 20000),
      ])));
      await tester.pump();
      expect(find.text('Rp150.000'), findsWidgets);
      expect(find.text('Habis'), findsOneWidget);
      await tester.tap(find.text('Habis (1)'));
      await tester.pump();
      expect(find.text('Susu'), findsOneWidget);
      expect(find.text('Alpukat'), findsNothing);
    });

    testWidgets('Arus Stok & Pembelian tampil dari mutasi yang sama', (tester) async {
      final mutasi = [
        MutasiStok(ingredientId: 'b1', namaBahan: 'Alpukat', jenis: 'masuk', jumlah: 10, stokSesudah: 60, satuan: 'kg', waktu: DateTime.now()),
      ];
      await tester.pumpWidget(bungkus(ArusStokScreen(mutasi: mutasi)));
      await tester.pump();
      expect(find.text('Alpukat'), findsOneWidget);
      await tester.pumpWidget(bungkus(PembelianScreen(mutasi: mutasi, ingredients: [_bahan(harga: 3000)])));
      await tester.pump();
      expect(find.text('Rp30.000'), findsWidgets);
      expect(find.text('Rekap per Bahan'), findsOneWidget);
    });
  });

  group('HutangScreen', () {
    testWidgets('lunasi lewat dialog mengubah status jadi lunas bertanggal', (tester) async {
      Hutang? sunting;
      await tester.pumpWidget(bungkus(HutangScreen(
        hutang: [Hutang(id: 'h1', tanggal: DateTime(2026, 11, 1), kreditur: 'Toko Makmur', jumlah: 200000, branchId: 'utama')],
        branchId: 'utama',
        branchName: 'Cabang Utama',
        onAdd: (_) {},
        onEdit: (h) => sunting = h,
        onDelete: (_) {},
      )));
      await tester.pump();
      expect(find.text('Toko Makmur'), findsOneWidget);
      expect(find.text('Rp200.000'), findsWidgets);
      await tester.tap(find.text('Lunasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Lunas'));
      await tester.pumpAndSettle();
      expect(sunting?.lunas, isTrue);
      expect(sunting?.tanggalLunas, isNotNull);
    });

    testWidgets('catat hutang baru lewat formulir', (tester) async {
      Hutang? tambah;
      await tester.pumpWidget(bungkus(HutangScreen(
        hutang: const [],
        branchId: 'utama',
        branchName: 'Cabang Utama',
        onAdd: (h) => tambah = h,
        onEdit: (_) {},
        onDelete: (_) {},
      )));
      await tester.pump();
      await tester.tap(find.text('Catat Hutang'));
      await tester.pumpAndSettle();
      final kolom = diSheet(find.byType(TextField));
      await tester.enterText(kolom.at(0), 'Pemasok A');
      await tester.enterText(kolom.at(1), '150000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Hutang'));
      await tester.pumpAndSettle();
      expect(tambah?.kreditur, 'Pemasok A');
      expect(tambah?.jumlah, 150000);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('formulir menolak pemberi hutang kosong', (tester) async {
      await tester.pumpWidget(bungkus(HutangScreen(
        hutang: const [],
        branchId: 'utama',
        branchName: 'Cabang Utama',
        onAdd: (_) {},
        onEdit: (_) {},
        onDelete: (_) {},
      )));
      await tester.pump();
      await tester.tap(find.text('Catat Hutang'));
      await tester.pumpAndSettle();
      await tester.enterText(diSheet(find.byType(TextField)).at(1), '50000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Hutang'));
      await tester.pumpAndSettle();
      expect(find.text('Nama pemberi hutang wajib diisi.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  group('PromoScreen', () {
    testWidgets('saklar aktif + pemakaian + buat promo baru', (tester) async {
      Promo? sunting;
      Promo? tambah;
      await tester.pumpWidget(bungkus(PromoScreen(
        promos: [Promo(id: 'p1', nama: 'Promo Uji', jenis: 'persen', nilai: 10)],
        transactions: [_tx('A-1', 27000, DateTime(2026, 11, 16), diskon: 3000, promoNama: 'Promo Uji')],
        onAdd: (p) => tambah = p,
        onEdit: (p) => sunting = p,
        onDelete: (_) {},
      )));
      await tester.pump();
      expect(find.text('Rp3.000'), findsWidgets);
      expect(find.text('1 transaksi'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(sunting?.aktif, isFalse);
      await tester.tap(find.text('Buat Promo'));
      await tester.pumpAndSettle();
      final kolom = diSheet(find.byType(TextField));
      await tester.enterText(kolom.at(0), 'Promo Baru');
      await tester.enterText(kolom.at(1), '25');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Promo'));
      await tester.pumpAndSettle();
      expect(tambah?.nama, 'Promo Baru');
      expect(tambah?.jenis, 'persen');
      expect(tambah?.nilai, 25);
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  group('LaporanScreen tanpa Segera', () {
    testWidgets('semua baris hidup; ketuk Neraca memanggil callback', (tester) async {
      var neracaDibuka = false;
      await tester.pumpWidget(bungkusHalaman(LaporanScreen(
        transactions: const [],
        branchId: 'utama',
        tables: const [],
        onOpenRiwayat: () {},
        onOpenBulanan: () {},
        onOpenPajak: () {},
        onOpenPiutang: () {},
        onOpenLabaRugi: () {},
        onOpenNeraca: () => neracaDibuka = true,
        onOpenArusKas: () {},
        onOpenArusStok: () {},
        onOpenPersediaan: () {},
        onOpenPembelian: () {},
        onOpenHutang: () {},
        onOpenPromo: () {},
      )));
      await tester.pump();
      expect(find.text('Segera'), findsNothing);
      await tester.scrollUntilVisible(find.text('Neraca'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Neraca'));
      await tester.pump();
      expect(neracaDibuka, isTrue);
    });
  });

  group('Promo di kasir (ujung ke ujung)', () {
    testWidgets('pilih promo → total berkurang → tercatat di checkout', (tester) async {
      Promo? promoCheckout;
      String? metodeCheckout;
      await tester.pumpWidget(bungkusHalaman(KasirScreen(
        cart: [CartItem(menu: _menu(), variant: 'Reguler', qty: 2, unitPrice: 15000)],
        menus: [_menu()],
        selectedTable: null,
        tables: const [],
        servicePercent: 0,
        taxPercent: 0,
        tablesEnabled: false,
        kitchenEnabled: false,
        onSelectTable: (_) {},
        onAdd: (_, _, _, _) {},
        onInc: (_) {},
        onDec: (_) {},
        onRemove: (_) {},
        onCheckout: (m, t, o, p) {
          metodeCheckout = m;
          promoCheckout = p;
        },
        promos: [Promo(id: 'p1', nama: 'Promo Uji', jenis: 'persen', nilai: 10)],
      )));
      await tester.pump();
      await tester.tap(find.text('Lihat Keranjang'));
      await tester.pumpAndSettle();
      expect(diSheet(find.text('Pakai Promo')), findsOneWidget);
      await tester.tap(diSheet(find.text('Pakai Promo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Promo Uji'));
      await tester.pumpAndSettle();
      expect(diSheet(find.text('Diskon promo')), findsOneWidget);
      expect(diSheet(find.text('-Rp3.000')), findsOneWidget);
      await tester.tap(diSheet(find.text('Bayar Sekarang')));
      await tester.pumpAndSettle();
      expect(find.text('Diskon · Promo Uji'), findsOneWidget);
      await seretSampai(tester, find.text('Uang pas'));
      await tester.tap(find.text('Uang pas'));
      await tester.pump();
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      expect(metodeCheckout, 'Tunai');
      expect(promoCheckout?.nama, 'Promo Uji');
      expect(find.text('Pembayaran Berhasil'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  group('Gerbang PIN berlogo', () {
    testWidgets('logo aplikasi tampil sebagai gambar di gerbang PIN', (tester) async {
      await tester.pumpWidget(bungkus(Scaffold(body: PinGateScreen(pinHash: 'x', businessName: 'Avoera', onUnlock: () {}))));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
