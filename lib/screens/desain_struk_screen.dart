import 'package:flutter/material.dart';

import '../data.dart';
import '../printer.dart';
import '../struk.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';
import 'kelola_widgets.dart';
import 'printer_screen.dart';
import 'struk_screen.dart';

/// Desain Struk & Printer (v0.15.0): atur isi struk (teks
/// pembuka/penutup/tambahan, saklar tampil alamat/telepon/
/// tamu, lebar kertas) dan printer thermal Bluetooth-nya.
/// Perubahan berlaku sesudah tombol Simpan ditekan; tombol
/// Pratinjau menggambar struk contoh dengan isian TERKINI
/// (belum tersimpan pun terlihat).
class DesainStrukScreen extends StatefulWidget {
  const DesainStrukScreen({
    super.key,
    required this.awal,
    required this.namaUsaha,
    required this.alamat,
    required this.telepon,
    required this.branchName,
    required this.onSimpan,
  });

  final DesainStruk awal;
  final String namaUsaha;
  final String alamat;
  final String telepon;
  final String branchName;
  final void Function(DesainStruk) onSimpan;

  @override
  State<DesainStrukScreen> createState() => _DesainStrukScreenState();
}

class _DesainStrukScreenState extends State<DesainStrukScreen> {
  late DesainStruk _d = widget.awal.salin();
  late final _headerCtrl = TextEditingController(text: _d.teksHeader);
  late final _footerCtrl = TextEditingController(text: _d.teksFooter);
  late final _tambahanCtrl = TextEditingController(text: _d.teksTambahan);
  bool _mengetes = false;

  @override
  void dispose() {
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    _tambahanCtrl.dispose();
    super.dispose();
  }

  DesainStruk get _terkini => _d.salin()
    ..teksHeader = _headerCtrl.text.trim()
    ..teksFooter = _footerCtrl.text.trim()
    ..teksTambahan = _tambahanCtrl.text.trim();

  /// Transaksi contoh untuk pratinjau & tes cetak.
  TxRecord get _contohTx => TxRecord(
        id: 'A-0123',
        at: DateTime.now(),
        method: 'Tunai',
        items: 3,
        subtotal: 58000,
        service: 2900,
        tax: 5800,
        total: 66700,
        tamu: 2,
        lines: [
          TxLine(nama: 'Alpukat Kocok Original', qty: 2, total: 36000),
          TxLine(nama: 'Alpukat Kocok Coklat', keterangan: 'Less sugar', qty: 1, total: 22000),
        ],
      );

  Future<void> _cariPrinter() async {
    final pilih = await Navigator.of(context).push<PrinterDipilih>(MaterialPageRoute(builder: (_) => const PrinterScreen()));
    if (pilih == null || !mounted) return;
    setState(() {
      _d.namaPrinter = pilih.nama;
      _d.idPrinter = pilih.id;
    });
    tampilToast(context, 'Printer dipilih: ${pilih.nama.isEmpty ? pilih.id : pilih.nama}', icon: Ikon.print_outlined);
  }

  Future<void> _tesCetak() async {
    if (_mengetes) return;
    setState(() => _mengetes = true);
    final d = _terkini;
    final bytes = strukKeEscPos(
      susunStruk(tx: _contohTx, desain: d, namaUsaha: widget.namaUsaha, alamat: widget.alamat, telepon: widget.telepon, branchName: widget.branchName),
      d.lebarKarakter,
    );
    final pesan = await PrinterTermal.cetak(d.idPrinter, bytes);
    if (!mounted) return;
    setState(() => _mengetes = false);
    tampilToast(context, pesan ?? 'Tes cetak terkirim — periksa printer.', icon: pesan == null ? Ikon.check_circle_outline : Ikon.error_outline);
  }

  void _pratinjau() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StrukScreen(
          tx: _contohTx,
          desain: _terkini,
          namaUsaha: widget.namaUsaha,
          alamat: widget.alamat,
          telepon: widget.telepon,
          branchName: widget.branchName,
        ),
      ),
    );
  }

  void _simpan() {
    widget.onSimpan(_terkini);
    tampilToast(context, 'Desain struk & printer tersimpan.', icon: Ikon.check_circle_outline);
    Navigator.of(context).pop();
  }

  Widget _barisSaklar(String label, String keterangan, bool nilai, ValueChanged<bool> onUbah) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink)),
                Text(keterangan, style: AppText.caption.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          Switch(value: nilai, onChanged: onUbah, activeThumbColor: AppColors.accent),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Desain Struk & Printer')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          const SectionTitle('Printer Thermal'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Ikon.print_outlined, color: AppColors.accentDark, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _d.printerSiap ? (_d.namaPrinter.isEmpty ? _d.idPrinter : _d.namaPrinter) : 'Belum ada printer',
                            style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          Text(
                            _d.printerSiap ? 'Dipakai tombol Cetak di Detail Transaksi.' : 'Hubungkan printer thermal Bluetooth untuk mencetak struk.',
                            style: AppText.caption.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cariPrinter,
                        icon: const Icon(Ikon.bluetooth, size: 19),
                        label: Text(_d.printerSiap ? 'Ganti Printer' : 'Cari Printer'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                    ),
                    if (_d.printerSiap) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _mengetes ? null : _tesCetak,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                          child: Text(_mengetes ? 'Mengirim…' : 'Tes Cetak'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_d.printerSiap)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _d.namaPrinter = '';
                        _d.idPrinter = '';
                      }),
                      child: const Text('Lupakan printer ini'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Desain Struk'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                _barisSaklar('Alamat usaha', 'Dari Profil Usaha', _d.tampilAlamat, (v) => setState(() => _d.tampilAlamat = v)),
                const Divider(height: 17),
                _barisSaklar('Nomor telepon', 'Dari Profil Usaha', _d.tampilTelepon, (v) => setState(() => _d.tampilTelepon = v)),
                const Divider(height: 17),
                _barisSaklar('Jumlah tamu', 'Tampil bila kasir mencatatnya', _d.tampilTamu, (v) => setState(() => _d.tampilTamu = v)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FormLabel('Teks pembuka (di bawah nama usaha)'),
          TextField(
            controller: _headerCtrl,
            decoration: const InputDecoration(hintText: 'Mis. Bikin Harimu Lebih Segar!'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FormLabel('Teks penutup'),
          TextField(
            controller: _footerCtrl,
            decoration: const InputDecoration(hintText: 'Mis. Terima kasih sudah berkunjung!'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FormLabel('Teks tambahan (paling bawah)'),
          TextField(
            controller: _tambahanCtrl,
            decoration: const InputDecoration(hintText: 'Mis. WiFi: AvoreaGuest · Instagram: @avorea'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FormLabel('Lebar kertas printer'),
          FilterChipRow(
            children: [
              AppChip(label: '58 mm', selected: _d.lebarKertas == 58, onSelected: (_) => setState(() => _d.lebarKertas = 58)),
              AppChip(label: '80 mm', selected: _d.lebarKertas == 80, onSelected: (_) => setState(() => _d.lebarKertas = 80)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _pratinjau,
            icon: const Icon(Ikon.visibility_outlined, size: 19),
            label: const Text('Lihat Pratinjau'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Simpan', icon: Ikon.check, onPressed: _simpan),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Catatan: cetak thermal hanya bisa dibuktikan di perangkat asli dengan printer menyala — bila gagal, pesan kesalahannya tampil apa adanya.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
