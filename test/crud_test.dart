import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/kelola_menu_screen.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bukti CRUD ujung ke ujung: menu yang ditambah dari Kelola Menu harus
// (1) tampil di daftar kelola, (2) tersimpan permanen di LocalStore,
// (3) tampil di grid kasir dan bisa dijual.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

  testWidgets('Tambah menu → tersimpan → tampil di kasir', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengaturan').last);
    await tester.pumpAndSettle();
    // Daftar Pengaturan makin panjang — gulir ke baris Kelola Menu.
    await tester.scrollUntilVisible(find.text('Kelola Menu'), 120,
        scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byType(Scrollable)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kelola Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kelola Menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Menu'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'Es Kopi Uji');
    await tester.enterText(fields.at(1), '21000');
    await tester.tap(find.text('Simpan Menu'));
    await tester.pumpAndSettle();
    // Menu baru ada di urutan terakhir — gulir daftar kelola sampai terlihat.
    await tester.scrollUntilVisible(
      find.text('Es Kopi Uji'),
      120,
      scrollable: find.descendant(of: find.byType(KelolaMenuScreen), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Es Kopi Uji'), findsOneWidget, reason: 'Menu baru tampil di daftar kelola');

    final loaded = await LocalStore.load();
    expect(
      loaded.menus.any((m) => m.name == 'Es Kopi Uji' && m.price == 21000),
      isTrue,
      reason: 'Menu baru tersimpan permanen',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kasir').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Es Kopi Uji'),
      120,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Es Kopi Uji'), findsOneWidget, reason: 'Menu baru tampil di kasir');
  });
}
