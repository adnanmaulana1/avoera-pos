import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'laporan_bersama.dart';

/// Laporan Persediaan Barang (update besar v0.11.0): nilai
/// stok semua bahan dari stok × harga pokok terkini, lengkap
/// dengan status stok (Aman / Kritis / Habis) terhadap batas
/// minimum masing-masing bahan. Saring per status.
class PersediaanScreen extends StatefulWidget {
  const PersediaanScreen({super.key, required this.ingredients});
  final List<Ingredient> ingredients;

  @override
  State<PersediaanScreen> createState() => _PersediaanScreenState();
}

class _PersediaanScreenState extends State<PersediaanScreen> {
  String _saring = 'semua'; // semua | kritis | habis

  String _status(Ingredient i) => i.stock <= 0 ? 'Habis' : (i.stock <= i.minStock ? 'Kritis' : 'Aman');
  Color _warnaStatus(String s) => s == 'Habis' ? AppColors.danger : (s == 'Kritis' ? AppColors.warning : AppColors.accentDark);

  @override
  Widget build(BuildContext context) {
    final (total, rincian) = nilaiPersediaan(widget.ingredients);
    final jumlahKritis = widget.ingredients.where((i) => _status(i) == 'Kritis').length;
    final jumlahHabis = widget.ingredients.where((i) => _status(i) == 'Habis').length;
    final tampil = rincian.where((r) {
      if (_saring == 'kritis') return _status(r.bahan) == 'Kritis';
      if (_saring == 'habis') return _status(r.bahan) == 'Habis';
      return true;
    }).toList();

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Persediaan Barang')
        ..writeln('Total nilai persediaan: ${rupiah(total)} (${widget.ingredients.length} bahan)')
        ..writeln('Kritis: $jumlahKritis · Habis: $jumlahHabis');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Persediaan',
        ringkasan: r.toString().trim(),
        kepala: const ['Bahan', 'Stok', 'Harga Pokok', 'Nilai', 'Status'],
        baris: [
          for (final b in rincian) [b.bahan.name, '${teksStok(b.stok)} ${b.satuan}', '${b.hargaPokok}', '${b.nilai}', _status(b.bahan)],
          ['TOTAL', '', '', '$total', ''],
        ],
        catatan: 'Nilai = stok terkini × harga pokok terkini. Status Kritis bila stok ≤ batas minimum bahan.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persediaan Barang'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          KartuHero(
            label: 'Total Nilai Persediaan',
            nilai: rupiah(total),
            keterangan: '${widget.ingredients.length} bahan · $jumlahKritis kritis · $jumlahHabis habis',
          ),
          const SizedBox(height: AppSpacing.lg),
          FilterChipRow(
            children: [
              AppChip(label: 'Semua', selected: _saring == 'semua', onSelected: (_) => setState(() => _saring = 'semua')),
              AppChip(label: 'Kritis ($jumlahKritis)', selected: _saring == 'kritis', onSelected: (_) => setState(() => _saring = 'kritis')),
              AppChip(label: 'Habis ($jumlahHabis)', selected: _saring == 'habis', onSelected: (_) => setState(() => _saring = 'habis')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tampil.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                _saring == 'semua' ? 'Belum ada bahan tercatat.' : 'Tidak ada bahan berstatus ${_saring == 'kritis' ? 'Kritis' : 'Habis'}. Bagus — stok aman.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.muted),
              ),
            ),
          if (tampil.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < tampil.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text(tampil[i].bahan.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink), overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: AppSpacing.sm),
                                    StatusChip(label: _status(tampil[i].bahan), color: _warnaStatus(_status(tampil[i].bahan))),
                                  ],
                                ),
                                Text(
                                  '${teksStok(tampil[i].stok)} ${tampil[i].satuan} × ${rupiah(tampil[i].hargaPokok)} · min. ${teksStok(tampil[i].bahan.minStock)} ${tampil[i].satuan}',
                                  style: AppText.caption.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(rupiah(tampil[i].nilai), style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Catatan: nilai persediaan = stok saat ini × harga pokok (harga beli terakhir) masing-masing bahan. Status Kritis bila stok sudah di bawah batas minimum yang diatur di Stok Bahan.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
