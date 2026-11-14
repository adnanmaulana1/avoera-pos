import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

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
  });
  final String nama;
  final String alamat;
  final String telepon;
  final void Function(String nama, String alamat, String telepon) onSave;

  @override
  State<ProfilUsahaScreen> createState() => _ProfilUsahaScreenState();
}

class _ProfilUsahaScreenState extends State<ProfilUsahaScreen> {
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
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Icon(Icons.storefront, color: AppColors.card, size: 34),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.nama, textAlign: TextAlign.center, style: AppText.title),
            Text('Profil ini tampil di Beranda, struk, dan laporan.', textAlign: TextAlign.center, style: AppText.caption.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.xl),
            TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama usaha')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _alamatCtrl, decoration: const InputDecoration(labelText: 'Alamat usaha')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _teleponCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon / WhatsApp')),
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
