import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Satu baris pesanan yang ditampilkan di halaman Pembayaran
/// (nama, keterangan varian/catatan, jumlah, total baris).
class BarisBayar {
  const BarisBayar({required this.nama, this.keterangan = '', required this.qty, required this.total});

  final String nama;
  final String keterangan;
  final int qty;
  final int total;
}

/// Halaman Pembayaran PENUH (v0.10.1, permintaan Adnan
/// 2026-11-15): dulu dialog melayang — sempit, tombol Proses
/// Bayar menimpa kolom saat keyboard naik. v0.10.2: tampilan
/// diperkaya atas keluhan Adnan "terlalu sederhana" — kartu
/// total emerald besar (bahasa visual yang sama dengan kartu
/// penjualan Beranda), rincian pesanan asli dari keranjang,
/// metode sebagai kartu pilih bergambar, nominal sebagai ubin
/// besar, dan kartu status kembalian/kurang. Perilaku tidak
/// berubah: mengembalikan nama metode ('Tunai'/'QRIS') saat
/// dibayar, null bila dibatalkan (tombol kembali).
class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({
    super.key,
    required this.subtotal,
    required this.service,
    required this.tax,
    required this.grandTotal,
    required this.servicePercent,
    required this.taxPercent,
    this.items = const [],
    this.diskon = 0,
    this.promoNama = '',
  });

  final int subtotal;
  final int service;
  final int tax;
  final int grandTotal;
  final int servicePercent;
  final int taxPercent;
  final List<BarisBayar> items;

  /// Diskon promo yang sudah dikurangkan dari [grandTotal]
  /// (v0.11.0; 0 = tanpa promo) + nama promonya untuk baris
  /// rincian di kartu total.
  final int diskon;
  final String promoNama;

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String _method = 'Tunai';
  int? _paid;
  // Kolom nominal & ubin berbagi satu nilai: memilih ubin
  // mengisi kolom (berformat titik), mengetik memperbarui ubin.
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _bisaProses => _method != 'Tunai' || (_paid != null && _paid! >= widget.grandTotal);

  void _pilihNominal(int amt) => setState(() {
        _paid = amt;
        _amountCtrl.text = ThousandsFormatter.format(amt);
      });

  @override
  Widget build(BuildContext context) {
    final change = (_paid ?? 0) - widget.grandTotal;
    final totalQty = widget.items.fold<int>(0, (a, b) => a + b.qty);
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ===== Kartu total: angka terpenting halaman ini =====
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total bayar', style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                    if (widget.items.isNotEmpty)
                      Text('$totalQty item', style: AppText.small.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(rupiah(widget.grandTotal), style: AppText.display.copyWith(color: Colors.white)),
                const SizedBox(height: AppSpacing.md),
                Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: AppSpacing.sm),
                _totalRow('Subtotal', widget.subtotal),
                _totalRow('Biaya layanan (${widget.servicePercent}%)', widget.service),
                _totalRow('Pajak (${widget.taxPercent}%)', widget.tax),
                if (widget.diskon > 0) _totalRow('Diskon${widget.promoNama.isNotEmpty ? ' · ${widget.promoNama}' : ''}', -widget.diskon),
              ],
            ),
          ),
          // ===== Rincian pesanan dari keranjang =====
          if (widget.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Rincian pesanan', style: AppText.subtitle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < widget.items.length; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Text('×${widget.items[i].qty}', style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.items[i].nama, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                              if (widget.items[i].keterangan.isNotEmpty)
                                Text(widget.items[i].keterangan, style: AppText.small.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(rupiah(widget.items[i].total), style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          // ===== Metode pembayaran: kartu pilih =====
          const SizedBox(height: AppSpacing.xl),
          Text('Metode pembayaran', style: AppText.subtitle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _kartuMetode('Tunai', Icons.payments_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _kartuMetode('QRIS', Icons.qr_code_2)),
            ],
          ),
          if (_method == 'Tunai') ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Uang diterima', style: AppText.subtitle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _ubinNominal(widget.grandTotal, 'Uang pas', caption: rupiah(widget.grandTotal))),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _ubinNominal(50000, rupiah(50000))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _ubinNominal(100000, rupiah(100000))),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _ubinNominal(200000, rupiah(200000))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: 'atau ketik nominal sendiri'),
              onChanged: (v) => setState(() => _paid = int.tryParse(v.replaceAll('.', ''))),
            ),
            if (_paid != null) ...[
              const SizedBox(height: AppSpacing.md),
              if (_paid! < widget.grandTotal)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Masih kurang ${rupiah(widget.grandTotal - _paid!)}', style: AppText.body.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(
                    children: [
                      Icon(Icons.savings_outlined, color: AppColors.accentDark, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Kembalian: ${rupiah(change)}', style: AppText.body.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ] else ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: cardDecoration(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(Icons.qr_code_2, size: 120, color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Tampilkan QR ini ke pelanggan', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Pelanggan memindai kode untuk membayar ${rupiah(widget.grandTotal)}.', style: AppText.small.copyWith(color: AppColors.muted), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Kode QR asli muncul saat QRIS SoraPay aktif.', style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_method == 'Tunai' && _paid == null) ...[
                Text('Pilih nominal atau ketik jumlah uang diterima.', style: AppText.small.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.sm),
              ],
              PrimaryButton(
                label: 'Proses Bayar',
                onPressed: _bisaProses ? () => Navigator.of(context).pop(_method) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Baris rincian di dalam kartu total (di atas latar emerald).
  Widget _totalRow(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.small.copyWith(color: Colors.white.withValues(alpha: 0.8))),
            Text(rupiah(value), style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  /// SATU sistem kartu tombol pilih (perbaikan Adnan 2026-11-16
  /// + update identitas v0.12.0): metode bayar dan ubin nominal
  /// memakai rangka yang sama persis — tinggi tetap 76, radius
  /// sama, perlakuan terpilih sama. Terpilih TIDAK lagi diisi
  /// pastel: cukup garis aksen 2px + isi berwarna aksen di atas
  /// permukaan kartu. Tanpa ikon centang (aturan permanen).
  Widget _kartuPilih({required bool aktif, required VoidCallback? onTap, required Widget isi, bool redup = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: redup ? AppColors.track : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: aktif ? AppColors.accent : AppColors.border, width: aktif ? 2 : 1),
          ),
          child: isi,
        ),
      ),
    );
  }

  /// Kartu pilih metode (Tunai/QRIS) — rangka [_kartuPilih].
  Widget _kartuMetode(String method, IconData icon) {
    final aktif = _method == method;
    return _kartuPilih(
      aktif: aktif,
      onTap: () => setState(() => _method = method),
      isi: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: aktif ? AppColors.accentDark : AppColors.muted),
          const SizedBox(height: 6),
          Text(method, style: AppText.subtitle.copyWith(fontSize: 14, color: aktif ? AppColors.accentDark : AppColors.ink)),
        ],
      ),
    );
  }

  /// Ubin nominal — rangka [_kartuPilih] yang sama dengan kartu
  /// metode; nominal di bawah total (selain Uang pas) redup & mati.
  Widget _ubinNominal(int amt, String label, {String? caption}) {
    final aktif = _paid == amt;
    final bisa = amt >= widget.grandTotal;
    return _kartuPilih(
      aktif: aktif,
      redup: !bisa,
      onTap: bisa ? () => _pilihNominal(amt) : null,
      isi: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.subtitle.copyWith(fontSize: 14, color: !bisa ? AppColors.muted : (aktif ? AppColors.accentDark : AppColors.ink))),
          if (caption != null)
            Text(caption, style: AppText.caption.copyWith(color: aktif ? AppColors.accentDark : AppColors.muted)),
        ],
      ),
    );
  }
}
