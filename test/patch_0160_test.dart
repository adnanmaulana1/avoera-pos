// Tes v0.16.0 (diminta Adnan 2026-11-17): keranjang & pesanan
// dapur TERSIMPAN — aplikasi tertutup paksa / dibuka ulang,
// pesanan yang belum dibayar dan antrean dapur tidak hilang.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pembayaran_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/widgets.dart';
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
  });

  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

  group('model & penyimpanan', () {
    test('KitchenOrder JSON pulang-pergi utuh', () {
      final asli = KitchenOrder(
        id: 'A-2001',
        tableLabel: 'Meja 4',
        lines: const [KitchenOrderLine('Caffe Latte', 2, 'Less sugar'), KitchenOrderLine('Kentang Goreng', 1)],
        status: KitchenStatus.dimasak,
        time: '19:42',
        orderType: 'Takeaway',
      );
      final pulih = KitchenOrder.fromJson(asli.toJson());
      expect(pulih.id, 'A-2001');
      expect(pulih.tableLabel, 'Meja 4');
      expect(pulih.status, KitchenStatus.dimasak);
      expect(pulih.orderType, 'Takeaway');
      expect(pulih.lines.length, 2);
      expect(pulih.lines.first.name, 'Caffe Latte');
      expect(pulih.lines.first.qty, 2);
      expect(pulih.lines.first.note, 'Less sugar');
    });

    test('DraftKasir JSON pulang-pergi utuh', () {
      final asli = DraftKasir(
        items: const [BarisKeranjang(menuId: 'k1', variant: 'Besar · Less sugar', note: 'Tanpa es', qty: 3, unitPrice: 22000)],
        nomorMeja: 7,
        counter: 2000,
        jenis: 'Bungkus',
        promoId: 'pr9',
      );
      final pulih = DraftKasir.fromJson(asli.toJson());
      expect(pulih.items.single.menuId, 'k1');
      expect(pulih.items.single.qty, 3);
      expect(pulih.items.single.unitPrice, 22000);
      expect(pulih.nomorMeja, 7);
      expect(pulih.counter, 2000);
      expect(pulih.jenis, 'Bungkus');
      expect(pulih.promoId, 'pr9');
    });

    test('LocalStore: dapur & draf kasir tersimpan lalu terbaca lagi', () async {
      await LocalStore.saveDapur([
        KitchenOrder(id: 'A-9', tableLabel: 'Bungkus', lines: const [KitchenOrderLine('Americano', 1)], status: KitchenStatus.baru, time: '08:00', orderType: 'Takeaway'),
      ]);
      await LocalStore.saveDraftKasir(DraftKasir(
        items: const [BarisKeranjang(menuId: 'k3', variant: 'Reguler', qty: 1, unitPrice: 15000)],
        counter: 1050,
      ));
      final data = await LocalStore.load();
      expect(data.dapur.single.id, 'A-9');
      expect(data.dapur.single.lines.single.name, 'Americano');
      final draf = await LocalStore.loadDraftKasir();
      expect(draf.items.single.menuId, 'k3');
      expect(draf.counter, 1050);
    });
  });

  group('pulih sesudah aplikasi dibuka ulang', () {
    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const KasirFnbApp());
      await tester.pumpAndSettle();
    }

    Future<void> keKasir(WidgetTester tester) async {
      await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Kasir')));
      await tester.pumpAndSettle();
    }

    Future<void> tambahMenu(WidgetTester tester, String namaMenu) async {
      final grid = find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable));
      // Menu incaran bisa berada DI ATAS posisi gulir sekarang
      // (grid tertinggal di bawah sesudah belanja sebelumnya) —
      // scrollUntilVisible hanya mencari ke bawah, jadi tarik
      // grid kembali ke puncak dulu.
      for (var i = 0; i < 3; i++) {
        await tester.drag(grid, const Offset(0, 600));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        find.text(namaMenu),
        120,
        scrollable: grid,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(namaMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Tambah ·'));
      await tester.pumpAndSettle();
    }

    testWidgets('keranjang belum dibayar + tiket dapur selamat dari buka ulang', (tester) async {
      await pumpApp(tester);
      await keKasir(tester);
      // Pesanan pertama: dibayar → jadi tiket dapur.
      await tambahMenu(tester, 'Caffe Latte');
      await tester.tap(find.text('Lihat Keranjang'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Bayar Sekarang')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Uang pas'), 150, scrollable: find.descendant(of: find.byType(PembayaranScreen), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uang pas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('Pembayaran Berhasil'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      // Pesanan kedua: masuk keranjang, SENGAJA belum dibayar.
      await tambahMenu(tester, 'Kopi Susu Gula Aren');
      expect(find.text('1 item'), findsOneWidget);

      // === Aplikasi dibuka ulang (pohon widget baru, simpanan sama) ===
      await tester.pumpWidget(const KasirFnbApp());
      await tester.pumpAndSettle();
      await keKasir(tester);
      expect(find.text('1 item'), findsOneWidget, reason: 'Keranjang belum dibayar harus selamat dari buka ulang');
      await tester.tap(find.text('Lihat Keranjang'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Kopi Susu Gula Aren')), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      // Tiket dapur dari pesanan pertama juga selamat.
      await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Dapur')));
      await tester.pumpAndSettle();
      expect(find.text('Caffe Latte'), findsWidgets, reason: 'Tiket dapur harus selamat dari buka ulang');
      // Majukan statusnya, lalu buka ulang lagi: status ikut selamat.
      await tester.tap(find.text('Mulai Masak').first);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const KasirFnbApp());
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Dapur')));
      await tester.pumpAndSettle();
      expect(find.text('Caffe Latte'), findsWidgets);
      expect(find.text('Tandai Selesai'), findsWidgets, reason: 'Status Dimasak harus tersimpan, bukan kembali ke Baru');
      // Siram timer milik cangkang.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('draf berisi menu hantu: baris hantu dibuang, jenis Bungkus pulih', (tester) async {
      await LocalStore.saveDraftKasir(DraftKasir(
        items: const [
          BarisKeranjang(menuId: 'k1', variant: 'Reguler', qty: 2, unitPrice: 18000),
          BarisKeranjang(menuId: 'menu-sudah-dihapus', variant: 'Reguler', qty: 5, unitPrice: 99000),
        ],
        jenis: 'Bungkus',
        counter: 2000,
      ));
      await pumpApp(tester);
      await keKasir(tester);
      expect(find.text('2 item'), findsOneWidget, reason: 'Hanya 2 item dari menu asli; 5 item hantu harus dibuang');
      final seg = tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
      expect(seg.selected, {'Bungkus'}, reason: 'Jenis pesanan tersimpan harus pulih');
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
