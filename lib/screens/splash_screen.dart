import 'package:flutter/material.dart';

import '../widgets.dart';

/// Layar sambut: tampil selama data dimuat + sekejap sesudahnya.
///
/// Desain v0.12.0 (update identitas): PUTIH bersih, logo sebagai
/// susunan huruf saja (LogoAvorea) — tanpa karya poster promosi
/// dan tanpa efek isi warna yang dulu dipakai; poster terasa
/// seperti membuka iklan. Spinner hijau brand kecil di bawah
/// logo; label studio di dasar layar. Timer splash tetap di
/// shell (±1,5 detik).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _hijauBrand = Color(0xFF1E3A2A);
  static const _mutedLabel = Color(0xFF6B7268);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              Spacer(flex: 5),
              LogoAvorea(skala: 1.15),
              SizedBox(height: 34),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 3, color: _hijauBrand),
              ),
              Spacer(flex: 6),
              Text(
                'AVOERA POS · BY WEBTALES STUDIO',
                style: TextStyle(color: _mutedLabel, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.2),
              ),
              SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
