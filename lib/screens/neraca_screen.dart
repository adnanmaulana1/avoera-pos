import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'laporan_bersama.dart';

/// Neraca — laporan posisi keuangan usaha pada satu tanggal
/// (update besar v0.11.0, diminta Adnan "detail"). Aktiva:
/// kas tunai perkiraan, saldo QRIS, persediaan bahan, piutang.
/// Pasiva: hutang belum lunas + modal (modal pemilik adalah
/// angka penyeimbang, laba ditahan dari Laba Rugi kumulatif).
/// Semua angka dari catatan aplikasi; catatan kejujuran di
/// kaki layar menjelaskan batasnya.
class NeracaScreen extends StatefulWidget {
  const NeracaScreen({
    super.key,
    required this.transactions,
    required this.menus,
    required this.ingredients,
    required this.expenses,
    required this.hutang,
    required this.branchId,
    required this.branchName,
  });

  final List<TxRecord> transactions;
  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final List<Pengeluaran> expenses;
  final List<Hutang> hutang;
  final String branchId;
  final String branchName;

  @override
  State<NeracaScreen> createState() => _NeracaScreenState();
}

class _NeracaScreenState extends State<NeracaScreen> {
  DateTime _tanggal = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final hasil = hitungNeraca(
      transactions: widget.transactions,
      menus: widget.menus,
      ingredients: widget.ingredients,
      expenses: widget.expenses,
      hutang: widget.hutang,
      branchId: widget.branchId,
      tanggal: _tanggal,
    );
    final stokBernilai = hasil.rincianPersediaan.where((r) => r.nilai > 0).toList();
    const batasRincian = 12;
    final stokTampil = stokBernilai.take(batasRincian).toList();
    final stokSisa = stokBernilai.skip(batasRincian).toList();
    final nilaiSisa = stokSisa.fold(0, (a, r) => a + r.nilai);

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Neraca — ${widget.branchName}')
        ..writeln('Posisi per ${labelTgl(_tanggal)}')
        ..writeln('Total Aktiva: ${rupiah(hasil.totalAktiva)}')
        ..writeln('Total Pasiva: ${rupiah(hasil.totalPasiva)} (seimbang)');
      return bukaPratinjauLaporan(
        context,
        judul: 'Neraca',
        ringkasan: r.toString().trim(),
        kepala: const ['Komponen', 'Jumlah'],
        baris: [
          ['AKTIVA', ''],
          ['Kas Tunai (perkiraan)', '${hasil.kasTunai}'],
          ['Saldo QRIS', '${hasil.saldoQris}'],
          ['Persediaan Bahan', '${hasil.nilaiPersediaan}'],
          ['Piutang Usaha', '${hasil.piutang}'],
          ['Total Aktiva', '${hasil.totalAktiva}'],
          ['KEWAJIBAN & MODAL', ''],
          ['Utang Usaha', '${hasil.utang}'],
          ['Modal Pemilik (penyeimbang)', '${hasil.modalPenyeimbang}'],
          ['Laba Ditahan', '${hasil.labaDitahan}'],
          ['Total Pasiva', '${hasil.totalPasiva}'],
        ],
        catatan: 'Kas adalah perkiraan dari catatan aplikasi. Persediaan dinilai dari stok & harga pokok terkini. Modal pemilik = angka penyeimbang.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neraca'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          Row(
            children: [
              Expanded(child: Text('Posisi per ${labelTgl(_tanggal)} · ${widget.branchName}', style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink))),
              TextButton.icon(
                onPressed: () async {
                  final pilih = await showDatePicker(
                    context: context,
                    initialDate: _tanggal,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    helpText: 'Posisi per tanggal',
                  );
                  if (pilih != null && mounted) setState(() => _tanggal = pilih);
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Ganti'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          KartuHero(
            label: 'Total Aktiva',
            nilai: rupiah(hasil.totalAktiva),
            keterangan: 'Total Pasiva ${rupiah(hasil.totalPasiva)} · ${hasil.seimbang ? 'SEIMBANG ✓' : 'BELUM SEIMBANG'}',
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.account_balance_wallet_outlined, teks: 'Aktiva (yang dimiliki usaha)'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Kas Tunai', catatan: 'Perkiraan: penjualan tunai lunas − pengeluaran tercatat', nilai: rupiah(hasil.kasTunai)),
                const GarisTipis(),
                BarisNilai(label: 'Saldo QRIS', catatan: 'Penjualan QRIS lunas tercatat (belum dikurangi biaya di luar aplikasi)', nilai: rupiah(hasil.saldoQris)),
                const GarisTipis(),
                BarisNilai(label: 'Persediaan Bahan', catatan: '${hasil.rincianPersediaan.length} bahan · stok & harga pokok terkini', nilai: rupiah(hasil.nilaiPersediaan)),
                const GarisTipis(),
                BarisNilai(label: 'Piutang Usaha', catatan: hasil.jumlahPiutang > 0 ? '${hasil.jumlahPiutang} tagihan belum dibayar' : 'Tidak ada tagihan menggantung', nilai: rupiah(hasil.piutang)),
                const GarisTipis(),
                BarisNilai(label: 'Total Aktiva', nilai: rupiah(hasil.totalAktiva), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.inventory_2_outlined, teks: 'Rincian Persediaan'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: stokBernilai.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text('Belum ada bahan yang bernilai (stok kosong atau harga pokok belum diisi).', style: AppText.body.copyWith(color: AppColors.muted)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < stokTampil.length; i++) ...[
                        if (i > 0) const GarisTipis(),
                        BarisNilai(
                          label: stokTampil[i].bahan.name,
                          catatan: '${teksStok(stokTampil[i].stok)} ${stokTampil[i].satuan} × ${rupiah(stokTampil[i].hargaPokok)}',
                          nilai: rupiah(stokTampil[i].nilai),
                        ),
                      ],
                      if (stokSisa.isNotEmpty) ...[
                        const GarisTipis(),
                        BarisNilai(label: '+ ${stokSisa.length} bahan lain', nilai: rupiah(nilaiSisa)),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.balance_outlined, teks: 'Kewajiban & Modal'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Utang Usaha', catatan: hasil.jumlahUtang > 0 ? '${hasil.jumlahUtang} catatan hutang belum lunas' : 'Tidak ada hutang tercatat', nilai: rupiah(hasil.utang)),
                const GarisTipis(),
                BarisNilai(label: 'Total Kewajiban', nilai: rupiah(hasil.totalKewajiban), tebal: true),
                const GarisTipis(),
                BarisNilai(label: 'Modal Pemilik', catatan: 'Angka penyeimbang: aktiva − kewajiban − laba ditahan', nilai: rupiah(hasil.modalPenyeimbang)),
                const GarisTipis(),
                BarisNilai(label: 'Laba Ditahan', catatan: 'Akumulasi laba bersih sampai tanggal ini (rincian di bawah)', nilai: rupiah(hasil.labaDitahan)),
                const GarisTipis(),
                BarisNilai(label: 'Total Modal', nilai: rupiah(hasil.totalModal), tebal: true),
                const GarisTipis(),
                BarisNilai(label: 'Total Pasiva', nilai: rupiah(hasil.totalPasiva), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.trending_up_outlined, teks: 'Rincian Laba Ditahan'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Pendapatan Kumulatif', catatan: 'Semua penjualan lunas sampai tanggal ini', nilai: rupiah(hasil.pendapatanKumulatif)),
                const GarisTipis(),
                BarisNilai(label: 'HPP Kumulatif', catatan: 'Modal bahan dari resep & harga pokok kini', nilai: '-${rupiah(hasil.hppKumulatif)}'),
                const GarisTipis(),
                BarisNilai(label: 'Biaya Operasional Kumulatif', nilai: '-${rupiah(hasil.biayaKumulatif)}'),
                const GarisTipis(),
                BarisNilai(label: 'Laba Ditahan', nilai: rupiah(hasil.labaDitahan), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Catatan: neraca ini disusun dari catatan di aplikasi. Kas tunai adalah perkiraan (pembelian bahan dan pergerakan uang di luar aplikasi tidak tercatat di sini). Persediaan selalu dinilai dengan stok & harga pokok TERKINI, bukan pada tanggal posisi. Piutang dari transaksi berstatus "Belum bayar".',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
