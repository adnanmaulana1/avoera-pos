import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_stok_screen.dart' show showIngredientEditor;

/// Stok Bahan dengan CRUD LANGSUNG di layar ini (permintaan Adnan
/// 2026-11-14): ketuk bahan untuk mengubah, tombol + untuk tambah —
/// tidak perlu lagi mampir Pengaturan. Plus cari, filter pill
/// standar (FilterChipRow), dan ekspor daftar stok.
class StokScreen extends StatefulWidget {
  const StokScreen({super.key, required this.ingredients, required this.onAdd, required this.onChanged, required this.onDelete});

  final List<Ingredient> ingredients;
  final ValueChanged<Ingredient> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<Ingredient> onDelete;

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  String _filter = 'Semua';
  String _query = '';

  List<Ingredient> get _list => widget.ingredients.where((i) {
        final cocokFilter = switch (_filter) {
          'Aman' => i.status == StockStatus.aman,
          'Kritis' => i.status == StockStatus.kritis,
          'Habis' => i.status == StockStatus.habis,
          _ => true,
        };
        return cocokFilter && i.name.toLowerCase().contains(_query.toLowerCase());
      }).toList();

  Future<void> _bukaEditor(Ingredient? ing) async {
    await showIngredientEditor(context, initial: ing, onAdd: widget.onAdd, onChanged: widget.onChanged, onDelete: widget.onDelete);
    if (mounted) setState(() {});
  }

  Future<void> _ekspor() {
    final semua = widget.ingredients;
    final ringkasan = StringBuffer('Stok Bahan — ${semua.length} bahan\n');
    for (final i in semua) {
      ringkasan.writeln('• ${i.name}: sisa ${stockText(i.stock)} ${i.unit} (${i.status.name})');
    }
    return bukaPratinjauLaporan(
      context,
      judul: 'Stok Bahan',
      ringkasan: ringkasan.toString().trim(),
      kepala: const ['Bahan', 'Sisa', 'Satuan', 'Batas Kritis', 'Status'],
      baris: [
        for (final i in semua) [i.name, stockText(i.stock), i.unit, stockText(i.minStock), i.status.name],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PageHeader(
              title: 'Stok Bahan',
              subtitle: '${widget.ingredients.length} bahan tersimpan. Ketuk bahan untuk mengubahnya.',
              trailing: TombolEkspor(onPressed: _ekspor),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari bahan…'),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.md),
            FilterChipRow(
              children: [
                for (final f in ['Semua', 'Aman', 'Kritis', 'Habis'])
                  AppChip(label: f, selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (list.isEmpty)
              const EmptyState(message: 'Tidak ada bahan yang cocok.\nCoba kata cari atau filter lain.', icon: Icons.inventory_2_outlined),
            for (final ing in list)
              AppCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                onTap: () => _bukaEditor(ing),
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
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
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
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: FloatingActionButton(
            heroTag: 'tambahBahan',
            onPressed: () => _bukaEditor(null),
            tooltip: 'Tambah Bahan',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
