import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Hash PIN kasir (tidak pernah menyimpan PIN mentah).
String hashPin(String pin) => sha256.convert(utf8.encode('avoera:$pin')).toString();

/// Alur pembuka untuk pemasangan pertama (permintaan Adnan
/// 2026-11-14): 3 halaman perkenalan bergambar SVG beranimasi,
/// lalu wizard cabang pertama — nama usaha, nama cabang, PIN
/// kasir, dan mode meja. Sesudah selesai aplikasi tidak
/// menampilkannya lagi (penanda onboarded di pengaturan).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.initial, required this.onDone});
  final AppSettings initial;
  final ValueChanged<AppSettings> onDone;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> with SingleTickerProviderStateMixin {
  final _page = PageController();
  late final AnimationController _float;
  int _index = 0;
  bool _wizard = false;

  final _usahaCtrl = TextEditingController();
  final _cabangCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  bool _tables = true;
  bool _kitchen = true;
  String? _error;

  static const _pages = <(String, String, String)>[
    ('assets/svg/onboarding_1.svg', 'Kasir Cepat untuk Cafe & Resto', 'Catat pesanan, pilih meja, terima tunai & QRIS. Semua tercatat rapi dan tersimpan di perangkat.'),
    ('assets/svg/onboarding_2.svg', 'Penjualan Terpantau Tiap Hari', 'Beranda menampilkan penjualan asli hari ini, grafik mingguan & bulanan, sampai laporan pajak yang terkumpul.'),
    ('assets/svg/onboarding_3.svg', 'Siap Multi-Cabang', 'Mulai dari satu cabang, tambah cabang kapan saja. Data tersimpan di perangkat dan siap disinkronkan saat online.'),
  ];

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _usahaCtrl.text = widget.initial.businessName;
    _cabangCtrl.text = widget.initial.activeBranch.name;
    _tables = widget.initial.tablesEnabled;
    _kitchen = widget.initial.kitchenEnabled;
  }

  @override
  void dispose() {
    _page.dispose();
    _float.dispose();
    _usahaCtrl.dispose();
    _cabangCtrl.dispose();
    _pinCtrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  void _finish() {
    final usaha = _usahaCtrl.text.trim();
    final cabang = _cabangCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (usaha.isEmpty) return setState(() => _error = 'Nama usaha wajib diisi.');
    if (cabang.isEmpty) return setState(() => _error = 'Nama cabang wajib diisi.');
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) return setState(() => _error = 'PIN harus 4–6 angka.');
    if (pin != _pin2Ctrl.text.trim()) return setState(() => _error = 'Konfirmasi PIN tidak sama.');
    final s = widget.initial;
    s.businessName = usaha;
    s.branches = [Branch(id: s.activeBranchId, name: cabang)];
    s.pinHash = hashPin(pin);
    s.tablesEnabled = _tables;
    s.kitchenEnabled = _kitchen;
    s.onboarded = true;
    widget.onDone(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _wizard ? _wizardView() : _pagesView(),
      ),
    );
  }

  Widget _pagesView() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextButton(
              onPressed: () => setState(() {
                    _wizard = true;
                    _float.stop();
                  }),
              child: const Text('Lewati')),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _page,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final (asset, title, desc) = _pages[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _float,
                      builder: (_, child) => Transform.translate(offset: Offset(0, -6 + 12 * _float.value), child: child),
                      child: SvgPicture.asset(asset, width: 260, height: 195),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(title, textAlign: TextAlign.center, style: AppText.pageTitle),
                    const SizedBox(height: AppSpacing.md),
                    Text(desc, textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.muted)),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _index == _pages.length - 1 ? 'Atur Cabang Pertama' : 'Lanjut',
              onPressed: () {
                if (_index == _pages.length - 1) {
                  setState(() {
                    _wizard = true;
                    _float.stop();
                  });
                } else {
                  _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _wizardView() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: const Icon(Icons.storefront_outlined, color: AppColors.accentDark, size: 28),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Atur Cabang Pertama', style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text('Tiga hal ini cukup untuk mulai jualan. Sisanya bisa diubah kapan saja di Pengaturan.', style: AppText.small.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.xl),
        TextField(controller: _usahaCtrl, decoration: const InputDecoration(labelText: 'Nama usaha', hintText: 'cth. Kopi Senja')),
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _cabangCtrl, decoration: const InputDecoration(labelText: 'Nama cabang pertama', hintText: 'cth. Cabang Utama')),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN kasir (4–6 angka)', hintText: 'Untuk persetujuan penting di kasir'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _pin2Ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Ulangi PIN'),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Memakai meja', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Matikan bila kedai tanpa meja (hanya pesan & bayar).', style: AppText.small.copyWith(color: AppColors.muted)),
                  value: _tables,
                  onChanged: (v) => setState(() => _tables = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Memakai layar dapur', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Matikan bila pesanan tidak perlu antre di dapur.', style: AppText.small.copyWith(color: AppColors.muted)),
                  value: _kitchen,
                  onChanged: (v) => setState(() => _kitchen = v),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: AppText.small.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Mulai Berjualan', icon: Icons.rocket_launch_outlined, onPressed: _finish),
      ],
    );
  }
}

/// Animasi layar penuh sesudah penyiapan selesai (permintaan Adnan
/// 2026-11-14): bundaran emerald MELEBAR menutupi layar (zoom in)
/// dengan centang + tulisan, lalu MENYUSUT lagi (zoom out) membuka
/// layar di belakangnya. Dipakai sesudah wizard pertama & wizard
/// tambah cabang.
class SetupCelebration extends StatefulWidget {
  const SetupCelebration({super.key, required this.judul, required this.subjudul, required this.onSelesai});
  final String judul;
  final String subjudul;
  final VoidCallback onSelesai;

  @override
  State<SetupCelebration> createState() => _SetupCelebrationState();
}

class _SetupCelebrationState extends State<SetupCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _dilaporkan = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))..forward();
    _ctrl.addStatusListener((st) {
      if (st == AnimationStatus.completed && !_dilaporkan) {
        _dilaporkan = true;
        widget.onSelesai();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maks = size.longestSide * 2.4;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value;
        // Fase 1 (0–0,35): bundaran melebar. Fase 3 (0,72–1):
        // bundaran menyusut sampai hilang.
        final double d;
        if (t < 0.35) {
          d = maks * Curves.easeOutCubic.transform(t / 0.35);
        } else if (t < 0.72) {
          d = maks;
        } else {
          d = maks * (1 - Curves.easeInCubic.transform((t - 0.72) / 0.28));
        }
        final kontenMasuk = t < 0.3 ? 0.0 : ((t - 0.3) / 0.15).clamp(0.0, 1.0);
        final kontenKeluar = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.12).clamp(0.0, 1.0);
        final opasitas = (kontenMasuk * kontenKeluar).clamp(0.0, 1.0);
        return SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: d,
                height: d,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
              Opacity(
                opacity: opasitas,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 3),
                      ),
                      child: Icon(Icons.check, color: AppColors.card, size: 44),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(widget.judul, textAlign: TextAlign.center, style: AppText.hero.copyWith(color: AppColors.card)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(widget.subjudul, textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.card.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
