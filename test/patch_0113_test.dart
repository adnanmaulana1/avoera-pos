// Tes v0.10.13 — unduhan pembaruan ringan per jenis HP
// (perintah Adnan 2026-11-16 01:11: unduhan 61 MB lewat
// GitHub lambat). Berkas universal diganti split per ABI:
// arm64 ±25 MB sebagai berkas utama, arm32 untuk HP lama;
// aplikasi memilih sendiri lewat Abi perangkat.
import 'dart:ffi';
import 'dart:io';

import 'package:avoera_pos/update.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      roboto.addFont(File('/home/hatch/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await roboto.load();
    // Huruf khas v0.12.0 ikut dimuat — tanpa ini judul/angka
    // jatuh ke font uji raksasa dan lebar teksnya mengecoh.
    final jakarta = FontLoader('Plus Jakarta Sans');
    for (final f in ['PlusJakartaSans-Regular.ttf', 'PlusJakartaSans-Medium.ttf', 'PlusJakartaSans-SemiBold.ttf', 'PlusJakartaSans-Bold.ttf', 'PlusJakartaSans-ExtraBold.ttf']) {
      jakarta.addFont(Future.value(ByteData.view((await File('/home/hatch/workspace/projects/avoera-pos/assets/fonts/$f').readAsBytes()).buffer)));
    }
    await jakarta.load();
  });

  group('Berkas per jenis HP', () {
    final info = InfoUpdate(kode: 39, nama: '0.10.13', urlApk: 'https://x/avoera.apk', urlApk32: 'https://x/avoera-32.apk', catatan: 'Ringan.');

    test('InfoUpdate JSON: urlApk32 terbaca; version.json lama tanpa urlApk32 aman', () {
      final dariJson = InfoUpdate.fromJson({'kode': 39, 'nama': '0.10.13', 'urlApk': 'https://x/avoera.apk', 'urlApk32': 'https://x/avoera-32.apk', 'catatan': 'Ringan.'});
      expect(dariJson.urlApk32, 'https://x/avoera-32.apk');
      final lama = InfoUpdate.fromJson({'kode': 38, 'nama': '0.10.12', 'urlApk': 'https://x/avoera.apk'});
      expect(lama.urlApk32, '');
    });

    test('urlApkUntukPerangkat: arm32 dapat berkas 32, sisanya berkas utama', () {
      expect(urlApkUntukPerangkat(info, Abi.androidArm), 'https://x/avoera-32.apk');
      expect(urlApkUntukPerangkat(info, Abi.androidArm64), 'https://x/avoera.apk');
      expect(urlApkUntukPerangkat(info, Abi.androidX64), 'https://x/avoera.apk');
      // Tanpa berkas 32 diterbitkan → arm32 jatuh ke utama.
      final tanpa32 = InfoUpdate(kode: 39, nama: '0.10.13', urlApk: 'https://x/avoera.apk');
      expect(urlApkUntukPerangkat(tanpa32, Abi.androidArm), 'https://x/avoera.apk');
    });
  });
}
