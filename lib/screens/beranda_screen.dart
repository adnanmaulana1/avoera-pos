import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../update.dart';
import '../widgets.dart';
import '../ikon.dart';

/// Beranda: layar pembuka ala referensi Bisakasir (permintaan Adnan
/// 2026-11-14), diisi ANGKA ASLI dari transaksi yang tercatat.
/// v0.7.0: + grafik penjualan (Mingguan/Bulanan), Transaksi Terbaru,
/// pemilih cabang, dan lonceng pemberitahuan.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({
    super.key,
    required this.businessName,
    required this.branch,
    required this.branches,
    required this.transactions,
    required this.kitchenActive,
    required this.kitchenEnabled,
    required this.menuCount,
    required this.syncStatus,
    required this.onSyncTap,
    required this.tablesEnabled,
    required this.tablesOccupied,
    required this.tablesTotal,
    required this.noticeCount,
    required this.onOpenKasir,
    required this.onNavigate,
    required this.onManageTables,
    required this.onManageIngredients,
    required this.onSwitchBranch,
    required this.onOpenNotices,
    required this.onOpenRiwayat,
    this.infoUpdate,
    this.onTapUpdate,
  });

  final String businessName;
  final Branch branch;
  final List<Branch> branches;
  final List<TxRecord> transactions;
  final int kitchenActive;
  final bool kitchenEnabled;
  final int menuCount;

  /// Indikator awan: status sinkron Supabase + aksi ketuknya
  /// (sinkron sekarang / buka pengaturan sinkron).
  final StatusSinkron syncStatus;
  final VoidCallback onSyncTap;
  final bool tablesEnabled;
  final int tablesOccupied;
  final int tablesTotal;
  final int noticeCount;
  final VoidCallback onOpenKasir;
  final ValueChanged<int> onNavigate;
  final VoidCallback onManageTables;
  final VoidCallback onManageIngredients;
  final ValueChanged<Branch> onSwitchBranch;
  final VoidCallback onOpenNotices;
  final VoidCallback onOpenRiwayat;

  /// Pembaruan aplikasi yang tersedia (dari cek versi server).
  /// Null = tidak ada banner. Ketuk banner → alur unduh+pasang
  /// di cangkang utama.
  final InfoUpdate? infoUpdate;
  final VoidCallback? onTapUpdate;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  bool _bulanan = false;

  String _sapaan(DateTime now) {
    final h = now.hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _hariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _tanggal(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Transaksi cabang aktif (transaksi lama tanpa cabang dianggap
  /// milik cabang yang sedang aktif).
  List<TxRecord> get _tx => widget.transactions.where((t) => t.branchId.isEmpty || t.branchId == widget.branch.id).toList();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tx = _tx;
    final todayTx = tx.where((t) => _sameDay(t.at, now)).toList();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayTotal = tx.where((t) => _sameDay(t.at, yesterday)).fold(0, (a, t) => a + t.total);
    final totalToday = todayTx.fold(0, (a, t) => a + t.total);
    final countToday = todayTx.length;
    final avgToday = countToday == 0 ? 0 : (totalToday / countToday).round();
    final jam = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    int? pct;
    if (yesterdayTotal > 0) {
      pct = ((totalToday - yesterdayTotal) / yesterdayTotal * 100).round();
    }
    final latest = [...tx]..sort((a, b) => b.at.compareTo(a.at));

    final tiles = <(IconData, String, VoidCallback)>[
      if (widget.tablesEnabled) (Ikon.table_restaurant_outlined, 'Meja', () => widget.onNavigate(3)),
      if (widget.kitchenEnabled) (Ikon.soup_kitchen_outlined, 'Dapur', () => widget.onNavigate(4)),
      (Ikon.inventory_2_outlined, 'Produk', () => widget.onNavigate(2)),
      (Ikon.bar_chart_outlined, 'Laporan', () => widget.onNavigate(5)),
      (Ikon.inventory_outlined, 'Stok Bahan', () => widget.onNavigate(6)),
      (Ikon.settings_outlined, 'Pengaturan', () => widget.onNavigate(7)),
      if (widget.tablesEnabled) (Ikon.table_bar_outlined, 'Atur Meja', widget.onManageTables),
      (Ikon.fact_check_outlined, 'Atur Stok', widget.onManageIngredients),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sapaan(now), style: AppText.pageTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_tanggal(now), style: AppText.small.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            // Ikon awan = indikator sinkron online (Supabase).
            IconButton(
              tooltip: switch (widget.syncStatus) {
                StatusSinkron.belumDiatur => 'Sinkron awan belum diatur',
                StatusSinkron.menyinkron => 'Sedang menyinkronkan…',
                StatusSinkron.tersinkron => 'Data tersinkron ke awan',
                StatusSinkron.gagal => 'Sinkron gagal — ketuk untuk coba lagi',
              },
              onPressed: widget.onSyncTap,
              icon: switch (widget.syncStatus) {
                StatusSinkron.belumDiatur => Icon(Ikon.cloud_off_outlined, color: AppColors.muted),
                StatusSinkron.menyinkron => const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accent),
                  ),
                StatusSinkron.tersinkron => const Icon(Ikon.cloud_done_outlined, color: AppColors.accentDark),
                StatusSinkron.gagal => const Icon(Ikon.cloud_off_outlined, color: AppColors.danger),
              },
            ),
            IconButton(
              tooltip: 'Pemberitahuan',
              onPressed: widget.onOpenNotices,
              icon: Badge(
                isLabelVisible: widget.noticeCount > 0,
                label: Text('${widget.noticeCount}'),
                backgroundColor: AppColors.danger,
                child: const Icon(Ikon.notifications_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            // Chip cabang: ketuk untuk pindah cabang (bila > 1).
            if (widget.branches.length > 1)
              PopupMenuButton<Branch>(
                onSelected: widget.onSwitchBranch,
                itemBuilder: (_) => widget.branches
                    .map((b) => PopupMenuItem<Branch>(value: b, child: Text(b.id == widget.branch.id ? '${b.name} ✓' : b.name)))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.branch.name, style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
                      const Icon(Ikon.expand_more, size: 16, color: AppColors.accentDark),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(widget.branch.name, style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: AppSpacing.md),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: AppSpacing.sm),
            Text('Aktif', style: AppText.small.copyWith(color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Banner pembaruan tinggal DI BAWAH sapaan + cabang
        // (v0.10.12 — Adnan mempertanyakan posisi lamanya di
        // paling atas, mendahului sapaan). Tawaran utamanya
        // kini dialog yang muncul sendiri; banner ini
        // pengingat tenangnya.
        if (widget.infoUpdate != null && widget.onTapUpdate != null) ...[
          BannerUpdate(info: widget.infoUpdate!, onTap: widget.onTapUpdate!),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Kartu penjualan: emerald pekat satu warna (bukan gradasi),
        // satu-satunya elemen berbayangan di aplikasi + tekstur dua
        // lingkaran sewarna.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpenRiwayat,
          child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.heroCard,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -70,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                  ),
                ),
                Positioned(
                  right: 60,
                  bottom: -80,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Penjualan hari ini', style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('Diperbarui $jam', style: AppText.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FitNumber(rupiah(totalToday), style: AppText.display.copyWith(color: Colors.white)),
                      const SizedBox(height: AppSpacing.md),
                      if (pct != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.pill)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(pct >= 0 ? Ikon.trending_up : Ikon.trending_down, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    pct >= 0 ? '+$pct%' : '$pct%',
                                    style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('dibanding kemarin', style: AppText.small.copyWith(color: Colors.white70)),
                          ],
                        )
                      else if (totalToday > 0)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.pill)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Ikon.show_chart, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('Mulai tercatat', style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('kemarin belum ada penjualan', style: AppText.small.copyWith(color: Colors.white70)),
                          ],
                        )
                      else
                        Text('Penjualan tercatat otomatis setiap ada pembayaran di kasir.', style: AppText.small.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // SATU kartu lebar isi 3 kolom (pilihan Adnan
        // 2026-11-17: tiga kartu terpisah terasa sempit di HP).
        // Kolom dipisah garis tipis; tiap kolom tetap bisa
        // diketuk ke tujuan yang sama seperti kartu lamanya.
        // Tinggi dikunci 88 seperti sebelumnya.
        SizedBox(
          height: 88,
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KolomStat(label: 'Transaksi', value: '$countToday', onTap: widget.onOpenRiwayat),
                const _PemisahStat(),
                _KolomStat(label: 'Rata-rata', value: rupiah(avgToday), onTap: widget.onOpenRiwayat),
                const _PemisahStat(),
                widget.kitchenEnabled
                    ? _KolomStat(label: 'Di Dapur', value: '${widget.kitchenActive}', onTap: () => widget.onNavigate(4))
                    : _KolomStat(label: 'Menu Dijual', value: '${widget.menuCount}', onTap: () => widget.onNavigate(2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChartCard(tx: tx, bulanan: _bulanan, onToggle: (b) => setState(() => _bulanan = b), hariSingkat: _hariSingkat, onTap: () => widget.onNavigate(5)),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Ikon.point_of_sale_outlined, color: AppColors.accentDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kasir', style: AppText.subtitle),
                    Text(
                      [
                        if (widget.tablesEnabled) '${widget.tablesOccupied} dari ${widget.tablesTotal} meja terisi',
                        if (widget.kitchenEnabled) '${widget.kitchenActive} pesanan di dapur',
                        if (!widget.tablesEnabled && !widget.kitchenEnabled) 'Siap melayani pesanan',
                      ].join(' · '),
                      style: AppText.small.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              PrimaryButton(label: 'Buka Kasir', onPressed: widget.onOpenKasir),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Transaksi Terbaru (pola referensi): kosong → ajakan buka
        // kasir; ada isi → 5 transaksi terakhir + Lihat Semua.
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Transaksi Terbaru', style: AppText.subtitle),
                  const Spacer(),
                  TextButton(onPressed: widget.onOpenRiwayat, child: const Text('Lihat Semua')),
                ],
              ),
              if (latest.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: const Icon(Ikon.receipt_long_outlined, color: AppColors.accentDark, size: 28),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Belum ada transaksi', style: AppText.subtitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Transaksi dari kasir akan muncul di sini.', style: AppText.small.copyWith(color: AppColors.muted)),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(label: 'Buka Kasir', onPressed: widget.onOpenKasir),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ] else
                for (final t in latest.take(5))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Icon(t.method == 'QRIS' ? Ikon.qr_code_2_outlined : Ikon.payments_outlined, color: AppColors.accentDark, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${t.id} · ${t.method}', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                '${t.at.hour.toString().padLeft(2, '0')}:${t.at.minute.toString().padLeft(2, '0')} · ${t.items} item',
                                style: AppText.caption.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(rupiah(t.total), style: AppText.body.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Menu cepat', style: AppText.title),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            // Persegi 1:1 persis (keluhan Adnan 2026-11-15: ubin
            // menu cepat lebih tinggi daripada lebarnya).
            childAspectRatio: 1,
          ),
          itemCount: tiles.length,
          itemBuilder: (_, i) {
            final (icon, label, action) = tiles[i];
            return Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: action,
                child: Container(
                  decoration: cardDecoration(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(icon, color: AppColors.accentDark, size: 20),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Satu kolom statistik di dalam kartu lebar Beranda: label
/// redup + angka FitNumber (menyusut sendiri bila panjang).
/// Material transparan + InkWell agar sentuhan terlihat di
/// atas permukaan kartu.
class _KolomStat extends StatelessWidget {
  const _KolomStat({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppText.small.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.xs),
                FitNumber(value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Garis pemisah tegak antar kolom statistik — menjorok dari
/// tepi atas-bawah kartu agar terlihat ringan.
class _PemisahStat extends StatelessWidget {
  const _PemisahStat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Container(width: 1, color: AppColors.border),
    );
  }
}

/// Grafik batang penjualan: Mingguan = 8 hari terakhir (per hari),
/// Bulanan = 4 minggu terakhir (per minggu). Angka ASLI dari
/// transaksi tercatat; hari ini / minggu ini disorot aksen.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.tx, required this.bulanan, required this.onToggle, required this.hariSingkat, this.onTap});
  final VoidCallback? onTap;
  final List<TxRecord> tx;
  final bool bulanan;
  final ValueChanged<bool> onToggle;
  final List<String> hariSingkat;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final values = <int>[];
    final labels = <String>[];
    if (!bulanan) {
      for (var i = 7; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        values.add(tx.where((t) => t.at.year == d.year && t.at.month == d.month && t.at.day == d.day).fold(0, (a, t) => a + t.total));
        labels.add(hariSingkat[d.weekday - 1]);
      }
    } else {
      for (var w = 3; w >= 0; w--) {
        final start = today.subtract(Duration(days: w * 7 + 6));
        final end = today.subtract(Duration(days: w * 7));
        values.add(tx.where((t) {
          final d = DateTime(t.at.year, t.at.month, t.at.day);
          return !d.isBefore(start) && !d.isAfter(end);
        }).fold(0, (a, t) => a + t.total));
        labels.add('Mg ${4 - w}');
      }
    }
    final maxV = values.fold(0, (a, b) => b > a ? b : a);
    final scaleMax = maxV == 0 ? 100000 : maxV;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(bulanan ? 'Penjualan 4 Minggu Terakhir' : 'Penjualan 8 Hari Terakhir', style: AppText.subtitle),
              ),
              AppChip(label: 'Mingguan', selected: !bulanan, onSelected: (_) => onToggle(false)),
              const SizedBox(width: AppSpacing.sm),
              AppChip(label: 'Bulanan', selected: bulanan, onSelected: (_) => onToggle(true)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sumbu nilai: 4 tingkat.
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var f = 4; f >= 0; f--)
                      Text(ringkas((scaleMax * f / 4).round()), style: AppText.caption.copyWith(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < values.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // softWrap mati: label seperti
                                // '175 rb' TIDAK boleh membungkus
                                // jadi 2 baris — kolom batang
                                // sempit, bungkusan membuat kolom
                                // meluap 6px dari kotak 150px
                                // (ketahuan 2026-11-15 saat render
                                // Beranda berdata penjualan asli).
                                Text(ringkas(values[i]), style: AppText.caption.copyWith(color: AppColors.muted), softWrap: false),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  height: values[i] == 0 ? 3 : 8 + 92 * values[i] / scaleMax,
                                  decoration: BoxDecoration(
                                    color: i == values.length - 1 ? AppColors.chartBarActive : AppColors.chartBar,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xs)),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  labels[i],
                                  style: AppText.caption.copyWith(
                                    color: i == values.length - 1 ? AppColors.accentDark : AppColors.muted,
                                    fontWeight: i == values.length - 1 ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (maxV == 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text('Belum ada penjualan pada periode ini.', style: AppText.caption.copyWith(color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}
