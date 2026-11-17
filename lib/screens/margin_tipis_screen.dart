import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';
import 'laporan_bersama.dart';

/// Laporan Margin Tipis (v0.15.0, menuntaskan baris 'Segera'
/// terakhir di hub Laporan): semua menu diurutkan dari margin
/// paling tipis — margin = (harga jual − HPP) ÷ harga jual,
/// HPP dari resep × harga beli bahan SAAT INI. Menu tanpa
/// resep atau yang harga bahannya belum diisi TIDAK ikut
/// urutan; mereka dikumpulkan di bawah dengan alasannya,
/// supaya pemilik tahu persis data apa yang kurang.
class MarginTipisScreen extends StatefulWidget {
  const MarginTipisScreen({
    super.key,
    required this.menus,
    required this.ingredients,
    required this.transactions,
    required this.branchId,
    required this.branchName,
  });

  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final List<TxRecord> transactions;
  final String branchId;
  final String branchName;

  @override
  State<MarginTipisScreen> createState() => _MarginTipisScreenState();
}

/// Persen untuk tampilan: bulat tanpa desimal, pecahan satu
/// desimal dengan koma ('12%' / '12,5%').
String teksPersen(double v) {
  if (v == v.roundToDouble()) return '${v.toInt()}%';
  return '${v.toStringAsFixed(1).replaceAll('.', ',')}%';
}

class _MarginTipisScreenState extends State<MarginTipisScreen> {
  RentangPeriode _rentang = rentangBulanIni();

  Color _warnaPersen(double persen) => persen < 15 ? AppColors.danger : (persen < 30 ? AppColors.warning : AppColors.accentDark);

  @override
  Widget build(BuildContext context) {
    final semua = hitungMarginMenu(menus: widget.menus, ingredients: widget.ingredients);
    final terhitung = semua.where((m) => m.status == StatusMargin.terhitung).toList();
    final belum = semua.where((m) => m.status != StatusMargin.terhitung).toList();
    final terjual = jumlahTerjualPerMenu(transactions: widget.transactions, branchId: widget.branchId, dari: _rentang.dari, sampai: _rentang.sampai);
    final tipis = terhitung.isEmpty ? null : terhitung.first;

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Margin Tipis — ${widget.branchName}')
        ..writeln(tipis == null ? 'Belum ada menu yang marginnya bisa dihitung.' : 'Margin paling tipis: ${tipis.menu.name} (${teksPersen(tipis.persen)})')
        ..writeln('Terhitung: ${terhitung.length} menu · Belum terhitung: ${belum.length} menu');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Margin Tipis',
        ringkasan: r.toString().trim(),
        kepala: const ['Menu', 'Harga Jual', 'HPP', 'Untung/Porsi', 'Margin', 'Terjual'],
        baris: [
          for (final m in terhitung) [m.menu.name, rupiah(m.menu.price), rupiah(m.hpp), rupiah(m.untung), teksPersen(m.persen), '${terjual[m.menu.name] ?? 0}'],
          for (final m in belum) [m.menu.name, rupiah(m.menu.price), '-', '-', m.status == StatusMargin.tanpaResep ? 'Belum ada resep' : 'Harga bahan belum diisi', '${terjual[m.menu.name] ?? 0}'],
        ],
        catatan: 'Margin = (harga jual − HPP) ÷ harga jual. HPP dari resep × harga beli bahan saat ini. Kolom Terjual mengikuti periode terpilih (${_rentang.label}).',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Margin Tipis'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          KartuHero(
            label: 'Margin Paling Tipis',
            nilai: tipis == null ? '—' : teksPersen(tipis.persen),
            keterangan: tipis == null
                ? 'Belum ada menu yang bisa dihitung — isi resep & harga beli bahan dulu.'
                : '${tipis.menu.name} · untung ${rupiah(tipis.untung)}/porsi dari harga ${rupiah(tipis.menu.price)}',
          ),
          const SizedBox(height: AppSpacing.lg),
          PemilihPeriode(onChanged: (r) => setState(() => _rentang = r)),
          const SizedBox(height: AppSpacing.xs),
          Text('Kolom "terjual" mengikuti periode: ${_rentang.label}.', style: AppText.caption.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.lg),
          if (terhitung.isNotEmpty) ...[
            const JudulSeksi(ikon: Ikon.show_chart_outlined, teks: 'Urutan margin — paling tipis di atas'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < terhitung.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(terhitung[i].menu.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                Text(
                                  'Harga ${rupiah(terhitung[i].menu.price)} · HPP ${rupiah(terhitung[i].hpp)} · untung ${rupiah(terhitung[i].untung)}/porsi · terjual ${terjual[terhitung[i].menu.name] ?? 0}',
                                  style: AppText.caption.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          StatusChip(label: teksPersen(terhitung[i].persen), color: _warnaPersen(terhitung[i].persen)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (belum.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const JudulSeksi(ikon: Ikon.error_outline, teks: 'Belum bisa dihitung'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < belum.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(belum[i].menu.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                Text('Harga ${rupiah(belum[i].menu.price)}', style: AppText.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          StatusChip(
                            label: belum[i].status == StatusMargin.tanpaResep ? 'Belum ada resep' : 'Harga bahan belum diisi',
                            color: belum[i].status == StatusMargin.tanpaResep ? AppColors.muted : AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Catatan: margin dihitung dari resep & harga beli bahan SAAT INI, bukan saat transaksi terjadi. Merah di bawah 15%, kuning di bawah 30%. Menu paket dihitung dari HPP komponen-komponennya.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
