import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

/// Potongan bersama layar-layar laporan (dipakai Neraca,
/// Arus Kas, Arus Stok, Pembelian, Hutang, Promo — update
/// besar v0.11.0): nama bulan, pemilih periode, baris nilai,
/// dan garis tipis. Laba Rugi punya salinannya sendiri yang
/// lebih dulu ada; layar baru memakai yang di sini.

const bulanId = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

String labelTgl(DateTime d) => '${d.day} ${bulanId[d.month - 1]} ${d.year}';

/// Rentang tanggal terpilih + label tampilnya.
typedef RentangPeriode = ({DateTime dari, DateTime sampai, String label});

RentangPeriode rentangBulanIni() {
  final now = DateTime.now();
  return (dari: DateTime(now.year, now.month), sampai: DateTime(now.year, now.month + 1, 0), label: '${bulanId[now.month - 1]} ${now.year}');
}

/// Pilihan periode standar laporan: Bulan Ini / Bulan Lalu /
/// Hari Ini / Pilih Tanggal. Memanggil [onChanged] setiap
/// pilihan berubah (keadaan awal "Bulan Ini" dianggap sudah
/// diketahui pemanggil — samakan dengan [rentangBulanIni]).
class PemilihPeriode extends StatefulWidget {
  const PemilihPeriode({super.key, required this.onChanged});
  final ValueChanged<RentangPeriode> onChanged;

  @override
  State<PemilihPeriode> createState() => _PemilihPeriodeState();
}

class _PemilihPeriodeState extends State<PemilihPeriode> {
  String _mode = 'bulan-ini';
  DateTimeRange? _rentang;

  void _terapkan(String mode, DateTimeRange? rentang) {
    final now = DateTime.now();
    final RentangPeriode hasil;
    if (mode == 'bulan-lalu') {
      final m = DateTime(now.year, now.month - 1);
      hasil = (dari: m, sampai: DateTime(m.year, m.month + 1, 0), label: '${bulanId[m.month - 1]} ${m.year}');
    } else if (mode == 'hari-ini') {
      final t = DateTime(now.year, now.month, now.day);
      hasil = (dari: t, sampai: t, label: 'Hari ini · ${labelTgl(t)}');
    } else if (mode == 'rentang' && rentang != null) {
      hasil = (dari: rentang.start, sampai: rentang.end, label: '${labelTgl(rentang.start)} – ${labelTgl(rentang.end)}');
    } else {
      hasil = rentangBulanIni();
    }
    setState(() {
      _mode = mode;
      _rentang = rentang;
    });
    widget.onChanged(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return FilterChipRow(
      children: [
        AppChip(label: 'Bulan Ini', selected: _mode == 'bulan-ini', onSelected: (_) => _terapkan('bulan-ini', null)),
        AppChip(label: 'Bulan Lalu', selected: _mode == 'bulan-lalu', onSelected: (_) => _terapkan('bulan-lalu', null)),
        AppChip(label: 'Hari Ini', selected: _mode == 'hari-ini', onSelected: (_) => _terapkan('hari-ini', null)),
        AppChip(
          label: 'Pilih Tanggal',
          selected: _mode == 'rentang',
          onSelected: (_) async {
            final hasil = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2023),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: _rentang,
              helpText: 'Pilih rentang tanggal',
            );
            if (hasil != null && mounted) _terapkan('rentang', hasil);
          },
        ),
      ],
    );
  }
}

/// Satu baris "label — nilai" di kartu laporan. [nilai] sudah
/// diformat pemanggil (mis. rupiah(...)) supaya bisa juga
/// berisi teks seperti '3 catatan'.
class BarisNilai extends StatelessWidget {
  const BarisNilai({super.key, required this.label, this.catatan, required this.nilai, this.tebal = false, this.warnaNilai});
  final String label;
  final String? catatan;
  final String nilai;
  final bool tebal;
  final Color? warnaNilai;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body.copyWith(fontWeight: tebal ? FontWeight.w700 : FontWeight.w600, color: AppColors.ink)),
                if (catatan != null) Text(catatan!, style: AppText.caption.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(nilai, style: (tebal ? AppText.subtitle : AppText.body).copyWith(fontWeight: FontWeight.w700, color: warnaNilai ?? AppColors.ink)),
        ],
      ),
    );
  }
}

/// Garis pemisah tipis di dalam kartu laporan.
class GarisTipis extends StatelessWidget {
  const GarisTipis({super.key});
  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return Divider(height: 1, thickness: 0.7, color: AppColors.border.withValues(alpha: 0.6));
  }
}

/// Judul seksi di dalam kartu laporan (ikon + teks).
class JudulSeksi extends StatelessWidget {
  const JudulSeksi({super.key, required this.ikon, required this.teks});
  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return Row(
      children: [
        Icon(ikon, size: 19, color: AppColors.accentDark),
        const SizedBox(width: AppSpacing.sm),
        Text(teks, style: AppText.subtitle.copyWith(color: AppColors.ink)),
      ],
    );
  }
}

/// Kartu pahlawan (hero) hijau emerald di puncak laporan:
/// angka utama besar + keterangan. Dipakai Neraca & Arus Kas.
class KartuHero extends StatelessWidget {
  const KartuHero({super.key, required this.label, required this.nilai, required this.keterangan});
  final String label;
  final String nilai;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.small.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(nilai, style: AppText.number.copyWith(color: Colors.white, fontSize: 26)),
          const SizedBox(height: AppSpacing.xs),
          Text(keterangan, style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// Nilai stok untuk tampilan: bilangan bulat tanpa desimal,
/// pecahan dengan maksimal 1 desimal (selaras stockText).
String teksStok(double v) {
  if (v == v.roundToDouble()) return '${v.toInt()}';
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

/// Format bertanda untuk perubahan stok: +5 / -2,5 / 0.
String teksStokBertanda(double v) {
  if (v > 0) return '+${teksStok(v)}';
  if (v < 0) return '-${teksStok(-v)}';
  return '0';
}
