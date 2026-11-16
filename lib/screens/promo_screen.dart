import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart';
import 'laporan_bersama.dart';

/// Promo & Diskon (update besar v0.11.0): kelola promo yang
/// bisa dipakai kasir saat pembayaran (persen atau potongan
/// nominal, syarat belanja minimum opsional, saklar aktif) +
/// ringkasan pemakaian dari transaksi yang tercatat. Satu
/// promo per transaksi; diskon tercatat di transaksi
/// (TxRecord.diskon) jadi Laba Rugi & Riwayat tetap akurat.
class PromoScreen extends StatelessWidget {
  const PromoScreen({
    super.key,
    required this.promos,
    required this.transactions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Promo> promos;
  final List<TxRecord> transactions;
  final void Function(Promo) onAdd;
  final void Function(Promo) onEdit;
  final void Function(Promo) onDelete;

  static String deskripsi(Promo p) {
    final inti = p.jenis == 'persen' ? 'Diskon ${p.nilai}%' : 'Potongan ${rupiah(p.nilai)}';
    return p.minBelanja > 0 ? '$inti · min. belanja ${rupiah(p.minBelanja)}' : '$inti · tanpa syarat minimum';
  }

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    // Pemakaian: kelompokkan transaksi berpromo.
    final perPromo = <String, ({int kali, int total})>{};
    var totalDiskon = 0;
    var totalKali = 0;
    for (final t in transactions) {
      if (t.diskon <= 0) continue;
      final nama = t.promoNama.isEmpty ? '(Promo lama)' : t.promoNama;
      final lama = perPromo[nama];
      perPromo[nama] = (kali: (lama?.kali ?? 0) + 1, total: (lama?.total ?? 0) + t.diskon);
      totalDiskon += t.diskon;
      totalKali++;
    }
    final pemakaian = perPromo.entries.toList()..sort((a, b) => b.value.total.compareTo(a.value.total));

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Promo & Diskon')
        ..writeln('${promos.length} promo terdaftar · ${promos.where((p) => p.aktif).length} aktif')
        ..writeln('Total diskon diberikan: ${rupiah(totalDiskon)} ($totalKali transaksi)');
      return bukaPratinjauLaporan(
        context,
        judul: 'Promo & Diskon',
        ringkasan: r.toString().trim(),
        kepala: const ['Promo', 'Ketentuan', 'Dipakai', 'Total Diskon'],
        baris: [
          for (final p in promos) [p.nama, deskripsi(p), '${perPromo[p.nama]?.kali ?? 0} kali', '${perPromo[p.nama]?.total ?? 0}'],
          ['TOTAL DISKON DIBERIKAN', '', '$totalKali kali', '$totalDiskon'],
        ],
        catatan: 'Pemakaian dihitung dari transaksi tercatat yang memakai promo.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo & Diskon'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          KartuHero(
            label: 'Total Diskon Sudah Diberikan',
            nilai: rupiah(totalDiskon),
            keterangan: '$totalKali transaksi memakai promo · ${promos.where((p) => p.aktif).length} promo aktif dari ${promos.length}',
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.local_offer_outlined, teks: 'Daftar Promo'),
          const SizedBox(height: AppSpacing.sm),
          if (promos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Belum ada promo. Buat promo pertama dengan tombol di bawah — sesudah itu kasir bisa memakainya saat pembayaran.', style: AppText.body.copyWith(color: AppColors.muted)),
            ),
          if (promos.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < promos.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    InkWell(
                      onTap: () => showPromoSheet(context, awal: promos[i], onSimpan: onEdit, onHapus: onDelete),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(promos[i].nama, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  Text(deskripsi(promos[i]), style: AppText.caption.copyWith(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Switch(value: promos[i].aktif, onChanged: (v) => onEdit(promos[i].salin(aktif: v))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Buat Promo',
            onPressed: () => showPromoSheet(context, onSimpan: onAdd),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Icons.bar_chart_outlined, teks: 'Pemakaian Promo'),
          const SizedBox(height: AppSpacing.sm),
          if (pemakaian.isEmpty)
            Text('Belum ada transaksi yang memakai promo.', style: AppText.body.copyWith(color: AppColors.muted))
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < pemakaian.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    BarisNilai(
                      label: pemakaian[i].key,
                      catatan: '${pemakaian[i].value.kali} transaksi',
                      nilai: rupiah(pemakaian[i].value.total),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Cara pakai: saat pembayaran, kasir mengetuk baris Promo di keranjang lalu memilih promo yang aktif. Satu promo per transaksi; diskon mengurangi total dan tercatat di transaksi. Promo tersimpan di perangkat ini (belum ikut sinkron).',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Formulir buat/edit promo: nama, jenis (persen/nominal),
/// nilai, syarat minimum belanja, saklar aktif saat edit
/// mengikuti keadaan promo (diubah lewat daftar).
Future<void> showPromoSheet(
  BuildContext context, {
  Promo? awal,
  required void Function(Promo) onSimpan,
  void Function(Promo)? onHapus,
}) async {
  final a = awal;
  var jenis = a?.jenis ?? 'persen';
  final namaCtrl = TextEditingController(text: a?.nama ?? '');
  final nilaiCtrl = TextEditingController(text: a == null ? '' : (a.jenis == 'persen' ? '${a.nilai}' : ThousandsFormatter.format(a.nilai)));
  final minCtrl = TextEditingController(text: a == null || a.minBelanja == 0 ? '' : ThousandsFormatter.format(a.minBelanja));
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return FormSheet(
          title: a == null ? 'Buat Promo' : 'Edit Promo',
          showClose: true,
          saveLabel: a == null ? 'Simpan Promo' : 'Simpan Perubahan',
          errorText: error,
          onDelete: a != null && onHapus != null
              ? () async {
                  final ok = await showConfirmDelete(
                    ctx,
                    title: 'Hapus Promo',
                    message: 'Promo "${a.nama}" akan dihapus. Transaksi lama yang memakainya tidak berubah.',
                  );
                  if (ok && ctx.mounted) {
                    onHapus(a);
                    Navigator.of(ctx).pop();
                  }
                }
              : null,
          onSave: () {
            final nilai = int.tryParse(nilaiCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final minBelanja = int.tryParse(minCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (namaCtrl.text.trim().isEmpty) return setSheet(() => error = 'Nama promo wajib diisi.');
            if (nilai <= 0) return setSheet(() => error = 'Nilai diskon harus lebih dari 0.');
            if (jenis == 'persen' && nilai > 100) return setSheet(() => error = 'Diskon persen tidak boleh lebih dari 100%.');
            onSimpan(Promo(
              id: a?.id,
              nama: namaCtrl.text.trim(),
              jenis: jenis,
              nilai: nilai,
              minBelanja: minBelanja,
              aktif: a?.aktif ?? true,
            ));
            Navigator.of(ctx).pop();
          },
          children: [
            const FormLabel('Nama promo'),
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(hintText: 'cth. Happy Hour / Promo Jumat'),
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Jenis diskon'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppChip(label: 'Persen (%)', selected: jenis == 'persen', onSelected: (_) => setSheet(() => jenis = 'persen')),
                AppChip(label: 'Potongan Nominal (Rp)', selected: jenis == 'nominal', onSelected: (_) => setSheet(() => jenis = 'nominal')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormLabel(jenis == 'persen' ? 'Nilai diskon (%)' : 'Nilai potongan (Rp)'),
            TextField(
              controller: nilaiCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: jenis == 'persen' ? [FilteringTextInputFormatter.digitsOnly] : [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
              decoration: InputDecoration(prefixText: jenis == 'persen' ? '' : 'Rp ', suffixText: jenis == 'persen' ? '%' : '', hintText: '0'),
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Minimum belanja (opsional, Rp)'),
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0 = tanpa syarat'),
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([namaCtrl, nilaiCtrl, minCtrl]);
}
