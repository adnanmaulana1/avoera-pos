import 'package:flutter/material.dart';

/// Layar sambut (permintaan Adnan 2026-11-15, desain ulang total
/// di hari yang sama): tampil selama data dimuat + sekejap
/// sesudahnya. Logo Avorea tampil MENYATU di atas hijau emerald
/// tua — bukan gambar ditempel dalam kotak putih. Berkas
/// avorea-logo-gelap.png adalah varian logo asli yang disiapkan
/// untuk latar gelap: pola latar dibuang, hijau gelap pada badan
/// alpukat & teks bawah diangkat jadi hijau muda supaya terbaca.
/// Mekanisme tampil & alur startup TIDAK berubah — yang berubah
/// hanya visual + animasi masuk.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _masuk;

  static const _kuningBrand = Color(0xFFF5B921);
  static const _kremBrand = Color(0xFFF7F8F2);

  @override
  void initState() {
    super.initState();
    _masuk = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _masuk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final lebarLogo = (size.width * 0.78).clamp(240.0, 340.0);
    final logoMasuk = CurvedAnimation(parent: _masuk, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic));
    final teksMasuk = CurvedAnimation(parent: _masuk, curve: const Interval(0.35, 1, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A2A),
      body: Stack(
        // expand WAJIB: tanpa ini Stack menyusut selebar isi kolom
        // dan logo/tagline bergeser ke kiri (ketahuan dari bedah
        // frame 2026-11-15).
        fit: StackFit.expand,
        children: [
          // Latar: emerald tua bergradasi halus + aksen visual.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF17402A), Color(0xFF1E3A2A), Color(0xFF122A1C)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _AksenSplashPainter())),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: logoMasuk,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1).animate(logoMasuk),
                    child: Image.asset(
                      'assets/branding/avorea-logo-gelap.png',
                      width: lebarLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'AVOREA',
                        style: TextStyle(color: _kremBrand, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: teksMasuk,
                  child: Column(
                    children: [
                      const Text(
                        'Bikin Harimu Lebih Segar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _kuningBrand, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 30),
                      // Penanda muat ramping berwarna brand.
                      SizedBox(
                        width: 128,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: _kremBrand.withValues(alpha: 0.14),
                            valueColor: const AlwaysStoppedAnimation<Color>(_kuningBrand),
                          ),
                        ),
                      ),
                    ],
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
        ],
      ),
    );
  }
}

/// Aksen visual minimalis: cahaya radial lembut di belakang logo,
/// cincin-cincin tipis samar di dua sudut, dan tiga titik kecil —
/// cukup memberi tekstur tanpa meramaikan.
class _AksenSplashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cahaya = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF3E7A52).withValues(alpha: 0.35), const Color(0xFF3E7A52).withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.38), radius: size.width * 0.62));
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.38), size.width * 0.62, cahaya);
    final cincin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.055);
    for (final r in [54.0, 92.0, 130.0]) {
      canvas.drawCircle(Offset(size.width - 8, -10), r, cincin);
    }
    for (final r in [40.0, 74.0]) {
      canvas.drawCircle(Offset(6, size.height + 6), r, cincin);
    }
    final titik = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(26, size.height * 0.30 + i * 16), 2.2, titik);
    }
  }

  @override
  bool shouldRepaint(_AksenSplashPainter oldDelegate) => false;
}
