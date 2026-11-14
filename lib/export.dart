import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

/// Ekspor laporan (permintaan Adnan 2026-11-14): setiap laporan &
/// daftar penting bisa dibagikan sebagai ringkasan teks (langsung
/// cocok untuk WhatsApp), berkas CSV, atau berkas PDF — TAPI selalu
/// lewat layar pratinjau dulu (lihat [bukaPratinjauLaporan]).

String toCsv(List<List<String>> rows) {
  String cell(String s) => s.contains(RegExp(r'[;",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  return rows.map((r) => r.map(cell).join(';')).join('\n');
}

Future<void> _bagikanTeks(String teks) => SharePlus.instance.share(ShareParams(text: teks));

Future<void> _bagikanBerkas(String nama, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$nama');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

/// Susun PDF laporan sederhana: judul, keterangan, tabel, catatan kaki.
Future<Uint8List> buatPdfLaporan({
  required String judul,
  required String keterangan,
  required List<String> kepala,
  required List<List<String>> baris,
  String catatan = '',
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text(judul, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(keterangan, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: kepala,
          data: baris,
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF059669)),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        ),
        if (catatan.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(catatan, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
        pw.SizedBox(height: 16),
        pw.Text('Dibuat oleh Avoera POS · Webtales Studio', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    ),
  );
  return doc.save();
}

/// Pintu ekspor SATU-SATUNYA (permintaan Adnan 2026-11-14):
/// laporan TIDAK boleh langsung dibagikan/disimpan/diunduh —
/// selalu tampil layar pratinjau dulu. Semua layar laporan &
/// daftar memanggil fungsi ini; tombol bagikan/simpan/unduh hanya
/// ada di dalam [PratinjauLaporanScreen].
/// [ringkasan] = teks siap kirim (WhatsApp), [kepala]+[baris] = isi
/// tabel untuk CSV & PDF.
Future<void> bukaPratinjauLaporan(
  BuildContext context, {
  required String judul,
  required String ringkasan,
  required List<String> kepala,
  required List<List<String>> baris,
  String catatan = '',
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PratinjauLaporanScreen(
        judul: judul,
        ringkasan: ringkasan,
        kepala: kepala,
        baris: baris,
        catatan: catatan,
      ),
    ),
  );
}

/// Layar pratinjau laporan: memperlihatkan laporan PERSIS wujud
/// jadinya — judul, keterangan, tabel berkepala hijau, catatan,
/// dan kaki dokumen yang sama dengan PDF dari [buatPdfLaporan]
/// (keduanya membaca nilai yang sama persis, jadi yang dilihat =
/// yang dibagikan). Kertasnya selalu putih seperti hasil cetak,
/// di mode terang maupun gelap.
class PratinjauLaporanScreen extends StatelessWidget {
  const PratinjauLaporanScreen({
    super.key,
    required this.judul,
    required this.ringkasan,
    required this.kepala,
    required this.baris,
    this.catatan = '',
  });

  final String judul;
  final String ringkasan;
  final List<String> kepala;
  final List<List<String>> baris;
  final String catatan;

  // Palet kertas cetak (tetap, tidak mengikuti mode aplikasi).
  static const _hitam = Color(0xFF111827);
  static const _abu = Color(0xFF6B7280);
  static const _garis = Color(0xFFE5E7EB);
  static const _hijau = Color(0xFF059669);

  String get _namaDasar => judul.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  /// Keterangan dokumen = baris pertama ringkasan — persis yang
  /// ditulis [buatPdfLaporan] di bawah judul PDF.
  String get _keterangan => ringkasan.split('\n').first;

  Future<Uint8List> _pdf() => buatPdfLaporan(judul: judul, keterangan: _keterangan, kepala: kepala, baris: baris, catatan: catatan);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Judul AppBar pendek tetap — nama laporan tampil besar di
      // kertas; "Pratinjau — Riwayat Transaksi" terpotong di HP.
      appBar: AppBar(title: const Text('Pratinjau Laporan')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul, style: const TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w700, color: _hitam)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_keterangan, style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: _abu)),
                    const SizedBox(height: AppSpacing.lg),
                    // Tabel sama susunannya dengan PDF: kepala hijau
                    // putih tebal, baris bergaris bawah tipis. Lebar
                    // minimal 640 — di layar sempit bisa digeser
                    // menyamping, di layar lebar memenuhi kertas.
                    // (560 bikin kolom tanggal 7-kolom cuma 80px —
                    // "14/11/2026" terpotong jadi dua baris.)
                    LayoutBuilder(
                      builder: (context, c) {
                        final lebar = c.maxWidth < 640 ? 640.0 : c.maxWidth;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: lebar,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Container(
                              color: _hijau,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  for (final k in kepala)
                                    Expanded(
                                      child: Text(k, style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ),
                                ],
                              ),
                            ),
                            for (final b in baris)
                              Container(
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _garis, width: 0.5))),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                                child: Row(
                                  children: [
                                    for (final sel in b)
                                      Expanded(
                                        child: Text(sel, style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: _hitam)),
                                      ),
                                  ],
                                ),
                              ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (catatan.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(catatan, style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: _abu)),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Dibuat oleh Avoera POS · Webtales Studio', style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: _abu)),
                  ],
                ),
              ),
            ),
          ),
          // Bar aksi ekspor — SATU-SATUNYA tempat bagikan/simpan/
          // unduh boleh jalan, dan hanya sesudah pratinjau tampil.
          Container(
            decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Bagikan PDF',
                        icon: Icons.share_outlined,
                        onPressed: () async {
                          final bytes = await _pdf();
                          await _bagikanBerkas('$_namaDasar.pdf', bytes);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                            icon: const Icon(Icons.save_alt, size: 16),
                            label: const Text('Simpan PDF', style: TextStyle(fontSize: 12), maxLines: 1),
                            onPressed: () async {
                              final bytes = await _pdf();
                              final dir = await getApplicationDocumentsDirectory();
                              final file = File('${dir.path}/$_namaDasar.pdf');
                              await file.writeAsBytes(bytes, flush: true);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('PDF tersimpan di ${file.path}')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                            icon: const Icon(Icons.table_chart_outlined, size: 16),
                            label: const Text('CSV', style: TextStyle(fontSize: 12), maxLines: 1),
                            onPressed: () => _bagikanBerkas('$_namaDasar.csv', toCsv([kepala, ...baris]).codeUnits),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                            icon: const Icon(Icons.chat_outlined, size: 16),
                            label: const Text('Teks WA', style: TextStyle(fontSize: 12), maxLines: 1),
                            onPressed: () => _bagikanTeks(ringkasan),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol bagikan untuk AppBar layar laporan — satu bentuk di mana-mana.
class TombolEkspor extends StatelessWidget {
  const TombolEkspor({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Bagikan / ekspor', onPressed: onPressed);
  }
}

/// PDF label harga (permintaan Adnan 2026-11-15 — fitur yang dulu
/// 'Segera'): lembar A4 berisi label-label siap potong — nama
/// usaha kecil di atas, nama menu, harga besar. Dicetak lalu
/// digunting untuk ditempel di etalase / daftar menu fisik.
Future<Uint8List> buatPdfLabel({
  required List<MenuItem> menus,
  required String businessName,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in menus)
              pw.Container(
                width: 168,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName.toUpperCase(),
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                      maxLines: 1,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      m.name,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      maxLines: 2,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(m.category, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      rupiah(m.price),
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF047857)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Text('Label harga $businessName · dibuat oleh Avoera POS', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    ),
  );
  return doc.save();
}

/// Bangun PDF label lalu buka lembar bagikan sistem.
Future<void> bagikanPdfLabel({
  required List<MenuItem> menus,
  required String businessName,
}) async {
  final bytes = await buatPdfLabel(menus: menus, businessName: businessName);
  await _bagikanBerkas('label-harga.pdf', bytes);
}
