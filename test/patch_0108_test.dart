// v0.10.8: pemberitahuan bisa diketuk menuju tujuannya
// (permintaan Adnan 2026-11-15 22:38) — stok membuka Stok
// Bahan tersaring ke bahannya, sinkron membuka Status
// Sinkronisasi, info pembaruan memulai pembaruan.
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/notifikasi_screen.dart';
import 'package:avoera_pos/screens/stok_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      roboto.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    await icons.load();
  });

  AppNotification notif(String id, String jenis, String judul, String kunci) => AppNotification(
        id: id,
        judul: judul,
        isi: 'Isi contoh untuk $judul.',
        waktu: DateTime.now(),
        jenis: jenis,
        kunci: kunci,
      );

  testWidgets('NotifikasiScreen: yang bertujuan berpanah & terketuk; info biasa tidak', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final diketuk = <AppNotification>[];
    final daftar = [
      notif('n1', 'stok', 'Stok habis: Bubuk Matcha', 'stok-b1-habis'),
      notif('n2', 'sinkron', 'Sinkron gagal', 'sinkron-gagal'),
      notif('n3', 'info', 'Pembaruan tersedia', 'update-34'),
      notif('n4', 'info', 'Info umum saja', ''),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: NotifikasiScreen(notifications: daftar, onTapNotification: diketuk.add),
      ),
    );
    await tester.pumpAndSettle();

    // Tiga yang bertujuan berpanah; info biasa tidak.
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));

    await tester.tap(find.text('Stok habis: Bubuk Matcha'));
    await tester.pump();
    expect(diketuk.map((n) => n.id), ['n1']);

    await tester.tap(find.text('Sinkron gagal'));
    await tester.pump();
    expect(diketuk.map((n) => n.id), ['n1', 'n2']);

    await tester.tap(find.text('Info umum saja'));
    await tester.pump();
    expect(diketuk.length, 2, reason: 'info tanpa tujuan tidak memanggil callback');
  });

  Future<void> seedDanBuka(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final sekarang = DateTime.now().toIso8601String();
    SharedPreferences.setMockInitialValues({
      'avoera.settings.v1': '{"onboarded":true}',
      'avoera.ingredients.v1':
          '[{"id":"b-uji","name":"Bubuk Matcha","stock":0,"unit":"kg","minStock":1,"maxStock":10,"costPerUnit":50000},'
          '{"id":"b-lain","name":"Susu Segar","stock":10,"unit":"liter","minStock":4,"maxStock":20,"costPerUnit":12000}]',
      'avoera.notifications.v1':
          '[{"id":"n1","judul":"Stok habis: Bubuk Matcha","isi":"Sisa 0 kg — segera pesan lagi.","waktu":"$sekarang","jenis":"stok","kunci":"stok-b-uji-habis","dibaca":false},'
          '{"id":"n2","judul":"Sinkron gagal","isi":"Server terlalu lama menjawab.","waktu":"$sekarang","jenis":"sinkron","kunci":"sinkron-gagal","dibaca":false}]',
    });
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pemberitahuan'));
    await tester.pumpAndSettle();
    expect(find.text('Pemberitahuan'), findsOneWidget);
  }

  testWidgets('Aplikasi: ketuk notifikasi stok -> Stok Bahan tersaring ke bahan itu', (tester) async {
    await seedDanBuka(tester);
    await tester.tap(find.text('Stok habis: Bubuk Matcha'));
    await tester.pumpAndSettle();

    expect(find.text('Pemberitahuan'), findsNothing);
    expect(find.text('Stok Bahan'), findsWidgets);
    final kolom = tester.widget<TextField>(
      find.descendant(of: find.byType(StokScreen), matching: find.byType(TextField)),
    );
    expect(kolom.controller!.text, 'Bubuk Matcha');
    expect(find.text('Susu Segar'), findsNothing, reason: 'daftar tersaring, bahan lain sembunyi');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Aplikasi: ketuk notifikasi sinkron -> Status Sinkronisasi', (tester) async {
    await seedDanBuka(tester);
    await tester.tap(find.text('Sinkron gagal'));
    await tester.pumpAndSettle();

    expect(find.text('Status Sinkronisasi'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
