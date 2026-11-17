// Tes v0.21.0 (wizard pintar — permintaan Adnan 2026-11-18):
// onboarding menyesuaikan keadaan. Cabang lama yang ketemu
// dari awan (daftar > 1) → mode PILIH: kolom nama cabang
// hilang, yang dipilih hanya cabang aktif perangkat ini,
// daftar cabang TIDAK PERNAH ditimpa (akar kejadian nama
// cabang tertimpa 2026-11-17). Usaha baru (daftar 1) → mode
// BUAT seperti dulu. Termasuk pagar: sinkron yang mendarat di
// tengah wizard mengubah mode dan tetap tidak menimpa.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

  AppSettings duaCabang() => AppSettings(
        businessName: 'Avorea Cafe & Resto',
        branches: [
          Branch(id: 'c1', name: 'Cabang Utama'),
          Branch(id: 'c1794705028468', name: 'Cabang 2', address: 'Jl. Ahmad Yani'),
        ],
        activeBranchId: 'c1',
      );

  Future<void> bukaWizard(WidgetTester tester, AppSettings s, void Function(AppSettings) onDone) async {
    // Layar tinggi: seluruh formulir wizard muat tanpa gulir,
    // tombol selesai bisa diketuk langsung.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: OnboardingFlow(initial: s, onDone: onDone)));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai Berjualan'), findsOneWidget);
  }

  Future<void> ketukMulai(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Berjualan'));
    await tester.pumpAndSettle();
  }

  testWidgets('mode pilih: judul & daftar cabang tampil, kolom nama cabang hilang', (tester) async {
    await bukaWizard(tester, duaCabang(), (_) {});
    expect(find.text('Cabang Lamamu Ketemu'), findsOneWidget);
    expect(find.text('Nama Cabang Pertama'), findsNothing);
    expect(find.text('Cabang Utama'), findsOneWidget);
    expect(find.text('Cabang 2'), findsOneWidget);
    expect(find.text('Dipakai di perangkat ini'), findsOneWidget);
    // Hanya 3 kolom teks: nama usaha + PIN + ulangi PIN.
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('mode pilih: selesai → cabang utuh, yang berubah hanya cabang aktif', (tester) async {
    AppSettings? hasil;
    await bukaWizard(tester, duaCabang(), (s) => hasil = s);
    await tester.tap(find.text('Cabang 2'));
    await tester.pumpAndSettle();
    expect(find.text('Dipakai di perangkat ini'), findsOneWidget);
    final kolom = find.byType(TextField);
    await tester.enterText(kolom.at(1), '1234');
    await tester.enterText(kolom.at(2), '1234');
    await ketukMulai(tester);
    expect(hasil, isNotNull);
    expect(hasil!.onboarded, isTrue);
    expect(hasil!.branches.length, 2);
    expect(hasil!.branches.map((b) => b.name), ['Cabang Utama', 'Cabang 2']);
    expect(hasil!.activeBranchId, 'c1794705028468');
    expect(hasil!.pinHash, hashPin('1234'));
  });

  testWidgets('sinkron mendarat di tengah wizard → mode beralih pilih & tetap tidak menimpa', (tester) async {
    final s = AppSettings(businessName: 'Avorea Cafe & Resto');
    AppSettings? hasil;
    await bukaWizard(tester, s, (x) => hasil = x);
    expect(find.text('Nama Cabang Pertama'), findsOneWidget);
    // Sinkron tiba: daftar cabang pada objek pengaturan yang
    // sama bertambah (persis yang dilakukan shell saat hasil
    // sinkron diterapkan), lalu pohon dibangun ulang.
    s.branches = [
      Branch(id: 'c1', name: 'Cabang Utama'),
      Branch(id: 'c1794705028468', name: 'Cabang 2'),
    ];
    await tester.pumpWidget(MaterialApp(home: OnboardingFlow(initial: s, onDone: (x) => hasil = x)));
    await tester.pumpAndSettle();
    expect(find.text('Cabang Lamamu Ketemu'), findsOneWidget);
    expect(find.text('Nama Cabang Pertama'), findsNothing);
    final kolom = find.byType(TextField);
    await tester.enterText(kolom.at(1), '1234');
    await tester.enterText(kolom.at(2), '1234');
    await ketukMulai(tester);
    expect(hasil, isNotNull);
    expect(hasil!.branches.length, 2);
    expect(hasil!.branches.map((b) => b.name), ['Cabang Utama', 'Cabang 2']);
  });

  testWidgets('mode buat: satu cabang → kolom nama tampil & mengisi cabang pertama', (tester) async {
    final s = AppSettings();
    AppSettings? hasil;
    await bukaWizard(tester, s, (x) => hasil = x);
    expect(find.text('Atur Cabang Pertama'), findsWidgets);
    expect(find.text('Nama Cabang Pertama'), findsOneWidget);
    final kolom = find.byType(TextField);
    await tester.enterText(kolom.at(0), 'Kopi Uji');
    await tester.enterText(kolom.at(1), 'Cabang Uji');
    await tester.enterText(kolom.at(2), '1234');
    await tester.enterText(kolom.at(3), '1234');
    await ketukMulai(tester);
    expect(hasil, isNotNull);
    expect(hasil!.branches.single.id, 'c1');
    expect(hasil!.branches.single.name, 'Cabang Uji');
    expect(hasil!.businessName, 'Kopi Uji');
  });
}
