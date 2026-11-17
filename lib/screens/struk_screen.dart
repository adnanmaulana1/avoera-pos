import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data.dart';
import '../struk.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';

/// Pratinjau struk (v0.15.0): struk digambar persis mengikuti
/// Desain Struk tersimpan — apa yang terlihat di sini adalah
/// isi yang sama dengan yang dibagikan & dicetak ke printer
/// thermal (satu sumber: susunStruk di struk.dart). Tombol
/// Cetak hanya ada bila pemanggil memberinya (dari Detail
/// Transaksi); dari layar Desain Struk halaman ini contoh.
class StrukScreen extends StatefulWidget {
  const StrukScreen({
    super.key,
    required this.tx,
    required this.desain,
    required this.namaUsaha,
    required this.alamat,
    required this.telepon,
    required this.branchName,
    this.onCetak,
    this.onEditDesain,
  });

  final TxRecord tx;
  final DesainStruk desain;
  final String namaUsaha;
  final String alamat;
  final String telepon;
  final String branchName;

  /// Kirim struk ke printer thermal; mengembalikan pesan
  /// kesalahan atau null bila terkirim. Null (tanpa fungsi) =
  /// mode contoh, tombol Cetak disembunyikan.
  final Future<String?> Function()? onCetak;
  final VoidCallback? onEditDesain;

  @override
  State<StrukScreen> createState() => _StrukScreenState();
}

class _StrukScreenState extends State<StrukScreen> {
  bool _mencetak = false;

  List<BarisStruk> get _baris => susunStruk(
        tx: widget.tx,
        desain: widget.desain,
        namaUsaha: widget.namaUsaha,
        alamat: widget.alamat,
        telepon: widget.telepon,
        branchName: widget.branchName,
      );

  Future<void> _bagikan() async {
    final teks = strukKeTeks(_baris, widget.desain.lebarKarakter);
    await SharePlus.instance.share(ShareParams(text: teks));
  }

  Future<void> _cetak() async {
    if (widget.onCetak == null || _mencetak) return;
    setState(() => _mencetak = true);
    final pesan = await widget.onCetak!();
    if (!mounted) return;
    setState(() => _mencetak = false);
    tampilToast(context, pesan ?? 'Struk terkirim ke printer.', icon: pesan == null ? Ikon.check_circle_outline : Ikon.error_outline);
  }

  @override
  Widget build(BuildContext context) {
    final lebarKertas = widget.desain.lebarKertas >= 80 ? 400.0 : 320.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Struk'),
        actions: [
          if (widget.onEditDesain != null) IconButton(icon: const Icon(Ikon.edit_outlined), tooltip: 'Desain Struk', onPressed: widget.onEditDesain),
        ],
      ),
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          Center(
            child: Container(
              width: lebarKertas,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final b in _baris) _gambarBaris(b),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kertas ${widget.desain.lebarKertas} mm · ${widget.desain.lebarKarakter} karakter per baris',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: widget.onCetak == null
              ? Text('Ini contoh struk — buka dari Detail Transaksi untuk mencetak.', textAlign: TextAlign.center, style: AppText.small.copyWith(color: AppColors.muted))
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _bagikan,
                        icon: const Icon(Ikon.share_outlined, size: 19),
                        label: const Text('Bagikan'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: _mencetak ? 'Mengirim…' : 'Cetak',
                        icon: Ikon.print_outlined,
                        onPressed: _mencetak ? null : _cetak,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _gambarBaris(BarisStruk b) {
    const dasar = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: Color(0xFF111827));
    if (b.isPemisah) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('-' * widget.desain.lebarKarakter, style: dasar.copyWith(color: const Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.clip),
      );
    }
    final gaya = dasar.copyWith(
      fontWeight: b.tebal ? FontWeight.w700 : FontWeight.w400,
      fontSize: b.besar ? 17 : 13,
    );
    if (b.isPasangan) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(b.kiri!, style: gaya)),
          const SizedBox(width: 8),
          Text(b.kanan!, style: gaya, textAlign: TextAlign.right),
        ],
      );
    }
    return Text(
      b.teks!,
      style: gaya,
      textAlign: b.rata == RataStruk.tengah ? TextAlign.center : TextAlign.left,
    );
  }
}
