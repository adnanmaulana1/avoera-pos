import 'package:flutter/material.dart';

import '../data.dart';

/// Layar sambut (permintaan Adnan 2026-11-15): tampil selama data
/// dimuat + sekejap sesudahnya, memakai bahan brand Avorea yang
/// dikirim Adnan (logo dipotong dari banner 'Bikin Harimu Lebih
/// Segar!'). Warna brand dipatok — tidak ikut mode terang/gelap —
/// karena ini kartu nama usaha, bukan layar kerja.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _masuk;

  static const _hijauBrand = Color(0xFF1E3A2A);
  static const _kuningBrand = Color(0xFFF5B921);
  static const _kremBrand = Color(0xFFF7F8F2);

  @override
  void initState() {
    super.initState();
    _masuk = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..forward();
  }

  @override
  void dispose() {
    _masuk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hijauBrand,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _masuk, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: _masuk, curve: Curves.easeOut)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 302,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: _kremBrand,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 12))],
                  ),
                  child: Image.asset(
                    'assets/branding/avorea-logo.png',
                    width: 258,
                    height: 119,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 119,
                      child: Center(
                        child: Text('AVOREA', style: TextStyle(color: Color(0xFF1E3A2A), fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Bikin Harimu Lebih Segar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kuningBrand, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                const SizedBox(height: 30),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _kremBrand),
                ),
                const Spacer(flex: 4),
                Text(
                  '$appName · by $appStudio',
                  style: TextStyle(color: _kremBrand.withValues(alpha: 0.65), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
