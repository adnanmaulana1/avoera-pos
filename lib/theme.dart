import 'package:flutter/material.dart';

// ============================================================
// Token desain Avoera POS — aturan lengkapnya di DESIGN.md.
// File layar TIDAK boleh menulis Color(0x...), fontSize, atau
// BorderRadius.circular sendiri; semua lewat token di sini
// atau komponen bersama di widgets.dart.
// ============================================================

class AppColors {
  static const accent = Color(0xFF059669); // emerald, satu aksen hemat
  static const accentDark = Color(0xFF047857);
  static const accentSoft = Color(0xFFECFDF5); // latar keadaan terpilih
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const bg = Color(0xFFF7F7F5);
  static const card = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);
  static const danger = Color(0xFFDC2626);
  static const track = Color(0xFFF3F4F6); // rel bar stok
  static const chartBar = Color(0xFFA7F3D0); // batang grafik tidak aktif
  static const chartBarActive = accent; // batang grafik hari sorotan
}

/// Skala jarak — kelipatan 4. Lihat DESIGN.md.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// Skala radius. Lihat DESIGN.md.
class AppRadius {
  static const xs = 6.0; // khusus elemen kecil (ujung batang grafik)
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

/// Skala teks — satu-satunya tempat fontSize ditulis. Lihat DESIGN.md.
/// fontFamily dipatok di sini juga: gaya komponen (tombol, chip, segmented)
/// memakai AppText apa adanya, jadi tanpa ini font-nya jatuh ke bawaan
/// merek HP dan tampilan bisa bergeser antar perangkat.
class AppText {
  static const caption = TextStyle(fontFamily: 'Roboto', fontSize: 11);
  static const small = TextStyle(fontFamily: 'Roboto', fontSize: 12);
  static const body = TextStyle(fontFamily: 'Roboto', fontSize: 14);
  static const subtitle = TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700);
  static const title = TextStyle(fontFamily: 'Roboto', fontSize: 17, fontWeight: FontWeight.w700);
  static const pageTitle = TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800);
  static const number = TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w800);
  static const hero = TextStyle(fontFamily: 'Roboto', fontSize: 26, fontWeight: FontWeight.w800);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.card,
    ),
    // Roboto = font sistem Android (tetap aman offline), dipatok supaya
    // tampilan teks konsisten di semua merek HP/tablet — font bawaan
    // tiap merek berbeda dan bikin desain bergeser.
    fontFamily: 'Roboto',
  );

  const chipBorder = BorderSide(color: AppColors.border);
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: chipBorder,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
    ),
    dividerColor: AppColors.border,
    // Chip pilihan di semua layar: satu gaya terpilih / tak terpilih.
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.accent,
      disabledColor: AppColors.card,
      side: chipBorder,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      labelStyle: AppText.small.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      secondaryLabelStyle: AppText.small.copyWith(color: AppColors.card, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    ),
    // Semua tombol utama: tinggi 52, radius md, teks subtitle tebal.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.card,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppText.subtitle,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentDark,
        textStyle: AppText.small.copyWith(fontWeight: FontWeight.w700),
        minimumSize: const Size(48, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        textStyle: WidgetStatePropertyAll(AppText.small.copyWith(fontWeight: FontWeight.w600)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
        side: const WidgetStatePropertyAll(chipBorder),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accentSoft : AppColors.card,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accentDark : AppColors.ink,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accentDark : AppColors.muted,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.accentSoft,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 24,
          color: s.contains(WidgetState.selected) ? AppColors.accentDark : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => AppText.small.copyWith(
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? AppColors.accentDark : AppColors.muted,
        ),
      ),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: AppColors.danger,
      textColor: AppColors.card,
      textStyle: AppText.caption.copyWith(fontWeight: FontWeight.w700),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: AppText.title.copyWith(color: AppColors.ink),
      contentTextStyle: AppText.body.copyWith(color: AppColors.ink),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      hintStyle: AppText.small.copyWith(color: AppColors.muted),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: AppText.title.copyWith(color: AppColors.ink))),
        ?trailing,
      ],
    );
  }
}

/// Label status pill — satu gaya di semua layar.
/// Latar = warna status dilembutkan, teks = warna status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

BoxDecoration cardDecoration({
  Color color = AppColors.card,
  Color borderColor = AppColors.border,
  double radius = AppRadius.md,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
  );
}

String stockText(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString().replaceAll('.', ',');
}
