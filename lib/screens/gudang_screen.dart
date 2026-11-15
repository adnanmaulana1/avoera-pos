import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_widgets.dart' show FormLabel, FormSheet;

/// Modul Gudang (v0.10.0, permintaan Adnan 2026-11-15): barang
/// masuk, opname, dan riwayat mutasi stok (kartu stok). Semua
/// perubahan jumlah bahan tercatat sebagai MutasiStok oleh
/// HomeShell — layar ini hanya mengumpulkan isian.

/// Sama dengan konvensi editor bahan: koma atau titik sama-sama
/// pemisah desimal.
double? _parseQty(String raw) {
  final cleaned = raw.trim().replaceAll(',', '.');
  return double.tryParse(cleaned);
}

/// Pemilih bahan: sheet berisi daftar bahan yang bisa dicari.
Future<Ingredient?> pilihBahan(BuildContext context, List<Ingredient> ingredients) async {
  final cari = TextEditingController();
  final hasilPilih = await showAppSheet<Ingredient>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final q = cari.text.toLowerCase();
        final hasil = ingredients.where((i) => i.name.toLowerCase().contains(q)).toList();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Bahan', style: AppText.subtitle),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: cari,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari bahan…'),
                  onChanged: (_) => setSheet(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (hasil.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Text('Tidak ada bahan yang cocok.', style: AppText.small.copyWith(color: AppColors.muted)),
                        ),
                      for (final ing in hasil)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(ing.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text('Sisa ${stockText(ing.stock)} ${ing.unit}', style: AppText.small.copyWith(color: AppColors.muted)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => Navigator.of(ctx).pop(ing),
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
  );
  disposeControllersLater([cari]);
  return hasilPilih;
}

/// Kolom pemilih bahan (ketuk untuk membuka pemilih).
class _KolomBahan extends StatelessWidget {
  const _KolomBahan({required this.terpilih, required this.onTap});
  final Ingredient? terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                terpilih == null ? 'Pilih bahan…' : '${terpilih!.name} (sisa ${stockText(terpilih!.stock)} ${terpilih!.unit})',
                style: terpilih == null ? AppText.body.copyWith(color: AppColors.muted) : AppText.body,
              ),
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Formulir Barang Masuk: stok bertambah + harga beli terbaru
/// memperbarui harga beli bahan (dasar HPP).
Future<void> showBarangMasukSheet(
  BuildContext context, {
  required List<Ingredient> ingredients,
  required void Function(Ingredient bahan, double jumlah, int hargaBeli, String catatan) onSimpan,
}) async {
  Ingredient? bahan;
  final qtyCtrl = TextEditingController();
  final hargaCtrl = TextEditingController();
  final catatanCtrl = TextEditingController();
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return FormSheet(
          title: 'Barang Masuk',
          showClose: true,
          saveLabel: 'Simpan Barang Masuk',
          errorText: error,
          onSave: () {
            final b = bahan;
            final qty = _parseQty(qtyCtrl.text);
            if (b == null) return setSheet(() => error = 'Pilih bahan dulu.');
            if (qty == null || qty <= 0) return setSheet(() => error = 'Jumlah masuk harus lebih dari 0.');
            final harga = int.tryParse(hargaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            onSimpan(b, qty, harga, catatanCtrl.text.trim());
            Navigator.of(ctx).pop();
          },
          children: [
            const FormLabel('Bahan'),
            _KolomBahan(
              terpilih: bahan,
              onTap: () async {
                final pilih = await pilihBahan(ctx, ingredients);
                if (pilih != null) {
                  setSheet(() {
                    bahan = pilih;
                    if (pilih.costPerUnit > 0 && hargaCtrl.text.isEmpty) {
                      hargaCtrl.text = ThousandsFormatter.format(pilih.costPerUnit);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Jumlah Masuk'),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: 'cth. 10', suffixText: bahan?.unit ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Harga Beli per Satuan (Rp)'),
            TextField(
              controller: hargaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Harga ini jadi harga beli terbaru bahan — dasar hitung HPP. Kosongkan bila tidak berubah.', style: AppText.small.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Catatan (opsional)'),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(hintText: 'cth. Beli di Toko Berkah'),
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([qtyCtrl, hargaCtrl, catatanCtrl]);
}

/// Formulir Opname: samakan stok sistem dengan hasil hitung fisik.
/// Selisihnya tampil langsung dan tercatat sebagai mutasi opname.
Future<void> showOpnameSheet(
  BuildContext context, {
  required List<Ingredient> ingredients,
  required void Function(Ingredient bahan, double stokFisik, String catatan) onSimpan,
}) async {
  Ingredient? bahan;
  final fisikCtrl = TextEditingController();
  final catatanCtrl = TextEditingController();
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final fisik = _parseQty(fisikCtrl.text);
        final selisih = (bahan != null && fisik != null) ? fisik - bahan!.stock : null;
        return FormSheet(
          title: 'Opname Stok',
          showClose: true,
          saveLabel: 'Simpan Opname',
          errorText: error,
          onSave: () {
            final b = bahan;
            if (b == null) return setSheet(() => error = 'Pilih bahan dulu.');
            if (fisik == null || fisik < 0) return setSheet(() => error = 'Isi hasil hitung fisik (boleh 0).');
            onSimpan(b, fisik, catatanCtrl.text.trim());
            Navigator.of(ctx).pop();
          },
          children: [
            const FormLabel('Bahan'),
            _KolomBahan(
              terpilih: bahan,
              onTap: () async {
                final pilih = await pilihBahan(ctx, ingredients);
                if (pilih != null) setSheet(() => bahan = pilih);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Hasil Hitung Fisik'),
            TextField(
              controller: fisikCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: 'Berapa sisa sebenarnya?', suffixText: bahan?.unit ?? ''),
              onChanged: (_) => setSheet(() {}),
            ),
            if (bahan != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.sm + 2)),
                child: Row(
                  children: [
                    Expanded(child: Text('Stok di sistem: ${stockText(bahan!.stock)} ${bahan!.unit}', style: AppText.small)),
                    if (selisih != null)
                      Text(
                        selisih == 0 ? 'Pas, tidak ada selisih' : 'Selisih ${selisih > 0 ? '+' : '−'}${stockText(selisih.abs())} ${bahan!.unit}',
                        style: AppText.small.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selisih == 0 ? AppColors.accentDark : (selisih > 0 ? AppColors.accentDark : AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const FormLabel('Catatan (opsional)'),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(hintText: 'cth. Opname akhir bulan'),
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([fisikCtrl, catatanCtrl]);
}

/// Ikon + warna + label per jenis mutasi.
(IconData, Color, String) _gayaMutasi(String jenis) => switch (jenis) {
      'masuk' => (Icons.add_box_outlined, AppColors.accent, 'Barang Masuk'),
      'jual' => (Icons.point_of_sale_outlined, AppColors.warning, 'Penjualan'),
      'opname' => (Icons.fact_check_outlined, AppColors.ink, 'Opname'),
      _ => (Icons.edit_outlined, AppColors.muted, 'Ubah Manual'),
    };

String _waktuMutasi(DateTime w) {
  final now = DateTime.now();
  final hariIni = DateTime(now.year, now.month, now.day);
  final tgl = DateTime(w.year, w.month, w.day);
  final jam = '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  if (tgl == hariIni) return 'Hari ini · $jam';
  if (tgl == hariIni.subtract(const Duration(days: 1))) return 'Kemarin · $jam';
  return '${w.day}/${w.month}/${w.year} · $jam';
}

/// Riwayat Mutasi (kartu stok): semua pergerakan bahan, terbaru
/// di atas. Bisa disaring per jenis atau per bahan.
class RiwayatMutasiScreen extends StatefulWidget {
  const RiwayatMutasiScreen({super.key, required this.mutasi, required this.ingredients});
  final List<MutasiStok> mutasi;
  final List<Ingredient> ingredients;

  @override
  State<RiwayatMutasiScreen> createState() => _RiwayatMutasiScreenState();
}

class _RiwayatMutasiScreenState extends State<RiwayatMutasiScreen> {
  String _jenis = 'Semua';
  Ingredient? _bahan;

  List<MutasiStok> get _list => widget.mutasi.where((m) {
        final cocokJenis = _jenis == 'Semua' || m.jenis == _jenis;
        final cocokBahan = _bahan == null || m.ingredientId == _bahan!.id;
        return cocokJenis && cocokBahan;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Mutasi Stok')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FilterChipRow(
            children: [
              for (final (kode, label) in [('Semua', 'Semua'), ('masuk', 'Masuk'), ('jual', 'Penjualan'), ('opname', 'Opname'), ('edit', 'Ubah Manual')])
                AppChip(label: label, selected: _jenis == kode, onSelected: (_) => setState(() => _jenis = kode)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _KolomBahan(
            terpilih: _bahan,
            onTap: () async {
              final pilih = await pilihBahan(context, widget.ingredients);
              if (pilih != null) setState(() => _bahan = pilih);
            },
          ),
          if (_bahan != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _bahan = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Tampilkan semua bahan'),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (list.isEmpty)
            const EmptyState(message: 'Belum ada mutasi tercatat.\nBarang masuk, penjualan beresep, dan opname akan tampil di sini.', icon: Icons.history)
          else
            for (final m in list)
              Builder(builder: (_) {
                final (ikon, warna, label) = _gayaMutasi(m.jenis);
                final positif = m.jumlah >= 0;
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: warna.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(ikon, color: warna, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.namaBahan, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              [label, if (m.catatan.isNotEmpty) m.catatan, _waktuMutasi(m.waktu)].join(' · '),
                              style: AppText.small.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${positif ? '+' : '−'}${stockText(m.jumlah.abs())} ${m.satuan}',
                            style: AppText.body.copyWith(fontWeight: FontWeight.w800, color: positif ? AppColors.accentDark : AppColors.danger),
                          ),
                          Text('Sisa ${stockText(m.stokSesudah)}', style: AppText.small.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }
}
