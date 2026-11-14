import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Beranda: layar pembuka ala referensi yang dikirim Adnan
/// (screenshot Bisakasir, 2026-11-14) tapi dengan bahasa desain
/// Avoera sendiri — bersih, satu aksen emerald, tanpa gradasi.
///
/// Semua angka di sini ASLI: penjualan dihitung dari transaksi yang
/// tercatat permanen tiap checkout (bukan angka contoh). Hari
/// pertama memasang, angkanya memang Rp0 — sama seperti referensi.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({
    super.key,
    required this.businessName,
    required this.transactions,
    required this.kitchenActive,
    required this.tablesEnabled,
    required this.tablesOccupied,
    required this.tablesTotal,
    required this.onOpenKasir,
    required this.onNavigate,
    required this.onManageMenus,
    required this.onManageTables,
    required this.onManageIngredients,
  });

  final String businessName;
  final List<TxRecord> transactions;
  final int kitchenActive;
  final bool tablesEnabled;
  final int tablesOccupied;
  final int tablesTotal;
  final VoidCallback onOpenKasir;
  final ValueChanged<int> onNavigate;
  final VoidCallback onManageMenus;
  final VoidCallback onManageTables;
  final VoidCallback onManageIngredients;

  String _sapaan(DateTime now) {
    final h = now.hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayTx = transactions.where((t) => _sameDay(t.at, now)).toList();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayTotal = transactions.where((t) => _sameDay(t.at, yesterday)).fold(0, (a, t) => a + t.total);
    final totalToday = todayTx.fold(0, (a, t) => a + t.total);
    final countToday = todayTx.length;
    final avgToday = countToday == 0 ? 0 : totalToday ~/ countToday;
    final double? pct = yesterdayTotal > 0 ? (totalToday - yesterdayTotal) / yesterdayTotal * 100 : null;
    final jam = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final tiles = <(String, IconData, VoidCallback)>[
      // Tile Meja & Kelola Meja ikut hilang saat fitur meja mati.
      if (tablesEnabled) ('Meja', Icons.table_restaurant_outlined, () => onNavigate(2)),
      ('Dapur', Icons.soup_kitchen_outlined, () => onNavigate(3)),
      ('Laporan', Icons.bar_chart_outlined, () => onNavigate(4)),
      ('Stok Bahan', Icons.inventory_2_outlined, () => onNavigate(5)),
      ('Pengaturan', Icons.settings_outlined, () => onNavigate(6)),
      ('Atur Menu', Icons.restaurant_menu_outlined, onManageMenus),
      if (tablesEnabled) ('Atur Meja', Icons.table_bar_outlined, onManageTables),
      ('Atur Stok', Icons.inventory_outlined, onManageIngredients),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(_sapaan(now), style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
              child: Text(businessName, style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: AppSpacing.xs),
            Text('Aktif', style: AppText.small.copyWith(color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Kartu penjualan: emerald pekat satu warna (bukan gradasi).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Penjualan hari ini', style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Diperbarui $jam', style: AppText.caption.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(rupiah(totalToday), style: AppText.hero.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.md),
              if (pct != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pct >= 0 ? Icons.trending_up : Icons.trending_down, size: 14, color: Colors.white),
                          const SizedBox(width: AppSpacing.xs),
                          Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1).replaceAll('.', ',')}%', style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('dibanding kemarin', style: AppText.small.copyWith(color: Colors.white70)),
                  ],
                )
              else
                Text('Penjualan tercatat otomatis setiap ada pembayaran di kasir.', style: AppText.small.copyWith(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Transaksi', value: '$countToday')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _StatCard(label: 'Rata-rata', value: rupiah(avgToday))),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _StatCard(label: 'Di Dapur', value: '$kitchenActive')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Icon(Icons.point_of_sale, color: AppColors.accentDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kasir', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                        tablesEnabled
                            ? '$tablesOccupied dari $tablesTotal meja terisi · $kitchenActive pesanan di dapur'
                            : '$kitchenActive pesanan di dapur',
                        style: AppText.small.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              FilledButton(onPressed: onOpenKasir, child: const Text('Buka Kasir')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Menu cepat', style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 900 ? 8 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 96,
              ),
              itemCount: tiles.length,
              itemBuilder: (_, i) {
                final (label, icon, onTap) = tiles[i];
                return Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Container(
                      decoration: cardDecoration(),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                            child: Icon(icon, color: AppColors.accentDark, size: 22),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.small.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
