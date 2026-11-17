import 'package:flutter/material.dart';

/// Layar sambut: tampil selama data dimuat + sekejap sesudahnya.
///
/// Desain v0.15.0 (pilihan Adnan 2026-11-17): karya kunci resmi
/// Avorea kiriman Adnan sendiri (assets/branding/avorea-splash.png,
/// PNG latar transparan). Latar diganti HITAM → PUTIH di v0.16.1
/// (permintaan Adnan sore yang sama); karena itu spinner &
/// label studio yang tadinya kuning/krem di atas hitam kini
/// memakai hijau alpukat tua #1E3A2A — warna huruf karya itu
/// sendiri — supaya tetap terbaca. Timer splash tetap di
/// shell (±1,5 detik).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _hijauBrand = Color(0xFF1E3A2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Image.asset('assets/branding/avorea-splash.png'),
              ),
              const SizedBox(height: 34),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3, color: _hijauBrand),
              ),
              const Spacer(flex: 5),
              Text(
                'AVOERA POS · BY WEBTALES STUDIO',
                style: TextStyle(color: _hijauBrand.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.2),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
