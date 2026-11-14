import 'dart:convert';

import 'package:avoera_pos/export.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.8.0: ekspor laporan — CSV harus aman untuk sel berisi
// pemisah/kutip, dan PDF harus berkas PDF asli.
void main() {
  test('toCsv mengutip sel yang berisi titik koma / kutip / baris baru', () {
    final csv = toCsv([
      ['Nama', 'Harga'],
      ['Kopi;Susu', '18000'],
      ['Teh "Manis"', '8000'],
      ['Baris\nBaru', '1000'],
    ]);
    final lines = csv.split('\n');
    expect(lines[0], 'Nama;Harga');
    expect(lines[1], '"Kopi;Susu";18000');
    expect(lines[2], '"Teh ""Manis""";8000');
    expect(csv.contains('"Baris\nBaru";1000'), isTrue);
  });

  test('buatPdfLaporan menghasilkan berkas PDF', () async {
    final bytes = await buatPdfLaporan(
      judul: 'Laporan Uji',
      keterangan: 'Keterangan uji',
      kepala: const ['A', 'B'],
      baris: const [
        ['1', '2'],
      ],
    );
    expect(bytes.length, greaterThan(200));
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
  });
}
