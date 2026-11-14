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
  const KelolaMenuScreen({super.key, required this.menus, required this.onAdd, required this.onChanged, required this.onDelete, this.embedded = false, this.ingredients = const []});

  final List<MenuItem> menus;

  /// Bahan untuk editor resep di formulir menu.
  final List<Ingredient> ingredients;
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
      ingredients: widget.ingredients,
      allMenus: widget.menus,
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
  List<Ingredient> ingredients = const [],
  List<MenuItem> allMenus = const [],
}) async {
  final item = initial;
  final menuId = item?.id ?? 'm${DateTime.now().millisecondsSinceEpoch}';
  final nameCtrl = TextEditingController(text: item?.name ?? '');
  final priceCtrl = TextEditingController(text: item == null ? '' : ThousandsFormatter.format(item.price));
  final ojolCtrl = TextEditingController(text: item == null || item.priceOjol == 0 ? '' : ThousandsFormatter.format(item.priceOjol));
  // Salinan kerja resep & isi bundle (asli hanya berubah saat Simpan).
  final resep = <RecipeLine>[for (final r in item?.recipe ?? const <RecipeLine>[]) RecipeLine(ingredientId: r.ingredientId, qty: r.qty)];
  final isiBundle = <BundleLine>[for (final b in item?.bundle ?? const <BundleLine>[]) BundleLine(menuId: b.menuId, qty: b.qty)];
  var category = item?.category ?? 'Kopi';
  var color = item?.color ?? menuPalette.first;
  var icon = item?.icon ?? menuIconChoices.first;
  var isDrink = item?.isDrink ?? false;
  String? imagePath = item?.imagePath;
  String? error;
  String snapshot() => [
        nameCtrl.text,
        priceCtrl.text,
        ojolCtrl.text,
        category,
        '${color.toARGB32()}',
        '${icon.codePoint}',
        '$isDrink',
        imagePath ?? '',
        resep.map((r) => '${r.ingredientId}:${r.qty}').join(','),
        isiBundle.map((b) => '${b.menuId}:${b.qty}').join(','),
      ].join('|');
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

        Future<double?> tanyaTakaran(String judul, double awalQty, {bool bulat = false}) async {
          final ctrl = TextEditingController(text: awalQty == 0 ? '' : (bulat ? '${awalQty.round()}' : '$awalQty'.replaceAll('.', ',')));
          final hasil = await showDialog<double>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: Text(judul),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(hintText: '0'),
                onSubmitted: (v) => Navigator.of(dctx).pop(double.tryParse(v.replaceAll(',', '.'))),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Batal')),
                PrimaryButton(label: 'Pakai', onPressed: () => Navigator.of(dctx).pop(double.tryParse(ctrl.text.replaceAll(',', '.')))),
              ],
            ),
          );
          disposeControllersLater([ctrl]);
          return hasil;
        }

        Future<void> tambahBahanResep() async {
          final belum = ingredients.where((i) => !resep.any((r) => r.ingredientId == i.id)).toList();
          if (belum.isEmpty) return;
          final dipilih = await showDialog<Ingredient>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: const Text('Pilih Bahan'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final ing in belum)
                      ListTile(
                        title: Text(ing.name),
                        subtitle: Text('per ${ing.unit}'),
                        onTap: () => Navigator.of(dctx).pop(ing),
                      ),
                  ],
                ),
              ),
            ),
          );
          if (dipilih == null) return;
          final qty = await tanyaTakaran('Takaran ${dipilih.name} per porsi (${dipilih.unit})', 0);
          if (qty == null || qty <= 0) return;
          setSheet(() => resep.add(RecipeLine(ingredientId: dipilih.id, qty: qty)));
        }

        Future<void> tambahIsiBundle() async {
          final belum = allMenus.where((m) => m.id != menuId && !isiBundle.any((b) => b.menuId == m.id)).toList();
          if (belum.isEmpty) return;
          final dipilih = await showDialog<MenuItem>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: const Text('Pilih Menu Komponen'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in belum)
                      ListTile(
                        title: Text(m.name),
                        subtitle: Text(rupiah(m.price)),
                        onTap: () => Navigator.of(dctx).pop(m),
                      ),
                  ],
                ),
              ),
            ),
          );
          if (dipilih == null) return;
          final qty = await tanyaTakaran('Jumlah ${dipilih.name} dalam bundle', 1, bulat: true);
          if (qty == null || qty < 1) return;
          setSheet(() => isiBundle.add(BundleLine(menuId: dipilih.id, qty: qty.round())));
        }

        String namaBahan(String id) => ingredients.where((i) => i.id == id).map((i) => i.name).firstOrNull ?? '(bahan terhapus)';
        String satuanBahan(String id) => ingredients.where((i) => i.id == id).map((i) => i.unit).firstOrNull ?? '';
        String namaMenu(String id) => allMenus.where((m) => m.id == id).map((m) => m.name).firstOrNull ?? '(menu terhapus)';

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
              final ojol = int.tryParse(ojolCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
                  priceOjol: ojol,
                  recipe: resep,
                  bundle: isiBundle,
                ));
              } else {
                item.name = name;
                item.category = category;
                item.price = price;
                item.color = color;
                item.icon = icon;
                item.isDrink = isDrink;
                item.imagePath = imagePath;
                item.priceOjol = ojol;
                item.recipe = resep;
                item.bundle = isiBundle;
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
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FormLabel('Harga Ojol (Rp) — boleh kosong'),
              TextField(
                controller: ojolCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, const ThousandsFormatter()],
                decoration: const InputDecoration(prefixText: 'Rp ', hintText: 'Sama dengan harga biasa'),
                onChanged: (_) => setSheet(() {}),
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
                      // Warna terpilih ditandai CINCIN (tepi putih +
                      // lingkaran luar aksen), bukan centang —
                      // aturan permanen Adnan.
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: color == c ? Border.all(color: Colors.white, width: 3) : Border.all(color: AppColors.border),
                          boxShadow: color == c
                              ? [BoxShadow(color: AppColors.accentDark, spreadRadius: 2, blurRadius: 0)]
                              : null,
                        ),
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
              const SizedBox(height: AppSpacing.xl),
              const FormLabel('Resep — Bahan per Porsi'),
              if (ingredients.isEmpty)
                Text('Belum ada bahan. Tambah dulu bahan di Stok Bahan, lalu kembali ke sini.', style: AppText.caption.copyWith(color: AppColors.muted))
              else ...[
                for (final r in resep)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(child: Text(namaBahan(r.ingredientId), style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
                        InkWell(
                          onTap: () async {
                            final q = await tanyaTakaran('Takaran ${namaBahan(r.ingredientId)} per porsi (${satuanBahan(r.ingredientId)})', r.qty);
                            if (q != null && q > 0) setSheet(() => r.qty = q);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.sm)),
                            child: Text('${_qtyTeks(r.qty)} ${satuanBahan(r.ingredientId)}', style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.danger,
                          tooltip: 'Hapus dari resep',
                          onPressed: () => setSheet(() => resep.remove(r)),
                        ),
                      ],
                    ),
                  ),
                if (resep.length < ingredients.length)
                  OutlinedButton.icon(
                    onPressed: tambahBahanResep,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Bahan'),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Menu terjual di kasir otomatis memotong stok bahan sesuai resep ini.',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const FormLabel('Isi Bundle — bila menu ini paket'),
              if (allMenus.where((m) => m.id != menuId).isEmpty)
                Text('Belum ada menu lain untuk dijadikan isi bundle.', style: AppText.caption.copyWith(color: AppColors.muted))
              else ...[
                for (final b in isiBundle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(child: Text(namaMenu(b.menuId), style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
                        InkWell(
                          onTap: () async {
                            final q = await tanyaTakaran('Jumlah ${namaMenu(b.menuId)} dalam bundle', b.qty.toDouble(), bulat: true);
                            if (q != null && q >= 1) setSheet(() => b.qty = q.round());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.sm)),
                            child: Text('${b.qty}×', style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.danger,
                          tooltip: 'Hapus dari bundle',
                          onPressed: () => setSheet(() => isiBundle.remove(b)),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: tambahIsiBundle,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Isi Bundle'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bundle terjual memotong stok lewat resep menu komponennya. Harga jual bundle = kolom Harga di atas.',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
              Builder(
                builder: (_) {
                  final hargaKini = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  if ((resep.isEmpty && isiBundle.isEmpty) || hargaKini <= 0) return const SizedBox.shrink();
                  final contoh = MenuItem(
                    id: menuId,
                    name: nameCtrl.text,
                    category: category,
                    price: hargaKini,
                    color: color,
                    icon: icon,
                    recipe: resep,
                    bundle: isiBundle,
                  );
                  final hpp = hppMenu(contoh, allMenus, ingredients);
                  if (hpp <= 0) return const SizedBox.shrink();
                  final margin = hargaKini - hpp;
                  final persen = (margin / hargaKini * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text(
                        'Perkiraan HPP ${rupiah(hpp)} · Margin kotor ${rupiah(margin)} ($persen%)',
                        style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  );
  disposeControllersLater([nameCtrl, priceCtrl, ojolCtrl]);
}

String _qtyTeks(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v'.replaceAll('.', ',');

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
