import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Pusat Pemberitahuan (difungsikan penuh 2026-11-15): daftar
/// pemberitahuan TERSIMPAN dari kejadian nyata — stok kritis &
/// habis, sinkron gagal. Yang belum dibaca berjudul tebal + titik
/// penanda; membuka halaman ini menandai semuanya dibaca.
class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key, required this.notifications});
  final List<AppNotification> notifications;

  (IconData, Color) _gaya(AppNotification n) {
    switch (n.jenis) {
      case 'stok':
        return n.judul.contains('habis')
            ? (Icons.error_outline, AppColors.danger)
            : (Icons.warning_amber_outlined, AppColors.warning);
      case 'sinkron':
        return (Icons.cloud_off_outlined, AppColors.danger);
      default:
        return (Icons.info_outline, AppColors.accentDark);
    }
  }

  String _waktu(DateTime w) {
    final jam = '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final hariIni = w.year == now.year && w.month == now.month && w.day == now.day;
    return hariIni ? 'Hari ini · $jam' : '${w.day}/${w.month}/${w.year} · $jam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pemberitahuan')),
      body: notifications.isEmpty
          ? const EmptyState(message: 'Tidak ada pemberitahuan.\nStok aman, semua berjalan baik.', icon: Icons.notifications_none_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];
                final (icon, color) = _gaya(n);
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.judul,
                                    style: AppText.body.copyWith(fontWeight: n.dibaca ? FontWeight.w600 : FontWeight.w800),
                                  ),
                                ),
                                if (!n.dibaca)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(n.isi, style: AppText.small.copyWith(color: AppColors.muted)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(_waktu(n.waktu), style: AppText.caption.copyWith(color: AppColors.muted)),
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
