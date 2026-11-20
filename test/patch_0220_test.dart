// Tes v0.22.0 (permintaan Adnan 2026-11-20: SEMUA data harus
// tersimpan di lokal DAN awan + kejadian cabang di HP lain):
// 1) DataEkstra (meja, promo, pengeluaran, hutang, mutasi,
//    sesi, dapur, desain struk, draf keranjang) pulang-pergi
//    JSON tanpa hilang.
// 2) gabungEkstra: gabung per id (server menang), hantu
//    dibuang, barang baru perangkat lain dipertahankan, benda
//    tunggal mengikuti bendera kotor, mutasi terbaru di depan.
// 3) Gerbang sinkron wizard: sinkron yang mendarat saat
//    tombol selesai ditekan mengubah wizard ke mode pilih —
//    wizard TIDAK selesai sebelum pengguna memilih cabang.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/onboarding_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/struk.dart';
import 'package:avoera_pos/sync.dart';
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

  DataEkstra contohPenuh() => DataEkstra(
        tables: [CafeTable(number: 3, capacity: 4, status: TableStatus.terisi, guestName: 'Rina', openAmount: 56000, since: '12:05')],
        promos: [Promo(id: 'pr1', nama: 'Hemat Siang', jenis: 'persen', nilai: 10, minBelanja: 50000)],
        expenses: [Pengeluaran(id: 'p1', tanggal: DateTime(2026, 11, 20), kategori: 'Sewa', jumlah: 1100000)],
        hutang: [Hutang(id: 'h1', tanggal: DateTime(2026, 11, 1), kreditur: 'Toko Beras Makmur', jumlah: 850000)],
        mutasi: [MutasiStok(id: 'm1', ingredientId: 'b1', namaBahan: 'Biji Kopi', jenis: 'masuk', jumlah: 5, stokSesudah: 12, satuan: 'kg', waktu: DateTime(2026, 11, 20, 9))],
        sesi: [SesiKasir(id: 's1', branchId: 'c1', dibukaPada: DateTime(2026, 11, 20, 8), modalAwal: 200000, namaKasir: 'Adnan')],
        dapur: [
          KitchenOrder(id: 'A-1043', tableLabel: 'Meja 3', lines: const [KitchenOrderLine('Kopi Susu', 2)], status: KitchenStatus.dimasak, time: '12:06'),
        ],
        struk: DesainStruk(lebarKertas: 80, teksFooter: 'Makasih!'),
        draft: DraftKasir(items: [BarisKeranjang(menuId: 'm1', variant: 'Besar', qty: 2, unitPrice: 18000)], nomorMeja: 3, counter: 1044, jenis: 'Dine-in', promoId: 'pr1'),
      );

  test('DataEkstra pulang-pergi JSON utuh', () {
    final asal = contohPenuh();
    final hasil = DataEkstra.fromJson(asal.toJson());
    expect(hasil.tables.single.number, 3);
    expect(hasil.tables.single.guestName, 'Rina');
    expect(hasil.promos.single.nama, 'Hemat Siang');
    expect(hasil.expenses.single.jumlah, 1100000);
    expect(hasil.hutang.single.kreditur, 'Toko Beras Makmur');
    expect(hasil.mutasi.single.jenis, 'masuk');
    expect(hasil.sesi.single.namaKasir, 'Adnan');
    expect(hasil.dapur.single.status, KitchenStatus.dimasak);
    expect(hasil.struk!.lebarKertas, 80);
    expect(hasil.struk!.teksFooter, 'Makasih!');
    expect(hasil.draft!.items.single.qty, 2);
    expect(hasil.draft!.nomorMeja, 3);
    expect(hasil.jumlah, 7);
    // JSON rusak/sebagian tidak meledak.
    final sebagian = DataEkstra.fromJson({'promos': 'bukan-daftar', 'struk': 42});
    expect(sebagian.promos, isEmpty);
    expect(sebagian.struk, isNull);
  });

  test('gabungEkstra: gabung per id, server menang, hantu dibuang, yang baru dipertahankan', () {
    final lokal = DataEkstra(
      promos: [Promo(id: 'pr1', nama: 'Promo Lokal', jenis: 'persen', nilai: 10)],
      hutang: [Hutang(id: 'h-lokal', tanggal: DateTime(2026, 11, 1), kreditur: 'Lokal', jumlah: 1000)],
    );
    final server = DataEkstra(
      promos: [
        Promo(id: 'pr1', nama: 'Promo Server', jenis: 'persen', nilai: 25),
        Promo(id: 'pr2', nama: 'Promo Perangkat Lain', jenis: 'nominal', nilai: 5000),
      ],
      hutang: [
        Hutang(id: 'h-hantu', tanggal: DateTime(2026, 10, 1), kreditur: 'Sudah Dihapus', jumlah: 2000),
        Hutang(id: 'h-baru', tanggal: DateTime(2026, 11, 19), kreditur: 'Baru Dari HP Lain', jumlah: 3000),
      ],
    );
    final gab = gabungEkstra(
      lokal: lokal,
      server: server,
      dikenal: {
        'x:hutang': {'h-hantu', 'h-lokal'},
      },
      strukKotor: false,
      draftKotor: false,
    );
    // Id sama → versi server menang; id server baru ikut masuk.
    expect(gab.promos.map((p) => p.id), containsAll(['pr1', 'pr2']));
    expect(gab.promos.firstWhere((p) => p.id == 'pr1').nilai, 25);
    // h-hantu: dikenal + tidak lokal → dibuang walau server punya.
    // h-baru: tidak dikenal → dipertahankan (barang perangkat lain).
    expect(gab.hutang.map((h) => h.id), containsAll(['h-lokal', 'h-baru']));
    expect(gab.hutang.map((h) => h.id), isNot(contains('h-hantu')));
    final dikenal = dikenalEkstra(gab);
    expect(dikenal['x:promos'], {'pr1', 'pr2'});
    expect(dikenal['x:hutang'], {'h-lokal', 'h-baru'});
  });

  test('gabungEkstra: benda tunggal mengikuti bendera kotor + mutasi terbaru di depan', () {
    final lokal = DataEkstra(
      struk: DesainStruk(lebarKertas: 58),
      draft: DraftKasir(counter: 2000),
      mutasi: [MutasiStok(id: 'm-lama', ingredientId: 'b1', namaBahan: 'Kopi', jenis: 'masuk', jumlah: 1, stokSesudah: 1, satuan: 'kg', waktu: DateTime(2026, 11, 19))],
    );
    final server = DataEkstra(
      struk: DesainStruk(lebarKertas: 80),
      draft: DraftKasir(counter: 3000),
      mutasi: [MutasiStok(id: 'm-baru', ingredientId: 'b1', namaBahan: 'Kopi', jenis: 'jual', jumlah: -1, stokSesudah: 0, satuan: 'kg', waktu: DateTime(2026, 11, 20))],
    );
    final kotor = gabungEkstra(lokal: lokal, server: server, dikenal: const {}, strukKotor: true, draftKotor: true);
    expect(kotor.struk!.lebarKertas, 58, reason: 'lokal kotor → desain lokal menang');
    expect(kotor.draft!.counter, 2000, reason: 'lokal kotor → draf lokal menang');
    expect(kotor.mutasi.map((m) => m.id), ['m-baru', 'm-lama'], reason: 'mutasi gabungan terbaru di depan');
    final bersih = gabungEkstra(lokal: lokal, server: server, dikenal: const {}, strukKotor: false, draftKotor: false);
    expect(bersih.struk!.lebarKertas, 80, reason: 'lokal bersih → desain server masuk');
    expect(bersih.draft!.counter, 3000, reason: 'lokal bersih → draf server masuk');
  });

  testWidgets('gerbang wizard: cabang ketemu saat selesai → wizard beralih ke mode pilih, bukan selesai', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final s = AppSettings(businessName: 'Avorea Cafe & Resto');
    AppSettings? hasil;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingFlow(
        initial: s,
        onDone: (x) => hasil = x,
        // Mensimulasikan sinkron yang mendarat: daftar cabang
        // pada objek pengaturan yang sama bertambah.
        sebelumSelesai: () async {
          s.branches = [
            Branch(id: 'c1', name: 'Cabang Utama'),
            Branch(id: 'c1794705028468', name: 'Cabang 2'),
          ];
        },
      ),
    ));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Nama Cabang Pertama'), findsOneWidget);
    final kolom = find.byType(TextField);
    await tester.enterText(kolom.at(1), 'Cabang Ketikanku');
    await tester.enterText(kolom.at(2), '1234');
    await tester.enterText(kolom.at(3), '1234');
    await tester.ensureVisible(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
    // Wizard TIDAK selesai: beralih ke mode pilih + penjelasan.
    expect(hasil, isNull);
    expect(find.text('Cabang Lamamu Ketemu'), findsOneWidget);
    expect(find.textContaining('pilih cabang untuk perangkat ini dulu'), findsOneWidget);
    // Pilih cabang ke-2 lalu selesai — daftar tetap utuh.
    await tester.tap(find.text('Cabang 2'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
    expect(hasil, isNotNull);
    expect(hasil!.branches.length, 2);
    expect(hasil!.branches.map((b) => b.name), ['Cabang Utama', 'Cabang 2']);
    expect(hasil!.activeBranchId, 'c1794705028468');
  });

  testWidgets('data ekstra lokal tidak hilang saat aplikasi dibuka (sinkron gagal di tes)', (tester) async {
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    await LocalStore.savePromos([Promo(id: 'pr-bertahan', nama: 'Promo Bertahan', jenis: 'persen', nilai: 15)]);
    await LocalStore.saveExpenses([Pengeluaran(id: 'p-bertahan', tanggal: DateTime(2026, 11, 20), kategori: 'Sewa', jumlah: 500000)]);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    final data = await LocalStore.load();
    expect(data.promos.map((p) => p.id), contains('pr-bertahan'));
    expect(data.expenses.map((e) => e.id), contains('p-bertahan'));
    await tester.pump(const Duration(seconds: 30));
  });
}
