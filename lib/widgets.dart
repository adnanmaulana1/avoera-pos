import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'package:avoera_pos/ikon.dart';

// ============================================================
// Komponen bersama Avorea POS — aturan lengkapnya di DESIGN.md.
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
    // Baca Theme agar ikut dibangun ulang saat mode terang/gelap
    // berganti (lihat catatan di SectionTitle).
    final _ = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Motif khas Avorea (v0.12.0): garis aksen pendek —
              // penanda yang sama dengan indikator bar bawah &
              // garis tepi pita ringkasan laporan. Satu motif
              // kecil yang berulang = identitas, bukan dekorasi.
              Container(
                width: 26,
                height: 4,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              const SizedBox(height: AppSpacing.sm),
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
    this.color,
    this.borderColor,
    this.margin,
    this.onTap,
    this.shadowAlpha,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  /// Menimpa kekuatan bayangan kartu (bawaan: ikuti tema).
  final double? shadowAlpha;

  /// Bila diisi, seluruh kartu bisa diketuk (ripple di dalam kartu).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isi = Container(
      margin: margin,
      decoration: cardDecoration(color: color, borderColor: borderColor, shadowAlpha: shadowAlpha),
      padding: padding,
      child: child,
    );
    if (onTap == null) return isi;
    return Container(
      margin: margin,
      decoration: cardDecoration(color: color, borderColor: borderColor),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Toast kaya (permintaan Adnan 2026-11-15, desain ulang toast):
/// pil melayang berisi ikon berwarna sesuai keadaan — hijau untuk
/// berhasil, merah untuk gagal, kuning untuk peringatan. Dipakai
/// untuk kejadian penting (sinkron, simpan besar); pesan kecil
/// biasa tetap SnackBar standar yang sudah dipercantik temanya.
void tampilToast(
  BuildContext context,
  String pesan, {
  IconData icon = Ikon.check_circle_outline,
  Color? warna,
  Duration durasi = const Duration(seconds: 3),
}) {
  final c = warna ?? AppColors.accent;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: durasi,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.gelap ? const Color(0xFF2A332E) : const Color(0xFF14201A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Icon(icon, color: c, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(pesan, style: const TextStyle(color: Color(0xFFF3F5F4), fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Format angka ribuan OTOMATIS saat mengetik (permintaan Adnan
/// 2026-11-14: "yang harga-harga gitu kasih titik sendiri"):
/// 18888 langsung tampil 18.888 di semua kolom harga/uang.
class ThousandsFormatter extends TextInputFormatter {
  const ThousandsFormatter();

  static String format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final text = format(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Baris pill saringan resmi: bisa digeser menyamping supaya tidak
/// pernah meluber di layar sempit, jarak & gaya chip selalu sama.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Angka uang yang BERGERAK saat nilainya berubah (permintaan
/// Adnan 2026-11-14): total keranjang menghitung naik/turun dengan
/// cepat (±350 mdtk) supaya perubahan terasa hidup, bukan berkedip.
class AnimatedRupiah extends StatelessWidget {
  const AnimatedRupiah({super.key, required this.value, this.style});
  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: const Duration(milliseconds: 350),
      builder: (_, v, _) => Text(
        _ribuan(v),
        style: style ?? AppText.body.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  static String _ribuan(int n) {
    final neg = n < 0;
    final s = n.abs().toString();
    final buf = StringBuffer(neg ? '-Rp' : 'Rp');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Angka statistik yang MENYESUAIKAN diri (permintaan Adnan
/// 2026-11-14): Rp1.000.000 dan Rp800.000 harus muat utuh di kartu
/// sempit — teks mengecil otomatis, tidak kepotong, tidak dibulatkan.
class FitNumber extends StatelessWidget {
  const FitNumber(this.text, {super.key, this.style, this.alignment = Alignment.centerLeft});
  final String text;
  final TextStyle? style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(text, style: style ?? AppText.number, maxLines: 1),
    );
  }
}

/// Chip pilihan tunggal — gaya terpilih/tidak-terpilih diatur tema chip.
/// Dipakai untuk kategori menu, filter stok, varian, dan metode bayar.
///
/// ATURAN PERMANEN Adnan: chip TIDAK PERNAH memakai ikon centang —
/// keadaan terpilih cukup dari warna isi & teks (showCheckmark mati).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  // Boleh null = chip nonaktif (mis. chip nominal uang yang lebih
  // kecil dari total bayar di dialog pembayaran).
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // daftar ulang saat tema berganti
    final aktif = onSelected != null;
    // Jahitan sendiri (v0.12.0), bukan ChoiceChip bawaan:
    // terpilih = isi aksen PEKAT + teks putih (tegas, bukan
    // pastel); tidak terpilih = permukaan kartu + garis tepi;
    // nonaktif = teks pudar tanpa ketukan.
    final latar = selected ? AppColors.accent : AppColors.card;
    final garis = selected ? AppColors.accent : AppColors.border;
    final warnaTeks = !aktif ? AppColors.muted : (selected ? Colors.white : AppColors.ink);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Ink(
          decoration: BoxDecoration(
            color: latar,
            border: Border.all(color: garis),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w600, color: warnaTeks),
            ),
          ),
        ),
      ),
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
            side: filled ? null : BorderSide(color: AppColors.border),
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
    // Baca Theme agar ikut dibangun ulang saat mode terang/gelap
    // berganti (lihat catatan di SectionTitle).
    final _ = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              // Ikon di dalam CINCIN bergaris (v0.12.0) — keadaan
              // kosong yang dirancang, bukan ikon lepas polos
              // seperti contoh dokumentasi.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Icon(icon, size: 28, color: AppColors.accentDark),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
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

/// Peringatan buang perubahan (permintaan Adnan 2026-11-14):
/// saat sedang mengisi data, tombol kembali TIDAK boleh langsung
/// menutup formulir — tanya dulu.
Future<bool> konfirmasiBuangPerubahan(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Perubahan belum disimpan'),
      content: const Text('Data yang sudah diisi akan hilang. Buang perubahan ini?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Tetap Mengisi')),
        PrimaryButton(
          label: 'Buang',
          backgroundColor: AppColors.danger,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Pembungkus penjaga tombol kembali untuk formulir (sheet & halaman):
/// kembali hanya jalan langsung bila formulir belum diubah;
/// bila sudah diubah → peringatan [konfirmasiBuangPerubahan] dulu.
class GuardBack extends StatelessWidget {
  const GuardBack({super.key, required this.dirty, required this.child});

  /// true bila isi formulir sudah berubah dari keadaan awal.
  final bool Function() dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!dirty()) {
          Navigator.of(context).pop();
          return;
        }
        final buang = await konfirmasiBuangPerubahan(context);
        if (buang && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}

/// Membuka sheet bawah dengan bentuk yang sama di semua tempat:
/// latar, sudut atas, dan tint dari tema sheet. Isi sheet WAJIB diawali
/// [SheetHandle] (dengan jarak atas md) supaya semua sheet sejajar.
/// Jarak bawah isi untuk LAYAR TERDORONG (layar dengan AppBar
/// sendiri, bukan halaman shell): jarak dasar ditambah tinggi
/// area tombol navigasi sistem Android. Di HP tombol 3 area itu
/// ±48dp dan tembus pandang — tanpa tambahan ini isi terakhir
/// daftar tertutup navbar (keluhan Adnan berulang sejak
/// 2026-11-15; Status Sinkronisasi dulu diperbaiki sendiri,
/// kini semua layar memakai hitungan yang sama). Halaman shell
/// TIDAK memakai ini: bar bawah shell sudah menyisakan ruang.
/// Lembar popup juga tidak: showAppSheet sudah membungkus
/// SafeArea.
double paddingBawahAman(BuildContext context, [double dasar = AppSpacing.lg]) =>
    dasar + MediaQuery.viewPaddingOf(context).bottom;

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
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

/// Animasi ganti tema IRIS (perbaikan v0.8.1, permintaan Adnan
/// 2026-11-14): metode standar transisi tema melingkar — gambar
/// tampilan LAMA (ditangkap KasirFnbApp dari RepaintBoundary akar
/// sebelum tema diganti) ditampilkan di atas tema baru, di-clip
/// jalur evenOdd: persegi layar penuh DIKURANGI lingkaran yang
/// membesar dari titik tombol tema yang diketuk. Tema baru
/// "mengintip" lewat lingkaran itu dan tema lama tersisih ke
/// tepi — seperti iris kamera membuka. Overlay ini HANYA gambar:
/// tidak menangkap sentuhan dan tidak mengubah state apa pun.
class AnimasiIrisTema extends StatefulWidget {
  const AnimasiIrisTema({
    super.key,
    required this.gambarLama,
    required this.pusat,
    required this.onSelesai,
  });

  /// Tangkapan tampilan tema lama (sudah diskalakan pixelRatio
  /// tangkapan; painter meregangkannya ke ukuran layar penuh).
  final ui.Image gambarLama;

  /// Titik pusat lingkaran iris (koordinat global = logis layar).
  /// Boleh null → fallback pojok kanan atas.
  final Offset? pusat;

  /// Dipanggil TEPAT sekali saat animasi tuntas (atau saat widget
  /// dibuang di tengah jalan) supaya overlay selalu dibersihkan.
  final VoidCallback onSelesai;

  /// Durasi satu arah ganti tema.
  static const durasi = Duration(milliseconds: 600);

  /// Pusat iris dari ketukan terakhir pada pilihan tema di
  /// Pengaturan (dicatat Listener di sana). Dikosongkan pemakai
  /// sesudah dibaca.
  static Offset? pusatDariKetukan;

  @override
  State<AnimasiIrisTema> createState() => _AnimasiIrisTemaState();
}

class _AnimasiIrisTemaState extends State<AnimasiIrisTema> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _kurva;
  bool _selesaiDilaporkan = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AnimasiIrisTema.durasi);
    _kurva = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _ctrl.addStatusListener((st) {
      if (st == AnimationStatus.completed) _laporSelesai();
    });
    _ctrl.forward();
  }

  void _laporSelesai() {
    if (_selesaiDilaporkan) return;
    _selesaiDilaporkan = true;
    widget.onSelesai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    // Widget dibuang di tengah animasi → tetap laporkan selesai
    // (ditunda ke sesudah bingkai ini) supaya gambar lama tidak
    // tertinggal menempel di state pemilik.
    if (!_selesaiDilaporkan) {
      _selesaiDilaporkan = true;
      final cb = widget.onSelesai;
      WidgetsBinding.instance.addPostFrameCallback((_) => cb());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Fallback: pojok kanan atas, di sekitar area tombol/ikon.
    final pusat = widget.pusat ?? Offset(size.width - 48, 56);
    // Radius maksimum = jarak pusat ke sudut layar terjauh, supaya
    // di akhir animasi lingkaran menelan seluruh layar.
    var rMaks = 0.0;
    for (final sudut in [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)]) {
      final d = (sudut - pusat).distance;
      if (d > rMaks) rMaks = d;
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _kurva,
        builder: (_, _) => CustomPaint(
          size: size,
          painter: _IrisTemaPainter(
            gambar: widget.gambarLama,
            pusat: pusat,
            radius: rMaks * _kurva.value,
          ),
        ),
      ),
    );
  }
}

/// Pelukis iris: gambar tema lama digambar HANYA di luar lingkaran
/// (jalur evenOdd = persegi penuh minus lingkaran). Di dalam
/// lingkaran, tema baru yang sudah terpasang di bawahnya terlihat.
class _IrisTemaPainter extends CustomPainter {
  const _IrisTemaPainter({required this.gambar, required this.pusat, required this.radius});

  final ui.Image gambar;
  final Offset pusat;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final jalan = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: pusat, radius: radius));
    canvas.save();
    canvas.clipPath(jalan);
    canvas.drawImageRect(
      gambar,
      Rect.fromLTWH(0, 0, gambar.width.toDouble(), gambar.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IrisTemaPainter old) => old.radius != radius || old.gambar != gambar || old.pusat != pusat;
}

/// Kerangka shimmer selama penyegaran tarik-ke-bawah (permintaan
/// Adnan 2026-11-15): balok-balok berbentuk halaman (judul, kolom
/// cari, pill, kartu daftar) yang terangnya berdenyut bergelombang.
/// Menutupi seluruh area halaman; ketukan terserap lapisannya.
class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({super.key});

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        var urut = 0;
        Widget balok({double? lebar, required double tinggi, double radius = AppRadius.sm}) {
          // Denyut terang berjalan dari balok ke balok.
          final gelombang = 0.5 + 0.5 * math.sin(2 * math.pi * (_ctrl.value - urut++ * 0.07));
          return Container(
            width: lebar,
            height: tinggi,
            decoration: BoxDecoration(
              color: Color.lerp(AppColors.track, AppColors.card, gelombang),
              borderRadius: BorderRadius.circular(radius),
            ),
          );
        }

        return Container(
          color: AppColors.bg,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              balok(lebar: 150, tinggi: 26),
              const SizedBox(height: AppSpacing.sm),
              balok(lebar: 210, tinggi: 14),
              const SizedBox(height: AppSpacing.lg),
              balok(tinggi: 52, radius: AppRadius.md),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  balok(lebar: 74, tinggi: 34, radius: AppRadius.pill),
                  const SizedBox(width: AppSpacing.sm),
                  balok(lebar: 74, tinggi: 34, radius: AppRadius.pill),
                  const SizedBox(width: AppSpacing.sm),
                  balok(lebar: 74, tinggi: 34, radius: AppRadius.pill),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < 5; i++) ...[
                balok(tinggi: 76, radius: AppRadius.md),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Satu tujuan di [BarNavigasiBawah].
class TujuanBar {
  const TujuanBar({required this.icon, required this.selectedIcon, required this.label, this.badge = 0});

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Angka lencana (0 = tanpa lencana), mis. pesanan dapur baru.
  final int badge;
}

/// Bar navigasi bawah JAHITAN SENDIRI (update identitas v0.12.0)
/// — menggantikan NavigationBar Material yang terasa bawaan
/// template: tanpa kapsul pastel di belakang ikon aktif.
/// Keadaan aktif ditandai garis aksen pendek di atas ikon +
/// ikon & label berwarna aksen; sisanya abu tenang. Permukaan
/// kartu + garis tepi atas; area tombol Android di bawah ikut
/// tertutup permukaan yang sama (SafeArea di dalam Material).
class BarNavigasiBawah extends StatelessWidget {
  const BarNavigasiBawah({super.key, required this.items, required this.selectedIndex, required this.onTap});

  final List<TujuanBar> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // daftar ulang saat tema berganti
    return Material(
      color: AppColors.card,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [for (var i = 0; i < items.length; i++) Expanded(child: _item(i))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int pos) {
    final t = items[pos];
    final aktif = pos == selectedIndex;
    final warna = aktif ? AppColors.accent : AppColors.muted;
    return InkWell(
      onTap: () => onTap(pos),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ruang penanda selalu disediakan supaya tinggi tidak
          // meloncat saat pilihan berpindah.
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 3,
            width: aktif ? 22 : 0,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
          ),
          const SizedBox(height: 6),
          Badge(
            isLabelVisible: t.badge > 0,
            label: Text('${t.badge}'),
            child: Icon(aktif ? t.selectedIcon : t.icon, color: warna, size: 24),
          ),
          const SizedBox(height: 3),
          Text(
            t.label,
            // Label navigasi TIDAK boleh membungkus dua baris —
            // lebar tiap tujuan sempit; satu baris selalu.
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo Avorea sebagai SUSUNAN HURUF (update identitas
/// v0.12.0) — bukan lagi gambar poster promosi: 'AVOREA'
/// Plus Jakarta Sans ExtraBold hijau alpukat tua, garis
/// kuning brand, dan 'MAESTRO ALPUKAT KOCOK' berjarak huruf.
/// Dipakai layar sambut & gerbang PIN. [terang] untuk latar
/// gelap (teks krem).
class LogoAvorea extends StatelessWidget {
  const LogoAvorea({super.key, this.skala = 1, this.terang = false});

  final double skala;
  final bool terang;

  static const _hijau = Color(0xFF1E3A2A);
  static const _kuning = Color(0xFFF5B921);
  static const _krem = Color(0xFFF7F8F2);

  @override
  Widget build(BuildContext context) {
    final warnaUtama = terang ? _krem : _hijau;
    final warnaSampingan = terang ? _krem.withValues(alpha: 0.75) : const Color(0xFF6B7268);
    Widget garis() => Container(
          width: 18 * skala,
          height: 3,
          decoration: BoxDecoration(color: _kuning, borderRadius: BorderRadius.circular(AppRadius.pill)),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AVOREA',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 42 * skala,
            fontWeight: FontWeight.w800,
            letterSpacing: 5 * skala,
            color: warnaUtama,
          ),
        ),
        SizedBox(height: 8 * skala),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            garis(),
            SizedBox(width: 10 * skala),
            Text(
              'MAESTRO ALPUKAT KOCOK',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10 * skala,
                fontWeight: FontWeight.w600,
                letterSpacing: 3 * skala,
                color: warnaSampingan,
              ),
            ),
            SizedBox(width: 10 * skala),
            garis(),
          ],
        ),
      ],
    );
  }
}
