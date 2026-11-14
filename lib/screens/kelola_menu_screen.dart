import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data.dart';
import '../media_store.dart';
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
                          MenuThumb(menu: m, size: 48),
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
    await showMenuEditor(
      context,
      initial: item,
      onAdd: widget.onAdd,
      onChanged: widget.onChanged,
      onDelete: widget.onDelete,
    );
    // Layar ini rute terdorong: induk tidak membangun ulang kita —
    // segarkan sendiri sesudah editor selesai.
    if (mounted) setState(() {});
  }
}

/// Kotak gambar menu resmi: foto produk bila ada (dan berkasnya
/// masih ada), selain itu kotak warna + ikon menu. Satu komponen
/// untuk kasir, produk, dan kelola supaya tidak ada tampilan
/// gambar yang pecah di satu tempat saja.
class MenuThumb extends StatelessWidget {
  const MenuThumb({super.key, required this.menu, this.size = 48, this.radius = AppRadius.md});
  final MenuItem menu;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = menu.imagePath;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: menu.color, borderRadius: BorderRadius.circular(radius)),
      child: Icon(menu.icon, color: AppColors.card, size: size * 0.5),
    );
    if (path == null || path.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Formulir menu bersama (Kelola Menu & layar Produk). Termasuk
/// foto produk: ambil dari kamera / galeri (permintaan Adnan
/// 2026-11-14), harga berformat titik otomatis, dan penjaga tombol
/// kembali (GuardBack) supaya isian tidak hilang tanpa peringatan.
Future<void> showMenuEditor(
  BuildContext context, {
  MenuItem? initial,
  required ValueChanged<MenuItem> onAdd,
  required VoidCallback onChanged,
  required ValueChanged<MenuItem> onDelete,
}) async {
  final item = initial;
  final menuId = item?.id ?? 'm${DateTime.now().millisecondsSinceEpoch}';
  final nameCtrl = TextEditingController(text: item?.name ?? '');
  final priceCtrl = TextEditingController(text: item == null ? '' : ThousandsFormatter.format(item.price));
  var category = item?.category ?? 'Kopi';
  var color = item?.color ?? menuPalette.first;
  var icon = item?.icon ?? menuIconChoices.first;
  var isDrink = item?.isDrink ?? false;
  String? imagePath = item?.imagePath;
  String? error;
  String snapshot() => [nameCtrl.text, priceCtrl.text, category, '${color.toARGB32()}', '${icon.codePoint}', '$isDrink', imagePath ?? ''].join('|');
  final awal = snapshot();

  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        Future<void> pilihFoto(ImageSource sumber) async {
          try {
            final x = await ImagePicker().pickImage(source: sumber, maxWidth: 900, imageQuality: 82);
            if (x == null) return;
            final permanen = await simpanFotoMenu(x.path, menuId);
            setSheet(() => imagePath = permanen);
          } catch (_) {
            setSheet(() => error = 'Tidak bisa membuka ${sumber == ImageSource.camera ? 'kamera' : 'galeri'} di perangkat ini.');
          }
        }

        return GuardBack(
          dirty: () => snapshot() != awal,
          child: FormSheet(
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
                      onDelete(item);
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
                onAdd(MenuItem(
                  id: menuId,
                  name: name,
                  category: category,
                  price: price,
                  color: color,
                  icon: icon,
                  isDrink: isDrink,
                  imagePath: imagePath,
                ));
              } else {
                item.name = name;
                item.category = category;
                item.price = price;
                item.color = color;
                item.icon = icon;
                item.isDrink = isDrink;
                item.imagePath = imagePath;
                onChanged();
              }
              Navigator.of(ctx).pop();
            },
            children: [
              const FormLabel('Foto Produk (boleh kosong)'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PratinjauFoto(imagePath: imagePath, color: color, icon: icon),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            OutlinedButton.icon(onPressed: () => pilihFoto(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined, size: 18), label: const Text('Kamera')),
                            OutlinedButton.icon(onPressed: () => pilihFoto(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined, size: 18), label: const Text('Galeri')),
                          ],
                        ),
                        if (imagePath != null)
                          TextButton(
                            onPressed: () => setSheet(() => imagePath = null),
                            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                            child: const Text('Hapus Foto'),
                          ),
                        Text('Foto tampil di kartu kasir & daftar produk.', style: AppText.caption.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, const ThousandsFormatter()],
                decoration: const InputDecoration(prefixText: 'Rp ', hintText: '18.000'),
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
          ),
        );
      },
    ),
  );
  disposeControllersLater([nameCtrl, priceCtrl]);
}

class _PratinjauFoto extends StatelessWidget {
  const _PratinjauFoto({required this.imagePath, required this.color, required this.icon});
  final String? imagePath;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final kosong = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Icon(icon, color: AppColors.card, size: 36),
    );
    if (imagePath == null) return kosong;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.file(
        File(imagePath!),
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => kosong,
      ),
    );
  }
}
