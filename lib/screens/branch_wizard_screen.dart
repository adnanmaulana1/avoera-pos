import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart' show FormLabel, FormSheet;
import 'onboarding_screen.dart' show SetupCelebration;
import '../ikon.dart';

/// Wizard tambah cabang (permintaan Adnan 2026-11-14: tambah cabang
/// pakai wizard + penyiapan ala onboarding, bukan dialog satu kolom):
/// langkah 1 isi detail cabang, langkah 2 periksa ringkasan, selesai
/// dengan animasi bundaran "Cabang Siap".
class BranchWizardScreen extends StatefulWidget {
  const BranchWizardScreen({super.key, required this.onCreate});
  final void Function(Branch branch, bool langsungAktif) onCreate;

  @override
  State<BranchWizardScreen> createState() => _BranchWizardScreenState();
}

class _BranchWizardScreenState extends State<BranchWizardScreen> {
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  int _langkah = 0;
  bool _langsungAktif = true;
  bool _selesai = false;
  String? _error;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Branch get _cabang => Branch(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        name: _namaCtrl.text.trim(),
        address: _alamatCtrl.text.trim(),
        phone: _teleponCtrl.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    return GuardBack(
      dirty: () => _namaCtrl.text.isNotEmpty || _alamatCtrl.text.isNotEmpty || _teleponCtrl.text.isNotEmpty,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tambah Cabang')),
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, paddingBawahAman(context, AppSpacing.xl)),
              children: [
                Row(
                  children: [
                    _TitikLangkah(nomor: 1, label: 'Detail Cabang', aktif: _langkah == 0, beres: _langkah > 0),
                    const Expanded(child: Divider()),
                    _TitikLangkah(nomor: 2, label: 'Periksa', aktif: _langkah == 1, beres: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_langkah == 0) ..._form() else ..._ringkasan(),
              ],
            ),
            if (_selesai)
              Positioned.fill(
                child: Container(
                  color: AppColors.bg,
                  child: SetupCelebration(
                    judul: 'Cabang Siap!',
                    subjudul: _cabang.name,
                    onSelesai: () {
                      widget.onCreate(_cabang, _langsungAktif);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _form() => [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: const Icon(Ikon.add_business_outlined, color: AppColors.accentDark, size: 28),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Cabang Baru', style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text('Cabang baru memakai menu & stok yang sama (menu pusat). Penjualannya tercatat terpisah per cabang.', style: AppText.small.copyWith(color: AppColors.muted)),
        const SizedBox(height: AppSpacing.xl),
        const FormLabel('Nama Cabang'),
        TextField(controller: _namaCtrl, decoration: const InputDecoration(hintText: 'cth. Cabang Wonomulyo')),
        const SizedBox(height: AppSpacing.md),
        const FormLabel('Alamat Cabang'),
        TextField(controller: _alamatCtrl, decoration: const InputDecoration(hintText: 'cth. Jl. Poros Majene No. 5')),
        const SizedBox(height: AppSpacing.md),
        const FormLabel('Telepon / WhatsApp'),
        TextField(controller: _teleponCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Boleh kosong')),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: AppText.small.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Lanjut',
          onPressed: () {
            if (_namaCtrl.text.trim().isEmpty) {
              setState(() => _error = 'Nama cabang wajib diisi.');
              return;
            }
            setState(() {
              _error = null;
              _langkah = 1;
            });
          },
        ),
      ];

  List<Widget> _ringkasan() => [
        Text('Periksa Cabang Baru', style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BarisRingkasan('Nama cabang', _cabang.name),
              const Divider(height: AppSpacing.lg),
              _BarisRingkasan('Alamat', _cabang.address.isEmpty ? '—' : _cabang.address),
              const Divider(height: AppSpacing.lg),
              _BarisRingkasan('Telepon', _cabang.phone.isEmpty ? '—' : _cabang.phone),
              const Divider(height: AppSpacing.lg),
              _BarisRingkasan('Menu & stok', 'Mengikuti menu pusat'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              title: Text('Langsung jadikan cabang aktif', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('Sesudah dibuat, kasir langsung mencatat penjualan di cabang ini.', style: AppText.small.copyWith(color: AppColors.muted)),
              value: _langsungAktif,
              onChanged: (v) => setState(() => _langsungAktif = v),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(onPressed: () => setState(() => _langkah = 0), child: const Text('Kembali')),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(label: 'Buat Cabang', icon: Ikon.add_business_outlined, onPressed: () => setState(() => _selesai = true)),
            ),
          ],
        ),
      ];
}

class _TitikLangkah extends StatelessWidget {
  const _TitikLangkah({required this.nomor, required this.label, required this.aktif, required this.beres});
  final int nomor;
  final String label;
  final bool aktif;
  final bool beres;

  @override
  Widget build(BuildContext context) {
    final warna = (aktif || beres) ? AppColors.accent : AppColors.border;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
          child: Center(
            // Langkah beres ditandai titik isi, BUKAN centang
            // (aturan permanen Adnan: tanpa ikon centang).
            child: beres
                ? Icon(Ikon.circle, size: 10, color: AppColors.card)
                : Text('$nomor', style: AppText.small.copyWith(color: aktif ? AppColors.card : AppColors.muted, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppText.small.copyWith(fontWeight: FontWeight.w700, color: (aktif || beres) ? AppColors.ink : AppColors.muted)),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

class _BarisRingkasan extends StatelessWidget {
  const _BarisRingkasan(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: AppText.small.copyWith(color: AppColors.muted))),
        Expanded(child: Text(value, style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

/// Sheet ubah cabang (nama, alamat, telepon) dari Pengaturan —
/// id cabang tidak berubah, jadi transaksi lama tetap nyambung.
/// Lahir dari kejadian 2026-11-17: nama cabang tertimpa saat
/// sambutan awal sesudah install ulang dan tidak ada jalan
/// membetulkannya dari aplikasi.
Future<void> showUbahCabangSheet(
  BuildContext context, {
  required Branch awal,
  required ValueChanged<Branch> onSimpan,
}) async {
  final namaCtrl = TextEditingController(text: awal.name);
  final alamatCtrl = TextEditingController(text: awal.address);
  final teleponCtrl = TextEditingController(text: awal.phone);
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return FormSheet(
          title: 'Ubah Cabang',
          showClose: true,
          saveLabel: 'Simpan Perubahan',
          errorText: error,
          onSave: () {
            final nama = namaCtrl.text.trim();
            if (nama.isEmpty) {
              setSheet(() => error = 'Nama cabang belum diisi.');
              return;
            }
            Navigator.of(ctx).pop();
            onSimpan(Branch(
              id: awal.id,
              name: nama,
              address: alamatCtrl.text.trim(),
              phone: teleponCtrl.text.trim(),
            ));
          },
          children: [
            const FormLabel('Nama Cabang'),
            TextField(
              controller: namaCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Contoh: Cabang Utama'),
              onChanged: (_) {
                if (error != null) setSheet(() => error = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const FormLabel('Alamat'),
            TextField(
              controller: alamatCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Boleh kosong'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const FormLabel('Telepon'),
            TextField(
              controller: teleponCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Boleh kosong'),
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([namaCtrl, alamatCtrl, teleponCtrl]);
}
