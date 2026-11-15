import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'detail_transaksi_screen.dart';

/// Apakah waktu transaksi masuk rentang tanggal inklusif
/// (hari terakhir dihitung penuh sampai 23:59). Rentang null
/// = semua waktu.
bool txDalamRentang(DateTime at, DateTimeRange? r) {
  if (r == null) return true;
  return !at.isBefore(r.start) && at.isBefore(r.end.add(const Duration(days: 1)));
}

const _bulanSingkat = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _hariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Judul baris transaksi dari rincian itemnya (v0.10.9,
/// permintaan Adnan: tampilkan nama produk, bukan "1 item"):
/// nama produk pertama. Transaksi LAMA tanpa rincian
/// tersimpan tetap jujur: jumlah itemnya.
String ringkasanProdukTx(TxRecord t) {
  if (t.lines.isEmpty) return '${t.items} item';
  return t.lines.first.nama;
}

/// Jumlah produk LAIN sesudah produk pertama di baris ini
/// (v0.10.11: tampil sebagai "+N" di sebelah nama produk,
/// bukan lagi "+N lainnya" di subjudul — permintaan Adnan).
int jumlahTambahanTx(TxRecord t) {
  if (t.lines.length <= 1) return 0;
  return t.lines.length - 1;
}

/// Pencarian Riwayat (v0.10.11, permintaan Adnan): cocok bila
/// nomor transaksi mengandung teks cari (tak peka huruf),
/// ATAU nominal transaksi mengandung urutan angka yang
/// dicari (tanda titik dsb. diabaikan — '52.900' dan '52900'
/// sama-sama menemukan total 52900).
bool txCocokCari(TxRecord t, String cari) {
  final q = cari.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (t.id.toLowerCase().contains(q)) return true;
  final angka = q.replaceAll(RegExp(r'[^0-9]'), '');
  if (angka.isNotEmpty && t.total.toString().contains(angka)) return true;
  return false;
}

/// Label kartu total yang DINAMIS mengikuti saringan
/// (v0.10.11, permintaan Adnan — contohnya sendiri: "Total
/// semua transaksi"): metode + periode/rentang yang aktif.
String labelTotalRiwayat({required int filter, required String metode, String? labelRentang}) {
  final benda = metode == 'Semua' ? 'semua transaksi' : 'transaksi $metode';
  if (labelRentang != null) return 'Total $benda · $labelRentang';
  final ekor = switch (filter) {
    1 => ' hari ini',
    2 => ' minggu ini',
    3 => ' bulan ini',
    _ => '',
  };
  return 'Total $benda$ekor';
}

/// Badge status baris (v0.10.11, permintaan Adnan): baris
/// biasa (Lunas) TIDAK ber-badge; badge hanya untuk status
/// luar biasa — Batal (merah), Refund (kuning), Belum bayar
/// (abu). Null = tanpa badge.
({String label, Color latar, Color teks})? badgeStatusTx(TxRecord t) {
  switch (t.status) {
    case 'Batal':
      return (label: 'Batal', latar: AppColors.danger.withValues(alpha: AppColors.gelap ? 0.25 : 0.10), teks: AppColors.danger);
    case 'Refund':
      return (label: 'Refund', latar: AppColors.warningSoft, teks: AppColors.warning);
    case 'Belum bayar':
      return (label: 'Belum bayar', latar: AppColors.track, teks: AppColors.muted);
    default:
      return null;
  }
}

/// Kelompokkan transaksi per hari kalender, urutan mengikuti
/// daftar masuk (yang sudah terurut terbaru dulu).
Map<DateTime, List<TxRecord>> kelompokTxPerHari(List<TxRecord> daftar) {
  final grup = <DateTime, List<TxRecord>>{};
  for (final t in daftar) {
    final d = DateTime(t.at.year, t.at.month, t.at.day);
    grup.putIfAbsent(d, () => []).add(t);
  }
  return grup;
}

/// Label header kelompok: 'Hari ini · Min, 15 Nov 2026',
/// 'Kemarin · Sab, 14 Nov 2026', atau 'Kam, 13 Nov 2026'.
String labelHariTx(DateTime hari, DateTime sekarang) {
  final dasar = '${_hariSingkat[hari.weekday - 1]}, ${hari.day} ${_bulanSingkat[hari.month - 1]} ${hari.year}';
  final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  if (hari == hariIni) return 'Hari ini · $dasar';
  if (hari == hariIni.subtract(const Duration(days: 1))) return 'Kemarin · $dasar';
  return dasar;
}

/// Riwayat Transaksi = Laporan Transaksi: semua pembayaran yang
/// tercatat, bisa disaring per periode. Dibuka dari Beranda
/// (Lihat Semua) dan dari hub Laporan.
///
/// v0.10.11 (permintaan Adnan 2026-11-16 00:22, 7 poin dari
/// screenshot): gaya/struktur kartu v0.10.9 DIPERTAHANKAN,
/// dengan perubahan — (1) app bar bertombol kembali + ikon
/// kalender di sebelah ikon bagikan (kalender pindah dari
/// baris saringan); (2) saringan metode DIPISAH dari baris
/// periode jadi baris sendiri; (3) kolom pencarian nomor
/// transaksi / nominal di bawah chip; (4) label kartu total
/// dinamis mengikuti saringan; (5) badge 'Lunas' DIHAPUS dari
/// baris biasa — badge hanya untuk Batal/Refund/Belum bayar;
/// (6) subjudul baris = 'A-1045 · 12:10' (metode cukup dari
/// ikon) dan '+N' pindah ke sebelah nama produk; (7) garis
/// pemisah + bayangan kartu dilembutkan.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, required this.transactions, required this.branchId, this.branchName = ''});
  final List<TxRecord> transactions;
  final String branchId;

  /// Nama cabang aktif — diteruskan ke halaman Detail
  /// Transaksi. Kosong = tidak ditampilkan.
  final String branchName;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  int _filter = 0; // 0 semua, 1 hari ini, 2 minggu ini, 3 bulan ini
  String _metode = 'Semua'; // Semua / Tunai / QRIS

  /// Rentang tanggal pilihan sendiri (filter tanggal, diminta
  /// Adnan 2026-11-15). Selama terisi, saringan periode di
  /// atasnya tidak dipakai; memilih chip periode menghapusnya.
  DateTimeRange? _rentang;

  /// Kolom pencarian (v0.10.11): nomor transaksi atau nominal.
  final _cariController = TextEditingController();
  String _cari = '';

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _rentang,
    );
    if (hasil != null && mounted) setState(() => _rentang = hasil);
  }

  String _labelRentang() {
    final r = _rentang!;
    String f(DateTime d) => '${d.day} ${_bulanSingkat[d.month - 1]}';
    return r.start == r.end ? '${f(r.start)} ${r.start.year}' : '${f(r.start)} – ${f(r.end)} ${r.end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var list = widget.transactions.where((t) => t.branchId.isEmpty || t.branchId == widget.branchId).toList();
    if (_rentang != null) {
      list = list.where((t) => txDalamRentang(t.at, _rentang)).toList();
    } else if (_filter == 1) {
      list = list.where((t) => t.at.year == now.year && t.at.month == now.month && t.at.day == now.day).toList();
    } else if (_filter == 2) {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      list = list.where((t) => !t.at.isBefore(start)).toList();
    } else if (_filter == 3) {
      list = list.where((t) => t.at.year == now.year && t.at.month == now.month).toList();
    }
    if (_metode != 'Semua') {
      list = list.where((t) => t.method == _metode).toList();
    }
    if (_cari.trim().isNotEmpty) {
      list = list.where((t) => txCocokCari(t, _cari)).toList();
    }
    list.sort((a, b) => b.at.compareTo(a.at));
    final total = list.fold(0, (a, t) => a + t.total);
    final totalTunai = list.where((t) => t.method == 'Tunai').fold(0, (a, t) => a + t.total);
    final totalQris = list.where((t) => t.method == 'QRIS').fold(0, (a, t) => a + t.total);
    final grup = kelompokTxPerHari(list);
    // Bayangan lebih lembut khusus layar ini (poin 7 Adnan).
    final bayanganLembut = AppColors.gelap ? 0.18 : 0.03;
    final garisLembut = AppColors.border.withValues(alpha: 0.55);

    String dua(int n) => n.toString().padLeft(2, '0');
    Future<void> ekspor() {
      final ringkasan = StringBuffer('Riwayat Transaksi (${list.length} transaksi)\n');
      for (final t in list) {
        ringkasan.writeln('• ${t.at.day}/${t.at.month}/${t.at.year} ${dua(t.at.hour)}:${dua(t.at.minute)} · ${t.id} · ${t.method} — ${rupiah(t.total)}');
      }
      ringkasan.writeln('Total: ${rupiah(total)}');
      return bukaPratinjauLaporan(
        context,
        judul: 'Riwayat Transaksi',
        ringkasan: ringkasan.toString().trim(),
        kepala: const ['Tanggal', 'Jam', 'ID', 'Metode', 'Item', 'Subtotal', 'Biaya Layanan', 'Pajak', 'Total'],
        baris: [
          for (final t in list)
            [
              '${t.at.day}/${t.at.month}/${t.at.year}',
              '${dua(t.at.hour)}:${dua(t.at.minute)}',
              t.id,
              t.method,
              '${t.items}',
              '${t.subtotal}',
              '${t.service}',
              '${t.tax}',
              '${t.total}',
            ],
        ],
        catatan: 'Total periode: ${rupiah(total)}',
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Tombol kembali eksplisit (poin 1 Adnan) — layar ini
        // selalu dibuka sebagai rute tumpuk dari shell.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Riwayat Transaksi'),
        actions: [
          // Kalender pindah ke app bar, di sebelah bagikan.
          IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: _rentang != null ? AppColors.accent : null),
            tooltip: 'Pilih tanggal',
            onPressed: _pilihTanggal,
          ),
          TombolEkspor(onPressed: ekspor),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris PERIODE (metode sudah pindah ke baris
                // sendiri di bawah — poin 2 Adnan). Pil rentang
                // aktif tetap tampil di ujung baris ini.
                FilterChipRow(
                  children: [
                    for (final (i, label) in [(0, 'Semua'), (1, 'Hari Ini'), (2, 'Minggu Ini'), (3, 'Bulan Ini')])
                      AppChip(
                        label: label,
                        selected: _rentang == null && _filter == i,
                        onSelected: (_) => setState(() {
                          _filter = i;
                          _rentang = null;
                        }),
                      ),
                    if (_rentang != null) _PilRentang(label: _labelRentang(), onTap: _pilihTanggal, onHapus: () => setState(() => _rentang = null)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Baris METODE — terpisah dari periode.
                FilterChipRow(
                  children: [
                    for (final m in ['Semua', 'Tunai', 'QRIS'])
                      AppChip(label: m == 'Semua' ? 'Semua Metode' : m, selected: _metode == m, onSelected: (_) => setState(() => _metode = m)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Kolom pencarian (poin 3 Adnan).
                TextField(
                  controller: _cariController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari no. transaksi atau nominal',
                    suffixIcon: _cari.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _cariController.clear();
                              setState(() => _cari = '');
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _cari = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              shadowAlpha: bayanganLembut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelTotalRiwayat(filter: _filter, metode: _metode, labelRentang: _rentang != null ? _labelRentang() : null),
                              style: AppText.small.copyWith(color: AppColors.muted),
                            ),
                            FitNumber(rupiah(total)),
                          ],
                        ),
                      ),
                      Text('${list.length} transaksi', style: AppText.small.copyWith(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(height: 1, color: garisLembut),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _RincianMetode(ikon: Icons.payments_outlined, label: 'Tunai', nilai: totalTunai)),
                      Expanded(child: _RincianMetode(ikon: Icons.qr_code_2_outlined, label: 'QRIS', nilai: totalQris)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    message: _cari.trim().isNotEmpty ? 'Tidak ada transaksi yang cocok dengan pencarian.' : 'Belum ada transaksi pada periode ini.',
                    icon: Icons.receipt_long_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    children: [
                      for (final entri in grup.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(labelHariTx(entri.key, now), style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                              ),
                              Text(rupiah(entri.value.fold(0, (a, t) => a + t.total)), style: AppText.small.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        AppCard(
                          padding: EdgeInsets.zero,
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          shadowAlpha: bayanganLembut,
                          child: Column(
                            children: [
                              for (var i = 0; i < entri.value.length; i++) ...[
                                if (i > 0) Divider(height: 1, indent: 68, endIndent: AppSpacing.lg, color: garisLembut),
                                _BarisTx(
                                  tx: entri.value[i],
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => DetailTransaksiScreen(tx: entri.value[i], branchName: widget.branchName)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pil rentang tanggal aktif: hijau penuh seperti chip
/// terpilih; badan pil membuka pemilih lagi, tanda silang
/// menghapus saringan.
class _PilRentang extends StatelessWidget {
  const _PilRentang({required this.label, required this.onTap, required this.onHapus});
  final String label;
  final VoidCallback onTap;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.pill)),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.white),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onHapus,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppRadius.pill)),
            child: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.md),
              child: Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu sisi rincian metode di kartu total: ikon + label +
/// jumlah.
class _RincianMetode extends StatelessWidget {
  const _RincianMetode({required this.ikon, required this.label, required this.nilai});
  final IconData ikon;
  final String label;
  final int nilai;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 20, color: AppColors.accentDark),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.caption.copyWith(color: AppColors.muted)),
            Text(rupiah(nilai), style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

/// Baris transaksi padat di dalam kartu kelompok hari.
class _BarisTx extends StatelessWidget {
  const _BarisTx({required this.tx, required this.onTap});
  final TxRecord tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final jam = '${tx.at.hour.toString().padLeft(2, '0')}:${tx.at.minute.toString().padLeft(2, '0')}';
    final tambahan = jumlahTambahanTx(tx);
    final badge = badgeStatusTx(tx);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(tx.method == 'QRIS' ? Icons.qr_code_2_outlined : Icons.payments_outlined, color: AppColors.accentDark, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama produk + "+N" di sebelahnya (poin 6).
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ringkasanProdukTx(tx),
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tambahan > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text('+$tambahan', style: AppText.body.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Subjudul ringkas: nomor + jam saja; metode
                  // sudah terbaca dari ikon di kiri.
                  Text('${tx.id} · $jam', style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rupiah(tx.total), style: AppText.body.copyWith(fontWeight: FontWeight.w800)),
                // Badge HANYA untuk status luar biasa.
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(color: badge.latar, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(badge.label, style: AppText.caption.copyWith(color: badge.teks, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
