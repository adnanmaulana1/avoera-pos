import 'dart:io';
import 'dart:ui' as ui;

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// v0.8.1: animasi ganti tema IRIS — gambar tema lama di-clip
// lingkaran membesar dari titik chip tema yang diketuk (bukan
// lagi cakram warna solid "telur dadar" v0.8.0). Tes ini
// membuktikan: overlay muncul sesaat dari titik ketuk yang
// benar, tema benar-benar berganti, dan overlay TIDAK tertinggal
// sesudah animasi selesai — untuk dua arah. Tes kedua menangkap
// bingkai animasi sebagai bukti visual (contact sheet dibuat
// dari PNG-PNG itu).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

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

  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688); // 390x844 @2x
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    // Beranda di HP: navigasi bawah tampil.
    expect(find.text('Beranda'), findsWidgets);
    // Buka drawer 'Lainnya' → Pengaturan.
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.byType(PengaturanScreen), findsOneWidget);
    final scroll = find.descendant(
      of: find.byType(PengaturanScreen),
      matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
    );
    await tester.scrollUntilVisible(find.text('Gelap'), 200, scrollable: scroll);
    await tester.pumpAndSettle();
  }

  /// Ketuk chip tema lalu tunggu overlay iris muncul. Tangkapan
  /// gambar (toImage) di aplikasi selesai di jalur async asli,
  /// jadi beri kesempatan runAsync beberapa kali.
  Future<void> ketukChipSampaiOverlay(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    for (var i = 0; i < 25 && find.byType(AnimasiIrisTema).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(find.byType(AnimasiIrisTema), findsOneWidget, reason: 'Overlay iris harus muncul sesudah chip "$label" diketuk');
  }

  testWidgets('Iris ganti tema: overlay muncul dari titik chip, tema berganti, overlay hilang — dua arah', (tester) async {
    await pumpPhone(tester);
    expect(AppColors.gelap, isFalse, reason: 'Mulai dari tema terang');

    // --- Terang → Gelap ---
    final pusatChipGelap = tester.getCenter(find.text('Gelap'));
    await ketukChipSampaiOverlay(tester, 'Gelap');
    final iris1 = tester.widget<AnimasiIrisTema>(find.byType(AnimasiIrisTema));
    expect(iris1.pusat, isNotNull);
    expect((iris1.pusat! - pusatChipGelap).distance, lessThan(3),
        reason: 'Lingkaran iris harus berpusat di chip yang diketuk');
    expect(AppColors.gelap, isTrue, reason: 'Tema baru (gelap) langsung terpasang di bawah overlay');
    // Di tengah animasi overlay masih ada…
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AnimasiIrisTema), findsOneWidget, reason: 'Overlay masih tampil di tengah animasi');
    // …dan sesudah durasi penuh overlay hilang, tidak tertinggal.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(AnimasiIrisTema), findsNothing, reason: 'Overlay wajib hilang sesudah animasi selesai');
    expect(AppColors.gelap, isTrue);

    // --- Gelap → Terang (metode sama, arah sebaliknya) ---
    final pusatChipTerang = tester.getCenter(find.text('Terang'));
    await ketukChipSampaiOverlay(tester, 'Terang');
    final iris2 = tester.widget<AnimasiIrisTema>(find.byType(AnimasiIrisTema));
    expect((iris2.pusat! - pusatChipTerang).distance, lessThan(3),
        reason: 'Iris arah balik juga berpusat di chip yang diketuk');
    expect(AppColors.gelap, isFalse, reason: 'Tema terang langsung terpasang di bawah overlay');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.byType(AnimasiIrisTema), findsNothing, reason: 'Overlay arah balik juga wajib hilang');
    expect(AppColors.gelap, isFalse);
  });

  testWidgets('Bingkai animasi iris untuk contact sheet bukti visual', (tester) async {
    final folder = Directory('/home/hatch/workspace/avoera-screenshots/iris-frames');
    folder.createSync(recursive: true);
    for (final f in folder.listSync().whereType<File>()) {
      f.deleteSync();
    }

    Future<void> tangkap(String nama) async {
      // Tangkap boundary TERLUAR yang seukuran layar: pembungkus
      // rute di atas Stack — isinya HomeShell DAN overlay iris.
      // (Boundary akar di sekeliling HomeShell saja tidak memuat
      // overlay, karena overlay adalah saudaranya di Stack.)
      await tester.runAsync(() async {
        final ukuranLayar = tester.view.physicalSize / tester.view.devicePixelRatio;
        RenderRepaintBoundary? terluar;
        for (final e in find.ancestor(of: find.byType(HomeShell), matching: find.byType(RepaintBoundary)).evaluate()) {
          final kandidat = e.renderObject as RenderRepaintBoundary;
          if (kandidat.size == ukuranLayar) terluar = kandidat; // leluhur terakhir = terluar
        }
        expect(terluar, isNotNull, reason: 'Boundary terluar seukuran layar harus ketemu');
        final img = await terluar!.toImage(pixelRatio: 2.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        File('${folder.path}/$nama.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    Future<void> rekamArah(String awalan, String chip) async {
      await ketukChipSampaiOverlay(tester, chip);
      await tester.pump(); // bingkai awal: lingkaran masih ~0
      await tangkap('$awalan-0');
      for (var i = 1; i <= 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        await tangkap('$awalan-$i');
      }
      // Bingkai penutup: tuntaskan animasi (tiker mulai sedikit
      // sesudah overlay terpasang, jadi beri beberapa bingkai sisa).
      for (var i = 0; i < 6 && find.byType(AnimasiIrisTema).evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(AnimasiIrisTema), findsNothing, reason: 'Overlay bersih sesudah rekaman arah $awalan');
    }

    await pumpPhone(tester);
    await rekamArah('gelap', 'Gelap'); // terang → gelap: bingkai 0/±150/±300/±450/±600
    await rekamArah('terang', 'Terang'); // gelap → terang
  });
}
