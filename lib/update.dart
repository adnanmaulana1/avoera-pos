import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'widgets.dart';

/// Pembaruan dari dalam aplikasi (diminta Adnan 2026-11-15
/// 22:02). Android TIDAK mengizinkan aplikasi memasang pembaruan
/// diam-diam di luar Play Store — yang bisa dilakukan: aplikasi
/// mengecek versi terbaru di server, mengunduh APK-nya sendiri,
/// lalu membuka pemasang Android; pengguna menekan "Pasang"
/// satu kali. Alurnya:
///
/// 1. Aplikasi membaca [urlInfoUpdate] (version.json di server,
///    ditulis langkah unggah Codemagic sesudah build rilis).
/// 2. Nomor build server > nomor build aplikasi → banner di
///    Beranda + pemberitahuan tersimpan.
/// 3. Ketuk banner → dialog unduh berprogress → pemasang
///    Android dibuka lewat kanal native 'avoera/installer'
///    (MainActivity + FileProvider).
const urlInfoUpdate = 'https://webtales.my.id/avoera/version.json';

/// Info rilis terbaru sebagaimana tertulis di version.json
/// server: {kode, nama, urlApk, catatan}.
class InfoUpdate {
  InfoUpdate({required this.kode, required this.nama, required this.urlApk, this.catatan = ''});

  /// Nomor build (angka sesudah '+' pada versi).
  final int kode;

  /// Nama versi tampil, mis. '0.10.8'.
  final String nama;
  final String urlApk;
  final String catatan;

  factory InfoUpdate.fromJson(Map<String, dynamic> j) => InfoUpdate(
        kode: (j['kode'] as num).toInt(),
        nama: j['nama'] as String,
        urlApk: j['urlApk'] as String,
        catatan: j['catatan'] as String? ?? '',
      );
}

/// Jahitan uji: pengambil teks HTTP bisa diganti di tes.
typedef AmbilTeks = Future<String?> Function(Uri url);

Future<String?> _ambilTeksHttp(Uri url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(url);
    final resp = await req.close();
    if (resp.statusCode != 200) return null;
    return await resp.transform(utf8.decoder).join();
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

/// Ambil info rilis terbaru dari server. Null = tidak bisa
/// diperiksa (offline / server bermasalah / isi rusak) — itu
/// BUKAN berarti tidak ada pembaruan.
Future<InfoUpdate?> ambilInfoUpdate({AmbilTeks? ambil, Uri? url}) async {
  final teks = await (ambil ?? _ambilTeksHttp)(url ?? Uri.parse(urlInfoUpdate));
  if (teks == null) return null;
  try {
    return InfoUpdate.fromJson(jsonDecode(teks) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Unduh APK ke folder sementara sistem (cache aplikasi —
/// FileProvider native melayani dari sana). [onProgres]
/// menerima 0..1, atau null bila ukuran unduhan tak diketahui.
/// Mengembalikan null bila unduhan gagal.
Future<File?> unduhApk(InfoUpdate info, {required void Function(double?) onProgres, HttpClient? client}) async {
  final c = client ?? HttpClient();
  try {
    final req = await c.getUrl(Uri.parse(info.urlApk));
    final resp = await req.close();
    if (resp.statusCode != 200) return null;
    final file = File('${Directory.systemTemp.path}/avoera-${info.kode}.apk');
    final total = resp.contentLength;
    var diterima = 0;
    final sink = file.openWrite();
    await for (final potong in resp) {
      sink.add(potong);
      diterima += potong.length;
      onProgres(total > 0 ? diterima / total : null);
    }
    await sink.close();
    return file;
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

const _kanalPasang = MethodChannel('avoera/installer');

/// Minta Android membuka pemasang untuk APK ini (pengguna
/// tetap menekan "Pasang" di jendela sistem — itu aturan
/// Android). False = kanal tidak tersedia / gagal, mis. saat
/// berjalan di tes atau di luar Android.
Future<bool> pasangApk(File file) async {
  try {
    return await _kanalPasang.invokeMethod<bool>('install', {'path': file.path}) ?? false;
  } catch (_) {
    return false;
  }
}

/// Banner pembaruan di puncak Beranda.
class BannerUpdate extends StatelessWidget {
  const BannerUpdate({super.key, required this.info, required this.onTap});

  final InfoUpdate info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.system_update_alt, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ada versi baru — v${info.nama}', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  info.catatan.isNotEmpty ? info.catatan : 'Ketuk untuk memperbarui aplikasi.',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Dialog unduh APK dengan penunjuk kemajuan. Sesudah unduhan
/// selesai, pemasang Android langsung dibuka dan dialog
/// menutup. Gagal → pesan + tombol Tutup.
class DialogUnduhUpdate extends StatefulWidget {
  const DialogUnduhUpdate({super.key, required this.info});

  final InfoUpdate info;

  @override
  State<DialogUnduhUpdate> createState() => _DialogUnduhUpdateState();
}

class _DialogUnduhUpdateState extends State<DialogUnduhUpdate> {
  double? _progres;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _jalankan();
  }

  Future<void> _jalankan() async {
    final file = await unduhApk(widget.info, onProgres: (p) {
      if (mounted) setState(() => _progres = p);
    });
    if (!mounted) return;
    if (file == null) {
      setState(() => _galat = 'Unduhan gagal. Periksa koneksi internet, lalu coba lagi.');
      return;
    }
    final dibuka = await pasangApk(file);
    if (!mounted) return;
    if (dibuka) {
      Navigator.of(context).pop();
    } else {
      setState(() => _galat = 'Unduhan selesai, tetapi pemasang tidak bisa dibuka. Coba lagi dari Pengaturan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _galat != null,
      child: AlertDialog(
        title: Text('Memperbarui ke v${widget.info.nama}'),
        content: _galat != null
            ? Text(_galat!, style: AppText.body)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _progres == null ? 'Mengunduh…' : 'Mengunduh… ${(_progres! * 100).round()}%',
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(value: _progres),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Sesudah unduhan selesai, tekan "Pasang" di jendela Android.', style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
              ),
        actions: [
          if (_galat != null) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
