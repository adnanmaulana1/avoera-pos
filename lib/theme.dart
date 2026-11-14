import 'package:flutter/material.dart';

// ============================================================
// Token desain Avoera POS — aturan lengkapnya di DESIGN.md.
// File layar TIDAK boleh menulis Color(0x...), fontSize, atau
// BorderRadius.circular sendiri; semua lewat token di sini
// atau komponen bersama di widgets.dart.
// ============================================================

class AppColors {
  /// Mode gelap aktif? Diatur KasirFnbApp dari pilihan tema
  /// (Terang / Gelap / Ikuti Sistem). Warna permukaan & teks di
  /// bawah membaca nilai ini; warna aksen tetap sama di dua mode.
  static bool gelap = false;

  static const accent = Color(0xFF059669); // emerald, satu aksen hemat
  static const accentDark = Color(0xFF047857);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const chartBarActive = accent; // batang grafik hari sorotan

  static Color get accentSoft => gelap ? const Color(0xFF0C2B21) : const Color(0xFFECFDF5); // latar keadaan terpilih
  static Color get ink => gelap ? const Color(0xFFF3F5F4) : const Color(0xFF111827);
  static Color get muted => gelap ? const Color(0xFF9BA6A0) : const Color(0xFF6B7280);
  static Color get bg => gelap ? const Color(0xFF121614) : const Color(0xFFF7F7F5);
  static Color get card => gelap ? const Color(0xFF1C211E) : Colors.white;
  static Color get border => gelap ? const Color(0xFF2D3531) : const Color(0xFFE5E7EB);
  static Color get warningSoft => gelap ? const Color(0xFF2E230B) : const Color(0xFFFFFBEB);
  static Color get warningBorder => gelap ? const Color(0xFF6B5518) : const Color(0xFFFDE68A);
  static Color get track => gelap ? const Color(0xFF242B27) : const Color(0xFFF3F4F6); // rel bar stok
  static Color get fieldFill => gelap ? const Color(0xFF242B27) : const Color(0xFFEDF1EE); // isi kolom isian (lembut, tanpa garis)
  static Color get chartBar => gelap ? const Color(0xFF134E3A) : const Color(0xFFA7F3D0); // batang grafik tidak aktif
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
  // Khusus angka penjualan di Beranda: satu angka terpenting di
  // aplikasi, jadi satu-satunya yang berhak sebesar ini.
  static const display = TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w800);
}

/// Bayangan hanya untuk SATU elemen: kartu penjualan Beranda —
/// angka yang pertama dicek pemilik tiap membuka aplikasi.
/// Semua elemen lain duduk rata (antislop-ui R-12: bayangan adalah
/// penanda tingkat kepentingan, bukan dekorasi merata).
class AppShadows {
  static final heroCard = <BoxShadow>[
    BoxShadow(color: AppColors.accentDark.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
  ];
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: AppColors.gelap ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.card,
      brightness: AppColors.gelap ? Brightness.dark : Brightness.light,
    ),
    // Roboto = font sistem Android (tetap aman offline), dipatok supaya
    // tampilan teks konsisten di semua merek HP/tablet — font bawaan
    // tiap merek berbeda dan bikin desain bergeser.
    fontFamily: 'Roboto',
  );

  final chipBorder = BorderSide(color: AppColors.border);
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide.none,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
    ),
    dividerColor: AppColors.border,
    // Toast/pesan bawah didesain ulang (permintaan Adnan
    // 2026-11-15): melayang di atas bar bawah, sudut membulat,
    // gelap pekat dengan teks terang — terasa seperti notifikasi
    // aplikasi modern, bukan bilah hitam polos menempel di tepi.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.gelap ? const Color(0xFF2A332E) : const Color(0xFF14201A),
      contentTextStyle: const TextStyle(color: Color(0xFFF3F5F4), fontSize: 14, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ),
    // SATU pola transisi halaman untuk semua layar (permintaan
    // Adnan 2026-11-14): geser halus + memudar, durasi rute bawaan
    // ±300 mdtk. Dialog & lembar bawah tidak lewat sini.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AvoeraPageTransitionsBuilder(),
        TargetPlatform.iOS: AvoeraPageTransitionsBuilder(),
        TargetPlatform.linux: AvoeraPageTransitionsBuilder(),
        TargetPlatform.macOS: AvoeraPageTransitionsBuilder(),
        TargetPlatform.windows: AvoeraPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AvoeraPageTransitionsBuilder(),
      },
    ),
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
    // Tombol garis (pasangan tombol utama di dialog/wizard, aksi
    // sekunder di lembar): tinggi sama 52 dengan PrimaryButton
    // supaya pasangan tombol selalu sejajar rapi.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        side: BorderSide(color: AppColors.border),
        textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
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
        side: WidgetStatePropertyAll(chipBorder),
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      hintStyle: AppText.small.copyWith(color: AppColors.muted),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );
}

/// Pembangun transisi halaman bersama Avoera: halaman masuk
/// memudar sambil bergeser sedikit dari kanan (0,05 lebar layar),
/// kurva easeOutCubic; arah balik easeInCubic. Tenang, satu pola
/// untuk semua rute halaman (MaterialPageRoute membaca tema ini).
class AvoeraPageTransitionsBuilder extends PageTransitionsBuilder {
  const AvoeraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final masuk = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: masuk,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(masuk),
        child: child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    // Wajib membaca Theme di sini: SectionTitle sering dibuat const,
    // dan warna AppColors dibaca dari penanda statis — tanpa
    // ketergantungan Theme, judul tidak ikut berubah saat mode
    // terang/gelap diganti di tengah jalan (teks jadi tak terlihat).
    final _ = Theme.of(context);
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
  Color? color,
  Color? borderColor,
  double radius = AppRadius.md,
}) {
  return BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.border),
    // Bayangan TIPIS di semua kartu (permintaan Adnan 23:50):
    // cukup untuk mengangkat kartu dari latar, tidak dekoratif.
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: AppColors.gelap ? 0.30 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

String stockText(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString().replaceAll('.', ',');
}
