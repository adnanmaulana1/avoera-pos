// Tes v0.19.0 (kejadian cabang hilang 2026-11-17): pemulihan
// cabang yatim dari transaksi + sheet ubah cabang + alur penuh
// ubah nama cabang dari Pengaturan. Pembersih hantu khusus
// cabang dimatikan di sync.dart (perubahan satu baris, tidak
// bisa diuji tanpa server — logika pemulihannya yang diuji di sini).
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/branch_wizard_screen.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
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
    final lucide = FontLoader('Lucide');
    lucide.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/Lucide.ttf').readAsBytes()).buffer)));
    await lucide.load();
  });

  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

  TxRecord tx(String branchId) => TxRecord(id: 'A-1', total: 10000, method: 'Tunai', at: DateTime(2026, 11, 17), items: 1, branchId: branchId);

  group('pulihkanCabangYatim', () {
    test('transaksi yatim → cabang dibuatkan lagi dengan id yang sama', () {
      final hasil = pulihkanCabangYatim([Branch(id: 'c1', name: 'Cabang Utama')], [tx('c1794705028468')]);
      expect(hasil.length, 2);
      expect(hasil.last.id, 'c1794705028468');
      expect(hasil.last.name, 'Cabang (dipulihkan)');
    });

    test('branchId kosong (transaksi lama) dilewati', () {
      final hasil = pulihkanCabangYatim([Branch(id: 'c1', name: 'Cabang Utama')], [tx('')]);
      expect(hasil.length, 1);
    });

    test('cabang yang sudah ada tidak diduplikat; dua transaksi yatim seid → satu cabang', () {
      final hasil = pulihkanCabangYatim(
        [Branch(id: 'c1', name: 'Cabang Utama')],
        [tx('c1'), tx('c2'), tx('c2')],
      );
      expect(hasil.map((b) => b.id), ['c1', 'c2']);
    });
  });

  group('sheet Ubah Cabang', () {
    Finder inSheet(Finder inner) => find.descendant(of: find.byType(BottomSheet), matching: inner);

    Future<Branch?> bukaDanSimpan(WidgetTester tester, {required String namaBaru}) async {
      Branch? tangkap;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showUbahCabangSheet(
                  ctx,
                  awal: Branch(id: 'c9', name: 'Cabang Lama', address: 'Jl. Kenanga', phone: '0812'),
                  onSimpan: (b) => tangkap = b,
                ),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      await tester.enterText(inSheet(find.byType(TextField)).first, namaBaru);
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      return tangkap;
    }

    testWidgets('simpan: id tetap, nama baru, alamat & telepon ikut', (tester) async {
      final hasil = await bukaDanSimpan(tester, namaBaru: 'Cabang Baru');
      expect(hasil, isNotNull);
      expect(hasil!.id, 'c9');
      expect(hasil.name, 'Cabang Baru');
      expect(hasil.address, 'Jl. Kenanga');
      expect(hasil.phone, '0812');
    });

    testWidgets('nama dikosongkan → galat, tidak menyimpan', (tester) async {
      final hasil = await bukaDanSimpan(tester, namaBaru: '   ');
      expect(hasil, isNull);
      expect(find.text('Nama cabang belum diisi.'), findsOneWidget);
    });
  });

  testWidgets('aplikasi penuh: ubah nama cabang dari Pengaturan tersimpan', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaturan').last);
    await tester.pumpAndSettle();
    expect(find.byType(PengaturanScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Ubah cabang'),
      120,
      scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Ubah cabang').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ubah cabang').first);
    await tester.pumpAndSettle();
    expect(find.text('Ubah Cabang'), findsWidgets);
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)).first, 'Cabang Pusat');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(PrimaryButton)));
    await tester.pumpAndSettle();
    // Bukti tersimpan: nama berubah, id tetap c1.
    final data = await LocalStore.load();
    expect(data.settings.branches.first.id, 'c1');
    expect(data.settings.branches.first.name, 'Cabang Pusat');
    expect(find.text('Cabang Pusat'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
