// Tes v0.24.0 (pilihan Adnan 2026-11-21: bangun Hapus Cabang):
// penanda hapus tersimpan & tersinkron, pemulih cabang yatim
// menghormati penanda, dialog konfirmasi jujur, dan alur
// hapus dari Pengaturan bekerja ujung ke ujung.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/store.dart';
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

  test('AppSettings: penanda cabang terhapus pulang-pergi JSON; data lama aman', () {
    final s = AppSettings(cabangTerhapus: ['c9', 'c12']);
    final balik = AppSettings.fromJson(s.toJson());
    expect(balik.cabangTerhapus, ['c9', 'c12']);
    final lama = AppSettings.fromJson({'businessName': 'X'});
    expect(lama.cabangTerhapus, isEmpty);
  });

  test('pulihkanCabangYatim: cabang berpenanda hapus TIDAK dipulihkan, yang lain tetap', () {
    final tx = [
      TxRecord(id: 'A-1', total: 1000, method: 'Tunai', at: DateTime(2026, 11, 20), items: 1, branchId: 'c-hapus'),
      TxRecord(id: 'A-2', total: 2000, method: 'Tunai', at: DateTime(2026, 11, 20), items: 1, branchId: 'c-yatim'),
    ];
    final hasil = pulihkanCabangYatim([Branch(id: 'c1', name: 'Utama')], tx, terhapus: {'c-hapus'});
    expect(hasil.map((b) => b.id), ['c1', 'c-yatim']);
  });

  testWidgets('dialog hapus cabang: Batal → false, Hapus Cabang → true', (tester) async {
    bool? hasil;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              hasil = await showHapusCabangDialog(ctx, cabang: Branch(id: 'c2', name: 'Cabang Kedua'));
            },
            child: const Text('Buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Cabang?'), findsOneWidget);
    expect(find.textContaining('Transaksinya TIDAK ikut terhapus'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(hasil, isFalse);
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Cabang'));
    await tester.pumpAndSettle();
    expect(hasil, isTrue);
  });

  testWidgets('ujung ke ujung: hapus cabang tidak aktif dari Pengaturan → daftar & penanda tersimpan', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = AppSettings(
      branches: [Branch(id: 'c1', name: 'Cabang Utama'), Branch(id: 'c2', name: 'Cabang Kedua')],
      activeBranchId: 'c1',
    );
    s.onboarded = true;
    await LocalStore.saveSettings(s);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaturan').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cabang Kedua'),
      200,
      scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    // Hanya cabang tidak aktif yang punya tombol hapus.
    expect(find.byTooltip('Hapus cabang'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus cabang'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Cabang?'), findsOneWidget);
    await tester.tap(find.text('Hapus Cabang'));
    await tester.pumpAndSettle();
    expect(find.text('Cabang Kedua'), findsNothing);
    final data = await LocalStore.load();
    expect(data.settings.branches.map((b) => b.id), ['c1']);
    expect(data.settings.cabangTerhapus, ['c2']);
    await tester.pump(const Duration(seconds: 30));
  });
}
