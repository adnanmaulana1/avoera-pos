import 'package:flutter/material.dart';

import 'theme.dart';

// ============================================================
// Komponen bersama Avoera POS — aturan lengkapnya di DESIGN.md.
// Semua layar memakai komponen di sini supaya bentuk, jarak,
// dan gaya terpilih/tidak-terpilih sama persis di mana-mana.
// ============================================================

/// Kepala layar satu-satunya: judul + subjudul + aksi opsional di kanan.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.pageTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: AppText.small.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Kartu standar: putih, radius md, tepi border, tanpa bayangan.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: cardDecoration(color: color, borderColor: borderColor),
      padding: padding,
      child: child,
    );
  }
}

/// Chip pilihan tunggal — gaya terpilih/tidak-terpilih diatur tema chip.
/// Dipakai untuk kategori menu, filter stok, varian, dan metode bayar.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  // Boleh null = chip nonaktif (mis. chip nominal uang yang lebih
  // kecil dari total bayar di dialog pembayaran).
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Tombol aksi utama: tinggi 52, radius md, teks subtitle tebal.
/// Gaya dasarnya dari filledButtonTheme; di sini tinggi dikunci dan
/// warna latar bisa diganti untuk satu pengecualian terdokumentasi
/// (aksi selesai dapur memakai ink — lihat DESIGN.md).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final style = backgroundColor == null
        ? null
        : FilledButton.styleFrom(backgroundColor: backgroundColor);
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          );
    return SizedBox(
      height: 52,
      child: FilledButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

/// Tombol +/− bulat: daerah sentuh 44px, lingkaran visual 36px.
/// filled = tambah cepat di kartu menu (accent); outlined = pengatur
/// jumlah di keranjang & sheet.
class QtyButton extends StatelessWidget {
  const QtyButton({super.key, required this.icon, required this.onPressed, this.filled = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            maximumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            backgroundColor: filled ? AppColors.accent : AppColors.card,
            foregroundColor: filled ? AppColors.card : AppColors.ink,
            disabledBackgroundColor: AppColors.track,
            disabledForegroundColor: AppColors.muted,
            side: filled ? null : const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

/// Keadaan kosong yang jujur: menyebut keadaan + petunjuk, bukan "No data".
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: AppColors.muted),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gagang sheet bawah — selalu di tengah atas sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

/// Membuka sheet bawah dengan bentuk yang sama di semua tempat:
/// latar, sudut atas, dan tint dari tema sheet. Isi sheet WAJIB diawali
/// [SheetHandle] (dengan jarak atas md) supaya semua sheet sejajar.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (ctx) => SafeArea(child: builder(ctx)),
  );
}

/// Buang controller formulir dengan aman. Future sheet/dialog selesai
/// saat animasi tutup BARU mulai — membuang controller seketika itu
/// juga bikin TextField yang masih terpasang memakai controller mati
/// (pernah kejadian: crash "used after being disposed"). Tunda sampai
/// animasi tutup beres.
void disposeControllersLater(List<TextEditingController> controllers) {
  Future.delayed(const Duration(milliseconds: 500), () {
    for (final c in controllers) {
      c.dispose();
    }
  });
}
