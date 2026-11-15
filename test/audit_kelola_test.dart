import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/screens/stok_screen.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:avoera_pos/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// AUDIT FUNGSI kelompok 2: Pengaturan + Kelola Data + popup info +
// bukti permanen sesudah aplikasi "dimatikan" dan dibuka lagi.
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
  });

  Finder inSheet(Finder inner) => find.descendant(of: find.byType(BottomSheet), matching: inner);

  Future<void> pumpWide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Aplikasi membuka di Beranda — tes-tes ini mulai dari Kasir.
    await tester.tap(find.widgetWithText(ListTile, 'Kasir'));
    await tester.pumpAndSettle();
  }

  Future<void> kePengaturan(WidgetTester tester) async {
    await tester.tap(find.text('Pengaturan').last);
    await tester.pumpAndSettle();
  }

  /// Baris Kelola kini lebih ke bawah (ada bagian Cabang & Keamanan)
  /// — gulir daftar Pengaturan sampai barisnya terbangun, lalu ketuk.
  Future<void> tapKelola(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      120,
      scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('Audit: ubah pajak di Pengaturan langsung berlaku di Kasir + tersimpan', (tester) async {
    await pumpWide(tester);
    await tester.tap(find.text('Kopi Tubruk'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambah ·'));
    await tester.pumpAndSettle();
    expect(find.text('Pajak (10%)'), findsOneWidget);

    await kePengaturan(tester);
    await tester.tap(find.text('Pajak'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '11');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('11%'), findsOneWidget, reason: 'Baris pajak harus menunjukkan 11%');

    final data = await LocalStore.load();
    expect(data.settings.taxPercent, 11, reason: 'Pajak baru harus tersimpan permanen');

    await tester.tap(find.text('Kasir').last);
    await tester.pumpAndSettle();
    expect(find.text('Pajak (11%)'), findsOneWidget, reason: 'Panel kasir harus memakai pajak baru');
  });

  testWidgets('Audit: Kelola Meja — tambah, ubah kapasitas, hapus, semua permanen', (tester) async {
    await pumpWide(tester);
    await kePengaturan(tester);
    await tapKelola(tester, 'Kelola Meja');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Meja'));
    await tester.pumpAndSettle();
    final kolom = inSheet(find.byType(TextField));
    await tester.enterText(kolom.at(1), '3');
    await tester.tap(inSheet(find.text('Simpan Meja')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Meja 13'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('Meja 13'), findsOneWidget);
    expect(find.text('3 kursi'), findsOneWidget);

    Finder baris13() => find.ancestor(of: find.text('Meja 13'), matching: find.byType(AppCard));
    Finder tombolUbah13() => find.descendant(of: baris13(), matching: find.byIcon(Icons.edit_outlined));
    // Pastikan tombol ubah terlihat PENUH — kalau cuma sepotong, ketukan
    // bisa mendarat di kartu/bar bawah dan membuka sheet yang salah.
    await tester.ensureVisible(tombolUbah13());
    await tester.pumpAndSettle();
    await tester.tap(tombolUbah13());
    await tester.pumpAndSettle();
    await tester.enterText(inSheet(find.byType(TextField)).at(1), '6');
    await tester.ensureVisible(inSheet(find.text('Simpan Perubahan')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Simpan Perubahan')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: baris13(), matching: find.text('6 kursi')), findsOneWidget, reason: 'Kapasitas harus berubah jadi 6');

    var data = await LocalStore.load();
    expect(data.tables.where((t) => t.number == 13 && t.capacity == 6).length, 1, reason: 'Meja 13 tersimpan dengan kapasitas 6');

    await tester.ensureVisible(tombolUbah13());
    await tester.pumpAndSettle();
    await tester.tap(tombolUbah13());
    await tester.pumpAndSettle();
    await tester.ensureVisible(inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Meja 13'), findsNothing, reason: 'Sesudah konfirmasi, meja harus hilang');
    data = await LocalStore.load();
    expect(data.tables.any((t) => t.number == 13), isFalse, reason: 'Hapus harus permanen');
    // Siram timer dispose controller (500ms) supaya tidak menggantung di akhir tes.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Audit: Kelola Stok — tambah bahan tampil di Stok + permanen', (tester) async {
    await pumpWide(tester);
    await kePengaturan(tester);
    await tapKelola(tester, 'Kelola Stok Bahan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();
    final kolom = inSheet(find.byType(TextField));
    await tester.enterText(kolom.at(0), 'Es Batu Kristal');
    await tester.enterText(kolom.at(1), '20');
    await tester.enterText(kolom.at(2), 'kg');
    await tester.enterText(kolom.at(3), '5');
    await tester.enterText(kolom.at(4), '50');
    await tester.ensureVisible(inSheet(find.text('Simpan Bahan')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Simpan Bahan')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Es Batu Kristal'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('Es Batu Kristal'), findsOneWidget);

    final data = await LocalStore.load();
    expect(data.ingredients.any((i) => i.name == 'Es Batu Kristal' && i.stock == 20), isTrue, reason: 'Bahan baru harus tersimpan');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stok Bahan').first);
    await tester.pumpAndSettle();
    // Scrollable dibatasi ke layar Stok — sidebar kini juga punya
    // gulirannya sendiri, .first bisa salah sasaran.
    await tester.scrollUntilVisible(find.text('Es Batu Kristal'), 120,
        scrollable: find.descendant(of: find.byType(StokScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)));
    expect(find.text('Es Batu Kristal'), findsOneWidget, reason: 'Bahan baru harus tampil di layar Stok');
  });

  testWidgets('Audit: Kelola Menu — ubah harga & hapus menu, permanen', (tester) async {
    await pumpWide(tester);
    await kePengaturan(tester);
    await tapKelola(tester, 'Kelola Menu');
    await tester.pumpAndSettle();

    Finder barisMenu(String nama) => find.ancestor(of: find.text(nama), matching: find.byType(AppCard));
    await tester.scrollUntilVisible(find.text('Kopi Tubruk'), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.descendant(of: barisMenu('Kopi Tubruk'), matching: find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    await tester.enterText(inSheet(find.byType(TextField)).at(1), '13500');
    await tester.ensureVisible(inSheet(find.text('Simpan Perubahan')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Simpan Perubahan')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rp13.500'), findsOneWidget, reason: 'Harga baru harus tampil di daftar');

    var data = await LocalStore.load();
    expect(data.menus.firstWhere((m) => m.name == 'Kopi Tubruk').price, 13500, reason: 'Harga baru harus tersimpan');

    await tester.scrollUntilVisible(find.text('Paket Berdua'), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.descendant(of: barisMenu('Paket Berdua'), matching: find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Paket Berdua'), findsNothing);
    data = await LocalStore.load();
    expect(data.menus.any((m) => m.name == 'Paket Berdua'), isFalse, reason: 'Hapus menu harus permanen');
    // Siram timer dispose controller (500ms) supaya tidak menggantung di akhir tes.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Audit: popup Info Aplikasi tampil & tertutup', (tester) async {
    await pumpWide(tester);
    await kePengaturan(tester);
    // Baris Info Aplikasi ada di bagian paling bawah Pengaturan.
    await tester.scrollUntilVisible(
      find.text('Info Aplikasi'),
      100,
      scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Info Aplikasi'));
    await tester.pumpAndSettle();
    expect(find.text('by Webtales Studio'), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Versi 0.9.2')), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('by Webtales Studio'), findsNothing, reason: 'Popup harus tertutup');
  });

  testWidgets('Audit: data CRUD tetap ada sesudah aplikasi dibuka ulang', (tester) async {
    await pumpWide(tester);
    await kePengaturan(tester);
    await tapKelola(tester, 'Kelola Menu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Menu'));
    await tester.pumpAndSettle();
    final kolom = inSheet(find.byType(TextField));
    await tester.enterText(kolom.at(0), 'Menu Persist Uji');
    await tester.enterText(kolom.at(1), '9000');
    await tester.ensureVisible(inSheet(find.text('Simpan Menu')));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('Simpan Menu')));
    await tester.pumpAndSettle();

    // "Matikan" aplikasi lalu buka lagi dari nol.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Buka ulang mulai dari Beranda — ke Kasir dulu.
    await tester.tap(find.widgetWithText(ListTile, 'Kasir'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Menu Persist Uji'),
      120,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    expect(find.text('Menu Persist Uji'), findsOneWidget, reason: 'Menu buatan sendiri harus selamat dari buka ulang');
  });
}
