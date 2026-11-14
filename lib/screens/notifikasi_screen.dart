import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

/// Satu pemberitahuan di pusat notifikasi.
class AppNotice {
  const AppNotice({required this.title, required this.body, required this.danger});
  final String title;
  final String body;
  final bool danger;
}

/// Pusat Pemberitahuan (v0.7.0): pemberitahuan di dalam aplikasi
/// dari keadaan nyata — stok habis & stok kritis. Pemberitahuan
/// sistem (push) menyusul bersama backend.
class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key, required this.notices});
  final List<AppNotice> notices;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pemberitahuan')),
      body: notices.isEmpty
          ? const EmptyState(message: 'Tidak ada pemberitahuan.\nStok aman, semua berjalan baik.', icon: Icons.notifications_none_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: notices.length,
              itemBuilder: (_, i) {
                final n = notices[i];
                final color = n.danger ? AppColors.danger : AppColors.warning;
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Icon(n.danger ? Icons.error_outline : Icons.warning_amber_outlined, color: color, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(n.body, style: AppText.small.copyWith(color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
