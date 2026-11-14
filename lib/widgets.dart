import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  /// Bila diisi, seluruh kartu bisa diketuk (ripple di dalam kartu).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isi = Container(
      margin: margin,
      decoration: cardDecoration(color: color, borderColor: borderColor),
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
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
