// Tes v0.20.0 (Reset Total — permintaan Adnan 2026-11-17):
// hapus semua data lokal, dialog konfirmasi ketik-RESET, dan
// alur penuh dari Pengaturan: awan dibersihkan lewat jahitan
// tes, aplikasi kembali ke sambutan awal; kegagalan awan
// membatalkan reset (data HP utuh).
import 'dart:io';

import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/onboarding_screen.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/store.dart';
import 'package:avoera_pos/sync.dart';
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
    final lucide = FontLoader('Lucide');
    lucide.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/Lucide.ttf').readAsBytes()).buffer)));
    await lucide.load();
  });

  tearDown(() => jahitanHapusCloud = null);

  group('LocalStore.hapusSemuaData', () {
    testWidgets('semua kunci avoera.* hilang → muat berikutnya seperti baru', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStore.saveSettings(AppSettings(onboarded: true, businessName: 'Toko Tes'));
      await LocalStore.saveTransactions([
        TxRecord(id: 'A-1', total: 50000, method: 'Tunai', at: DateTime(2026, 11, 17), items: 2),
      ]);
      await LocalStore.saveSyncMeta({'kotor': {'menus': 3}});
      await LocalStore.hapusSemuaData();
      final data = await LocalStore.load();
      expect(data.settings.onboarded, isFalse);
      expect(data.settings.businessName, isNot('Toko Tes'));
      expect(data.transactions, isEmpty);
      expect(data.menus.length, seedMenus().length);
      final meta = await LocalStore.loadSyncMeta();
      expect(meta, isEmpty);
    });
  });

  group('dialog Reset Total', () {
    Finder inDialog(Finder inner) => find.descendant(of: find.byType(AlertDialog), matching: inner);

    Future<void> bukaDialog(WidgetTester tester, Future<String?> Function() stub) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showResetTotalDialog(ctx, onKonfirmasi: stub),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Semua Data?'), findsOneWidget);
    }

    testWidgets('tombol hapus mati sampai mengetik RESET (huruf kecil pun sah), sukses menutup dialog', (tester) async {
      var panggilan = 0;
      await bukaDialog(tester, () async {
        panggilan++;
        return null;
      });
      PrimaryButton tombol() => tester.widget<PrimaryButton>(inDialog(find.byType(PrimaryButton)));
      expect(tombol().onPressed, isNull);
      await tester.enterText(inDialog(find.byType(TextField)), 'reset');
      await tester.pump();
      expect(tombol().onPressed, isNotNull);
      await tester.tap(inDialog(find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(panggilan, 1);
      expect(find.byType(AlertDialog), findsNothing);
      // Siram timer buang controller (500md) sesudah dialog tutup.
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('galat dari konfirmasi tampil di dialog dan dialog tetap terbuka', (tester) async {
      await bukaDialog(tester, () async => 'Data di awan gagal dihapus (contoh). Data di HP ini TIDAK diubah.');
      await tester.enterText(inDialog(find.byType(TextField)), 'RESET');
      await tester.pump();
      await tester.tap(inDialog(find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(find.textContaining('gagal dihapus (contoh)'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(inDialog(find.text('Batal')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  group('aplikasi penuh', () {
    setUp(() => SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'}));

    Future<void> keZonaBahaya(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const KasirFnbApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengaturan').last);
      await tester.pumpAndSettle();
      expect(find.byType(PengaturanScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Reset Semua Data'),
        200,
        scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reset Semua Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset Semua Data'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Semua Data?'), findsOneWidget);
      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'RESET');
      await tester.pump();
    }

    testWidgets('reset berhasil → sambutan awal tampil, data lokal bersih', (tester) async {
      var awanDihapus = false;
      jahitanHapusCloud = (_) async {
        awanDihapus = true;
      };
      await keZonaBahaya(tester);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(PrimaryButton)));
      // Reset berjalan: ia menunggu sinkron awal yang masih
      // terbang menggantung sampai batas 25 detiknya, jadi
      // pompa waktu maju selangkah-selangkah sampai gerbang
      // sambutan awal tampil (animasi sambutan berulang —
      // pumpAndSettle tidak bisa dipakai di sini).
      for (var i = 0; i < 90 && find.byType(OnboardingFlow).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(awanDihapus, isTrue);
      // Dialog menutup tepat sesudah reset tuntas — beri
      // animasi keluarnya dua pompa lagi.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(OnboardingFlow), findsOneWidget);
      final data = await LocalStore.load();
      expect(data.settings.onboarded, isFalse);
      expect(data.transactions, isEmpty);
      // Siram timer sinkron (batas 25 detik) supaya tes bersih.
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
    });

    testWidgets('awan gagal dihapus → reset batal, data HP utuh', (tester) async {
      jahitanHapusCloud = (_) async => throw Exception('jaringan mati');
      await keZonaBahaya(tester);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(PrimaryButton)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Data di HP ini TIDAK diubah'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      final data = await LocalStore.load();
      expect(data.settings.onboarded, isTrue);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Batal')));
      await tester.pumpAndSettle();
      expect(find.byType(PengaturanScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
