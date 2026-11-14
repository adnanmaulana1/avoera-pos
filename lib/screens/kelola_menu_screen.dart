import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart';

/// Palet warna kartu menu yang bisa dipilih (pengganti foto produk).
const menuPalette = <Color>[
  Color(0xFF8D6E63),
  Color(0xFF4E342E),
  Color(0xFFA1887F),
  Color(0xFF7CB342),
  Color(0xFFF9A825),
  Color(0xFFEF6C00),
  Color(0xFFC62828),
  Color(0xFFAD1457),
  Color(0xFF00695C),
  Color(0xFF00838F),
  Color(0xFF4527A0),
  Color(0xFF5D4037),
];

/// Ikon yang bisa dipilih untuk kartu menu = daftar resmi di
/// data.dart (menuIconChoices), supaya nomor urutnya stabil.

/// Kelola Menu: tambah, ubah, hapus menu. Perubahan langsung tampil
/// di kasir dan tersimpan permanen lewat callback ke HomeShell.
class KelolaMenuScreen extends StatefulWidget {
  const KelolaMenuScreen({super.key, required this.menus, required this.onAdd, required this.onChanged, required this.onDelete, this.embedded = false});

  final List<MenuItem> menus;
  final ValueChanged<MenuItem> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<MenuItem> onDelete;

  /// true = dipakai sebagai isi layar Produk (tanpa Scaffold/AppBar
  /// sendiri; judul disediakan layar induk).
  final bool embedded;

  @override
  State<KelolaMenuScreen> createState() => _KelolaMenuScreenState();
}

class _KelolaMenuScreenState extends State<KelolaMenuScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _body();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu')),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
        children: [
          Expanded(
            child: widget.menus.isEmpty
                ? const EmptyState(message: 'Belum ada menu.\nKetuk Tambah Menu untuk membuat yang pertama.', icon: Icons.restaurant_menu_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: widget.menus.length,
                    itemBuilder: (_, i) {
                      final m = widget.menus[i];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: Icon(m.icon, color: AppColors.card, size: 24),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text('${m.category} · ${rupiah(m.price)}', style: AppText.small.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: AppColors.accentDark,
                              onPressed: () => _openEditor(m),
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
                child: PrimaryButton(label: 'Tambah Menu', icon: Icons.add, onPressed: () => _openEditor(null)),
              ),
            ),
          ),
        ],
    );
  }

  Future<void> _openEditor(MenuItem? item) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(text: item == null ? '' : '${item.price}');
    var category = item?.category ?? 'Kopi';
    var color = item?.color ?? menuPalette.first;
    var icon = item?.icon ?? menuIconChoices.first;
    var isDrink = item?.isDrink ?? false;
    String? error;

    await showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return FormSheet(
            title: item == null ? 'Tambah Menu' : 'Ubah Menu',
            saveLabel: item == null ? 'Simpan Menu' : 'Simpan Perubahan',
            errorText: error,
            onDelete: item == null
                ? null
                : () async {
                    final ok = await showConfirmDelete(
                      ctx,
                      title: 'Hapus Menu',
                      message: 'Menu "${item.name}" akan dihapus dari daftar dan tidak bisa lagi dijual di kasir.',
                    );
                    if (ok) {
                      widget.onDelete(item);
                      setState(() {});
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    }
                  },
            onSave: () {
              final name = nameCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
              if (name.isEmpty) {
                setSheet(() => error = 'Nama menu belum diisi.');
                return;
              }
              if (price == null || price <= 0) {
                setSheet(() => error = 'Harga harus angka lebih dari 0.');
                return;
              }
              if (item == null) {
                widget.onAdd(MenuItem(
                  id: 'm${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  category: category,
                  price: price,
                  color: color,
                  icon: icon,
                  isDrink: isDrink,
                ));
              } else {
                item.name = name;
                item.category = category;
                item.price = price;
                item.color = color;
                item.icon = icon;
                item.isDrink = isDrink;
                widget.onChanged();
              }
              setState(() {});
              Navigator.of(ctx).pop();
            },
            children: [
              const FormLabel('Nama Menu'),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Contoh: Kopi Susu Gula Aren')),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Kategori'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in categories.skip(1))
                    AppChip(label: c, selected: category == c, onSelected: (_) => setSheet(() => category = c)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Harga (Rp)'),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(prefixText: 'Rp ', hintText: '18000'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Warna Kartu'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in menuPalette)
                    GestureDetector(
                      onTap: () => setSheet(() => color = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        child: color == c ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Ikon'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final ic in menuIconChoices)
                    GestureDetector(
                      onTap: () => setSheet(() => icon = ic),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: icon == ic ? AppColors.accentSoft : AppColors.track,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(ic, size: 22, color: icon == ic ? AppColors.accentDark : AppColors.muted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Menu minuman', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                        Text('Ada pilihan level gula di kasir.', style: AppText.caption.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Switch(value: isDrink, onChanged: (v) => setSheet(() => isDrink = v)),
                ],
              ),
            ],
          );
        },
      ),
    );
    disposeControllersLater([nameCtrl, priceCtrl]);
  }
}
