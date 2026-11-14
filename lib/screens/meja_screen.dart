import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'Meja',
          subtitle: 'Ketuk meja untuk menjadikannya meja aktif di kasir.',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusChip(label: 'Kosong: $kosong', color: TableStatus.kosong.color),
            StatusChip(label: 'Terisi: $terisi', color: TableStatus.terisi.color),
            StatusChip(label: 'Belum Bayar: $belum', color: TableStatus.belumBayar.color),
            if (selectedTable != null) StatusChip(label: 'Aktif: Meja ${selectedTable!.number}', color: AppColors.accentDark),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final cross = constraints.maxWidth >= 900 ? 6 : (constraints.maxWidth >= 560 ? 4 : 3);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                // 180: isi kartu terisi (nomor + kursi + chip + tamu +
                // nominal baris sendiri + sejak) butuh ±172 di font tes;
                // di bawah itu Column meluber (tes tablet yang menangkap).
                mainAxisExtent: 180,
              ),
              itemCount: tables.length,
              itemBuilder: (_, i) {
                final t = tables[i];
                final selected = selectedTable?.number == t.number;
                return Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => onSelect(t),
                    child: Container(
                      decoration: cardDecoration(
                        borderColor: selected ? AppColors.accent : AppColors.border,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${t.number}', style: AppText.hero),
                              const Spacer(),
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: t.status.color, shape: BoxShape.circle)),
                            ],
                          ),
                          Text('${t.capacity} kursi', style: AppText.small.copyWith(color: AppColors.muted)),
                          const Spacer(),
                          StatusChip(label: t.status.label, color: t.status.color),
                          if (t.status != TableStatus.kosong) ...[
                            const SizedBox(height: AppSpacing.sm),
                            // Nama & nominal di baris terpisah: digabung
                            // satu baris nominalnya kepotong di kartu
                            // sempit ('Budi · Rp124.0…').
                            Text(t.guestName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                            Text(rupiah(t.openAmount), style: AppText.small.copyWith(fontWeight: FontWeight.w800)),
                            if (t.since != null) Text('Sejak ${t.since}', style: AppText.caption.copyWith(color: AppColors.muted)),
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
        const SizedBox(height: AppSpacing.lg),
        if (selectedTable != null)
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Pakai Meja ${selectedTable!.number} & Buka Kasir',
              icon: Icons.point_of_sale,
              onPressed: onGoKasir,
            ),
          ),
      ],
    );
  }
}
