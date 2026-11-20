import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';

/// Hub Laporan (v0.7.0): ringkasan hari ini dari ANGKA ASLI kasir
/// (dulu layar ini data contoh) + daftar semua laporan. Update
/// besar v0.11.0 menghidupkan hampir semuanya; v0.15.0
/// menuntaskan dua baris terakhir (Margin Tipis & Laporan
/// Pengunjung) — tidak ada lagi baris 'Segera'.
class LaporanScreen extends StatelessWidget {
  const LaporanScreen({
    super.key,
    required this.transactions,
    required this.branchId,
    required this.tables,
    required this.onOpenRiwayat,
    required this.onOpenBulanan,
    required this.onOpenPajak,
    required this.onOpenPiutang,
    this.onOpenLabaRugi,
    this.onOpenNeraca,
    this.onOpenArusKas,
    this.onOpenArusStok,
    this.onOpenPersediaan,
    this.onOpenPembelian,
    this.onOpenHutang,
    this.onOpenPromo,
    this.onOpenMarginTipis,
    this.onOpenPengunjung,
  });

  final List<TxRecord> transactions;
  final String branchId;
  final List<CafeTable> tables;
  final VoidCallback onOpenRiwayat;
  final VoidCallback onOpenBulanan;
  final VoidCallback onOpenPajak;
  final VoidCallback onOpenPiutang;

  /// Opsional supaya konstruksi lama (tes) tetap sah.
  final VoidCallback? onOpenLabaRugi;
  final VoidCallback? onOpenNeraca;
  final VoidCallback? onOpenArusKas;
  final VoidCallback? onOpenArusStok;
  final VoidCallback? onOpenPersediaan;
  final VoidCallback? onOpenPembelian;
  final VoidCallback? onOpenHutang;
  final VoidCallback? onOpenPromo;
  final VoidCallback? onOpenMarginTipis;
  final VoidCallback? onOpenPengunjung;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tx = transactions.where((t) => t.branchId.isEmpty || t.branchId == branchId).toList();
    // Ubin angka hanya dari transaksi Lunas (v0.23.0).
    final todayTx = tx.where((t) => t.status == 'Lunas' && t.at.year == now.year && t.at.month == now.month && t.at.day == now.day).toList();
    final omzet = todayTx.fold(0, (a, t) => a + t.total);
    final rata = todayTx.isEmpty ? 0 : (omzet / todayTx.length).round();
    final mejaTerisi = tables.where((t) => t.status != TableStatus.kosong).length;

    // Kelompok BERBOBOT (update identitas v0.12.0): ubin ikon
    // tidak lagi seragam — laporan uang memakai ubin aksen
    // pekat, stok & operasional ubin bergaris, yang belum jadi
    // ubin pudar. Mata langsung tahu mana yang inti.
    final kelompok = <(String, int, List<(IconData, String, String, VoidCallback?)>)>[
      ('Penjualan & Keuangan', 0, [
        (Ikon.receipt_long_outlined, 'Laporan Transaksi', 'Semua pembayaran tercatat, bisa disaring per periode.', onOpenRiwayat),
        (Ikon.calendar_month_outlined, 'Laporan Bulanan', 'Total penjualan 6 bulan terakhir + hari terbaik.', onOpenBulanan),
        (Ikon.account_balance_outlined, 'Laporan Pajak', 'Pajak & biaya layanan yang terkumpul per bulan.', onOpenPajak),
        (Ikon.person_outline, 'Laporan Piutang', 'Tagihan meja yang belum dibayar.', onOpenPiutang),
        (Ikon.trending_up_outlined, 'Laporan Laba Rugi', 'Pendapatan, HPP, biaya operasional & laba bersih per periode.', onOpenLabaRugi),
        (Ikon.scale_outlined, 'Neraca', 'Posisi aset, utang & modal usaha pada tanggal tertentu.', onOpenNeraca),
        (Ikon.payments_outlined, 'Arus Kas', 'Uang masuk & keluar per periode + saldo awal-akhir.', onOpenArusKas),
        (Ikon.show_chart_outlined, 'Margin Tipis', 'Menu dengan untung paling tipis dari harga jualnya.', onOpenMarginTipis),
        (Ikon.groups_outlined, 'Laporan Pengunjung', 'Jumlah tamu dari catatan kasir saat pembayaran.', onOpenPengunjung),
      ]),
      ('Stok & Operasional', 1, [
        (Ikon.swap_horiz_outlined, 'Arus Stok', 'Rekap masuk, terpakai & penyesuaian bahan per periode.', onOpenArusStok),
        (Ikon.warehouse_outlined, 'Persediaan Barang', 'Nilai stok semua bahan + status kritis & habis.', onOpenPersediaan),
        (Ikon.shopping_bag_outlined, 'Laporan Pembelian', 'Semua barang masuk gudang per periode + nilainya.', onOpenPembelian),
        (Ikon.store_outlined, 'Laporan Hutang', 'Catatan hutang usaha: tambah, lunasi, pantau jatuh tempo.', onOpenHutang),
        (Ikon.percent_outlined, 'Promo & Diskon', 'Kelola promo kasir + total diskon yang sudah diberikan.', onOpenPromo),
      ]),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(title: 'Laporan', subtitle: 'Ringkasan pemilik · angka asli dari kasir cabang ini.'),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, c) {
            final cross = c.maxWidth >= 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: 132,
              children: [
                _Stat(icon: Ikon.payments_outlined, value: rupiah(omzet), label: 'Omzet Hari Ini'),
                _Stat(icon: Ikon.receipt_outlined, value: '${todayTx.length}', label: 'Transaksi Hari Ini'),
                _Stat(icon: Ikon.calculate_outlined, value: rupiah(rata), label: 'Rata-rata / Transaksi'),
                _Stat(icon: Ikon.table_restaurant_outlined, value: '$mejaTerisi dari ${tables.length}', label: 'Meja Terisi Sekarang'),
              ],
            );
          },
        ),
        for (final (namaGrup, bobot, isi) in kelompok) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(namaGrup, style: AppText.title),
          const SizedBox(height: AppSpacing.md),
          for (final (icon, title, sub, action) in isi)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InkWell(
                onTap: action,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Row(
                  children: [
                    _UbinLaporan(icon: icon, bobot: bobot),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppText.subtitle),
                          Text(sub, style: AppText.caption.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (action != null)
                      Icon(Ikon.chevron_right, color: AppColors.muted)
                    else
                      StatusChip(label: 'Segera', color: AppColors.muted),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Ubin ikon baris laporan menurut bobot kelompoknya:
/// 0 = aksen pekat + ikon putih (inti uang), 1 = bergaris
/// aksen + ikon hijau tua, 2 = pudar (belum jadi).
class _UbinLaporan extends StatelessWidget {
  const _UbinLaporan({required this.icon, required this.bobot});
  final IconData icon;
  final int bobot;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    final (Color latar, Color warnaIkon, Border? garis) = switch (bobot) {
      0 => (AppColors.accent, Colors.white, null),
      1 => (Colors.transparent, AppColors.accentDark, Border.all(color: AppColors.accent.withValues(alpha: 0.45))),
      _ => (AppColors.track, AppColors.muted, null),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: latar, border: garis, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Icon(icon, color: warnaIkon, size: 22),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accentDark, size: 22),
          const SizedBox(height: AppSpacing.sm),
          FitNumber(value),
          Text(label, style: AppText.small.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}
