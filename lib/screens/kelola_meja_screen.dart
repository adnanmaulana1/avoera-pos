import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart';

/// Kelola Meja: tambah, ubah (nomor & kapasitas), hapus meja.
/// Perubahan langsung tampil di layar Meja dan tersimpan permanen.
class KelolaMejaScreen extends StatefulWidget {
  const KelolaMejaScreen({super.key, required this.tables, required this.onAdd, required this.onChanged, required this.onDelete});

  final List<CafeTable> tables;
  final ValueChanged<CafeTable> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<CafeTable> onDelete;

  @override
  State<KelolaMejaScreen> createState() => _KelolaMejaScreenState();
}

class _KelolaMejaScreenState extends State<KelolaMejaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Meja')),
      body: Column(
        children: [
          Expanded(
            child: widget.tables.isEmpty
                ? const EmptyState(message: 'Belum ada meja.\nKetuk Tambah Meja untuk membuat yang pertama.', icon: Icons.table_restaurant_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: widget.tables.length,
                    itemBuilder: (_, i) {
                      final t = widget.tables[i];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text('${t.number}', textAlign: TextAlign.center, style: AppText.number),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Meja ${t.number}', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${t.capacity} kursi', style: AppText.small.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            StatusChip(label: t.status.label, color: t.status.color),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: AppColors.accentDark,
                              onPressed: () => _openEditor(t),
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
                child: PrimaryButton(label: 'Tambah Meja', icon: Icons.add, onPressed: () => _openEditor(null)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(CafeTable? table) async {
    final nextNumber = widget.tables.isEmpty ? 1 : widget.tables.map((t) => t.number).reduce((a, b) => a > b ? a : b) + 1;
    final numberCtrl = TextEditingController(text: '${table?.number ?? nextNumber}');
    final capacityCtrl = TextEditingController(text: '${table?.capacity ?? 4}');
    String? error;

    final awal = '${numberCtrl.text}|${capacityCtrl.text}';
    await showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return GuardBack(
            dirty: () => '${numberCtrl.text}|${capacityCtrl.text}' != awal,
            child: FormSheet(
            title: table == null ? 'Tambah Meja' : 'Ubah Meja ${table.number}',
            saveLabel: table == null ? 'Simpan Meja' : 'Simpan Perubahan',
            errorText: error,
            onDelete: table == null
                ? null
                : () async {
                    final ok = await showConfirmDelete(
                      ctx,
                      title: 'Hapus Meja ${table.number}',
                      message: table.status == TableStatus.kosong
                          ? 'Meja ${table.number} akan dihapus dari daftar.'
                          : 'Meja ${table.number} sedang ${table.status.label.toLowerCase()} — tetap hapus? Pesanan yang sedang berjalan di meja ini tidak ikut terhapus dari dapur.',
                    );
                    if (ok) {
                      widget.onDelete(table);
                      setState(() {});
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    }
                  },
            onSave: () {
              final number = int.tryParse(numberCtrl.text.trim());
              final capacity = int.tryParse(capacityCtrl.text.trim());
              if (number == null || number < 1) {
                setSheet(() => error = 'Nomor meja harus angka 1 atau lebih.');
                return;
              }
              if (capacity == null || capacity < 1) {
                setSheet(() => error = 'Kapasitas harus angka 1 atau lebih.');
                return;
              }
              final dup = widget.tables.any((t) => t.number == number && t != table);
              if (dup) {
                setSheet(() => error = 'Nomor meja $number sudah dipakai meja lain.');
                return;
              }
              if (table == null) {
                widget.onAdd(CafeTable(number: number, capacity: capacity, status: TableStatus.kosong));
              } else {
                table.number = number;
                table.capacity = capacity;
                widget.onChanged();
              }
              setState(() {});
              Navigator.of(ctx).pop();
            },
            children: [
              const FormLabel('Nomor Meja'),
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'Contoh: 13'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Kapasitas (kursi)'),
              TextField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'Contoh: 4'),
              ),
            ],
            ),
          );
        },
      ),
    );
    disposeControllersLater([numberCtrl, capacityCtrl]);
  }
}
