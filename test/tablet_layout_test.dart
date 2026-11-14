import 'package:avoera_pos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cek tampilan tablet: semua layar dibuka di ukuran landscape & portrait,
// tidak boleh ada overflow / error tata letak.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Penyimpanan lokal perlu contoh kosong supaya muat data tidak menggantung.
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> checkAllScreens(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Kasir di $size');

    // Di lebar HP (<900) menu Laporan/Stok/Pengaturan ada di sidebar
    // geser — buka dulu lewat tombol Lainnya di bar bawah.
    final phoneLayout = size.width < 900;
    const drawerLabels = ['Laporan', 'Stok Bahan', 'Pengaturan'];
    for (final label in ['Meja', 'Dapur', 'Laporan', 'Stok Bahan', 'Pengaturan', 'Kasir']) {
      if (phoneLayout && drawerLabels.contains(label)) {
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Lainnya')));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text(label)));
      } else {
        await tester.tap(find.text(label).last);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label di $size');
    }
  }

  testWidgets('Tablet landscape 1280x800: semua layar tanpa overflow', (tester) async {
    await checkAllScreens(tester, const Size(1280, 800));
  });

  testWidgets('Tablet portrait 800x1280: semua layar tanpa overflow', (tester) async {
    await checkAllScreens(tester, const Size(800, 1280));
  });
}
