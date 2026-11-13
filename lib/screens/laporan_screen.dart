import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key, required this.ingredients});

  /// Stok dari data tersimpan — kartu stok kritis mengikuti data asli.
  final List<Ingredient> ingredients;

  static const int omzetHariIni = 3420000;
  static const int transaksiHariIni = 128;
  int get rataRata => (omzetHariIni / transaksiHariIni).round();

  @override
  Widget build(BuildContext context) {
    final kritis = ingredients.where((i) => i.status != StockStatus.aman).toList();
    final maxWeekly = weeklySales.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'Laporan',
          subtitle: 'Ringkasan pemilik · Hari ini',
          trailing: StatusChip(label: 'Data contoh', color: AppColors.warning),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, c) {
            final cross = c.maxWidth >= 900 ? 4 : 2;
            final stats = <(String, String, IconData)>[
              ('Omzet Hari Ini', rupiah(omzetHariIni), Icons.payments_outlined),
              ('Transaksi', '$transaksiHariIni', Icons.receipt_long_outlined),
              ('Rata-rata / Transaksi', rupiah(rataRata), Icons.calculate_outlined),
              ('Meja Terisi Sekarang', '4 dari 12', Icons.table_restaurant_outlined),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // 132: label kartu bisa 2 baris di sel sempit landscape;
                // 104 meluber 21px, 124 masih sisa 1px (tes tablet 1280x800).
                crossAxisCount: cross, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, mainAxisExtent: 132,
              ),
              itemCount: stats.length,
              itemBuilder: (_, i) => AppCard(
                // Kartu statistik kompak: padding md (lihat DESIGN.md).
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stats[i].$3, color: AppColors.accentDark, size: 20),
                    const Spacer(),
                    Text(stats[i].$2, style: AppText.number),
                    Text(stats[i].$1, style: AppText.small.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Omzet 7 Hari Terakhir'),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in weeklySales)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${(d.amount / 1000000).toStringAsFixed(1).replaceAll('.', ',')}jt',
                                  style: AppText.caption.copyWith(color: AppColors.muted)),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                height: 120 * (d.amount / maxWeekly),
                                decoration: BoxDecoration(
                                  color: d.day == 'Sab' ? AppColors.chartBarActive : AppColors.chartBar,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xs)),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(d.day, style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, c) {
            final sideBySide = c.maxWidth >= 900;
            final topCard = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Menu Paling Laris'),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < topMenus.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.accentSoft,
                            child: Text('${i + 1}', style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(topMenus[i].name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text('${topMenus[i].sold} terjual', style: AppText.small.copyWith(color: AppColors.muted)),
                          const SizedBox(width: AppSpacing.md),
                          Text(rupiah(topMenus[i].revenue), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            );
            final stockCard = AppCard(
              color: AppColors.warningSoft,
              borderColor: AppColors.warningBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Stok Bahan Kritis'),
                  const SizedBox(height: AppSpacing.sm),
                  if (kritis.isEmpty) const Text('Semua stok aman.'),
                  for (final ing in kritis)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(ing.status == StockStatus.habis ? Icons.error_outline : Icons.warning_amber_outlined,
                              color: ing.status == StockStatus.habis ? AppColors.danger : AppColors.warning, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text('Sisa ${stockText(ing.stock)} ${ing.unit}', style: AppText.small.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ),
                ],
              ),
            );
            if (sideBySide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: topCard), const SizedBox(width: AppSpacing.md), Expanded(child: stockCard)]);
            }
            return Column(children: [topCard, const SizedBox(height: AppSpacing.md), stockCard]);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Pembayaran Hari Ini'),
              SizedBox(height: AppSpacing.md),
              _PayRow(label: 'QRIS', value: 'Rp1.940.000 · 57%'),
              _PayRow(label: 'Tunai', value: 'Rp1.025.000 · 30%'),
              _PayRow(label: 'E-wallet / Debit', value: 'Rp455.000 · 13%'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
