import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart';
import 'laporan_bersama.dart';

/// Laporan Hutang (update besar v0.11.0): catatan hutang
/// usaha yang dicatat manual pemilik — pemasok, orang, atau
/// pihak lain. Bisa ditambah, diubah, dihapus, dan ditandai
/// lunas. Angka belum lunasnya mengalir ke Neraca & Arus Kas.
/// Tersimpan lokal di perangkat (belum ikut sinkron).
class HutangScreen extends StatelessWidget {
  const HutangScreen({
    super.key,
    required this.hutang,
    required this.branchId,
    required this.branchName,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Hutang> hutang;
  final String branchId;
  final String branchName;
  final void Function(Hutang) onAdd;
  final void Function(Hutang) onEdit;
  final void Function(Hutang) onDelete;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    final milik = hutang.where((h) => h.branchId.isEmpty || h.branchId == branchId).toList();
    final kini = DateTime.now();
    final belum = milik.where((h) => !h.lunas).toList()
      ..sort((a, b) {
        // Terlambat dulu, lalu jatuh tempo terdekat, lalu terbaru.
        final ta = a.terlambat(kini) ? 0 : 1;
        final tb = b.terlambat(kini) ? 0 : 1;
        if (ta != tb) return ta.compareTo(tb);
        final ja = a.jatuhTempo;
        final jb = b.jatuhTempo;
        if (ja != null && jb != null) return ja.compareTo(jb);
        if (ja != null) return -1;
        if (jb != null) return 1;
        return b.tanggal.compareTo(a.tanggal);
      });
    final lunas = milik.where((h) => h.lunas).toList()..sort((a, b) => (b.tanggalLunas ?? b.tanggal).compareTo(a.tanggalLunas ?? a.tanggal));
    final totalBelum = belum.fold(0, (a, h) => a + h.jumlah);
    final jumlahTerlambat = belum.where((h) => h.terlambat(kini)).length;

    Future<void> ekspor() {
      final r = StringBuffer()
        ..writeln('Laporan Hutang — $branchName')
        ..writeln('Total belum lunas: ${rupiah(totalBelum)} (${belum.length} catatan)')
        ..writeln('Sudah lunas: ${lunas.length} catatan');
      return bukaPratinjauLaporan(
        context,
        judul: 'Laporan Hutang',
        ringkasan: r.toString().trim(),
        kepala: const ['Kreditur', 'Jumlah', 'Status'],
        baris: [
          for (final h in belum) [h.kreditur, '${h.jumlah}', h.terlambat(kini) ? 'Terlambat' : 'Belum lunas'],
          for (final h in lunas) [h.kreditur, '${h.jumlah}', 'Lunas'],
          ['TOTAL BELUM LUNAS', '$totalBelum'],
        ],
        catatan: 'Catatan hutang diisi manual oleh pemilik dan tersimpan di perangkat ini (belum ikut sinkron).',
      );
    }

    Future<void> lunasi(Hutang h) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tandai Lunas'),
          content: Text('Hutang ke ${h.kreditur} sebesar ${rupiah(h.jumlah)} ditandai lunas hari ini?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ya, Lunas')),
          ],
        ),
      );
      if (ok == true) onEdit(h.salin(lunas: true, tanggalLunas: DateTime.now()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Hutang'),
        actions: [TombolEkspor(onPressed: ekspor)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          KartuHero(
            label: 'Total Hutang Belum Lunas · $branchName',
            nilai: rupiah(totalBelum),
            keterangan: jumlahTerlambat > 0
                ? '${belum.length} catatan belum lunas · $jumlahTerlambat TERLAMBAT'
                : '${belum.length} catatan belum lunas · ${lunas.length} sudah lunas',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (belum.isNotEmpty) ...[
            const JudulSeksi(ikon: Icons.schedule_outlined, teks: 'Belum Lunas'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < belum.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    _BarisHutang(h: belum[i], kini: kini, onTap: () => showHutangSheet(context, awal: belum[i], branchId: branchId, onSimpan: onEdit, onHapus: onDelete), onLunasi: () => lunasi(belum[i])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (lunas.isNotEmpty) ...[
            const JudulSeksi(ikon: Icons.check_circle_outline, teks: 'Sudah Lunas'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < lunas.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    _BarisHutang(h: lunas[i], kini: kini, onTap: () => showHutangSheet(context, awal: lunas[i], branchId: branchId, onSimpan: onEdit, onHapus: onDelete)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (milik.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text('Belum ada catatan hutang. Ketuk tombol di bawah untuk mencatat hutang pertama.', textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.muted)),
            ),
          PrimaryButton(
            label: 'Catat Hutang',
            onPressed: () => showHutangSheet(context, branchId: branchId, onSimpan: onAdd),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hutang dicatat manual oleh pemilik. Total belum lunas tampil juga di Neraca, dan pelunasan tercatat sebagai uang keluar di Arus Kas. Tersimpan di perangkat ini (belum ikut sinkron).',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BarisHutang extends StatelessWidget {
  const _BarisHutang({required this.h, required this.kini, required this.onTap, this.onLunasi});
  final Hutang h;
  final DateTime kini;
  final VoidCallback onTap;
  final VoidCallback? onLunasi;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    final terlambat = h.terlambat(kini);
    final sub = [
      if (h.keterangan.isNotEmpty) h.keterangan,
      'Dicatat ${labelTgl(h.tanggal)}',
      if (h.lunas && h.tanggalLunas != null) 'Lunas ${labelTgl(h.tanggalLunas!)}',
      if (!h.lunas && h.jatuhTempo != null) 'Jatuh tempo ${labelTgl(h.jatuhTempo!)}',
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(h.kreditur, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink), overflow: TextOverflow.ellipsis)),
                      if (terlambat) ...[
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(label: 'Terlambat', color: AppColors.danger),
                      ],
                    ],
                  ),
                  Text(sub, style: AppText.caption.copyWith(color: terlambat ? AppColors.danger : AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rupiah(h.jumlah), style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (onLunasi != null)
                  TextButton(
                    onPressed: onLunasi,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), minimumSize: const Size(0, 32)),
                    child: const Text('Lunasi'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulir tambah/edit catatan hutang (pola sheet yang sama
/// dengan Pengeluaran): tanggal, pemberi hutang, jumlah,
/// jatuh tempo opsional, keterangan, status lunas saat edit.
Future<void> showHutangSheet(
  BuildContext context, {
  Hutang? awal,
  required String branchId,
  required void Function(Hutang) onSimpan,
  void Function(Hutang)? onHapus,
}) async {
  final a = awal;
  var tanggal = a?.tanggal ?? DateTime.now();
  var jatuhTempo = a?.jatuhTempo;
  var lunas = a?.lunas ?? false;
  final krediturCtrl = TextEditingController(text: a?.kreditur ?? '');
  final ketCtrl = TextEditingController(text: a?.keterangan ?? '');
  final jumlahCtrl = TextEditingController(text: a == null ? '' : ThousandsFormatter.format(a.jumlah));
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        Widget barisTanggal(String label, DateTime nilai, ValueChanged<DateTime> onPilih) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormLabel(label),
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () async {
                    final pilih = await showDatePicker(
                      context: ctx,
                      initialDate: nilai,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (pilih != null) onPilih(pilih);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.muted),
                        const SizedBox(width: AppSpacing.sm),
                        Text(labelTgl(nilai), style: AppText.body.copyWith(color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
              ],
            );
        return FormSheet(
          title: a == null ? 'Catat Hutang' : 'Edit Hutang',
          showClose: true,
          saveLabel: a == null ? 'Simpan Hutang' : 'Simpan Perubahan',
          errorText: error,
          onDelete: a != null && onHapus != null
              ? () async {
                  final ok = await showConfirmDelete(
                    ctx,
                    title: 'Hapus Catatan Hutang',
                    message: 'Hutang ke ${a.kreditur} sebesar ${rupiah(a.jumlah)} akan dihapus.',
                  );
                  if (ok && ctx.mounted) {
                    onHapus(a);
                    Navigator.of(ctx).pop();
                  }
                }
              : null,
          onSave: () {
            final jumlah = int.tryParse(jumlahCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (krediturCtrl.text.trim().isEmpty) return setSheet(() => error = 'Nama pemberi hutang wajib diisi.');
            if (jumlah <= 0) return setSheet(() => error = 'Jumlah harus lebih dari 0.');
            final hasil = Hutang(
              id: a?.id,
              tanggal: tanggal,
              kreditur: krediturCtrl.text.trim(),
              keterangan: ketCtrl.text.trim(),
              jumlah: jumlah,
              jatuhTempo: jatuhTempo,
              lunas: lunas,
              tanggalLunas: lunas ? (a?.tanggalLunas ?? DateTime.now()) : null,
              branchId: a?.branchId ?? branchId,
            );
            onSimpan(hasil);
            Navigator.of(ctx).pop();
          },
          children: [
            barisTanggal('Tanggal hutang', tanggal, (d) => setSheet(() => tanggal = d)),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Pemberi hutang'),
            TextField(
              controller: krediturCtrl,
              decoration: const InputDecoration(hintText: 'cth. Toko Bahan Makmur / Pak Budi'),
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
            const FormLabel('Jatuh tempo (opsional)'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppChip(label: 'Tanpa Jatuh Tempo', selected: jatuhTempo == null, onSelected: (_) => setSheet(() => jatuhTempo = null)),
                AppChip(
                  label: jatuhTempo == null ? 'Pilih Tanggal' : labelTgl(jatuhTempo!),
                  selected: jatuhTempo != null,
                  onSelected: (_) async {
                    final pilih = await showDatePicker(
                      context: ctx,
                      initialDate: jatuhTempo ?? tanggal.add(const Duration(days: 30)),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (pilih != null) setSheet(() => jatuhTempo = pilih);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Keterangan (opsional)'),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(hintText: 'cth. Bahan alpukat 20 kg, bayar akhir bulan'),
            ),
            if (a != null) ...[
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Sudah lunas', style: AppText.body.copyWith(color: AppColors.ink)),
                value: lunas,
                onChanged: (v) => setSheet(() => lunas = v),
              ),
            ],
          ],
        );
      },
    ),
  );
  disposeControllersLater([krediturCtrl, ketCtrl, jumlahCtrl]);
}
