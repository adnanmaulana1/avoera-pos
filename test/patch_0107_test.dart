// Tes v0.10.7 — pembaruan dari dalam aplikasi: ambil info
// versi, unduh APK, kanal pemasang, banner Beranda, dan baris
// Pembaruan Aplikasi di Pengaturan.
import 'dart:async';
import 'dart:io';

import 'package:avoera_pos/main.dart';
import 'package:avoera_pos/screens/pengaturan_screen.dart';
import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RespPalsu extends Fake implements HttpClientResponse {
  _RespPalsu(this._bytes, {this.statusCode = 200});
  final List<int> _bytes;
  @override
  final int statusCode;
  @override
  int get contentLength => _bytes.length;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.fromIterable([_bytes]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class _ReqPalsu extends Fake implements HttpClientRequest {
  _ReqPalsu(this._resp);
  final HttpClientResponse _resp;
  @override
  Future<HttpClientResponse> close() async => _resp;
}

class _KlienPalsu extends Fake implements HttpClient {
  _KlienPalsu(this._resp);
  final HttpClientResponse _resp;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ReqPalsu(_resp);
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Ambil info update', () {
    test('JSON sah terbaca lengkap', () async {
      final info = await ambilInfoUpdate(
        ambil: (_) async => '{"kode": 99, "nama": "9.9.9", "urlApk": "https://x/avoera.apk", "catatan": "Fitur baru"}',
      );
      expect(info, isNotNull);
      expect(info!.kode, 99);
      expect(info.nama, '9.9.9');
      expect(info.urlApk, 'https://x/avoera.apk');
      expect(info.catatan, 'Fitur baru');
    });

    test('Isi rusak / kosong / gagal ambil = null (bukan crash)', () async {
      expect(await ambilInfoUpdate(ambil: (_) async => 'bukan json'), isNull);
      expect(await ambilInfoUpdate(ambil: (_) async => '{"kode": "salah"}'), isNull);
      expect(await ambilInfoUpdate(ambil: (_) async => null), isNull);
    });
  });

  group('Unduh APK', () {
    test('Berkas tertulis utuh & progres mencapai 1', () async {
      // Diawali 'PK' seperti APK asli (v0.10.15 memeriksa tanda
      // ZIP di kepala berkas).
      final bytes = List<int>.generate(5000, (i) => i % 251)..[0] = 0x50..[1] = 0x4B;
      double? terakhir;
      final file = await unduhApk(
        InfoUpdate(kode: 99, nama: '9.9.9', urlApk: 'https://x/avoera.apk'),
        onProgres: (p) => terakhir = p,
        client: _KlienPalsu(_RespPalsu(bytes)),
      );
      expect(file, isNotNull);
      expect(await file!.readAsBytes(), bytes);
      expect(terakhir, 1.0);
      await file.delete();
    });

    test('Status bukan 200 = gagal (null)', () async {
      final file = await unduhApk(
        InfoUpdate(kode: 99, nama: '9.9.9', urlApk: 'https://x/avoera.apk'),
        onProgres: (_) {},
        client: _KlienPalsu(_RespPalsu(const [], statusCode: 500)),
      );
      expect(file, isNull);
    });
  });

  group('Kanal pemasang', () {
    const kanal = MethodChannel('avoera/installer');
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, null);
    });

    test('pasangApk meneruskan jawaban kanal (v0.10.12: dibuka / perlu-izin / warisan true)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async {
        expect(call.method, 'install');
        expect((call.arguments as Map)['path'], '/tmp/x.apk');
        return 'dibuka';
      });
      expect(await pasangApk(File('/tmp/x.apk')), 'dibuka');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async => 'perlu-izin');
      expect(await pasangApk(File('/tmp/x.apk')), 'perlu-izin');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async => true);
      expect(await pasangApk(File('/tmp/x.apk')), 'dibuka', reason: 'jawaban bool sisi Android lama tetap dimengerti');
    });

    test('pasangApk gagal saat kanal tidak terdaftar', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, null);
      expect(await pasangApk(File('/tmp/x.apk')), 'gagal');
    });
  });

  testWidgets('BannerUpdate: versi + catatan tampil, ketuk memanggil aksi', (tester) async {
    var diketuk = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: BannerUpdate(
            info: InfoUpdate(kode: 99, nama: '9.9.9', urlApk: 'https://x/y.apk', catatan: 'Ada fitur baru'),
            onTap: () => diketuk = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada versi baru — v9.9.9'), findsOneWidget);
    expect(find.text('Ada fitur baru'), findsOneWidget);
    await tester.tap(find.text('Ada versi baru — v9.9.9'));
    expect(diketuk, isTrue);
  });

  testWidgets('Pengaturan punya baris Pembaruan Aplikasi & cek manual memberi umpan balik', (tester) async {
    SharedPreferences.setMockInitialValues({'avoera.settings.v1': '{"onboarded":true}'});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KasirFnbApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaturan').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pembaruan Aplikasi'),
      300,
      scrollable: find.descendant(of: find.byType(PengaturanScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Pembaruan Aplikasi'), findsOneWidget);
    await tester.tap(find.text('Pembaruan Aplikasi'));
    // Dialog "Memeriksa…" hanya sekejap (HTTP lingkungan tes
    // langsung menjawab 400) -> yang bisa diamati adalah hasil
    // akhirnya: toast gagal memeriksa.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Memeriksa pembaruan…'), findsNothing);
    expect(find.textContaining('Tidak bisa memeriksa pembaruan'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
  });
}
