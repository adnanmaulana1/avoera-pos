import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';
import 'laporan_bersama.dart';

/// Laporan Pengunjung (v0.15.0, menuntaskan baris 'Segera'
/// terakhir di hub Laporan): jumlah tamu dari catatan kasir
/// di halaman Pembayaran. Hanya transaksi Lunas yang jumlah
/// tamunya diisi (tamu > 0) yang terhitung — transaksi tanpa
/// catatan TIDAK dianggap kunjungan kosong, jadi angka di
/// sini jujur sebagai "dari sekian transaksi yang tercatat".
class PengunjungScreen extends StatefulWidget {
  const PengunjungScreen({
    super.key,
    required this.transactions,
    required this.branchId,
    required this.branchName,
  });

  final List<TxRecord> transactions;
  final String branchId;
  final String branchName;

  @override
  State<PengunjungScreen> createState() => _PengunjungScreenState();
}

/// Angka rata-rata untuk tampilan: satu desimal koma
/// ('3,5'), bulat tanpa desimal ('4').
String teksRata(double v) {
  if (v == v.roundToDouble()) return '${v.toInt()}';
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

class _PengunjungScreenState extends State<PengunjungScreen> {
  RentangPeriode _rentang = rentangBulanIni();

  @override
  Widget build(BuildContext context) {
    final hasil = hitungPengunjung(transactions: widget.transactions, branchId: widget.branchId, dari: _rentang.dari, sampai: _rentang.sampai);

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Pengunjung — ${widget.branchName}')
        ..writeln('Periode: ${_rentang.label}')
        ..writeln('Total pengunjung: ${hasil.totalTamu} dari ${hasil.txTercatat} transaksi tercatat (${hasil.totalTransaksi} transaksi lunas)');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Pengunjung',
        ringkasan: r.toString().trim(),
        kepala: const ['Tanggal', 'Pengunjung', 'Transaksi Tercatat'],
        baris: [
          for (final h in hasil.perHari) [labelTgl(h.tanggal), '${h.tamu}', '${h.transaksi}'],
          ['TOTAL', '${hasil.totalTamu}', '${hasil.txTercatat}'],
        ],
        catatan: 'Hanya transaksi lunas yang jumlah tamunya diisi kasir saat pembayaran yang terhitung.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pengunjung'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          KartuHero(
            label: 'Total Pengunjung',
            nilai: '${hasil.totalTamu}',
            keterangan: 'Dari ${hasil.txTercatat} transaksi tercatat · ${_rentang.label}',
          ),
          const SizedBox(height: AppSpacing.lg),
          PemilihPeriode(onChanged: (r) => setState(() => _rentang = r)),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Transaksi tercatat tamu', catatan: 'Dari ${hasil.totalTransaksi} transaksi lunas pada periode ini', nilai: '${hasil.txTercatat} transaksi'),
                const GarisTipis(),
                BarisNilai(label: 'Rata-rata per transaksi', nilai: hasil.txTercatat == 0 ? '—' : '${teksRata(hasil.rataRata)} orang'),
                const GarisTipis(),
                BarisNilai(label: 'Terbanyak dalam 1 transaksi', nilai: hasil.terbanyak == 0 ? '—' : '${hasil.terbanyak} orang'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (hasil.perHari.isEmpty)
            const EmptyState(message: 'Belum ada catatan tamu pada periode ini.\nKasir mengisi jumlah tamu di halaman Pembayaran.', icon: Ikon.groups_outlined)
          else ...[
            const JudulSeksi(ikon: Ikon.calendar_month_outlined, teks: 'Rincian per hari'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < hasil.perHari.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(labelTgl(hasil.perHari[i].tanggal), style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                Text('${hasil.perHari[i].transaksi} transaksi tercatat', style: AppText.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text('${hasil.perHari[i].tamu} tamu', style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Catatan: hanya transaksi lunas yang jumlah tamunya diisi kasir yang terhitung. Transaksi sebelum fitur ini ada tidak punya catatan tamu.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
