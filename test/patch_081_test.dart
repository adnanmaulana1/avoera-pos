import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/export.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/produk_screen.dart';
import 'package:avoera_pos/screens/riwayat_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Patch v0.8.1 lanjutan (permintaan Adnan 2026-11-14):
// 1) bukaan pertama = mode TERANG, simpanan tema tetap dihormati;
// 2) pill/chip/segmented TANPA centang + dialog Edit Harga Massal
//    memakai komponen bersama (tinggi & radius sama);
// 3) transisi halaman satu pola dari tema;
// 4) ekspor laporan WAJIB lewat layar pratinjau dulu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Font Roboto asli WAJIB dimuat: font tes bawaan lebih lebar dan
  // bikin teks meluber palsu di kartu produk & tabel pratinjau.
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
    // Huruf khas v0.12.0 ikut dimuat — tanpa ini judul/angka
    // jatuh ke font uji raksasa dan lebar teksnya mengecoh.
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  group('1. Mode terang bawaan awal', () {
    test('AppSettings segar & JSON tanpa modeTema = terang; simpanan dihormati', () {
      expect(AppSettings().modeTema, 'terang');
      expect(AppSettings.fromJson(const {}).modeTema, 'terang');
      expect(AppSettings.fromJson(const {'modeTema': 'gelap'}).modeTema, 'gelap');
      expect(AppSettings.fromJson(const {'modeTema': 'sistem'}).modeTema, 'sistem');
    });

    testWidgets('Pemasangan segar (tanpa simpanan tema) membuka TERANG', (tester) async {
      SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
      await tester.pumpWidget(const KasirFnbApp());
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light, reason: 'Tanpa simpanan tema, aplikasi wajib terang');
      expect(AppColors.gelap, isFalse);
    });

    testWidgets('Simpanan tema GELAP tetap gelap (tidak ditimpa bawaan)', (tester) async {
      SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true,"modeTema":"gelap"}'});
      await tester.pumpWidget(const KasirFnbApp());
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark, reason: 'Pilihan gelap yang tersimpan wajib dihormati');
      expect(AppColors.gelap, isTrue);
    });
  });

  group('2. Pill tanpa centang & dialog seragam', () {
    testWidgets('AppChip terpilih: showCheckmark mati, tidak ada ikon centang', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: AppChip(label: 'Semua', selected: true, onSelected: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Sejak v0.12.0 AppChip jahitan sendiri — ChoiceChip
      // bawaan tidak boleh muncul lagi, dan tetap tanpa centang.
      expect(find.byType(ChoiceChip), findsNothing, reason: 'AppChip tidak lagi memakai ChoiceChip bawaan');
      expect(find.byIcon(Icons.check), findsNothing);
    });

    Future<void> pumpProduk(WidgetTester tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
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
    }

    testWidgets('Chip kategori Produk terpilih tanpa centang', (tester) async {
      await pumpProduk(tester);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing, reason: 'Tidak boleh ada centang di chip kategori Produk');
    });

    testWidgets('Edit Harga Massal: segmented tanpa ikon terpilih, tinggi pill = kotak persen, Terapkan = PrimaryButton', (tester) async {
      await pumpProduk(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Harga Massal'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      final seg = tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>));
      expect(seg.showSelectedIcon, isFalse, reason: 'Segmented dialog tidak boleh menggambar ikon pada pilihan aktif');
      expect(find.byIcon(Icons.check), findsNothing, reason: 'Dialog tidak boleh berisi ikon centang');

      final tinggiSeg = tester.getSize(find.byType(SegmentedButton<bool>)).height;
      final kotakPersen = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      final tinggiPersen = tester.getSize(kotakPersen).height;
      expect(tinggiSeg, 48, reason: 'Tinggi segmented dikunci 48 di dialog');
      expect(tinggiPersen, tinggiSeg, reason: 'Kotak persen harus sama tinggi dengan pill arah');

      expect(find.widgetWithText(PrimaryButton, 'Terapkan'), findsOneWidget,
          reason: 'Tombol utama dialog wajib PrimaryButton bersama');
    });
  });

  group('3. Transisi halaman seragam', () {
    test('Tema memasang AvoeraPageTransitionsBuilder untuk Android', () {
      final tema = buildTheme();
      final builders = tema.pageTransitionsTheme.builders;
      expect(builders[TargetPlatform.android], isA<AvoeraPageTransitionsBuilder>());
      expect(builders[TargetPlatform.iOS], isA<AvoeraPageTransitionsBuilder>());
    });
  });

  group('4. Pratinjau sebelum ekspor', () {
    testWidgets('Tombol ekspor Riwayat membuka PRATINJAU (bukan lembar bagikan langsung)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final tx = [
        TxRecord(id: 'A-2001', total: 36800, method: 'Tunai', at: DateTime.now(), items: 2, subtotal: 32000, service: 1600, tax: 3200, branchId: 'c1'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: RiwayatScreen(transactions: tx, branchId: 'c1'),
        ),
      );
      await tester.pumpAndSettle();

      // Sebelum pratinjau: tidak ada tombol ekspor apa pun.
      expect(find.text('Bagikan PDF'), findsNothing);
      expect(find.byType(PratinjauLaporanScreen), findsNothing);

      await tester.tap(find.byType(TombolEkspor));
      await tester.pumpAndSettle();

      // Sesudah ketuk: layar pratinjau tampil membawa isi laporan
      // yang sama (judul, kepala tabel, catatan) + tombol ekspor.
      expect(find.byType(PratinjauLaporanScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing, reason: 'Tidak boleh lagi lembar bagikan langsung');
      expect(find.text('Riwayat Transaksi'), findsWidgets, reason: 'Judul laporan tampil di pratinjau');
      expect(find.text('Tanggal'), findsOneWidget, reason: 'Kepala tabel tampil di pratinjau');
      expect(find.widgetWithText(PrimaryButton, 'Bagikan PDF'), findsOneWidget);
      expect(find.text('Simpan PDF'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('Teks WA'), findsOneWidget);
    });
  });
}
