import 'package:flutter/material.dart';

import '../data.dart';
import '../ikon.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart';
import 'laporan_bersama.dart' show GarisTipis;

/// Kelola Kategori Menu (CRUD kategori, permintaan Adnan
/// 2026-11-17): tambah kategori baru, ubah nama (semua menu di
/// dalamnya IKUT berganti), hapus kategori (menu di dalamnya
/// dipindah ke 'Lainnya', tidak ikut terhapus). Daftar kategori
/// tersimpan di pengaturan; yang tampil di sini daftar EFEKTIF
/// dari [kategoriEfektif].
class KategoriScreen extends StatelessWidget {
  const KategoriScreen({
    super.key,
    required this.kategori,
    required this.menus,
    required this.onTambah,
    required this.onUbahNama,
    required this.onHapus,
  });

  /// Daftar kategori efektif (tanpa 'Semua').
  final List<String> kategori;
  final List<MenuItem> menus;
  final ValueChanged<String> onTambah;
  final void Function(String lama, String baru) onUbahNama;
  final ValueChanged<String> onHapus;

  int _jumlah(String nama) => menus.where((m) => m.category == nama).length;

  Future<void> _konfirmasiHapus(BuildContext context, String nama) async {
    final n = _jumlah(nama);
    final ok = await showConfirmDelete(
      context,
      title: 'Hapus Kategori',
      message: n > 0
          ? 'Kategori "$nama" dihapus. $n menu di dalamnya TIDAK ikut terhapus — dipindah ke kategori "Lainnya".'
          : 'Kategori "$nama" dihapus. Belum ada menu di dalamnya.',
    );
    if (ok) onHapus(nama);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Menu')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
          children: [
            Text(
              'Kelompok menu di kasir & produk — tambah, ubah nama, atau hapus kategori.',
              style: AppText.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (kategori.isEmpty)
              const EmptyState(message: 'Belum ada kategori.\nKetuk tombol di bawah untuk membuat kategori pertama.', icon: Ikon.local_offer_outlined)
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    for (var i = 0; i < kategori.length; i++) ...[
                      if (i > 0) const GarisTipis(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(kategori[i], style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${_jumlah(kategori[i])} menu', style: AppText.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Ubah nama',
                              icon: Icon(Ikon.edit_outlined, size: 19, color: AppColors.accentDark),
                              onPressed: () => showKategoriSheet(
                                context,
                                awal: kategori[i],
                                daftar: kategori,
                                onSimpan: (baru) => onUbahNama(kategori[i], baru),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              icon: Icon(Ikon.delete_outline, size: 19, color: AppColors.danger),
                              onPressed: () => _konfirmasiHapus(context, kategori[i]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Tambah Kategori',
              onPressed: () => showKategoriSheet(
                context,
                daftar: kategori,
                onSimpan: onTambah,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mengubah nama kategori ikut mengubah semua menu di dalamnya. Menghapus kategori memindahkan menunya ke "Lainnya" — menu tidak pernah ikut terhapus.',
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lembar tambah / ubah nama kategori. Nama tidak boleh kosong,
/// tidak boleh sama dengan kategori lain (huruf besar-kecil
/// dianggap sama), dan 'Semua' terlarang (itu penanda filter).
Future<void> showKategoriSheet(
  BuildContext context, {
  String? awal,
  required List<String> daftar,
  required ValueChanged<String> onSimpan,
}) async {
  final namaCtrl = TextEditingController(text: awal ?? '');
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return FormSheet(
          title: awal == null ? 'Tambah Kategori' : 'Ubah Nama Kategori',
          showClose: true,
          saveLabel: awal == null ? 'Simpan Kategori' : 'Simpan Perubahan',
          errorText: error,
          onSave: () {
            final nama = namaCtrl.text.trim();
            if (nama.isEmpty) {
              setSheet(() => error = 'Nama kategori belum diisi.');
              return;
            }
            if (nama.toLowerCase() == 'semua') {
              setSheet(() => error = '"Semua" adalah penanda filter, tidak bisa jadi nama kategori.');
              return;
            }
            final dobel = daftar.any((k) => k != awal && k.toLowerCase() == nama.toLowerCase());
            if (dobel) {
              setSheet(() => error = 'Kategori "$nama" sudah ada.');
              return;
            }
            Navigator.of(ctx).pop();
            if (nama != awal) onSimpan(nama);
          },
          children: [
            const FormLabel('Nama Kategori'),
            TextField(
              controller: namaCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Contoh: Minuman Segar'),
              onChanged: (_) {
                if (error != null) setSheet(() => error = null);
              },
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([namaCtrl]);
}
