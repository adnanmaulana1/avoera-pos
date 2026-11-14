import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Simpan foto menu yang dipilih pengguna ke folder dokumen
/// aplikasi (folder galeri sementara bisa dibersihkan sistem).
/// Mengembalikan jalur berkas permanennya.
Future<String> simpanFotoMenu(String sumber, String menuId) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/menu_foto');
  if (!await folder.exists()) await folder.create(recursive: true);
  final ext = sumber.contains('.') ? sumber.split('.').last : 'jpg';
  final tujuan = File('${folder.path}/$menuId.$ext');
  await File(sumber).copy(tujuan.path);
  return tujuan.path;
}
