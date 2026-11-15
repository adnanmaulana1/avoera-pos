import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_stok_screen.dart' show showIngredientEditor;
import 'gudang_screen.dart' show showBarangMasukSheet, showOpnameSheet;

/// Stok Bahan dengan CRUD LANGSUNG di layar ini (permintaan Adnan
/// 2026-11-14): ketuk bahan untuk mengubah, tombol + untuk tambah —
/// tidak perlu lagi mampir Pengaturan. Plus cari, filter pill
/// standar (FilterChipRow), dan ekspor daftar stok.
class StokScreen extends StatefulWidget {
  const StokScreen({
    super.key,
    required this.ingredients,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
    this.onBarangMasuk,
    this.onOpname,
    this.onBukaRiwayat,
    this.queryAwal,
    this.queryAwalKode = 0,
  });

  final List<Ingredient> ingredients;
  final ValueChanged<Ingredient> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<Ingredient> onDelete;

  /// v0.10.8: kata cari yang dipasang dari luar (ketukan
  /// pemberitahuan stok) — diterapkan sekali tiap [queryAwalKode]
  /// berubah: kotak cari terisi nama bahan & daftar tersaring
  /// ke bahan itu.
  final String? queryAwal;
  final int queryAwalKode;

  /// Modul Gudang (v0.10.0): barang masuk, opname, riwayat mutasi.
  final void Function(Ingredient bahan, double jumlah, int hargaBeli, String catatan)? onBarangMasuk;
  final void Function(Ingredient bahan, double stokFisik, String catatan)? onOpname;
  final VoidCallback? onBukaRiwayat;

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  String _filter = 'Semua';
  String _query = '';
  final _cariController = TextEditingController();
  int _kodeQueryTerapan = 0;

  @override
  void initState() {
    super.initState();
    _terapkanQueryAwal();
  }

  @override
  void didUpdateWidget(StokScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _terapkanQueryAwal();
  }

  void _terapkanQueryAwal() {
    final q = widget.queryAwal;
    if (q == null || widget.queryAwalKode == _kodeQueryTerapan) return;
    _kodeQueryTerapan = widget.queryAwalKode;
    _filter = 'Semua';
    _query = q;
    _cariController.text = q;
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  List<Ingredient> get _list => widget.ingredients.where((i) {
        final cocokFilter = switch (_filter) {
          'Aman' => i.status == StockStatus.aman,
          'Kritis' => i.status == StockStatus.kritis,
          'Habis' => i.status == StockStatus.habis,
          _ => true,
        };
        return cocokFilter && i.name.toLowerCase().contains(_query.toLowerCase());
      }).toList();

  Future<void> _bukaEditor(Ingredient? ing) async {
    await showIngredientEditor(context, initial: ing, onAdd: widget.onAdd, onChanged: widget.onChanged, onDelete: widget.onDelete);
    if (mounted) setState(() {});
  }

  Future<void> _ekspor() {
    final semua = widget.ingredients;
    final ringkasan = StringBuffer('Stok Bahan — ${semua.length} bahan\n');
    for (final i in semua) {
      ringkasan.writeln('• ${i.name}: sisa ${stockText(i.stock)} ${i.unit} (${i.status.name})');
    }
    return bukaPratinjauLaporan(
      context,
      judul: 'Stok Bahan',
      ringkasan: ringkasan.toString().trim(),
      kepala: const ['Bahan', 'Sisa', 'Satuan', 'Batas Kritis', 'Status'],
      baris: [
        for (final i in semua) [i.name, stockText(i.stock), i.unit, stockText(i.minStock), i.status.name],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PageHeader(
              title: 'Stok Bahan',
              subtitle: '${widget.ingredients.length} bahan tersimpan. Ketuk bahan untuk mengubahnya.',
              trailing: TombolEkspor(onPressed: _ekspor),
            ),
            if (widget.onBarangMasuk != null) ...[
              const SizedBox(height: AppSpacing.md),
              // Ubin aksi: ikon di atas, label di bawah. Tombol
              // sebaris ikon+teks MEMATAHKAN kata di tengah pada
              // lebar HP ("Opnam/e") — ketahuan dari audit frame
              // anti-slop 2026-11-15; ubin begini muat di semua
              // lebar dan tetap rapi di tablet.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _UbinAksi(
                      ikon: Icons.add_box_outlined,
                      label: 'Barang Masuk',
                      onTap: () => showBarangMasukSheet(context, ingredients: widget.ingredients, onSimpan: widget.onBarangMasuk!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _UbinAksi(
                      ikon: Icons.fact_check_outlined,
                      label: 'Opname',
                      onTap: () => showOpnameSheet(context, ingredients: widget.ingredients, onSimpan: widget.onOpname!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _UbinAksi(
                      ikon: Icons.history,
                      label: 'Riwayat',
                      onTap: widget.onBukaRiwayat,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cariController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari bahan…'),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.md),
            FilterChipRow(
              children: [
                for (final f in ['Semua', 'Aman', 'Kritis', 'Habis'])
                  AppChip(label: f, selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (list.isEmpty)
              const EmptyState(message: 'Tidak ada bahan yang cocok.\nCoba kata cari atau filter lain.', icon: Icons.inventory_2_outlined),
            for (final ing in list)
              AppCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                onTap: () => _bukaEditor(ing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(ing.name, style: AppText.subtitle)),
                        StatusChip(
                          label: switch (ing.status) { StockStatus.aman => 'Aman', StockStatus.kritis => 'Kritis', StockStatus.habis => 'Habis' },
                          color: switch (ing.status) { StockStatus.aman => AppColors.accentDark, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Sisa ${stockText(ing.stock)} ${ing.unit} · Batas minimum ${stockText(ing.minStock)} ${ing.unit}',
                        style: AppText.small.copyWith(color: AppColors.muted)),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: ing.ratio,
                        minHeight: 8,
                        backgroundColor: AppColors.track,
                        color: switch (ing.status) { StockStatus.aman => AppColors.accent, StockStatus.kritis => AppColors.warning, StockStatus.habis => AppColors.danger },
                      ),
                    ),
                    if (ing.status != StockStatus.aman) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ing.status == StockStatus.habis ? 'Segera pesan lagi — bahan sudah habis.' : 'Stok di bawah batas minimum — siapkan pesanan pembelian.',
                        style: AppText.small.copyWith(color: ing.status == StockStatus.habis ? AppColors.danger : AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: FloatingActionButton(
            heroTag: 'tambahBahan',
            onPressed: () => _bukaEditor(null),
            tooltip: 'Tambah Bahan',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Ubin aksi gudang: ikon di atas label, rata tengah, bingkai
/// tipis — pengganti tombol sebaris yang mematahkan kata di HP.
class _UbinAksi extends StatelessWidget {
  const _UbinAksi({required this.ikon, required this.label, required this.onTap});
  final IconData ikon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Daftarkan sebagai dependen Theme: warna AppColors statis
    // bisa basi saat tema berganti di tengah sesi (pelajaran
    // SectionTitle) — baris ini yang mencegahnya.
    Theme.of(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Icon(ikon, size: 22, color: AppColors.accentDark),
              const SizedBox(height: AppSpacing.xs),
              Text(label, textAlign: TextAlign.center, style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
