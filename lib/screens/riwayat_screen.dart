import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';

/// Riwayat Transaksi = Laporan Transaksi: semua pembayaran yang
/// tercatat, bisa disaring per periode. Dibuka dari Beranda
/// (Lihat Semua) dan dari hub Laporan.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, required this.transactions, required this.branchId});
  final List<TxRecord> transactions;
  final String branchId;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  int _filter = 0; // 0 semua, 1 hari ini, 2 minggu ini, 3 bulan ini
  String _metode = 'Semua'; // Semua / Tunai / QRIS

  static const _bulanSingkat = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var list = widget.transactions.where((t) => t.branchId.isEmpty || t.branchId == widget.branchId).toList();
    if (_filter == 1) {
      list = list.where((t) => t.at.year == now.year && t.at.month == now.month && t.at.day == now.day).toList();
    } else if (_filter == 2) {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      list = list.where((t) => !t.at.isBefore(start)).toList();
    } else if (_filter == 3) {
      list = list.where((t) => t.at.year == now.year && t.at.month == now.month).toList();
    }
    if (_metode != 'Semua') {
      list = list.where((t) => t.method == _metode).toList();
    }
    list.sort((a, b) => b.at.compareTo(a.at));
    final total = list.fold(0, (a, t) => a + t.total);

    String dua(int n) => n.toString().padLeft(2, '0');
    Future<void> ekspor() {
      final ringkasan = StringBuffer('Riwayat Transaksi (${list.length} transaksi)\n');
      for (final t in list) {
        ringkasan.writeln('• ${t.at.day}/${t.at.month}/${t.at.year} ${dua(t.at.hour)}:${dua(t.at.minute)} · ${t.id} · ${t.method} — ${rupiah(t.total)}');
      }
      ringkasan.writeln('Total: ${rupiah(total)}');
      return tampilkanMenuEkspor(
        context,
        judul: 'Riwayat Transaksi',
        ringkasan: ringkasan.toString().trim(),
        kepala: const ['Tanggal', 'Jam', 'ID', 'Metode', 'Item', 'Subtotal', 'Biaya Layanan', 'Pajak', 'Total'],
        baris: [
          for (final t in list)
            [
              '${t.at.day}/${t.at.month}/${t.at.year}',
              '${dua(t.at.hour)}:${dua(t.at.minute)}',
              t.id,
              t.method,
              '${t.items}',
              '${t.subtotal}',
              '${t.service}',
              '${t.tax}',
              '${t.total}',
            ],
        ],
        catatan: 'Total periode: ${rupiah(total)}',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: FilterChipRow(
              children: [
                for (final (i, label) in [(0, 'Semua'), (1, 'Hari Ini'), (2, 'Minggu Ini'), (3, 'Bulan Ini')])
                  AppChip(label: label, selected: _filter == i, onSelected: (_) => setState(() => _filter = i)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: FilterChipRow(
              children: [
                for (final m in ['Semua', 'Tunai', 'QRIS'])
                  AppChip(label: m == 'Semua' ? 'Semua Metode' : m, selected: _metode == m, onSelected: (_) => setState(() => _metode = m)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total periode ini', style: AppText.small.copyWith(color: AppColors.muted)),
                        FitNumber(rupiah(total)),
                      ],
                    ),
                  ),
                  Text('${list.length} transaksi', style: AppText.small.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(message: 'Belum ada transaksi pada periode ini.', icon: Icons.receipt_long_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final t = list[i];
                      final jam = '${t.at.hour.toString().padLeft(2, '0')}:${t.at.minute.toString().padLeft(2, '0')}';
                      final tgl = '${t.at.day} ${_bulanSingkat[t.at.month - 1]} ${t.at.year}';
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                              child: Icon(t.method == 'QRIS' ? Icons.qr_code_2_outlined : Icons.payments_outlined, color: AppColors.accentDark, size: 22),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t.id} · ${t.method}', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text('$tgl · $jam · ${t.items} item', style: AppText.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Text(rupiah(t.total), style: AppText.body.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
