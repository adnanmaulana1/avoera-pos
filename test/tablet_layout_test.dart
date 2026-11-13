import 'package:avoera_pos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Cek tampilan tablet: semua layar dibuka di ukuran landscape & portrait,
// tidak boleh ada overflow / error tata letak.
void main() {
  Future<void> checkAllScreens(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Kasir di $size');

    for (final label in ['Meja', 'Dapur', 'Laporan', 'Stok Bahan', 'Pengaturan', 'Kasir']) {
      await tester.tap(find.text(label).last);
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
