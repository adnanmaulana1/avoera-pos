import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'laporan_bersama.dart';

/// Laporan Arus Kas (update besar v0.11.0): uang masuk &
/// keluar per periode dari catatan aplikasi. Masuk: penjualan
/// tunai & QRIS lunas + hutang baru. Keluar: pembelian bahan
/// (barang masuk gudang), pengeluaran operasional, pelunasan
/// hutang. Saldo awal dihitung dengan aturan yang sama dari
/// semua catatan sebelum periode, jadi saldo akhir konsisten.
class ArusKasScreen extends StatefulWidget {
  const ArusKasScreen({
    super.key,
    required this.transactions,
    required this.expenses,
    required this.mutasi,
    required this.ingredients,
    required this.hutang,
    required this.branchId,
    required this.branchName,
  });

  final List<TxRecord> transactions;
  final List<Pengeluaran> expenses;
  final List<MutasiStok> mutasi;
  final List<Ingredient> ingredients;
  final List<Hutang> hutang;
  final String branchId;
  final String branchName;

  @override
  State<ArusKasScreen> createState() => _ArusKasScreenState();
}

class _ArusKasScreenState extends State<ArusKasScreen> {
  RentangPeriode _rentang = rentangBulanIni();

  @override
  Widget build(BuildContext context) {
    final hasil = hitungArusKas(
      transactions: widget.transactions,
      expenses: widget.expenses,
      mutasi: widget.mutasi,
      ingredients: widget.ingredients,
      hutang: widget.hutang,
      branchId: widget.branchId,
      dari: _rentang.dari,
      sampai: _rentang.sampai,
    );

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Arus Kas — ${widget.branchName}')
        ..writeln('Periode: ${_rentang.label}')
        ..writeln('Saldo Awal: ${rupiah(hasil.saldoAwal)}')
        ..writeln('Total Masuk: ${rupiah(hasil.totalMasuk)}')
        ..writeln('Total Keluar: ${rupiah(hasil.totalKeluar)}')
        ..writeln('Arus Bersih: ${rupiah(hasil.arusBersih)}')
        ..writeln('Saldo Akhir: ${rupiah(hasil.saldoAkhir)}');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Arus Kas',
        ringkasan: r.toString().trim(),
        kepala: const ['Komponen', 'Jumlah'],
        baris: [
          ['Saldo Awal', '${hasil.saldoAwal}'],
          ['Penjualan Tunai', '${hasil.masukTunai}'],
          ['Penjualan QRIS', '${hasil.masukQris}'],
          ['Hutang Baru', '${hasil.hutangBaru}'],
          ['Pembelian Bahan', '${hasil.pembelianBahan}'],
          ['Biaya Operasional', '${hasil.biayaOperasional}'],
          ['Pelunasan Hutang', '${hasil.bayarHutang}'],
          ['Arus Bersih', '${hasil.arusBersih}'],
          ['Saldo Akhir', '${hasil.saldoAkhir}'],
        ],
        catatan: 'Dari catatan aplikasi: kasir, gudang, pengeluaran & hutang. Pembelian bahan dinilai harga pokok kini dan mencakup semua cabang.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Arus Kas'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          PemilihPeriode(onChanged: (r) => setState(() => _rentang = r)),
          const SizedBox(height: AppSpacing.lg),
          KartuHero(
            label: 'Arus Bersih · ${_rentang.label}',
            nilai: rupiah(hasil.arusBersih),
            keterangan: 'Saldo awal ${rupiah(hasil.saldoAwal)} → Saldo akhir ${rupiah(hasil.saldoAkhir)}',
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.arrow_downward_outlined, teks: 'Uang Masuk'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Penjualan Tunai', catatan: 'Transaksi tunai lunas di kasir', nilai: rupiah(hasil.masukTunai)),
                const GarisTipis(),
                BarisNilai(label: 'Penjualan QRIS', catatan: 'Transaksi QRIS lunas (sebelum biaya di luar aplikasi)', nilai: rupiah(hasil.masukQris)),
                const GarisTipis(),
                BarisNilai(label: 'Hutang Baru', catatan: 'Hutang yang dicatat pada periode ini', nilai: rupiah(hasil.hutangBaru)),
                const GarisTipis(),
                BarisNilai(label: 'Total Masuk', nilai: rupiah(hasil.totalMasuk), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.arrow_upward_outlined, teks: 'Uang Keluar'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Pembelian Bahan', catatan: 'Nilai barang masuk gudang · harga pokok kini · semua cabang', nilai: rupiah(hasil.pembelianBahan)),
                const GarisTipis(),
                BarisNilai(label: 'Biaya Operasional', catatan: 'Pengeluaran tercatat di Laba Rugi', nilai: rupiah(hasil.biayaOperasional)),
                for (final (kat, total) in hasil.rincianBiaya) ...[
                  const GarisTipis(),
                  BarisNilai(label: '· $kat', nilai: rupiah(total)),
                ],
                const GarisTipis(),
                BarisNilai(label: 'Pelunasan Hutang', catatan: 'Hutang yang ditandai lunas pada periode ini', nilai: rupiah(hasil.bayarHutang)),
                const GarisTipis(),
                BarisNilai(label: 'Total Keluar', nilai: rupiah(hasil.totalKeluar), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.account_balance_outlined, teks: 'Saldo'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Saldo Awal Periode', catatan: 'Akumulasi semua catatan sebelum periode ini', nilai: rupiah(hasil.saldoAwal)),
                const GarisTipis(),
                BarisNilai(label: 'Arus Bersih Periode', nilai: rupiah(hasil.arusBersih)),
                const GarisTipis(),
                BarisNilai(label: 'Saldo Akhir Periode', nilai: rupiah(hasil.saldoAkhir), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Catatan: arus kas ini perkiraan dari catatan aplikasi (kasir, gudang, pengeluaran, hutang). Uang yang bergerak di luar aplikasi tidak tercatat. Saldo adalah saldo gabungan tunai + QRIS menurut catatan.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
