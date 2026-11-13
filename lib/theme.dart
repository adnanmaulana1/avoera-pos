import 'package:flutter/material.dart';

class AppColors {
  static const accent = Color(0xFF059669); // emerald, satu aksen hemat
  static const accentDark = Color(0xFF047857);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const bg = Color(0xFFF7F7F5);
  static const card = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
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
    fontFamily: null, // font bawaan, aman offline
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
    ),
    chipTheme: base.chipTheme.copyWith(side: const BorderSide(color: AppColors.border)),
    dividerColor: AppColors.border,
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
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
        ?trailing,
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

BoxDecoration cardDecoration({Color borderColor = AppColors.border, double radius = 14}) {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
  );
}

String stockText(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString().replaceAll('.', ',');
}
