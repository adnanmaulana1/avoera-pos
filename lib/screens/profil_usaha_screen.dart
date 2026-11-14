import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../media_store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart' show FormLabel;

/// Halaman Profil Usaha (permintaan Adnan 2026-11-14): data usaha
/// diedit di halaman sendiri — Pengaturan cukup menampilkan kartu
/// profilnya. Simpan sekaligus untuk nama, alamat, telepon.
class ProfilUsahaScreen extends StatefulWidget {
  const ProfilUsahaScreen({
    super.key,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.onSave,
    required this.fotoPath,
    required this.onSaveFoto,
  });
  final String nama;
  final String alamat;
  final String telepon;
  final void Function(String nama, String alamat, String telepon) onSave;

  /// Foto/logo usaha (berkas lokal) + penyimpannya. Foto disimpan
  /// SEGERA saat dipilih (seperti ganti foto profil di aplikasi
  /// lain) — tidak menunggu tombol Simpan Profil.
  final String? fotoPath;
  final ValueChanged<String?> onSaveFoto;

  @override
  State<ProfilUsahaScreen> createState() => _ProfilUsahaScreenState();
}

class _ProfilUsahaScreenState extends State<ProfilUsahaScreen> {
  late String? _fotoPath = widget.fotoPath;
  late final _namaCtrl = TextEditingController(text: widget.nama);
  late final _alamatCtrl = TextEditingController(text: widget.alamat);
  late final _teleponCtrl = TextEditingController(text: widget.telepon);
  String? _error;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    final sumber = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.of(ctx).pop('kamera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.of(ctx).pop('galeri'),
            ),
            if (_fotoPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text('Hapus Foto', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.of(ctx).pop('hapus'),
              ),
          ],
        ),
      ),
    );
    if (sumber == null) return;
    if (sumber == 'hapus') {
      setState(() => _fotoPath = null);
      widget.onSaveFoto(null);
      return;
    }
    try {
      final x = await ImagePicker().pickImage(
        source: sumber == 'kamera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 82,
      );
      if (x == null) return;
      final permanen = await simpanFotoProfil(x.path);
      if (!mounted) return;
      setState(() => _fotoPath = permanen);
      widget.onSaveFoto(permanen);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka kamera/galeri di perangkat ini.')));
      }
    }
  }

  bool get _berubah => _namaCtrl.text != widget.nama || _alamatCtrl.text != widget.alamat || _teleponCtrl.text != widget.telepon;

  void _simpan() {
    if (_namaCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nama usaha wajib diisi.');
      return;
    }
    widget.onSave(_namaCtrl.text.trim(), _alamatCtrl.text.trim(), _teleponCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil usaha disimpan.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GuardBack(
      dirty: () => _berubah,
      child: Scaffold(
        appBar: AppBar(title: const Text('Profil Usaha')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(child: _PemilihFoto(path: _fotoPath, onPilih: _pilihFoto)),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text('Ketuk foto untuk mengganti logo usaha.', style: AppText.caption.copyWith(color: AppColors.muted)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.nama, textAlign: TextAlign.center, style: AppText.title),
            Text('Profil ini tampil di Beranda, struk, dan laporan.', textAlign: TextAlign.center, style: AppText.caption.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.xl),
            const FormLabel('Nama Usaha'),
            TextField(controller: _namaCtrl, decoration: const InputDecoration(hintText: 'cth. Kopi Senja')),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Alamat Usaha'),
            TextField(controller: _alamatCtrl, decoration: const InputDecoration(hintText: 'cth. Jl. Merdeka No. 10')),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Telepon / WhatsApp'),
            TextField(controller: _teleponCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'cth. 0812-3456-7890')),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppText.small.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Simpan Profil', onPressed: _simpan),
          ],
        ),
      ),
    );
  }
}


/// Foto profil usaha 88px dengan lencana kamera: foto lokal bila
/// ada, selain itu kotak aksen + ikon toko.
class _PemilihFoto extends StatelessWidget {
  const _PemilihFoto({required this.path, required this.onPilih});
  final String? path;
  final VoidCallback onPilih;

  @override
  Widget build(BuildContext context) {
    final isi = (path == null || path!.isEmpty)
        ? Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Icon(Icons.storefront, color: AppColors.card, size: 40),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.file(
              File(path!),
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Icon(Icons.storefront, color: AppColors.card, size: 40),
              ),
            ),
          );
    return GestureDetector(
      onTap: onPilih,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          isi,
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.accentDark),
            ),
          ),
        ],
      ),
    );
  }
}
