import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_menu_screen.dart' show MenuThumb;

/// Layar Resep (permintaan Adnan 2026-11-15 — fitur yang dulu
/// 'Segera'): ringkasan resep semua menu + HPP & margin dari
/// harga beli bahan. Ketuk menu untuk mengubah resepnya di
/// editor menu (bagian Resep).
class ResepScreen extends StatefulWidget {
  const ResepScreen({super.key, required this.menus, required this.ingredients, required this.onEditMenu});
  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final Future<void> Function(MenuItem m) onEditMenu;

  @override
  State<ResepScreen> createState() => _ResepScreenState();
}

class _ResepScreenState extends State<ResepScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep Menu')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Resep menentukan bahan yang terpotong dari stok tiap menu terjual, dan jadi dasar hitung HPP (modal). '
            'Harga beli bahan diisi di Stok Bahan.',
            style: AppText.small.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.menus.isEmpty)
            const EmptyState(message: 'Belum ada menu.', icon: Icons.restaurant_menu_outlined),
          for (final m in widget.menus)
            Builder(
              builder: (_) {
                final hpp = hppMenu(m, widget.menus, widget.ingredients);
                final margin = m.price - hpp;
                final persen = m.price > 0 ? (margin / m.price * 100).round() : 0;
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () async {
                    await widget.onEditMenu(m);
                    if (mounted) setState(() {});
                  },
                  child: Row(
                    children: [
                      MenuThumb(menu: m, size: 48),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              m.isBundle
                                  ? 'Bundle — HPP dari komponen'
                                  : m.recipe.isEmpty
                                      ? 'Belum ada resep'
                                      : '${m.recipe.length} bahan per porsi',
                              style: AppText.caption.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(hpp > 0 ? 'HPP ${rupiah(hpp)}' : 'HPP —', style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                          if (hpp > 0)
                            Text('Margin $persen%', style: AppText.caption.copyWith(color: persen >= 0 ? AppColors.accentDark : AppColors.danger, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Layar Bundle (permintaan Adnan 2026-11-15 — fitur yang dulu
/// 'Segera'): daftar menu paket + isi komponennya. Bundle dibuat
/// & diubah dari editor menu (bagian Isi Bundle).
class BundleScreen extends StatefulWidget {
  const BundleScreen({super.key, required this.menus, required this.onEditMenu});
  final List<MenuItem> menus;
  final Future<void> Function(MenuItem? m) onEditMenu;

  @override
  State<BundleScreen> createState() => _BundleScreenState();
}

class _BundleScreenState extends State<BundleScreen> {
  @override
  Widget build(BuildContext context) {
    final bundles = widget.menus.where((m) => m.isBundle).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Bundle / Paket')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Bundle = satu menu paket berisi beberapa menu lain. Terjual di kasir seperti menu biasa; '
            'stok bahan terpotong lewat resep komponennya.',
            style: AppText.small.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (bundles.isEmpty)
            const EmptyState(message: 'Belum ada bundle.\nBuat menu baru lalu isi bagian Isi Bundle di editornya.', icon: Icons.card_giftcard_outlined),
          for (final m in bundles)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () async {
                await widget.onEditMenu(m);
                if (mounted) setState(() {});
              },
              child: Row(
                children: [
                  MenuThumb(menu: m, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          m.bundle.map((b) => '${b.qty}× ${widget.menus.where((x) => x.id == b.menuId).map((x) => x.name).firstOrNull ?? '(terhapus)'}').join(' · '),
                          style: AppText.caption.copyWith(color: AppColors.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(rupiah(m.price), style: AppText.body.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentDark)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Buat Bundle Baru',
            icon: Icons.add,
            onPressed: () async {
              await widget.onEditMenu(null);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
