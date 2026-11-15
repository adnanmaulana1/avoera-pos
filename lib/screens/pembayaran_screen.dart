import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Halaman Pembayaran PENUH (v0.10.1, permintaan Adnan
/// 2026-11-15): dulu dialog melayang — sempit, tombol Proses
/// Bayar menimpa kolom saat keyboard naik. Kini halaman
/// tersendiri: rincian di kartu, pilihan uang diterima, status
/// kurang/kembalian + tombol Proses Bayar menempel di bawah.
/// Mengembalikan nama metode ('Tunai'/'QRIS') saat dibayar,
/// null bila dibatalkan (tombol kembali).
class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({
    super.key,
    required this.subtotal,
    required this.service,
    required this.tax,
    required this.grandTotal,
    required this.servicePercent,
    required this.taxPercent,
  });

  final int subtotal;
  final int service;
  final int tax;
  final int grandTotal;
  final int servicePercent;
  final int taxPercent;

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String _method = 'Tunai';
  int? _paid;
  // Kolom nominal & chip berbagi satu nilai: memilih chip
  // mengisi kolom (berformat titik), mengetik memperbarui chip.
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _bisaProses => _method != 'Tunai' || (_paid != null && _paid! >= widget.grandTotal);

  @override
  Widget build(BuildContext context) {
    final change = (_paid ?? 0) - widget.grandTotal;
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('Metode pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final m in ['Tunai', 'QRIS'])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: m,
                    selected: _method == m,
                    onSelected: (_) => setState(() => _method = m),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _payRow('Subtotal', widget.subtotal),
                _payRow('Biaya layanan (${widget.servicePercent}%)', widget.service),
                _payRow('Pajak (${widget.taxPercent}%)', widget.tax),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total bayar'),
                    Text(rupiah(widget.grandTotal), style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          if (_method == 'Tunai') ...[
            const SizedBox(height: AppSpacing.lg),
            const Text('Uang diterima', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final amt in [widget.grandTotal, 50000, 100000, 200000])
                  AppChip(
                    label: amt == widget.grandTotal ? 'Uang pas' : rupiah(amt),
                    selected: _paid == amt,
                    onSelected: amt >= widget.grandTotal
                        ? (_) => setState(() {
                              _paid = amt;
                              _amountCtrl.text = ThousandsFormatter.format(amt);
                            })
                        : null,
                  ),
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
          ] else ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: cardDecoration(),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2, size: 96, color: AppColors.ink),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Tampilkan QR ini ke pelanggan', style: AppText.small.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_method == 'Tunai') ...[
                if (_paid == null)
                  Text('Pilih nominal atau ketik jumlah uang diterima.', style: AppText.small.copyWith(color: AppColors.muted))
                else if (_paid! < widget.grandTotal)
                  Text('Masih kurang ${rupiah(widget.grandTotal - _paid!)}', style: AppText.small.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700))
                else
                  Text('Kembalian: ${rupiah(change)}', style: AppText.body.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w800)),
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
}

/// Baris ringkasan kecil (Subtotal dsb) di kartu rincian.
Widget _payRow(String label, int value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.small.copyWith(color: AppColors.muted)),
          Text(rupiah(value), style: AppText.small),
        ],
      ),
    );
