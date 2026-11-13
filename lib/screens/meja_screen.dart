import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class MejaScreen extends StatelessWidget {
  const MejaScreen({super.key, required this.tables, required this.selectedTable, required this.onSelect, required this.onGoKasir});

  final List<CafeTable> tables;
  final CafeTable? selectedTable;
  final ValueChanged<CafeTable> onSelect;
  final VoidCallback onGoKasir;

  @override
  Widget build(BuildContext context) {
    final kosong = tables.where((t) => t.status == TableStatus.kosong).length;
    final terisi = tables.where((t) => t.status == TableStatus.terisi).length;
    final belum = tables.where((t) => t.status == TableStatus.belumBayar).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Meja', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Ketuk meja untuk menjadikannya meja aktif di kasir.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(label: 'Kosong: $kosong', color: TableStatus.kosong.color),
            StatusChip(label: 'Terisi: $terisi', color: TableStatus.terisi.color),
            StatusChip(label: 'Belum Bayar: $belum', color: TableStatus.belumBayar.color),
            if (selectedTable != null) StatusChip(label: 'Aktif: Meja ${selectedTable!.number}', color: AppColors.accentDark),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cross = constraints.maxWidth >= 900 ? 6 : (constraints.maxWidth >= 560 ? 4 : 3);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 132,
              ),
              itemCount: tables.length,
              itemBuilder: (_, i) {
                final t = tables[i];
                final selected = selectedTable?.number == t.number;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onSelect(t),
                    child: Container(
                      decoration: cardDecoration(
                        borderColor: selected ? AppColors.accent : AppColors.border,
                        radius: 14,
                      ).copyWith(boxShadow: selected ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 10)] : null),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${t.number}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: t.status.color, shape: BoxShape.circle)),
                            ],
                          ),
                          Text('${t.capacity} kursi', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          const Spacer(),
                          StatusChip(label: t.status.label, color: t.status.color),
                          if (t.status != TableStatus.kosong) ...[
                            const SizedBox(height: 6),
                            Text('${t.guestName ?? ''} · ${rupiah(t.openAmount)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            if (t.since != null) Text('Sejak ${t.since}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        if (selectedTable != null)
          FilledButton.icon(
            onPressed: onGoKasir,
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.point_of_sale),
            label: Text('Pakai Meja ${selectedTable!.number} & Buka Kasir'),
          ),
      ],
    );
  }
}
