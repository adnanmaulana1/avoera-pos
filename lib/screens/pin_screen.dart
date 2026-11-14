import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'onboarding_screen.dart' show hashPin;

/// Gerbang PIN kasir (permintaan Adnan 2026-11-14): selama PIN
/// diatur, layar Kasir terkunci — kasir wajib memasukkan PIN dulu.
/// Terbuka sekali per sesi aplikasi; memasang PIN bersifat pilihan
/// (bila PIN kosong, kasir langsung terbuka seperti biasa).
class PinGateScreen extends StatefulWidget {
  const PinGateScreen({super.key, required this.pinHash, required this.businessName, required this.onUnlock});
  final String pinHash;
  final String businessName;
  final VoidCallback onUnlock;

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _input = '';
  String? _error;

  void _tekan(String d) {
    if (_input.length >= 6) return;
    final baru = _input + d;
    // PIN 4–6 angka: periksa tiap panjang yang mungkin.
    if (baru.length >= 4 && hashPin(baru) == widget.pinHash) {
      widget.onUnlock();
      return;
    }
    if (baru.length == 6) {
      setState(() {
        _input = '';
        _error = 'PIN salah — coba lagi.';
      });
      return;
    }
    setState(() {
      _input = baru;
      _error = null;
    });
  }

  void _hapus() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Icon(Icons.lock_outline, color: AppColors.accentDark, size: 30),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Kasir Terkunci', textAlign: TextAlign.center, style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Masukkan PIN kasir untuk membuka kasir ${widget.businessName}.',
          textAlign: TextAlign.center,
          style: AppText.small.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 6; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _input.length ? AppColors.accent : AppColors.card,
                  border: Border.all(color: i < _input.length ? AppColors.accent : AppColors.border, width: 1.5),
                ),
              ),
          ],
        ),
        SizedBox(height: _error == null ? AppSpacing.xl : AppSpacing.sm),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(_error!, textAlign: TextAlign.center, style: AppText.small.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        for (final baris in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in baris)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: d.isEmpty
                      ? const SizedBox.shrink()
                      : InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => d == '<' ? _hapus() : _tekan(d),
                          child: Center(
                            child: d == '<'
                                ? const Icon(Icons.backspace_outlined, size: 24)
                                : Text(d, style: AppText.hero.copyWith(fontWeight: FontWeight.w600)),
                          ),
                        ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'PIN diatur pemilik di Pengaturan → Keamanan → PIN Kasir.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Halaman PIN Kasir (permintaan Adnan 2026-11-14: atur PIN punya
/// halaman sendiri, bukan dialog kecil): buat PIN pertama kali,
/// ubah PIN (wajib PIN lama), atau hapus PIN.
class PinSettingsScreen extends StatefulWidget {
  const PinSettingsScreen({super.key, required this.currentHash, required this.onSaveHash});
  final String currentHash;
  final ValueChanged<String> onSaveHash;

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen> {
  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _ulangCtrl = TextEditingController();
  String? _error;

  bool get _pinSet => widget.currentHash.isNotEmpty;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _ulangCtrl.dispose();
    super.dispose();
  }

  bool _cekLama() {
    if (!_pinSet) return true;
    if (hashPin(_lamaCtrl.text.trim()) != widget.currentHash) {
      setState(() => _error = 'PIN lama salah.');
      return false;
    }
    return true;
  }

  void _simpan() {
    if (!_cekLama()) return;
    final baru = _baruCtrl.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(baru)) {
      return setState(() => _error = 'PIN baru harus 4–6 angka.');
    }
    if (baru != _ulangCtrl.text.trim()) {
      return setState(() => _error = 'Konfirmasi PIN baru tidak sama.');
    }
    widget.onSaveHash(hashPin(baru));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN kasir disimpan.')));
    Navigator.of(context).pop();
  }

  Future<void> _hapusPin() async {
    if (!_cekLama()) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus PIN Kasir'),
        content: const Text('Kasir tidak lagi dikunci PIN. Siapa pun yang memegang perangkat bisa membuka kasir.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          PrimaryButton(label: 'Hapus PIN', backgroundColor: AppColors.danger, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.onSaveHash('');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN kasir dihapus.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GuardBack(
      dirty: () => _lamaCtrl.text.isNotEmpty || _baruCtrl.text.isNotEmpty || _ulangCtrl.text.isNotEmpty,
      child: Scaffold(
        appBar: AppBar(title: const Text('PIN Kasir')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: const Icon(Icons.pin_outlined, color: AppColors.accentDark, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _pinSet
                          ? 'PIN aktif — kasir terkunci PIN setiap aplikasi dibuka. Isi PIN lama untuk mengubah atau menghapusnya.'
                          : 'Belum ada PIN. Buat PIN supaya kasir terkunci dan hanya yang tahu PIN yang bisa membuka kasir.',
                      style: AppText.small.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_pinSet) ...[
              TextField(
                controller: _lamaCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'PIN lama'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _baruCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(labelText: _pinSet ? 'PIN baru (4–6 angka)' : 'PIN kasir (4–6 angka)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _ulangCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Ulangi PIN baru'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppText.small.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: _pinSet ? 'Simpan PIN Baru' : 'Buat PIN', onPressed: _simpan),
            if (_pinSet)
              Center(
                child: TextButton(
                  onPressed: _hapusPin,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Hapus PIN'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
