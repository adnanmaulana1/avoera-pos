// Tes v0.10.15 — pemasang dibuka paksa sampai sebabnya
// terlihat: unduhan wajib utuh (ukuran sama + kepala 'PK'),
// pasangApk meneruskan kode+pesan kesalahan Android, dialog
// menampilkan alasan gagal asli (uji Adnan atas v0.10.13/
// v0.10.14: unduhan sukses, pemasang 'gagal' tanpa sebab yang
// terbaca — pesan pengecualian ditelan versi lama).
import 'dart:async';
import 'dart:io';

import 'package:avoera_pos/theme.dart';
import 'package:avoera_pos/update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _RespPalsu extends Fake implements HttpClientResponse {
  _RespPalsu(this._bytes, {this._panjangKlaim});
  final List<int> _bytes;
  final int? _panjangKlaim;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _panjangKlaim ?? _bytes.length;
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
      roboto.addFont(Future.value(ByteData.view((await File('$dir/$f').readAsBytes()).buffer)));
    }
    await roboto.load();
  });

  group('Unduhan wajib utuh', () {
    test('Aliran terpotong (ukuran kurang dari janji server) = gagal', () async {
      final bytes = List<int>.generate(4000, (i) => i % 251)..[0] = 0x50..[1] = 0x4B;
      final file = await unduhApk(
        InfoUpdate(kode: 99, nama: '9.9.9', urlApk: 'https://x/avoera.apk'),
        onProgres: (_) {},
        client: _KlienPalsu(_RespPalsu(bytes, panjangKlaim: 9000)),
      );
      expect(file, isNull);
    });

    test('Isi bukan APK (kepala bukan PK) = gagal', () async {
      final bytes = List<int>.generate(4000, (i) => i % 251);
      final file = await unduhApk(
        InfoUpdate(kode: 99, nama: '9.9.9', urlApk: 'https://x/avoera.apk'),
        onProgres: (_) {},
        client: _KlienPalsu(_RespPalsu(bytes)),
      );
      expect(file, isNull);
    });
  });

  group('Sebab gagal diteruskan', () {
    const kanal = MethodChannel('avoera/installer');
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, null);
    });

    test('pasangApk membawa kode + pesan PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async {
        throw PlatformException(code: 'BUKA', message: 'ActivityNotFoundException: tidak ada penangan');
      });
      expect(await pasangApk(File('/tmp/x.apk')), 'gagal|BUKA: ActivityNotFoundException: tidak ada penangan');
    });
  });

  testWidgets('Dialog fase gagal menampilkan alasan asli dari Android', (tester) async {
    final info = InfoUpdate(kode: 41, nama: '0.10.15', urlApk: 'https://x/avoera.apk');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showDialog<void>(
                context: ctx,
                builder: (_) => DialogUnduhUpdate(
                  info: info,
                  unduhFn: (i, cb) async => File('/tmp/avoera-41.apk'),
                  pasangFn: (f) async => 'gagal|BUKA: ActivityNotFoundException: contoh sebab',
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Unduhan selesai, tetapi pemasang tidak bisa dibuka.'), findsOneWidget);
    expect(find.textContaining('ActivityNotFoundException: contoh sebab'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });
}
