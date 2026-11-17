// Tes v0.17.0 (diminta Adnan 2026-11-17): CRUD kategori menu —
// daftar kategori tersimpan & bisa ditambah/diubah/dihapus;
// ubah nama diikuti semua menu; hapus memindahkan menu ke
// 'Lainnya'. Plus splash latar putih (permintaan yang sama).
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/ikon.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/kategori_screen.dart';
import 'package:avoera_pos/screens/splash_screen.dart';
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

  MenuItem menu(String id, String nama, String kategori) => MenuItem(id: id, name: nama, category: kategori, price: 10000, color: const Color(0xFF8D6E63), icon: Ikon.coffee);

  group('kategoriEfektif & pengaturan', () {
    test('daftar kosong → bawaan + kategori ekstra dari menu', () {
      final hasil = kategoriEfektif(AppSettings(), [menu('a', 'Es Kopi', 'Kopi'), menu('b', 'Puding', 'Dessert')]);
      expect(hasil, [...kategoriBawaan, 'Dessert']);
    });

    test('daftar tersimpan dipakai apa adanya + ekstra menyusul', () {
      final s = AppSettings(menuCategories: ['Minuman', 'Dessert']);
      final hasil = kategoriEfektif(s, [menu('a', 'Es Kopi', 'Kopi'), menu('b', 'Puding', 'Dessert')]);
      expect(hasil, ['Minuman', 'Dessert', 'Kopi']);
    });

    test('AppSettings JSON pulang-pergi membawa menuCategories', () {
      final pulih = AppSettings.fromJson(AppSettings(menuCategories: ['Minuman', 'Dessert']).toJson());
      expect(pulih.menuCategories, ['Minuman', 'Dessert']);
      // JSON lama tanpa kunci ini → kosong (bawaan), tidak rusak.
      expect(AppSettings.fromJson(const {}).menuCategories, isEmpty);
    });
  });

  group('layar Kelola Kategori', () {
    Widget bungkus({required List<String> ditambah, required List<List<String>> diubah, required List<String> dihapus}) {
      return MaterialApp(
        home: KategoriScreen(
          kategori: const ['Kopi', 'Makanan'],
          menus: [menu('a', 'Es Kopi', 'Kopi'), menu('b', 'Kopi Tubruk', 'Kopi'), menu('c', 'Nasi', 'Makanan')],
          onTambah: ditambah.add,
          onUbahNama: (lama, baru) => diubah.add([lama, baru]),
          onHapus: dihapus.add,
        ),
      );
    }

    testWidgets('baris kategori tampil dengan jumlah menu', (tester) async {
      await tester.pumpWidget(bungkus(ditambah: [], diubah: [], dihapus: []));
      await tester.pumpAndSettle();
      expect(find.text('Kopi'), findsOneWidget);
      expect(find.text('2 menu'), findsOneWidget);
      expect(find.text('1 menu'), findsOneWidget);
    });

    testWidgets('tambah kategori: isi nama → Simpan Kategori', (tester) async {
      final ditambah = <String>[];
      await tester.pumpWidget(bungkus(ditambah: ditambah, diubah: [], dihapus: []));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Kategori'));
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Minuman Segar');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(ditambah, ['Minuman Segar']);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('nama dobel ditolak dengan pesan galat', (tester) async {
      final ditambah = <String>[];
      await tester.pumpWidget(bungkus(ditambah: ditambah, diubah: [], dihapus: []));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Kategori'));
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'kopi');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(find.text('Kategori "kopi" sudah ada.'), findsOneWidget);
      expect(ditambah, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('ubah nama: nilai awal terisi, hasil (lama, baru) terkirim', (tester) async {
      final diubah = <List<String>>[];
      await tester.pumpWidget(bungkus(ditambah: [], diubah: diubah, dihapus: []));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ubah nama').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Kopi Robusta');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(diubah, [['Kopi', 'Kopi Robusta']]);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('hapus: dialog menjelaskan menu pindah ke Lainnya', (tester) async {
      final dihapus = <String>[];
      await tester.pumpWidget(bungkus(ditambah: [], diubah: [], dihapus: dihapus));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('dipindah ke kategori "Lainnya"'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Hapus')));
      await tester.pumpAndSettle();
      expect(dihapus, ['Kopi']);
    });
  });

  testWidgets('splash berlatar putih', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 200));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white, reason: 'Permintaan Adnan 2026-11-17: latar splash putih');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('aplikasi penuh: ubah nama kategori dari Produk → menu & chip Kasir ikut', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Produk')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Ikon.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kelola Kategori'));
    await tester.pumpAndSettle();
    expect(find.byType(KategoriScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Ubah nama').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Kopi Robusta');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(PrimaryButton)));
    await tester.pumpAndSettle();
    // Bukti tersimpan: daftar kategori + menu k1 berganti.
    final data = await LocalStore.load();
    expect(data.settings.menuCategories, contains('Kopi Robusta'));
    expect(data.settings.menuCategories, isNot(contains('Kopi')));
    expect(data.menus.firstWhere((m) => m.id == 'k1').category, 'Kopi Robusta');
    // Kembali lalu ke Kasir: chip kategori baru tampil.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BarNavigasiBawah), matching: find.text('Kasir')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(FilterChipRow), matching: find.text('Kopi Robusta')), findsOneWidget);
    expect(find.descendant(of: find.byType(FilterChipRow), matching: find.text('Kopi')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
