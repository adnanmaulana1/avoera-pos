import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'laporan_bersama.dart';

/// Laporan Arus Stok (update besar v0.11.0): rekap pergerakan
/// bahan per periode dari riwayat mutasi gudang — masuk,
/// terpakai penjualan, penyesuaian opname & edit manual.
/// Riwayat mutasi tersimpan lokal (maks 800 peristiwa
/// terakhir) dan tidak terbagi per cabang.
class ArusStokScreen extends StatefulWidget {
  const ArusStokScreen({super.key, required this.mutasi});
  final List<MutasiStok> mutasi;

  @override
  State<ArusStokScreen> createState() => _ArusStokScreenState();
}

class _ArusStokScreenState extends State<ArusStokScreen> {
  RentangPeriode _rentang = rentangBulanIni();

  @override
  Widget build(BuildContext context) {
    final rekap = ringkasArusStok(widget.mutasi, dari: _rentang.dari, sampai: _rentang.sampai);
    final totalMasuk = rekap.fold(0.0, (a, r) => a + r.masuk);
    final totalPakai = rekap.fold(0.0, (a, r) => a + r.terpakai);
    final totalPeristiwa = rekap.fold(0, (a, r) => a + r.peristiwa);

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Arus Stok')
        ..writeln('Periode: ${_rentang.label}')
        ..writeln('${rekap.length} bahan bergerak · $totalPeristiwa peristiwa');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Arus Stok',
        ringkasan: r.toString().trim(),
        kepala: const ['Bahan', 'Masuk', 'Terpakai', 'Opname', 'Edit', 'Bersih'],
        baris: [
          for (final b in rekap) [b.nama, teksStok(b.masuk), teksStok(b.terpakai), teksStokBertanda(b.opname), teksStokBertanda(b.edit), teksStokBertanda(b.perubahanBersih)],
        ],
        catatan: 'Dari riwayat mutasi gudang di perangkat ini (maks 800 peristiwa terakhir). Satuan mengikuti satuan masing-masing bahan.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Arus Stok'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          PemilihPeriode(onChanged: (r) => setState(() => _rentang = r)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _KartuRingkasan(label: 'Jenis Bahan Bergerak', nilai: '${rekap.length}')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _KartuRingkasan(label: 'Peristiwa Tercatat', nilai: '$totalPeristiwa')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _KartuRingkasan(label: 'Total Masuk (semua satuan)', nilai: teksStok(totalMasuk))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _KartuRingkasan(label: 'Total Terpakai Jualan', nilai: teksStok(totalPakai))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rekap.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text('Tidak ada pergerakan stok pada periode ini.', textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.muted)),
            ),
          for (final b in rekap) ...[
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(b.nama, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink))),
                      StatusChip(label: '${b.peristiwa} peristiwa', color: AppColors.muted),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Mini(label: 'Masuk', nilai: '${teksStok(b.masuk)} ${b.satuan}'),
                      _Mini(label: 'Terpakai', nilai: '${teksStok(b.terpakai)} ${b.satuan}'),
                      _Mini(label: 'Opname', nilai: '${teksStokBertanda(b.opname)} ${b.satuan}'),
                      _Mini(label: 'Edit', nilai: '${teksStokBertanda(b.edit)} ${b.satuan}'),
                      _Mini(label: 'Bersih', nilai: '${teksStokBertanda(b.perubahanBersih)} ${b.satuan}', tebal: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Text(
            'Catatan: dari riwayat mutasi gudang di perangkat ini — barang masuk, potongan penjualan otomatis, opname, dan edit manual. Riwayat menyimpan maksimal 800 peristiwa terakhir dan tidak terbagi per cabang.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _KartuRingkasan extends StatelessWidget {
  const _KartuRingkasan({required this.label, required this.nilai});
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xs),
          Text(nilai, style: AppText.number.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.nilai, this.tebal = false});
  final String label;
  final String nilai;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption.copyWith(color: AppColors.muted)),
        Text(nilai, style: AppText.small.copyWith(fontWeight: tebal ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }
}
