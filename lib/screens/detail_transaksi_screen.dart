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
  const DetailTransaksiScreen({super.key, required this.tx, this.branchName = ''});

  final TxRecord tx;
  final String branchName;

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
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text('Lunas', style: AppText.caption.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
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
                const Divider(height: 17),
                _barisUang('Total', tx.total, tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
