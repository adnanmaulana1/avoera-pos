import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart' show FormLabel, FormSheet, showConfirmDelete;

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _tgl(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Laporan Laba Rugi (diminta Adnan 2026-11-16): pendapatan
/// dari transaksi lunas, dikurangi HPP (modal bahan dari
/// resep) dan biaya operasional yang dicatat pemilik, untuk
/// satu periode & cabang aktif. Baris "Laporan Laba Rugi" di
/// hub Laporan dulu berstatus 'Segera' — kini jadi beneran.
class LabaRugiScreen extends StatefulWidget {
  const LabaRugiScreen({
    super.key,
    required this.transactions,
    required this.menus,
    required this.ingredients,
    required this.expenses,
    required this.branchId,
    required this.branchName,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  final List<TxRecord> transactions;
  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final List<Pengeluaran> expenses;
  final String branchId;
  final String branchName;
  final void Function(Pengeluaran) onAddExpense;
  final void Function(Pengeluaran) onEditExpense;
  final void Function(Pengeluaran) onDeleteExpense;

  @override
  State<LabaRugiScreen> createState() => _LabaRugiScreenState();
}

class _LabaRugiScreenState extends State<LabaRugiScreen> {
  /// 'bulan-ini' | 'bulan-lalu' | 'hari-ini' | 'rentang'
  String _mode = 'bulan-ini';
  DateTimeRange? _rentang;

  (DateTime, DateTime, String) get _periode {
    final now = DateTime.now();
    if (_mode == 'hari-ini') return (now, now, 'Hari ini · ${_tgl(now)}');
    if (_mode == 'bulan-lalu') {
      final m = DateTime(now.year, now.month - 1);
      return (m, DateTime(m.year, m.month + 1, 0), '${_bulan[m.month - 1]} ${m.year}');
    }
    final r = _rentang;
    if (_mode == 'rentang' && r != null) return (r.start, r.end, '${_tgl(r.start)} – ${_tgl(r.end)}');
    return (DateTime(now.year, now.month), DateTime(now.year, now.month + 1, 0), '${_bulan[now.month - 1]} ${now.year}');
  }

  Future<void> _pilihRentang() async {
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _rentang,
      helpText: 'Pilih rentang tanggal',
    );
    if (hasil != null && mounted) {
      setState(() {
        _rentang = hasil;
        _mode = 'rentang';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final (dari, sampai, labelPeriode) = _periode;
    final hasil = hitungLabaRugi(
      transactions: widget.transactions,
      menus: widget.menus,
      ingredients: widget.ingredients,
      expenses: widget.expenses,
      branchId: widget.branchId,
      dari: dari,
      sampai: sampai,
    );
    final awal = DateTime(dari.year, dari.month, dari.day);
    final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
    final biayaPeriode = widget.expenses.where((e) => (e.branchId.isEmpty || e.branchId == widget.branchId) && !e.tanggal.isBefore(awal) && e.tanggal.isBefore(akhir)).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final rugi = hasil.labaBersih < 0;

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Laba Rugi — ${widget.branchName}')
        ..writeln('Periode: $labelPeriode')
        ..writeln('Pendapatan: ${rupiah(hasil.pendapatan)} (${hasil.jumlahTx} transaksi)')
        ..writeln('HPP (modal bahan): ${rupiah(hasil.hpp)}')
        ..writeln('Laba Kotor: ${rupiah(hasil.labaKotor)}')
        ..writeln('Biaya Operasional: ${rupiah(hasil.totalBiaya)}')
        ..writeln('Laba Bersih: ${rupiah(hasil.labaBersih)}');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Laba Rugi',
        ringkasan: r.toString().trim(),
        kepala: const ['Komponen', 'Jumlah'],
        baris: [
          ['Pendapatan (${hasil.jumlahTx} transaksi)', '${hasil.pendapatan}'],
          ['HPP (modal bahan)', '${hasil.hpp}'],
          ['Laba Kotor', '${hasil.labaKotor}'],
          for (final (kat, total) in hasil.rincianBiaya) ['Biaya · $kat', '$total'],
          ['Total Biaya Operasional', '${hasil.totalBiaya}'],
          ['Laba Bersih', '${hasil.labaBersih}'],
        ],
        catatan: 'HPP dihitung dari resep & harga beli bahan saat ini. Pengeluaran tersimpan di perangkat ini.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Laba Rugi'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FilterChipRow(
            children: [
              AppChip(label: 'Bulan Ini', selected: _mode == 'bulan-ini', onSelected: (_) => setState(() => _mode = 'bulan-ini')),
              AppChip(label: 'Bulan Lalu', selected: _mode == 'bulan-lalu', onSelected: (_) => setState(() => _mode = 'bulan-lalu')),
              AppChip(label: 'Hari Ini', selected: _mode == 'hari-ini', onSelected: (_) => setState(() => _mode = 'hari-ini')),
              AppChip(label: _mode == 'rentang' ? labelPeriode : 'Pilih Tanggal', selected: _mode == 'rentang', onSelected: (_) => _pilihRentang()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.heroCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rugi ? 'Rugi Bersih' : 'Laba Bersih', style: AppText.small.copyWith(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(rupiah(hasil.labaBersih), style: AppText.display.copyWith(color: Colors.white)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$labelPeriode · ${widget.branchName} · margin kotor ${(hasil.marginKotor * 100).round()}%',
                  style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                _BarisLaba(label: 'Pendapatan', catatan: '${hasil.jumlahTx} transaksi lunas', nilai: hasil.pendapatan),
                const _GarisTipis(),
                _BarisLaba(label: 'HPP (modal bahan)', catatan: 'Dari resep & harga beli bahan', nilai: -hasil.hpp),
                const _GarisTipis(),
                _BarisLaba(label: 'Laba Kotor', nilai: hasil.labaKotor, tebal: true),
                const _GarisTipis(),
                _BarisLaba(label: 'Biaya Operasional', catatan: '${biayaPeriode.length} catatan pengeluaran', nilai: -hasil.totalBiaya),
                const _GarisTipis(),
                _BarisLaba(label: rugi ? 'Rugi Bersih' : 'Laba Bersih', nilai: hasil.labaBersih, tebal: true),
              ],
            ),
          ),
          if (hasil.barisTakDikenal > 0 || hasil.adaTxTanpaRincian) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Sebagian modal bahan belum bisa dihitung${hasil.barisTakDikenal > 0 ? ' (${hasil.barisTakDikenal} baris: menu tanpa resep / sudah dihapus)' : ''}${hasil.adaTxTanpaRincian ? ' (ada transaksi lama tanpa rincian item)' : ''} — laba sebenarnya bisa lebih kecil. Lengkapi resep menu supaya hitungan penuh.',
                      style: AppText.small.copyWith(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text('Biaya Operasional', style: AppText.title.copyWith(color: AppColors.ink))),
              Text(rupiah(hasil.totalBiaya), style: AppText.subtitle.copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasil.rincianBiaya.isNotEmpty)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                children: [
                  for (var i = 0; i < hasil.rincianBiaya.length; i++) ...[
                    if (i > 0) const _GarisTipis(),
                    _BarisLaba(label: hasil.rincianBiaya[i].$1, nilai: hasil.rincianBiaya[i].$2),
                  ],
                ],
              ),
            ),
          if (biayaPeriode.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text('Belum ada pengeluaran tercatat pada periode ini.', style: AppText.small.copyWith(color: AppColors.muted)),
            )
          else
            for (final e in biayaPeriode)
              AppCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                onTap: () => showPengeluaranSheet(
                  context,
                  awal: e,
                  branchId: widget.branchId,
                  onSimpan: widget.onEditExpense,
                  onHapus: widget.onDeleteExpense,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.kategori, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text(
                            [if (e.keterangan.isNotEmpty) e.keterangan, _tgl(e.tanggal)].join(' · '),
                            style: AppText.caption.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(rupiah(e.jumlah), style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ],
                ),
              ),
          PrimaryButton(
            label: 'Tambah Pengeluaran',
            onPressed: () => showPengeluaranSheet(context, branchId: widget.branchId, onSimpan: widget.onAddExpense),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pendapatan dari transaksi lunas di kasir cabang ini. HPP memakai resep & harga beli bahan saat ini. Pengeluaran tersimpan di perangkat ini (belum ikut sinkron).',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _GarisTipis extends StatelessWidget {
  const _GarisTipis();
  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return Divider(height: 1, thickness: 0.7, color: AppColors.border.withValues(alpha: 0.6));
  }
}

class _BarisLaba extends StatelessWidget {
  const _BarisLaba({required this.label, this.catatan, required this.nilai, this.tebal = false});
  final String label;
  final String? catatan;
  final int nilai;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    // Merah HANYA untuk baris laba yang minus; biaya & HPP
    // memang pengurang (ditulis -Rp) tapi bukan keadaan bahaya.
    final gayaNilai = (tebal ? AppText.subtitle : AppText.body).copyWith(
      color: tebal && nilai < 0 ? AppColors.danger : AppColors.ink,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body.copyWith(fontWeight: tebal ? FontWeight.w700 : FontWeight.w600, color: AppColors.ink)),
                if (catatan != null) Text(catatan!, style: AppText.caption.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          Text(rupiah(nilai), style: gayaNilai),
        ],
      ),
    );
  }
}

/// Formulir tambah/edit pengeluaran operasional (pola sheet
/// Gudang): tanggal, kategori pilihan, keterangan, jumlah.
/// [awal] null = tambah baru; terisi = edit (tombol Hapus
/// muncul lewat FormSheet).
Future<void> showPengeluaranSheet(
  BuildContext context, {
  Pengeluaran? awal,
  required String branchId,
  required void Function(Pengeluaran) onSimpan,
  void Function(Pengeluaran)? onHapus,
}) async {
  final a = awal; // final lokal: promosi non-null berlaku di dalam closure sheet
  var tanggal = a?.tanggal ?? DateTime.now();
  var kategori = a?.kategori ?? 'Lainnya';
  final ketCtrl = TextEditingController(text: a?.keterangan ?? '');
  final jumlahCtrl = TextEditingController(text: a == null ? '' : ThousandsFormatter.format(a.jumlah));
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return FormSheet(
          title: a == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran',
          showClose: true,
          saveLabel: a == null ? 'Simpan Pengeluaran' : 'Simpan Perubahan',
          errorText: error,
          onDelete: a != null && onHapus != null
              ? () async {
                  final ok = await showConfirmDelete(
                    ctx,
                    title: 'Hapus Pengeluaran',
                    message: 'Catatan ${a.kategori} sebesar ${rupiah(a.jumlah)} akan dihapus dari laporan.',
                  );
                  if (ok && ctx.mounted) {
                    onHapus(a);
                    Navigator.of(ctx).pop();
                  }
                }
              : null,
          onSave: () {
            final jumlah = int.tryParse(jumlahCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (jumlah <= 0) return setSheet(() => error = 'Jumlah harus lebih dari 0.');
            final hasil = Pengeluaran(
              id: a?.id,
              tanggal: tanggal,
              kategori: kategori,
              keterangan: ketCtrl.text.trim(),
              jumlah: jumlah,
              branchId: a?.branchId ?? branchId,
            );
            onSimpan(hasil);
            Navigator.of(ctx).pop();
          },
          children: [
            const FormLabel('Tanggal'),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () async {
                final pilih = await showDatePicker(
                  context: ctx,
                  initialDate: tanggal,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pilih != null) setSheet(() => tanggal = pilih);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.muted),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_tgl(tanggal), style: AppText.body.copyWith(color: AppColors.ink)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Kategori'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final k in {...kategoriPengeluaran, if (a != null) a.kategori})
                  AppChip(label: k, selected: kategori == k, onSelected: (_) => setSheet(() => kategori = k)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Jumlah (Rp)'),
            TextField(
              controller: jumlahCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Keterangan (opsional)'),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(hintText: 'cth. Sewa ruko bulan November'),
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([ketCtrl, jumlahCtrl]);
}
