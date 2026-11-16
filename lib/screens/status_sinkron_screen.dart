import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../sync.dart';
import '../theme.dart';
import '../widgets.dart';

/// Halaman Status Sinkronisasi (permintaan Adnan 2026-11-15):
/// Pengaturan kini cukup menampilkan saklar Cloud Sync + pintu ke
/// halaman ini. Di sini lengkap: apa yang MENUNGGU terkirim, apa
/// yang GAGAL + sebabnya, tombol sinkron manual, tombol Perbarui
/// Semua Data, dan pengaturan Supabase-nya sendiri.
///
/// Nilai dibaca lewat getter + penanda ubah ([penanda]) supaya
/// halaman yang sedang terbuka ikut segar sesudah sinkron selesai.
class StatusSinkronScreen extends StatefulWidget {
  const StatusSinkronScreen({
    super.key,
    required this.penanda,
    required this.ambilLaporan,
    required this.ambilKotor,
    required this.ambilRingkasan,
    required this.ambilSedang,
    required this.cloudSyncEnabled,
    required this.siap,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.businessKey,
    required this.onSupabaseChanged,
    required this.onSinkron,
    required this.onPerbaruiSemua,
  });

  final ValueListenable<int> penanda;
  final List<StatusTabel> Function() ambilLaporan;
  final Map<String, int> Function() ambilKotor;
  final String Function() ambilRingkasan;
  final bool Function() ambilSedang;
  final bool cloudSyncEnabled;
  final bool siap;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String businessKey;
  final void Function(String url, String anonKey, String businessKey) onSupabaseChanged;
  final Future<void> Function() onSinkron;
  final Future<void> Function() onPerbaruiSemua;

  @override
  State<StatusSinkronScreen> createState() => _StatusSinkronScreenState();
}

class _StatusSinkronScreenState extends State<StatusSinkronScreen> {
  @override
  void initState() {
    super.initState();
    widget.penanda.addListener(_segar);
  }

  @override
  void dispose() {
    widget.penanda.removeListener(_segar);
    super.dispose();
  }

  void _segar() {
    if (mounted) setState(() {});
  }

  Future<void> _perbaruiSemua() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perbarui Semua Data'),
        content: const Text(
          'Semua data lokal diunggah ulang, lalu data server ditarik dan digabungkan, dan hasil gabungannya diunggah sekali lagi. '
          'Pakai ini bila data antar perangkat terasa tidak cocok. Data tidak ada yang dihapus.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          PrimaryButton(label: 'Perbarui Semua', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok == true) await widget.onPerbaruiSemua();
  }

  Future<void> _editText({
    required String title,
    required String initial,
    required String hint,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initial);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          PrimaryButton(label: 'Simpan', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (saved == true) onSave(controller.text.trim());
    disposeControllersLater([controller]);
  }

  @override
  Widget build(BuildContext context) {
    final laporan = widget.ambilLaporan();
    final kotor = widget.ambilKotor();
    final sedang = widget.ambilSedang();
    final menunggu = kotor.entries.where((e) => e.value > 0).toList();
    final gagal = laporan.where((r) => !r.berhasil).toList();
    final bisaSinkron = widget.siap && widget.cloudSyncEnabled && !sedang;

    final (ikonStatus, warnaStatus) = !widget.siap
        ? (Icons.cloud_off_outlined, AppColors.muted)
        : !widget.cloudSyncEnabled
            ? (Icons.cloud_off_outlined, AppColors.muted)
            : gagal.isNotEmpty
                ? (Icons.cloud_off_outlined, AppColors.danger)
                : sedang
                    ? (Icons.sync, AppColors.accentDark)
                    : (Icons.cloud_done_outlined, AppColors.accent);

    return Scaffold(
      appBar: AppBar(title: const Text('Status Sinkronisasi')),
      body: ListView(
        // Bawah ditambah inset sistem: teks terakhir jangan
        // tertutup navbar Android (keluhan Adnan 2026-11-15).
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: warnaStatus.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(ikonStatus, color: warnaStatus, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !widget.siap
                            ? 'Belum diatur'
                            : !widget.cloudSyncEnabled
                                ? 'Cloud Sync mati'
                                : sedang
                                    ? 'Sedang menyinkron…'
                                    : gagal.isNotEmpty
                                        ? 'Ada yang gagal'
                                        : 'Tersinkron',
                        style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.ambilRingkasan(), style: AppText.small.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Menunggu Terkirim'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: menunggu.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('Tidak ada yang menunggu — semua perubahan sudah terkirim.', style: AppText.small.copyWith(color: AppColors.muted)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < menunggu.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 68),
                        _BarisStatus(
                          icon: Icons.schedule_outlined,
                          warna: AppColors.warning,
                          label: labelTabelSinkron(menunggu[i].key),
                          nilai: '${menunggu[i].value} perubahan',
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Hasil Sinkron Terakhir'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: laporan.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('Belum pernah sinkron pada sesi ini.', style: AppText.small.copyWith(color: AppColors.muted)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < laporan.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 68),
                        _BarisStatus(
                          icon: laporan[i].berhasil ? Icons.check_circle_outline : Icons.error_outline,
                          warna: laporan[i].berhasil ? AppColors.accent : AppColors.danger,
                          label: laporan[i].label,
                          nilai: laporan[i].berhasil ? '${laporan[i].jumlah} data' : 'Gagal',
                          galat: laporan[i].galat,
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: sedang ? 'Sedang Menyinkron…' : 'Sinkronkan Sekarang',
            icon: Icons.sync,
            onPressed: bisaSinkron ? () => widget.onSinkron() : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: bisaSinkron ? _perbaruiSemua : null,
              icon: const Icon(Icons.cloud_sync_outlined, size: 19),
              label: const Text('Perbarui Semua Data'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Pengaturan Supabase'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _BarisAtur(
                  icon: Icons.cloud_outlined,
                  label: 'URL Proyek Supabase',
                  nilai: widget.supabaseUrl.isEmpty ? 'Belum diisi' : 'Sudah diisi',
                  onTap: () => _editText(
                    title: 'URL Proyek Supabase',
                    initial: widget.supabaseUrl,
                    hint: 'https://xxxx.supabase.co',
                    onSave: (v) => widget.onSupabaseChanged(v, widget.supabaseAnonKey, widget.businessKey),
                  ),
                ),
                const Divider(height: 1, indent: 68),
                _BarisAtur(
                  icon: Icons.key_outlined,
                  label: 'Kunci Anon Supabase',
                  nilai: widget.supabaseAnonKey.isEmpty ? 'Belum diisi' : 'Sudah diisi',
                  onTap: () => _editText(
                    title: 'Kunci Anon Supabase',
                    initial: widget.supabaseAnonKey,
                    hint: 'eyJhbGciOi...',
                    onSave: (v) => widget.onSupabaseChanged(widget.supabaseUrl, v, widget.businessKey),
                  ),
                ),
                const Divider(height: 1, indent: 68),
                _BarisAtur(
                  icon: Icons.qr_code_2_outlined,
                  label: 'Kode Usaha',
                  nilai: widget.businessKey.isEmpty ? 'Belum ada' : widget.businessKey,
                  onTap: () => _editText(
                    title: 'Kode Usaha',
                    initial: widget.businessKey,
                    hint: 'cth. kopisenja-2026',
                    onSave: (v) => widget.onSupabaseChanged(widget.supabaseUrl, widget.supabaseAnonKey, v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Kode Usaha yang sama di semua perangkat = data menyatu.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Nama ramah untuk kunci tabel sinkron.
String labelTabelSinkron(String kunci) => switch (kunci) {
      'menus' => 'Menu',
      'ingredients' => 'Bahan',
      'branches' => 'Cabang',
      'transactions' => 'Transaksi',
      'settings' => 'Pengaturan',
      _ => kunci,
    };

class _BarisStatus extends StatelessWidget {
  const _BarisStatus({required this.icon, required this.warna, required this.label, required this.nilai, this.galat});
  final IconData icon;
  final Color warna;
  final String label;
  final String nilai;
  final String? galat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: warna),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                if (galat != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(galat!, style: AppText.caption.copyWith(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          Text(nilai, style: AppText.small.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BarisAtur extends StatelessWidget {
  const _BarisAtur({required this.icon, required this.label, required this.nilai, required this.onTap});
  final IconData icon;
  final String label;
  final String nilai;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(icon, size: 20, color: AppColors.accentDark),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
            Text(nilai, style: AppText.small.copyWith(color: AppColors.muted)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
