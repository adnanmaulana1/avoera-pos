import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final list = ingredients.where((i) {
      return switch (_filter) {
        'Aman' => i.status == StockStatus.aman,
        'Kritis' => i.status == StockStatus.kritis,
        'Habis' => i.status == StockStatus.habis,
        _ => true,
      };
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'Stok Bahan',
          subtitle: 'Bahan berkurang otomatis dari resep tiap menu terjual (tampilan contoh).',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final f in ['Semua', 'Aman', 'Kritis', 'Habis'])
              AppChip(
                label: f,
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          const EmptyState(message: 'Tidak ada bahan pada filter ini.', icon: Icons.inventory_2_outlined),
        for (final ing in list)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(ing.name, style: AppText.subtitle)),
                    StatusChip(
                      label: switch (ing.status) { StockStatus.aman => 'Aman', StockStatus.kritis => 'Kritis', StockStatus.habis => 'Habis' },
                      color: switch (ing.status) { StockStatus.aman => AppColors.accentDark, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Sisa ${stockText(ing.stock)} ${ing.unit} · Batas minimum ${stockText(ing.minStock)} ${ing.unit}',
                    style: AppText.small.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: ing.ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.track,
                    color: switch (ing.status) { StockStatus.aman => AppColors.accent, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                  ),
                ),
                if (ing.status != StockStatus.aman) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ing.status == StockStatus.habis ? 'Segera pesan lagi — bahan sudah habis.' : 'Stok di bawah batas minimum — siapkan pesanan pembelian.',
                    style: AppText.small.copyWith(color: ing.status == StockStatus.habis ? AppColors.danger : AppColors.warning, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
