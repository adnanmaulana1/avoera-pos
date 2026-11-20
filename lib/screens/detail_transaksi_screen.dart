import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';

/// Halaman detail satu transaksi — dibuka dengan mengetuk
/// baris di Riwayat Transaksi (permintaan Adnan 2026-11-15).
/// Isi: kepala (id, metode, waktu, cabang, status lunas),
/// total, rincian pesanan, dan rincian uang.
///
/// Rincian pesanan hanya ada untuk transaksi sejak v0.10.6
/// (sebelumnya yang tersimpan hanya jumlah item) — transaksi
/// lama menampilkan jumlah item + catatan jujur.
class DetailTransaksiScreen extends StatelessWidget {
  const DetailTransaksiScreen({super.key, required this.tx, this.branchName = '', this.onLihatStruk, this.onUbahStatusTx});

  final TxRecord tx;
  final String branchName;

  /// Pintu ke Pratinjau Struk (v0.15.0). Null = tombol
  /// struk tidak tampil (konstruksi lama/tes).
  final VoidCallback? onLihatStruk;

  /// Alur Batal/Refund (v0.23.0): dipanggil dengan status
  /// baru ('Batal'/'Refund') sesudah pengguna mengonfirmasi.
  /// Null = tombol kelola tidak tampil.
  final void Function(TxRecord tx, String statusBaru)? onUbahStatusTx;

  static const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  String get _waktu {
    final a = tx.at;
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${a.day} ${_bulan[a.month - 1]} ${a.year} · ${dua(a.hour)}:${dua(a.minute)}';
  }

  Widget _barisUang(String label, int nilai, {bool tebal = false}) {
    final gayaLabel = tebal ? AppText.body.copyWith(fontWeight: FontWeight.w700) : AppText.body;
    final gayaNilai = tebal ? AppText.body.copyWith(fontWeight: FontWeight.w800) : AppText.body.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gayaLabel)),
          Text(rupiah(nilai), style: gayaNilai),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeLatar, badgeTeks) = switch (tx.status) {
      'Batal' => ('Batal', AppColors.danger.withValues(alpha: AppColors.gelap ? 0.25 : 0.10), AppColors.danger),
      'Refund' => ('Refund', AppColors.warningSoft, AppColors.warning),
      'Belum bayar' => ('Belum bayar', AppColors.track, AppColors.muted),
      _ => ('Lunas', AppColors.accentSoft, AppColors.accentDark),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          // Kepala: ikon metode, id, waktu & cabang, status.
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Icon(tx.method == 'QRIS' ? Ikon.qr_code_2_outlined : Ikon.payments_outlined, color: AppColors.accentDark, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${tx.id} · ${tx.method}', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      Text(_waktu, style: AppText.caption.copyWith(color: AppColors.muted)),
                      if (branchName.isNotEmpty) Text('Cabang $branchName', style: AppText.caption.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeLatar, borderRadius: BorderRadius.circular(999)),
                  child: Text(badgeLabel, style: AppText.caption.copyWith(color: badgeTeks, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Total bayar — hijau emerald seperti halaman pembayaran.
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Row(
              children: [
                Expanded(
                  child: Text('Total bayar', style: AppText.small.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                ),
                Text(rupiah(tx.total), style: AppText.number.copyWith(color: Colors.white)),
              ],
            ),
          ),
          if (tx.status != 'Lunas') ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Ikon.info_outline, size: 16, color: badgeTeks),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tx.status == 'Belum bayar'
                        ? 'Transaksi ini belum dibayar.'
                        : 'Transaksi ini sudah ditandai ${tx.status} — tidak dihitung di omzet, laporan, dan sesi kasir.',
                    style: AppText.caption.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('Rincian Pesanan'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: tx.lines.isNotEmpty
                ? Column(
                    children: [
                      for (var i = 0; i < tx.lines.length; i++) ...[
                        if (i > 0) const Divider(height: 17),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                              child: Text('×${tx.lines[i].qty}', textAlign: TextAlign.center, style: AppText.caption.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.lines[i].nama, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  if (tx.lines[i].keterangan.isNotEmpty) Text(tx.lines[i].keterangan, style: AppText.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Text(rupiah(tx.lines[i].total), style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Jumlah item', style: AppText.body)),
                          Text('${tx.items} item', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Transaksi ini dibuat sebelum rincian item disimpan, jadi nama pesanannya tidak tercatat.',
                        style: AppText.caption.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('Rincian Pembayaran'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _barisUang('Subtotal', tx.subtotal),
                _barisUang('Biaya layanan', tx.service),
                _barisUang('Pajak', tx.tax),
                if (tx.diskon > 0) _barisUang('Diskon${tx.promoNama.isNotEmpty ? ' · ${tx.promoNama}' : ' promo'}', -tx.diskon),
                if (tx.tamu > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Jumlah tamu', style: AppText.body)),
                        Text('${tx.tamu} orang', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const Divider(height: 17),
                _barisUang('Total', tx.total, tebal: true),
              ],
            ),
          ),
          if (onLihatStruk != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Lihat Struk', icon: Ikon.print_outlined, onPressed: onLihatStruk),
          ],
          if (tx.status == 'Lunas' && onUbahStatusTx != null) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle('Kelola Transaksi'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _BarisKelola(
                    ikon: Ikon.undo,
                    warna: AppColors.warning,
                    label: 'Refund Transaksi',
                    keterangan: 'Uang dikembalikan ke pelanggan.',
                    onTap: () => _konfirmasi(context, 'Refund'),
                  ),
                  const Divider(height: 1, indent: 60),
                  _BarisKelola(
                    ikon: Ikon.block_outlined,
                    warna: AppColors.danger,
                    label: 'Batalkan Transaksi',
                    keterangan: 'Anggap transaksi ini tidak pernah terjadi.',
                    onTap: () => _konfirmasi(context, 'Batal'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _konfirmasi(BuildContext context, String statusBaru) async {
    final jadi = await showKonfirmasiStatusTx(context, tx: tx, statusBaru: statusBaru);
    if (!jadi || !context.mounted) return;
    onUbahStatusTx!(tx, statusBaru);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// Satu baris aksi di kartu Kelola Transaksi.
class _BarisKelola extends StatelessWidget {
  const _BarisKelola({required this.ikon, required this.warna, required this.label, required this.keterangan, required this.onTap});

  final IconData ikon;
  final Color warna;
  final String label;
  final String keterangan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: warna.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(ikon, size: 19, color: warna),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: warna)),
                  Text(keterangan, style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Ikon.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Dialog konfirmasi Batal/Refund: menyebut akibatnya dengan
/// jujur sebelum status benar-benar diubah (keputusan ini
/// tidak bisa dibatalkan).
Future<bool> showKonfirmasiStatusTx(BuildContext context, {required TxRecord tx, required String statusBaru}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(statusBaru == 'Refund' ? 'Refund Transaksi?' : 'Batalkan Transaksi?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaksi ${tx.id} sebesar ${rupiah(tx.total)} akan ditandai ${statusBaru == 'Refund' ? 'Refund' : 'Batal'}.', style: AppText.body),
          const SizedBox(height: AppSpacing.md),
          Text(
            tx.lines.isNotEmpty
                ? '• Stok bahan dari resep pesanan ini dikembalikan.\n• Transaksi tidak dihitung lagi di omzet, laporan, dan sesi kasir.\n• Keputusan ini tidak bisa dibatalkan.'
                : '• Transaksi lama ini tidak punya rincian pesanan, jadi stok bahan tidak bisa dikembalikan otomatis.\n• Transaksi tidak dihitung lagi di omzet, laporan, dan sesi kasir.\n• Keputusan ini tidak bisa dibatalkan.',
            style: AppText.small.copyWith(color: AppColors.muted),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Kembali')),
        PrimaryButton(
          label: statusBaru == 'Refund' ? 'Ya, Refund' : 'Ya, Batalkan',
          backgroundColor: AppColors.danger,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return hasil ?? false;
}
