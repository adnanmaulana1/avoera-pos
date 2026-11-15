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
/// 1. Aplikasi membaca [urlInfoUpdate] (version.json di repo
///    GitHub publik avoera-releases, diterbitkan Muse sesudah
///    tiap build rilis Codemagic selesai). Sejak v0.10.10
///    berkas pembaruan TIDAK lagi tinggal di server Adnan —
///    keputusan Adnan 2026-11-15: servernya sering kena
///    suspend, pembaruan tidak boleh ikut mati.
/// 2. Nomor build terbaru > nomor build aplikasi → dialog
///    tawaran muncul SENDIRI sekali per versi (v0.10.12,
///    permintaan Adnan: jangan menunggu pengguna sadar /
///    membuka Pengaturan) + banner di Beranda + pemberitahuan
///    tersimpan.
/// 3. Ketuk Perbarui / banner → dialog unduh berprogress →
///    pemasang Android dibuka lewat kanal native
///    'avoera/installer' (MainActivity + FileProvider). Izin
///    "pasang aplikasi tidak dikenal" belum ada → sisi
///    Android membuka halaman izinya dan dialog memandu
///    memasang ulang tanpa unduh ulang.
const urlInfoUpdate = 'https://raw.githubusercontent.com/adnanmaulana1/avoera-releases/main/version.json';

/// Info rilis terbaru sebagaimana tertulis di version.json:
/// {kode, nama, urlApk, catatan}.
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
/// Android). Hasilnya (v0.10.12):
/// - 'dibuka': jendela pemasang tampil.
/// - 'perlu-izin': izin "pasang aplikasi tidak dikenal" belum
///   diberikan; sisi Android SUDAH membuka halaman izinya —
///   pengguna mengaktifkan sekali, lalu memasang ulang.
/// - 'gagal': kanal tidak tersedia / gagal lain, mis. saat
///   berjalan di tes atau di luar Android.
/// (Jawaban bool dari sisi Android lama diperlakukan sebagai
/// 'dibuka' bila true.)
Future<String> pasangApk(File file) async {
  try {
    final hasil = await _kanalPasang.invokeMethod<dynamic>('install', {'path': file.path});
    if (hasil == 'perlu-izin') return 'perlu-izin';
    if (hasil == 'dibuka' || hasil == true) return 'dibuka';
    return 'gagal';
  } catch (_) {
    return 'gagal';
  }
}

/// Apakah versi ini perlu DITAWARKAN OTOMATIS lewat dialog
/// saat aplikasi dibuka (permintaan Adnan 2026-11-16 00:43:
/// pembaruan harus muncul sendiri, jangan menunggu pengguna
/// membuka Pengaturan / menyadari banner). Sekali per versi:
/// [kodeTawaranTerakhir] = kode tertinggi yang sudah pernah
/// ditawarkan otomatis; rilis yang lebih baru ditawarkan lagi.
bool perluTawaranUpdate({required int kodeTersedia, required int buildSaatIni, required int kodeTawaranTerakhir}) {
  return kodeTersedia > buildSaatIni && kodeTersedia > kodeTawaranTerakhir;
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
/// selesai, pemasang Android langsung diminta membuka. Tiga
/// ujung (v0.10.12 — dialog lama cuma bisa bilang "gagal,
/// coba dari Pengaturan", yang dikeluhkan Adnan):
/// - pemasang terbuka → dialog menutup;
/// - izin pasang belum ada → penjelasan + tombol 'Pasang'
///   untuk mencoba lagi SESUDAH pengguna mengaktifkan izin
///   (berkas yang sama, tanpa mengunduh ulang);
/// - gagal lain → pesan + 'Coba Lagi' (juga tanpa unduh ulang).
class DialogUnduhUpdate extends StatefulWidget {
  const DialogUnduhUpdate({super.key, required this.info, this.unduhFn, this.pasangFn});

  final InfoUpdate info;

  /// Jahitan uji: pengganti pengunduh / pemasang bawaan.
  final Future<File?> Function(InfoUpdate info, void Function(double?) onProgres)? unduhFn;
  final Future<String> Function(File file)? pasangFn;

  @override
  State<DialogUnduhUpdate> createState() => _DialogUnduhUpdateState();
}

class _DialogUnduhUpdateState extends State<DialogUnduhUpdate> {
  double? _progres;
  File? _file;

  /// 'unduh' | 'unduh-gagal' | 'izin' | 'gagal'
  String _fase = 'unduh';

  @override
  void initState() {
    super.initState();
    _jalankan();
  }

  Future<void> _jalankan() async {
    final unduh = widget.unduhFn ?? (InfoUpdate i, void Function(double?) cb) => unduhApk(i, onProgres: cb);
    final file = await unduh(widget.info, (p) {
      if (mounted) setState(() => _progres = p);
    });
    if (!mounted) return;
    if (file == null) {
      setState(() => _fase = 'unduh-gagal');
      return;
    }
    _file = file;
    await _cobaPasang();
  }

  Future<void> _cobaPasang() async {
    final pasang = widget.pasangFn ?? pasangApk;
    final hasil = await pasang(_file!);
    if (!mounted) return;
    switch (hasil) {
      case 'dibuka':
        Navigator.of(context).pop();
      case 'perlu-izin':
        setState(() => _fase = 'izin');
      default:
        setState(() => _fase = 'gagal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sedangUnduh = _fase == 'unduh';
    return PopScope(
      canPop: !sedangUnduh,
      child: AlertDialog(
        title: Text('Memperbarui ke v${widget.info.nama}'),
        content: switch (_fase) {
          'unduh-gagal' => Text('Unduhan gagal. Periksa koneksi internet, lalu coba lagi.', style: AppText.body),
          'izin' => Text(
              'Unduhan selesai. Android meminta izin sekali saja agar Avoera boleh memasang pembaruannya sendiri — halaman izin sudah dibuka. Aktifkan "Izinkan dari sumber ini", kembali ke sini, lalu ketuk Pasang.',
              style: AppText.body,
            ),
          'gagal' => Text('Unduhan selesai, tetapi pemasang tidak bisa dibuka.', style: AppText.body),
          _ => Column(
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
        },
        actions: [
          if (_fase == 'unduh-gagal') TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
          if (_fase == 'izin' || _fase == 'gagal') ...[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
            FilledButton(onPressed: _cobaPasang, child: Text(_fase == 'izin' ? 'Pasang' : 'Coba Lagi')),
          ],
        ],
      ),
    );
  }
}
