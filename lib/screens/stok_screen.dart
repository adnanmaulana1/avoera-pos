import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

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
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Stok Bahan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Bahan berkurang otomatis dari resep tiap menu terjual (tampilan contoh).',
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final f in ['Semua', 'Aman', 'Kritis', 'Habis'])
              ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(color: _filter == f ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                backgroundColor: Colors.white,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Tidak ada bahan pada filter ini.', style: TextStyle(color: AppColors.muted)))),
        for (final ing in list)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    StatusChip(
                      label: switch (ing.status) { StockStatus.aman => 'Aman', StockStatus.kritis => 'Kritis', StockStatus.habis => 'Habis' },
                      color: switch (ing.status) { StockStatus.aman => AppColors.accentDark, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Sisa ${stockText(ing.stock)} ${ing.unit} · Batas minimum ${stockText(ing.minStock)} ${ing.unit}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ing.ratio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF3F4F6),
                    color: switch (ing.status) { StockStatus.aman => AppColors.accent, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                  ),
                ),
                if (ing.status != StockStatus.aman) ...[
                  const SizedBox(height: 8),
                  Text(
                    ing.status == StockStatus.habis ? 'Segera pesan lagi — bahan sudah habis.' : 'Stok di bawah batas minimum — siapkan pesanan pembelian.',
                    style: TextStyle(color: ing.status == StockStatus.habis ? AppColors.danger : AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
