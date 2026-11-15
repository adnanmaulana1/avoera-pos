import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart';

/// Kelola Stok Bahan: tambah, ubah (nama, jumlah, satuan, batas), hapus.
/// Perubahan langsung tampil di layar Stok & Laporan, tersimpan permanen.
class KelolaStokScreen extends StatefulWidget {
  const KelolaStokScreen({super.key, required this.ingredients, required this.onAdd, required this.onChanged, required this.onDelete});

  final List<Ingredient> ingredients;
  final ValueChanged<Ingredient> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<Ingredient> onDelete;

  @override
  State<KelolaStokScreen> createState() => _KelolaStokScreenState();
}

/// Angka stok menerima koma atau titik sebagai pemisah desimal.
double? _parseQty(String raw) {
  final cleaned = raw.trim().replaceAll(',', '.');
  return double.tryParse(cleaned);
}

String _qtyText(double v) => v % 1 == 0 ? '${v.toInt()}' : '$v'.replaceAll('.', ',');

class _KelolaStokScreenState extends State<KelolaStokScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Stok Bahan')),
      body: Column(
        children: [
          Expanded(
            child: widget.ingredients.isEmpty
                ? const EmptyState(message: 'Belum ada bahan.\nKetuk Tambah Bahan untuk membuat yang pertama.', icon: Icons.inventory_2_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: widget.ingredients.length,
                    itemBuilder: (_, i) {
                      final ing = widget.ingredients[i];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ing.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text(
                                    'Sisa ${stockText(ing.stock)} ${ing.unit} · Batas kritis ${stockText(ing.minStock)} ${ing.unit}',
                                    style: AppText.small.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: switch (ing.status) { StockStatus.aman => 'Aman', StockStatus.kritis => 'Kritis', StockStatus.habis => 'Habis' },
                              color: switch (ing.status) { StockStatus.aman => AppColors.accentDark, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: AppColors.accentDark,
                              onPressed: () => _openEditor(ing),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(label: 'Tambah Bahan', icon: Icons.add, onPressed: () => _openEditor(null)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(Ingredient? ing) async {
    await showIngredientEditor(
      context,
      initial: ing,
      onAdd: widget.onAdd,
      onChanged: widget.onChanged,
      onDelete: widget.onDelete,
    );
    if (mounted) setState(() {});
  }
}

/// Formulir bahan bersama — dipakai Kelola Stok DAN layar Stok
/// Bahan langsung (CRUD di tempat, permintaan Adnan 2026-11-14).
/// Formulir dijaga GuardBack: tombol kembali saat ada perubahan
/// memunculkan peringatan dulu, dan sheet tidak tertutup dari
/// ketukan di luar.
Future<void> showIngredientEditor(
  BuildContext context, {
  Ingredient? initial,
  required ValueChanged<Ingredient> onAdd,
  required VoidCallback onChanged,
  required ValueChanged<Ingredient> onDelete,
}) async {
  final ing = initial;
  final nameCtrl = TextEditingController(text: ing?.name ?? '');
  final stockCtrl = TextEditingController(text: ing == null ? '' : _qtyText(ing.stock));
  final unitCtrl = TextEditingController(text: ing?.unit ?? 'kg');
  final minCtrl = TextEditingController(text: ing == null ? '' : _qtyText(ing.minStock));
  final maxCtrl = TextEditingController(text: ing == null ? '' : _qtyText(ing.maxStock));
  final costCtrl = TextEditingController(text: ing == null || ing.costPerUnit == 0 ? '' : ThousandsFormatter.format(ing.costPerUnit));
  String? error;
  String snapshot() => [nameCtrl.text, stockCtrl.text, unitCtrl.text, minCtrl.text, maxCtrl.text, costCtrl.text].join('|');
  final awal = snapshot();

  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return GuardBack(
          dirty: () => snapshot() != awal,
          child: FormSheet(
            title: ing == null ? 'Tambah Bahan' : 'Ubah Bahan',
            showClose: true,
            saveLabel: ing == null ? 'Simpan Bahan' : 'Simpan Perubahan',
            errorText: error,
            onDelete: ing == null
                ? null
                : () async {
                    final ok = await showConfirmDelete(
                      ctx,
                      title: 'Hapus Bahan',
                      message: 'Bahan "${ing.name}" akan dihapus dari daftar stok.',
                    );
                    if (ok) {
                      onDelete(ing);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    }
                  },
            onSave: () {
              final name = nameCtrl.text.trim();
              final unit = unitCtrl.text.trim();
              final stock = _parseQty(stockCtrl.text);
              final min = _parseQty(minCtrl.text);
              final max = _parseQty(maxCtrl.text);
              if (name.isEmpty) {
                setSheet(() => error = 'Nama bahan belum diisi.');
                return;
              }
              if (unit.isEmpty) {
                setSheet(() => error = 'Satuan belum diisi (contoh: kg, liter, pcs).');
                return;
              }
              if (stock == null || stock < 0 || min == null || min < 0 || max == null || max <= 0) {
                setSheet(() => error = 'Jumlah, batas kritis, dan stok maksimal harus angka yang benar.');
                return;
              }
              final cost = int.tryParse(costCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (ing == null) {
                onAdd(Ingredient(name: name, stock: stock, unit: unit, minStock: min, maxStock: max, costPerUnit: cost));
              } else {
                ing.name = name;
                ing.stock = stock;
                ing.unit = unit;
                ing.minStock = min;
                ing.maxStock = max;
                ing.costPerUnit = cost;
                onChanged();
              }
              Navigator.of(ctx).pop();
            },
            children: [
              const FormLabel('Nama Bahan'),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Contoh: Biji Kopi Arabika')),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Jumlah Stok'),
                        TextField(
                          controller: stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Satuan'),
                        TextField(controller: unitCtrl, decoration: const InputDecoration(hintText: 'kg / liter / pcs')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Batas Kritis'),
                        TextField(
                          controller: minCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Stok Maksimal'),
                        TextField(
                          controller: maxCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: const InputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Batas kritis = angka peringatan "stok mau habis". Stok maksimal = patokan bar penuh di layar Stok.',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Harga Beli per Satuan (Rp)'),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, const ThousandsFormatter()],
                decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Harga beli terakhir bahan ini per satuannya — dasar hitung HPP (modal) menu dari resep. Boleh kosong.',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        );
      },
    ),
  );
  disposeControllersLater([nameCtrl, stockCtrl, unitCtrl, minCtrl, maxCtrl, costCtrl]);
}
