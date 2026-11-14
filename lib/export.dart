import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'theme.dart';
import 'widgets.dart';

/// Ekspor laporan (permintaan Adnan 2026-11-14): setiap laporan &
/// daftar penting bisa dibagikan sebagai ringkasan teks (langsung
/// cocok untuk WhatsApp), berkas CSV, atau berkas PDF — dipilih
/// dari satu menu bagikan yang sama di semua layar.

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

/// Menu bagikan standar — dipanggil tombol bagikan di AppBar laporan.
/// [ringkasan] = teks siap kirim (WhatsApp), [kepala]+[baris] = isi
/// tabel untuk CSV & PDF.
Future<void> tampilkanMenuEkspor(
  BuildContext context, {
  required String judul,
  required String ringkasan,
  required List<String> kepala,
  required List<List<String>> baris,
  String catatan = '',
}) {
  final namaDasar = judul.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return showAppSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.md),
          Text('Bagikan $judul', style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          _PilihanEkspor(
            icon: Icons.chat_outlined,
            label: 'Ringkasan teks (WhatsApp)',
            sub: 'Teks rapi, langsung bisa diteruskan.',
            onTap: () {
              Navigator.of(ctx).pop();
              _bagikanTeks(ringkasan);
            },
          ),
          _PilihanEkspor(
            icon: Icons.table_chart_outlined,
            label: 'Berkas CSV',
            sub: 'Bisa dibuka di Excel / Google Sheets.',
            onTap: () async {
              Navigator.of(ctx).pop();
              await _bagikanBerkas('$namaDasar.csv', toCsv([kepala, ...baris]).codeUnits);
            },
          ),
          _PilihanEkspor(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Berkas PDF',
            sub: 'Dokumen rapi siap cetak / arsip.',
            onTap: () async {
              Navigator.of(ctx).pop();
              final bytes = await buatPdfLaporan(judul: judul, keterangan: ringkasan.split('\n').first, kepala: kepala, baris: baris, catatan: catatan);
              await _bagikanBerkas('$namaDasar.pdf', bytes);
            },
          ),
        ],
      ),
    ),
  );
}

class _PilihanEkspor extends StatelessWidget {
  const _PilihanEkspor({required this.icon, required this.label, required this.sub, required this.onTap});
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, color: AppColors.accentDark, size: 20),
      ),
      title: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: AppText.caption.copyWith(color: AppColors.muted)),
      onTap: onTap,
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
