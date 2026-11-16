import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layar sambut: tampil selama data dimuat + sekejap sesudahnya.
///
/// Desain "Fill + Hijau" (dipilih Adnan 2026-11-16 dari 4
/// kandidat + usul efek fill dari Adnan sendiri): latar hijau
/// brand POLOS, karya logo transparan baru
/// (avorea-segar.png — "Bikin Harimu Lebih Segar!") di tengah,
/// dan logonya SENDIRI menjadi penanda muat: mulai pudar
/// abu-abu, warnanya MENGISI dari bawah ke atas dengan batas
/// gelombang tipis selama splash tampil (±1,5 detik, seirama
/// timer splash di shell). Tanpa garis muat terpisah, tanpa
/// teks slogan terpisah (sudah ada di dalam karya logo).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  static const _hijauBrand = Color(0xFF1E3A2A);
  static const _kremBrand = Color(0xFFF7F8F2);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final lebarLogo = (size.width * 0.86).clamp(260.0, 430.0);
    final logoMasuk = CurvedAnimation(parent: _anim, curve: const Interval(0, 0.2, curve: Curves.easeOut));
    final teksMasuk = CurvedAnimation(parent: _anim, curve: const Interval(0.3, 0.8, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: _hijauBrand,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 5),
              FadeTransition(
                opacity: logoMasuk,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final isi = const Interval(0.05, 0.95, curve: Curves.easeInOut).transform(_anim.value);
                    return _LogoIsi(lebar: lebarLogo, isi: isi);
                  },
                ),
              ),
              const Spacer(flex: 6),
              FadeTransition(
                opacity: teksMasuk,
                child: Text(
                  'AVOERA POS · BY WEBTALES STUDIO',
                  style: TextStyle(color: _kremBrand.withValues(alpha: 0.45), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.2),
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saringan abu-abu untuk lapisan "belum terisi".
const _saringAbu = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Logo dua lapis: pudar abu-abu di bawah; warna penuh di atas
/// terpotong sampai ketinggian [isi] (0..1) dengan tepi
/// gelombang tipis — seperti minuman yang sedang dituang.
class _LogoIsi extends StatelessWidget {
  const _LogoIsi({required this.lebar, required this.isi});

  final double lebar;
  final double isi;

  @override
  Widget build(BuildContext context) {
    final gambar = Image.asset(
      'assets/branding/avorea-segar.png',
      width: lebar,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Text(
        'AVOREA',
        style: TextStyle(color: Color(0xFFF7F8F2), fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 3),
      ),
    );
    return Stack(
      children: [
        Opacity(opacity: 0.45, child: ColorFiltered(colorFilter: _saringAbu, child: gambar)),
        ClipPath(clipper: _KlipIsi(isi), child: gambar),
      ],
    );
  }
}

/// Potongan isi: tampilkan gambar dari dasar sampai garis
/// gelombang di ketinggian [isi].
class _KlipIsi extends CustomClipper<Path> {
  _KlipIsi(this.isi);
  final double isi;

  @override
  Path getClip(Size size) {
    final y = size.height * (1 - isi);
    final p = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, y);
    for (double x = 0; x <= size.width; x += 4) {
      p.lineTo(x, y + math.sin(x / size.width * math.pi * 2.2) * 5);
    }
    p
      ..lineTo(size.width, size.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(_KlipIsi oldDelegate) => oldDelegate.isi != isi;
}
