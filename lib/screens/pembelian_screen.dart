import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'laporan_bersama.dart';

/// Laporan Pembelian (update besar v0.11.0): semua barang
/// masuk gudang per periode = pembelian bahan usaha. Nilai
/// dihitung dari jumlah × harga pokok bahan SAAT INI (mutasi
/// tidak menyimpan harga saat kejadian — ditulis apa adanya
/// di catatan kaki). Lengkap dengan rekap per bahan dan
/// daftar peristiwa pembelian.
class PembelianScreen extends StatefulWidget {
  const PembelianScreen({super.key, required this.mutasi, required this.ingredients});
  final List<MutasiStok> mutasi;
  final List<Ingredient> ingredients;

  @override
  State<PembelianScreen> createState() => _PembelianScreenState();
}

class _PembelianScreenState extends State<PembelianScreen> {
  RentangPeriode _rentang = rentangBulanIni();

  @override
  Widget build(BuildContext context) {
    final hasil = ringkasPembelian(widget.mutasi, widget.ingredients, dari: _rentang.dari, sampai: _rentang.sampai);

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Pembelian Bahan')
        ..writeln('Periode: ${_rentang.label}')
        ..writeln('Total pembelian: ${rupiah(hasil.totalNilai)} (${hasil.entri.length} peristiwa)');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Pembelian',
        ringkasan: r.toString().trim(),
        kepala: const ['Tanggal', 'Bahan', 'Jumlah', 'Nilai'],
        baris: [
          for (final (m, nilai) in hasil.entri) [labelTgl(m.waktu), m.namaBahan, '${teksStok(m.jumlah)} ${m.satuan}', '$nilai'],
          ['TOTAL', '', '', '${hasil.totalNilai}'],
        ],
        catatan: 'Dari catatan barang masuk gudang. Nilai memakai harga pokok bahan saat ini.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pembelian'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          PemilihPeriode(onChanged: (r) => setState(() => _rentang = r)),
          const SizedBox(height: AppSpacing.lg),
          KartuHero(
            label: 'Total Pembelian · ${_rentang.label}',
            nilai: rupiah(hasil.totalNilai),
            keterangan: '${hasil.entri.length} peristiwa barang masuk · ${hasil.perBahan.length} jenis bahan',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (hasil.entri.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text('Tidak ada barang masuk pada periode ini. Pembelian tercatat otomatis setiap "Barang Masuk" diisi di Stok Bahan.', textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.muted)),
            ),
          if (hasil.perBahan.isNotEmpty) ...[
            const JudulSeksi(ikon: Icons.inventory_outlined, teks: 'Rekap per Bahan'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < hasil.perBahan.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    BarisNilai(
                      label: hasil.perBahan[i].$1,
                      catatan: '${teksStok(hasil.perBahan[i].$3)} ${hasil.perBahan[i].$2} masuk periode ini',
                      nilai: rupiah(hasil.perBahan[i].$4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const JudulSeksi(ikon: Icons.receipt_long_outlined, teks: 'Daftar Pembelian'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < hasil.entri.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    BarisNilai(
                      label: hasil.entri[i].$1.namaBahan,
                      catatan: '${labelTgl(hasil.entri[i].$1.waktu)} · +${teksStok(hasil.entri[i].$1.jumlah)} ${hasil.entri[i].$1.satuan}${hasil.entri[i].$1.catatan.isNotEmpty ? ' · ${hasil.entri[i].$1.catatan}' : ''}',
                      nilai: rupiah(hasil.entri[i].$2),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Catatan: pembelian = catatan "Barang Masuk" di Stok Bahan (termasuk stok awal bahan baru). Nilainya memakai harga pokok bahan SAAT INI karena catatan lama tidak menyimpan harga saat pembelian terjadi.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
