import 'package:flutter/material.dart';

/// Layar sambut: tampil selama data dimuat + sekejap sesudahnya.
///
/// Desain v0.15.0 (pilihan Adnan 2026-11-17): karya kunci resmi
/// Avorea kiriman Adnan sendiri (assets/branding/avorea-splash.png,
/// PNG latar transparan) di atas HITAM — persis pratinjau yang
/// beliau kirim dan setujui. Menggantikan logo huruf di atas
/// putih dari v0.12.0 atas permintaan beliau. Spinner kuning
/// brand kecil di bawah karya; label studio krem di dasar
/// layar. Timer splash tetap di shell (±1,5 detik).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _kuningBrand = Color(0xFFF5B921);
  static const _kremLabel = Color(0xFFF7F8F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                child: CircularProgressIndicator(strokeWidth: 3, color: _kuningBrand),
              ),
              const Spacer(flex: 5),
              Text(
                'AVOERA POS · BY WEBTALES STUDIO',
                style: TextStyle(color: _kremLabel.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.2),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
