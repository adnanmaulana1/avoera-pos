import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Pusat Pemberitahuan: daftar pemberitahuan TERSIMPAN dari
/// kejadian nyata — stok kritis & habis, sinkron gagal. Yang
/// belum dibaca berjudul tebal + titik penanda.
///
/// v0.10.1 (permintaan Adnan 2026-11-15): pill kategori untuk
/// menyaring (Semua/Stok/Sinkron/Info) + tombol 'Tandai semua
/// terbaca'. Menandai dibaca kini EKSPLISIT lewat tombol itu —
/// membuka halaman tidak lagi menandai otomatis, supaya titik
/// belum-dibaca tidak hilang tanpa tindakan pengguna.
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key, required this.notifications, this.onTandaiSemuaDibaca, this.onTapNotification});
  final List<AppNotification> notifications;
  final VoidCallback? onTandaiSemuaDibaca;

  /// v0.10.8 (permintaan Adnan 2026-11-15 22:38): pemberitahuan
  /// yang punya TUJUAN bisa diketuk — stok membuka Stok Bahan,
  /// sinkron membuka Status Sinkronisasi, info pembaruan
  /// memulai pembaruan. Induk yang menavigasi.
  final ValueChanged<AppNotification>? onTapNotification;

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  String _kategori = 'Semua';

  static const _labelKategori = {'stok': 'Stok', 'sinkron': 'Sinkron', 'info': 'Info'};

  List<AppNotification> get _list => _kategori == 'Semua' ? widget.notifications : widget.notifications.where((n) => n.jenis == _kategori).toList();

  bool get _adaBelumDibaca => widget.notifications.any((n) => !n.dibaca);

  /// Pemberitahuan ini punya halaman tujuan bila diketuk?
  bool _bisaDibuka(AppNotification n) {
    if (n.jenis == 'stok' || n.jenis == 'sinkron') return true;
    return n.jenis == 'info' && n.kunci.startsWith('update-');
  }

  (IconData, Color) _gaya(AppNotification n) {
    switch (n.jenis) {
      case 'stok':
        return n.judul.contains('habis') ? (Icons.error_outline, AppColors.danger) : (Icons.warning_amber_outlined, AppColors.warning);
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
    final semua = widget.notifications;
    final list = _list;
    return Scaffold(
      appBar: AppBar(title: const Text('Pemberitahuan')),
      body: semua.isEmpty
          ? const EmptyState(message: 'Tidak ada pemberitahuan.\nStok aman, semua berjalan baik.', icon: Icons.notifications_none_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: FilterChipRow(
                    children: [
                      AppChip(label: 'Semua', selected: _kategori == 'Semua', onSelected: (_) => setState(() => _kategori = 'Semua')),
                      for (final jenis in _labelKategori.keys)
                        if (semua.any((n) => n.jenis == jenis))
                          AppChip(label: _labelKategori[jenis]!, selected: _kategori == jenis, onSelected: (_) => setState(() => _kategori = jenis)),
                    ],
                  ),
                ),
                if (_adaBelumDibaca)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: TextButton.icon(
                        onPressed: () {
                          widget.onTandaiSemuaDibaca?.call();
                          setState(() {});
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Tandai semua terbaca'),
                      ),
                    ),
                  ),
                Expanded(
                  child: list.isEmpty
                      ? const EmptyState(message: 'Tidak ada pemberitahuan di kategori ini.', icon: Icons.notifications_none_outlined)
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final n = list[i];
                            final (icon, color) = _gaya(n);
                            final bisaDibuka = _bisaDibuka(n) && widget.onTapNotification != null;
                            return AppCard(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              onTap: bisaDibuka ? () => widget.onTapNotification!(n) : null,
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
                                  if (bisaDibuka)
                                    Padding(
                                      padding: const EdgeInsets.only(left: AppSpacing.sm, top: 12),
                                      child: Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
