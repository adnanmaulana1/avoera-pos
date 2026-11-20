import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';

const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

List<TxRecord> _txCabang(List<TxRecord> all, String branchId) =>
    all.where((t) => t.branchId.isEmpty || t.branchId == branchId).toList();

/// Laporan Bulanan: total penjualan 6 bulan terakhir dari
/// transaksi asli, per bulan + rata-rata + hari terbaik bulan ini.
class LaporanBulananScreen extends StatelessWidget {
  const LaporanBulananScreen({super.key, required this.transactions, required this.branchId});
  final List<TxRecord> transactions;
  final String branchId;

  @override
  Widget build(BuildContext context) {
    // Hanya transaksi Lunas yang dihitung (v0.23.0).
    final tx = _txCabang(transactions, branchId).where((t) => t.status == 'Lunas').toList();
    final now = DateTime.now();
    final rows = <(String, int, int)>[]; // label, total, jumlah
    for (var i = 0; i < 6; i++) {
      final m = DateTime(now.year, now.month - i);
      final inMonth = tx.where((t) => t.at.year == m.year && t.at.month == m.month).toList();
      rows.add(('${_bulanPanjang[m.month - 1]} ${m.year}', inMonth.fold(0, (a, t) => a + t.total), inMonth.length));
    }
    // Hari terbaik bulan berjalan.
    final thisMonth = tx.where((t) => t.at.year == now.year && t.at.month == now.month).toList();
    final perDay = <int, int>{};
    for (final t in thisMonth) {
      perDay[t.at.day] = (perDay[t.at.day] ?? 0) + t.total;
    }
    final bestDay = perDay.entries.fold<(int, int)>((0, 0), (best, e) => e.value > best.$2 ? (e.key, e.value) : best);

    Future<void> ekspor() {
      final ringkasan = StringBuffer('Laporan Bulanan\n');
      for (final (label, total, count) in rows) {
        ringkasan.writeln('• $label: ${rupiah(total)} ($count transaksi)');
      }
      if (bestDay.$2 > 0) ringkasan.writeln('Hari terbaik bulan ini: tanggal ${bestDay.$1} — ${rupiah(bestDay.$2)}');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Bulanan',
        ringkasan: ringkasan.toString().trim(),
        kepala: const ['Bulan', 'Transaksi', 'Rata-rata', 'Total'],
        baris: [
          for (final (label, total, count) in rows)
            [label, '$count', count == 0 ? '0' : '${(total / count).round()}', '$total'],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          if (bestDay.$2 > 0)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Ikon.emoji_events_outlined, color: AppColors.accentDark),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Hari terbaik bulan ini: tanggal ${bestDay.$1} — ${rupiah(bestDay.$2)}',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          for (final (label, total, count) in rows)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                        Text(count == 0 ? 'Belum ada transaksi' : '$count transaksi · rata-rata ${rupiah((total / count).round())}',
                            style: AppText.caption.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(rupiah(total), style: AppText.subtitle),
                ],
              ),
            ),
          Text('Dihitung dari transaksi yang tercatat di kasir pada cabang ini.', style: AppText.caption.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Laporan Pajak: pajak & biaya layanan yang terkumpul dari
/// pembayaran pada satu periode (bulan ini / bulan lalu).
class LaporanPajakScreen extends StatefulWidget {
  const LaporanPajakScreen({super.key, required this.transactions, required this.branchId});
  final List<TxRecord> transactions;
  final String branchId;

  @override
  State<LaporanPajakScreen> createState() => _LaporanPajakScreenState();
}

class _LaporanPajakScreenState extends State<LaporanPajakScreen> {
  bool _bulanLalu = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final target = _bulanLalu ? DateTime(now.year, now.month - 1) : DateTime(now.year, now.month);
    final tx = _txCabang(widget.transactions, widget.branchId)
        .where((t) => t.status == 'Lunas' && t.at.year == target.year && t.at.month == target.month)
        .toList();
    final subtotal = tx.fold(0, (a, t) => a + t.subtotal);
    final service = tx.fold(0, (a, t) => a + t.service);
    final tax = tx.fold(0, (a, t) => a + t.tax);
    final total = tx.fold(0, (a, t) => a + t.total);
    final tunai = tx.where((t) => t.method == 'Tunai').fold(0, (a, t) => a + t.total);
    final qris = tx.where((t) => t.method == 'QRIS').fold(0, (a, t) => a + t.total);

    Widget row(String label, int value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.body.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
              Text(rupiah(value), style: AppText.body.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        );

    Future<void> ekspor() {
      final judulPeriode = '${_bulanPanjang[target.month - 1]} ${target.year}';
      final ringkasan = 'Laporan Pajak — $judulPeriode (${tx.length} transaksi)\n'
          'Penjualan (sebelum biaya & pajak): ${rupiah(subtotal)}\n'
          'Biaya layanan terkumpul: ${rupiah(service)}\n'
          'Pajak terkumpul: ${rupiah(tax)}\n'
          'Total diterima: ${rupiah(total)} (Tunai ${rupiah(tunai)} · QRIS ${rupiah(qris)})';
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Pajak',
        ringkasan: ringkasan,
        kepala: const ['Periode', 'Rincian', 'Jumlah'],
        baris: [
          [judulPeriode, 'Penjualan (sebelum biaya & pajak)', '$subtotal'],
          [judulPeriode, 'Biaya layanan terkumpul', '$service'],
          [judulPeriode, 'Pajak terkumpul', '$tax'],
          [judulPeriode, 'Total diterima', '$total'],
          [judulPeriode, 'Tunai', '$tunai'],
          [judulPeriode, 'QRIS', '$qris'],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pajak'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          FilterChipRow(
            children: [
              AppChip(label: 'Bulan Ini', selected: !_bulanLalu, onSelected: (_) => setState(() => _bulanLalu = false)),
              AppChip(label: 'Bulan Lalu', selected: _bulanLalu, onSelected: (_) => setState(() => _bulanLalu = true)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('${_bulanPanjang[target.month - 1]} ${target.year} · ${tx.length} transaksi', style: AppText.small.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                row('Penjualan (sebelum biaya & pajak)', subtotal),
                const Divider(height: 1),
                row('Biaya layanan terkumpul', service),
                const Divider(height: 1),
                row('Pajak terkumpul', tax, bold: true),
                const Divider(height: 1),
                row('Total diterima', total, bold: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Per cara bayar', style: AppText.subtitle),
                row('Tunai', tunai),
                const Divider(height: 1),
                row('QRIS', qris),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pajak terkumpul adalah pajak yang dipungut dari pembeli di setiap pembayaran — jumlah inilah yang disetor. Persentase pajak & biaya layanan diatur di Pengaturan. Transaksi lama (sebelum v0.7.0) tidak punya rincian pajak, jadi dihitung nol.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Laporan Piutang: tagihan meja yang belum dibayar — datanya
/// sudah ada dari keadaan meja (tamu + nominal terbuka).
class LaporanPiutangScreen extends StatelessWidget {
  const LaporanPiutangScreen({super.key, required this.tables});
  final List<CafeTable> tables;

  @override
  Widget build(BuildContext context) {
    final utang = tables.where((t) => t.openAmount > 0).toList()..sort((a, b) => b.openAmount.compareTo(a.openAmount));
    final total = utang.fold(0, (a, t) => a + t.openAmount);
    Future<void> ekspor() {
      final ringkasan = StringBuffer('Laporan Piutang — total ${rupiah(total)}\n');
      for (final t in utang) {
        ringkasan.writeln('• Meja ${t.number} · ${t.guestName ?? 'Tamu'}: ${rupiah(t.openAmount)}');
      }
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Piutang',
        ringkasan: ringkasan.toString().trim(),
        kepala: const ['Meja', 'Tamu', 'Sejak', 'Tagihan'],
        baris: [
          for (final t in utang) ['${t.number}', t.guestName ?? 'Tamu', t.since ?? '-', '${t.openAmount}'],
        ],
        catatan: 'Total belum dibayar: ${rupiah(total)}',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Piutang'),
        actions: [if (utang.isNotEmpty) TombolEkspor(onPressed: ekspor)],
      ),
      body: utang.isEmpty
          ? const EmptyState(message: 'Tidak ada piutang.\nSemua tagihan meja sudah lunas.', icon: Ikon.check_circle_outline)
          : ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
              children: [
                AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total belum dibayar', style: AppText.small.copyWith(color: AppColors.muted)),
                            FitNumber(rupiah(total)),
                          ],
                        ),
                      ),
                      Text('${utang.length} meja', style: AppText.small.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
                for (final t in utang)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Meja ${t.number} · ${t.guestName ?? 'Tamu'}', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                              Text(t.since != null ? 'Sejak ${t.since}' : 'Sedang berjalan', style: AppText.caption.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(rupiah(t.openAmount), style: AppText.body.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
