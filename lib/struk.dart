import 'data.dart';

/// Desain struk thermal + printer pilihannya (v0.15.0,
/// permintaan Adnan 2026-11-17: tombol struk dengan pratinjau,
/// desain struk yang bisa diatur, dan cetak ke printer
/// thermal Bluetooth). Tersimpan LOKAL di perangkat.
class DesainStruk {
  DesainStruk({
    this.tampilAlamat = true,
    this.tampilTelepon = true,
    this.tampilTamu = true,
    this.teksHeader = '',
    this.teksFooter = 'Terima kasih sudah berkunjung!',
    this.teksTambahan = '',
    this.lebarKertas = 58,
    this.namaPrinter = '',
    this.idPrinter = '',
  });

  bool tampilAlamat;
  bool tampilTelepon;

  /// Baris jumlah tamu tampil di struk (bila transaksi
  /// mencatatnya).
  bool tampilTamu;

  /// Teks bebas di bawah nama usaha (slogan dsb.).
  String teksHeader;

  /// Teks penutup struk.
  String teksFooter;

  /// Teks tambahan paling bawah (WiFi, Instagram, dsb.).
  String teksTambahan;

  /// Lebar kertas printer: 58 atau 80 (mm).
  int lebarKertas;

  /// Printer thermal terpilih (kosong = belum diatur).
  String namaPrinter;
  String idPrinter;

  bool get printerSiap => idPrinter.isNotEmpty;

  /// Jumlah karakter per baris untuk lebar kertas ini
  /// (huruf standar ESC/POS: 58mm ≈ 32, 80mm ≈ 48).
  int get lebarKarakter => lebarKertas >= 80 ? 48 : 32;

  DesainStruk salin() => DesainStruk(
        tampilAlamat: tampilAlamat,
        tampilTelepon: tampilTelepon,
        tampilTamu: tampilTamu,
        teksHeader: teksHeader,
        teksFooter: teksFooter,
        teksTambahan: teksTambahan,
        lebarKertas: lebarKertas,
        namaPrinter: namaPrinter,
        idPrinter: idPrinter,
      );

  Map<String, dynamic> toJson() => {
        'tampilAlamat': tampilAlamat,
        'tampilTelepon': tampilTelepon,
        'tampilTamu': tampilTamu,
        'teksHeader': teksHeader,
        'teksFooter': teksFooter,
        'teksTambahan': teksTambahan,
        'lebarKertas': lebarKertas,
        'namaPrinter': namaPrinter,
        'idPrinter': idPrinter,
      };

  factory DesainStruk.fromJson(Map<String, dynamic> j) => DesainStruk(
        tampilAlamat: j['tampilAlamat'] as bool? ?? true,
        tampilTelepon: j['tampilTelepon'] as bool? ?? true,
        tampilTamu: j['tampilTamu'] as bool? ?? true,
        teksHeader: j['teksHeader'] as String? ?? '',
        teksFooter: j['teksFooter'] as String? ?? 'Terima kasih sudah berkunjung!',
        teksTambahan: j['teksTambahan'] as String? ?? '',
        lebarKertas: (j['lebarKertas'] as num?)?.toInt() ?? 58,
        namaPrinter: j['namaPrinter'] as String? ?? '',
        idPrinter: j['idPrinter'] as String? ?? '',
      );
}

/// Satu baris struk terstruktur — satu-satunya sumber isi
/// struk; pratinjau layar, teks bagikan, dan perintah ESC/POS
/// printer semuanya dirender dari daftar ini supaya tidak
/// pernah berbeda isi.
class BarisStruk {
  const BarisStruk.teks(this.teks, {this.rata = RataStruk.kiri, this.tebal = false, this.besar = false})
      : kiri = null,
        kanan = null;

  const BarisStruk.pasangan(this.kiri, this.kanan, {this.tebal = false, this.besar = false})
      : teks = null,
        rata = RataStruk.kiri;

  const BarisStruk.pemisah()
      : teks = null,
        kiri = null,
        kanan = null,
        rata = RataStruk.kiri,
        tebal = false,
        besar = false;

  final String? teks;
  final String? kiri;
  final String? kanan;
  final RataStruk rata;
  final bool tebal;
  final bool besar;

  bool get isPemisah => teks == null && kiri == null;
  bool get isPasangan => kiri != null;
}

enum RataStruk { kiri, tengah }

String _dua(int n) => n.toString().padLeft(2, '0');

/// Susun isi struk satu transaksi menurut desain. [namaUsaha]
/// dsb. dari Profil Usaha tersimpan.
List<BarisStruk> susunStruk({
  required TxRecord tx,
  required DesainStruk desain,
  required String namaUsaha,
  required String alamat,
  required String telepon,
  required String branchName,
}) {
  final b = <BarisStruk>[];
  b.add(BarisStruk.teks(namaUsaha.isEmpty ? 'AVOERA POS' : namaUsaha, rata: RataStruk.tengah, tebal: true, besar: true));
  if (desain.teksHeader.isNotEmpty) b.add(BarisStruk.teks(desain.teksHeader, rata: RataStruk.tengah));
  if (desain.tampilAlamat && alamat.isNotEmpty) b.add(BarisStruk.teks(alamat, rata: RataStruk.tengah));
  if (desain.tampilTelepon && telepon.isNotEmpty) b.add(BarisStruk.teks('Telp $telepon', rata: RataStruk.tengah));
  b.add(const BarisStruk.pemisah());
  b.add(BarisStruk.pasangan(tx.id, '${_dua(tx.at.day)}/${_dua(tx.at.month)}/${tx.at.year} ${_dua(tx.at.hour)}:${_dua(tx.at.minute)}'));
  if (branchName.isNotEmpty) b.add(BarisStruk.pasangan('Cabang', branchName));
  b.add(BarisStruk.pasangan('Metode', tx.method));
  if (desain.tampilTamu && tx.tamu > 0) b.add(BarisStruk.pasangan('Jumlah tamu', '${tx.tamu} orang'));
  b.add(const BarisStruk.pemisah());
  if (tx.lines.isNotEmpty) {
    for (final l in tx.lines) {
      b.add(BarisStruk.teks(l.nama, tebal: true));
      if (l.keterangan.isNotEmpty) b.add(BarisStruk.teks('  ${l.keterangan}'));
      final hargaSatuan = l.qty > 0 ? (l.total / l.qty).round() : l.total;
      b.add(BarisStruk.pasangan('  ${l.qty} x ${rupiah(hargaSatuan)}', rupiah(l.total)));
    }
  } else {
    b.add(BarisStruk.pasangan('Jumlah item', '${tx.items} item'));
    b.add(const BarisStruk.teks('(rincian item tidak tercatat)'));
  }
  b.add(const BarisStruk.pemisah());
  b.add(BarisStruk.pasangan('Subtotal', rupiah(tx.subtotal)));
  if (tx.service > 0) b.add(BarisStruk.pasangan('Biaya layanan', rupiah(tx.service)));
  if (tx.tax > 0) b.add(BarisStruk.pasangan('Pajak', rupiah(tx.tax)));
  if (tx.diskon > 0) b.add(BarisStruk.pasangan('Diskon${tx.promoNama.isNotEmpty ? ' (${tx.promoNama})' : ''}', '-${rupiah(tx.diskon)}'));
  b.add(BarisStruk.pasangan('TOTAL', rupiah(tx.total), tebal: true, besar: true));
  b.add(BarisStruk.pasangan('Status', tx.status));
  b.add(const BarisStruk.pemisah());
  if (desain.teksFooter.isNotEmpty) b.add(BarisStruk.teks(desain.teksFooter, rata: RataStruk.tengah));
  if (desain.teksTambahan.isNotEmpty) b.add(BarisStruk.teks(desain.teksTambahan, rata: RataStruk.tengah));
  return b;
}

/// Bungkus teks ke beberapa baris selebar [lebar] karakter.
List<String> bungkusTeks(String teks, int lebar) {
  final hasil = <String>[];
  for (final kata in teks.split(' ')) {
    if (hasil.isEmpty || (hasil.last.length + 1 + kata.length) > lebar) {
      hasil.add(kata);
    } else {
      hasil[hasil.length - 1] = '${hasil.last} $kata';
    }
  }
  return hasil.isEmpty ? [''] : hasil;
}

String _rataTengah(String teks, int lebar) {
  if (teks.length >= lebar) return teks;
  final kiri = (lebar - teks.length) ~/ 2;
  return '${' ' * kiri}$teks';
}

String _pasanganKeTeks(String kiri, String kanan, int lebar) {
  if (kiri.length + 1 + kanan.length <= lebar) {
    return '$kiri${' ' * (lebar - kiri.length - kanan.length)}$kanan';
  }
  // Tidak muat satu baris: kiri di baris sendiri, kanan di
  // baris berikutnya rata kanan.
  final kananBaris = '${' ' * (lebar - kanan.length)}$kanan';
  return '$kiri\n$kananBaris';
}

/// Render struk sebagai teks polos (untuk dibagikan).
String strukKeTeks(List<BarisStruk> baris, int lebar) {
  final out = <String>[];
  for (final b in baris) {
    if (b.isPemisah) {
      out.add('-' * lebar);
    } else if (b.isPasangan) {
      out.add(_pasanganKeTeks(b.kiri!, b.kanan!, lebar));
    } else {
      for (final potong in bungkusTeks(b.teks!, lebar)) {
        out.add(b.rata == RataStruk.tengah ? _rataTengah(potong, lebar) : potong);
      }
    }
  }
  return out.join('\n');
}

/// Bersihkan teks untuk printer thermal: printer hanya paham
/// ASCII dasar — aksen & tanda baca khusus diganti padanan
/// terdekatnya supaya tidak tercetak sebagai kotak.
String teksAmanPrinter(String s) => s
    .replaceAll('·', '-')
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('‘', "'")
    .replaceAll('’', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('…', '...')
    .replaceAll('Rp', 'Rp')
    .split('')
    .map((c) => c.codeUnitAt(0) < 128 ? c : '?')
    .join();

/// Render struk sebagai perintah ESC/POS siap kirim ke
/// printer thermal Bluetooth: inisialisasi, per baris dengan
/// rata/tebal/ukuran sesuai susunan, umpan kertas, potong.
List<int> strukKeEscPos(List<BarisStruk> baris, int lebar) {
  final out = <int>[];
  void perintah(List<int> b) => out.addAll(b);
  void tulis(String s) => out.addAll(teksAmanPrinter(s).codeUnits);

  perintah([0x1B, 0x40]); // ESC @ — inisialisasi
  perintah([0x1B, 0x74, 0x00]); // code page PC437 (ASCII aman)
  for (final b in baris) {
    if (b.isPemisah) {
      perintah([0x1B, 0x61, 0x00, 0x1B, 0x45, 0x00, 0x1D, 0x21, 0x00]);
      tulis('-' * lebar);
      perintah([0x0A]);
      continue;
    }
    // Rata: 0 kiri, 1 tengah.
    perintah([0x1B, 0x61, b.isPasangan || b.rata == RataStruk.kiri ? 0x00 : 0x01]);
    // Tebal: ESC E 1/0. Ukuran: GS ! — 0x11 = dobel lebar+tinggi.
    perintah([0x1B, 0x45, b.tebal ? 0x01 : 0x00]);
    perintah([0x1D, 0x21, b.besar ? 0x11 : 0x00]);
    final lebarEfektif = b.besar ? lebar ~/ 2 : lebar;
    if (b.isPasangan) {
      tulis(_pasanganKeTeks(teksAmanPrinter(b.kiri!), teksAmanPrinter(b.kanan!), lebarEfektif));
    } else {
      var pertama = true;
      for (final potong in bungkusTeks(teksAmanPrinter(b.teks!), lebarEfektif)) {
        if (!pertama) perintah([0x0A]);
        pertama = false;
        tulis(potong);
      }
    }
    perintah([0x0A]);
  }
  perintah([0x1B, 0x45, 0x00, 0x1D, 0x21, 0x00]);
  perintah([0x0A, 0x0A, 0x0A]);
  perintah([0x1D, 0x56, 0x01]); // GS V 1 — potong sebagian
  return out;
}
