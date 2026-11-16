import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart' show FormLabel;
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

class _PinGateScreenState extends State<PinGateScreen> with SingleTickerProviderStateMixin {
  String _input = '';
  String? _error;
  late final AnimationController _goyang;

  @override
  void initState() {
    super.initState();
    _goyang = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _goyang.dispose();
    super.dispose();
  }

  void _tekan(String d) {
    if (_input.length >= 6) return;
    HapticFeedback.selectionClick();
    final baru = _input + d;
    // PIN 4–6 angka: periksa tiap panjang yang mungkin.
    if (baru.length >= 4 && hashPin(baru) == widget.pinHash) {
      widget.onUnlock();
      return;
    }
    if (baru.length == 6) {
      // PIN penuh tapi salah: getar, titik digoyang & memerah.
      HapticFeedback.mediumImpact();
      _goyang.forward(from: 0);
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
    HapticFeedback.selectionClick();
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  void _hapusSemua() {
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _input = '';
      _error = null;
    });
  }

  Widget _titik(int i) {
    final terisi = i < _input.length;
    final gagal = _error != null;
    final isi = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: terisi ? (gagal ? AppColors.danger : AppColors.accent) : Colors.transparent,
        border: Border.all(color: gagal ? AppColors.danger : (terisi ? AppColors.accent : AppColors.border), width: 1.5),
      ),
    );
    // Titik yang baru terisi memantul kecil — terasa hidup.
    if (terisi && i == _input.length - 1) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('pop-${_input.length}'),
        tween: Tween(begin: 1.5, end: 1),
        duration: const Duration(milliseconds: 180),
        builder: (_, skala, child) => Transform.scale(scale: skala, child: child),
        child: isi,
      );
    }
    return isi;
  }

  @override
  Widget build(BuildContext context) {
    // Tata letak "Bersih Tengah" — dipilih Adnan 2026-11-16 dari
    // 3 varian, MENGGANTIKAN "Padat Bawah" yang tidak lagi
    // disukai. Semua isi berkumpul di tengah: logo, nama usaha,
    // titik PIN polos tanpa pil, keterangan, lalu papan angka
    // lingkaran tanpa kotak. Petunjuk tinggal di bawah. Semua
    // perilaku lama dipertahankan: titik memantul, goyang +
    // merah saat salah, getar, tekan lama hapus = kosongkan.
    final gagal = _error != null;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          // IntrinsicHeight WAJIB: tanpa ini Column ber-Expanded di
          // dalam scroll view menerima tinggi tak terbatas dan
          // meledak ("non-zero flex but incoming height unbounded").
          child: IntrinsicHeight(
            child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(flex: 2, child: SizedBox()),
                    // Logo aplikasi (karya Avorea transparan yang
                    // sama dengan splash) BESAR di tengah — dulu
                    // ubin ikon toko 54px, diganti atas permintaan
                    // Adnan 2026-11-16 ("harusnya logo aplikasi,
                    // besarin skalanya"). Gagal muat → ubin lama.
                    Center(
                      child: Image.asset(
                        'assets/branding/avorea-segar.png',
                        width: 205,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: const Icon(Icons.storefront, color: Colors.white, size: 27),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(widget.businessName, textAlign: TextAlign.center, style: AppText.subtitle.copyWith(color: AppColors.ink), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Kasir Terkunci', textAlign: TextAlign.center, style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 26),
                    AnimatedBuilder(
                      animation: _goyang,
                      builder: (_, child) {
                        final v = _goyang.value;
                        final geser = _goyang.isAnimating ? math.sin(v * math.pi * 4) * 9 * (1 - v) : 0.0;
                        return Transform.translate(offset: Offset(geser, 0), child: child);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 6; i++)
                            Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.lg),
                              child: _titik(i),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error ?? 'Masukkan PIN untuk membuka kasir',
                      textAlign: TextAlign.center,
                      style: AppText.small.copyWith(
                        color: gagal ? AppColors.danger : AppColors.muted,
                        fontWeight: gagal ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 30),
                    for (final baris in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['', '0', '<'],
                    ]) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var j = 0; j < baris.length; j++) ...[
                            if (j > 0) const SizedBox(width: 28),
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: baris[j].isEmpty
                                  ? null
                                  : _TombolPin(
                                      label: baris[j],
                                      onTap: () => baris[j] == '<' ? _hapus() : _tekan(baris[j]),
                                      onLongPress: baris[j] == '<' ? _hapusSemua : null,
                                    ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Expanded(flex: 3, child: SizedBox()),
                    Text(
                      'PIN diatur pemilik di Pengaturan → Keamanan → PIN Kasir. Tekan lama tombol hapus untuk mengosongkan PIN.',
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu tombol papan angka PIN gaya "Bersih Tengah": lingkaran
/// polos tanpa kotak/garis; selama ditekan muncul lingkaran
/// hijau lembut di belakang angka — papan terasa hidup, bukan
/// teks diam.
class _TombolPin extends StatefulWidget {
  const _TombolPin({required this.label, required this.onTap, this.onLongPress});
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_TombolPin> createState() => _TombolPinState();
}

class _TombolPinState extends State<_TombolPin> {
  bool _ditekan = false;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _ditekan = true),
      onTapUp: (_) => setState(() => _ditekan = false),
      onTapCancel: () => setState(() => _ditekan = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _ditekan ? AppColors.accentSoft : Colors.transparent,
        ),
        child: Center(
          child: widget.label == '<'
              ? Icon(Icons.backspace_outlined, size: 26, color: AppColors.ink)
              : Text(widget.label, style: AppText.number.copyWith(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.ink)),
        ),
      ),
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
              const FormLabel('PIN Lama'),
              TextField(
                controller: _lamaCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(hintText: 'PIN yang dipakai sekarang'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FormLabel(_pinSet ? 'PIN Baru (4–6 angka)' : 'PIN Kasir (4–6 angka)'),
            TextField(
              controller: _baruCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(hintText: '4–6 angka'),
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Ulangi PIN Baru'),
            TextField(
              controller: _ulangCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(hintText: 'Ketik ulang PIN baru'),
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
