import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_menu_screen.dart' show MenuThumb, menuPalette, showMenuEditor;
import 'label_screen.dart';
import 'resep_screen.dart';

/// Layar Produk ala referensi Kasaba (permintaan Adnan 2026-11-14):
/// daftar produk dengan foto, nama, kategori + SKU, harga di kanan;
/// menu ⋯ berisi aksi massal. Yang sudah jalan penuh: Edit Harga
/// Massal, Tampilkan Bahan Baku, Pilih Produk (hapus massal),
/// Ekspor & Impor Data. Resep, Bundle, Harga Ojol, Cetak Label
/// Harga ditampilkan sebagai 'Segera' — menunggu giliran dibangun.
class ProdukScreen extends StatefulWidget {
  const ProdukScreen({
    super.key,
    required this.menus,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
    required this.branchName,
    required this.ingredients,
    required this.onBulkPrice,
    required this.onImport,
    this.businessName = '',
  });

  final List<MenuItem> menus;
  final ValueChanged<MenuItem> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<MenuItem> onDelete;
  final String branchName;
  final List<Ingredient> ingredients;

  /// Naik/turunkan semua harga sebesar persen (bertanda).
  final ValueChanged<int> onBulkPrice;
  final ValueChanged<List<MenuItem>> onImport;

  /// Nama usaha untuk kepala label harga (boleh kosong → pakai
  /// nama cabang).
  final String businessName;

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  String _kategori = 'Semua';
  String _query = '';
  bool _tampilBahan = false;
  bool _tampilOjol = false;
  bool _modePilih = false;
  final Set<String> _terpilih = {};

  // Tombol cari melayang (permintaan Adnan 2026-11-15): sesudah
  // daftar digulir jauh, kolom cari di atas sudah tak terlihat —
  // tombol ini muncul untuk melompat kembali ke kolom cari.
  final _gulirCtrl = ScrollController();
  final _cariCtrl = TextEditingController();
  final _fokusCari = FocusNode();
  bool _sudahGulir = false;

  @override
  void initState() {
    super.initState();
    _gulirCtrl.addListener(() {
      final jauh = _gulirCtrl.hasClients && _gulirCtrl.offset > 260;
      if (jauh != _sudahGulir) setState(() => _sudahGulir = jauh);
    });
  }

  @override
  void dispose() {
    _gulirCtrl.dispose();
    _cariCtrl.dispose();
    _fokusCari.dispose();
    super.dispose();
  }

  Future<void> _lompatKeCari() async {
    await _gulirCtrl.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    if (mounted) _fokusCari.requestFocus();
  }

  List<MenuItem> get _list => widget.menus.where((m) {
        final cocokKategori = _kategori == 'Semua' || m.category == _kategori;
        return cocokKategori && m.name.toLowerCase().contains(_query.toLowerCase());
      }).toList();

  void _keluarModePilih() => setState(() {
        _modePilih = false;
        _terpilih.clear();
      });

  Future<void> _hapusTerpilih() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${_terpilih.length} Produk'),
        content: const Text('Produk terpilih akan dihapus dari daftar dan tidak bisa lagi dijual di kasir.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          PrimaryButton(label: 'Hapus', backgroundColor: AppColors.danger, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok == true) {
      for (final m in widget.menus.where((m) => _terpilih.contains(m.id)).toList()) {
        widget.onDelete(m);
      }
      _fokusCari.unfocus();
      _keluarModePilih();
    }
  }

  Future<void> _editHargaMassal() async {
    final ctrl = TextEditingController(text: '10');
    var naik = true;
    final contoh = widget.menus.isEmpty ? 20000 : widget.menus.first.price;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final persen = (int.tryParse(ctrl.text.trim()) ?? 0).clamp(0, 500);
          final bertanda = naik ? persen : -persen;
          final contohBaru = (((contoh * (100 + bertanda) / 100).round() + 50) ~/ 100) * 100;
          return AlertDialog(
            title: const Text('Edit Harga Massal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill arah & kotak persen SATU tinggi (48, dikunci
                // tegas dengan SizedBox) dan SATU radius (md) dari
                // tema — dulu chip mungil + kolom isian tinggi beda
                // + centang, terlihat tidak rapi.
                Row(
                  children: [
                    SizedBox(
                      height: 48,
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: true, label: Text('Naik')),
                          ButtonSegment(value: false, label: Text('Turun')),
                        ],
                        selected: {naik},
                        onSelectionChanged: (s) => setDialog(() => naik = s.first),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 88,
                      height: 48,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(suffixText: '%', isDense: true),
                        onChanged: (_) => setDialog(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Simulasi', style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Semua harga ${naik ? 'naik' : 'turun'} $persen%, dibulatkan ke ratusan.\nContoh: ${rupiah(contoh)} → ${rupiah(contohBaru.clamp(100, 100000000))}',
                  style: AppText.small.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
              PrimaryButton(
                label: 'Terapkan',
                onPressed: () {
                  widget.onBulkPrice(bertanda);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Harga ${widget.menus.length} produk diperbarui.')));
                },
              ),
            ],
          );
        },
      ),
    );
    disposeControllersLater([ctrl]);
  }

  Future<void> _imporData() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impor Data Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Satu produk per baris, format:\nNama;Kategori;Harga', style: AppText.small.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Es Teh Manis;Non Kopi;8000\nRoti Bakar;Makanan;15000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          PrimaryButton(
            label: 'Impor',
            onPressed: () {
              final hasil = <MenuItem>[];
              var dilewati = 0;
              final baris = ctrl.text.split('\n').where((b) => b.trim().isNotEmpty);
              var i = 0;
              for (final b in baris) {
                final kolom = b.split(';').map((s) => s.trim()).toList();
                final harga = kolom.length == 3 ? int.tryParse(kolom[2].replaceAll(RegExp(r'[^0-9]'), '')) : null;
                if (kolom.length != 3 || kolom[0].isEmpty || harga == null || harga <= 0) {
                  dilewati++;
                  continue;
                }
                hasil.add(MenuItem(
                  id: 'm${DateTime.now().millisecondsSinceEpoch}-$i',
                  name: kolom[0],
                  category: categories.contains(kolom[1]) ? kolom[1] : 'Makanan',
                  price: harga,
                  color: menuPalette[i % menuPalette.length],
                  icon: menuIconChoices[i % menuIconChoices.length],
                  isDrink: false,
                ));
                i++;
              }
              Navigator.of(ctx).pop();
              if (hasil.isNotEmpty) widget.onImport(hasil);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${hasil.length} produk diimpor${dilewati > 0 ? ', $dilewati baris dilewati (format salah)' : ''}.')),
              );
            },
          ),
        ],
      ),
    );
    disposeControllersLater([ctrl]);
  }

  Future<void> _eksporData() {
    final semua = widget.menus;
    final ringkasan = StringBuffer('Daftar Produk — ${widget.branchName} (${semua.length} produk)\n');
    for (final m in semua) {
      ringkasan.writeln('• ${m.name} (${m.category}) — ${rupiah(m.price)}');
    }
    return bukaPratinjauLaporan(
      context,
      judul: 'Daftar Produk',
      ringkasan: ringkasan.toString().trim(),
      kepala: const ['Produk', 'Kategori', 'SKU', 'Harga'],
      baris: [for (final m in semua) [m.name, m.category, skuOf(m), '${m.price}']],
    );
  }

  Future<void> _bukaEditor(MenuItem? m) async {
    await showMenuEditor(
      context,
      initial: m,
      onAdd: widget.onAdd,
      onChanged: widget.onChanged,
      onDelete: widget.onDelete,
      ingredients: widget.ingredients,
      allMenus: widget.menus,
    );
    // Sesudah editor ditutup fokus jangan kembali ke kolom cari
    // (permintaan Adnan 2026-11-15: keyboard muncul sendiri
    // sesudah hapus produk).
    if (mounted) {
      _fokusCari.unfocus();
      setState(() {});
    }
  }

  void _aksiMenu(String aksi) {
    switch (aksi) {
      case 'massal':
        _editHargaMassal();
      case 'bahan':
        setState(() => _tampilBahan = !_tampilBahan);
      case 'ojol':
        setState(() => _tampilOjol = !_tampilOjol);
      case 'pilih':
        setState(() => _modePilih = true);
      case 'ekspor':
        _eksporData();
      case 'impor':
        _imporData();
      case 'resep':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResepScreen(menus: widget.menus, ingredients: widget.ingredients, onEditMenu: _bukaEditor),
          ),
        );
      case 'bundle':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BundleScreen(menus: widget.menus, onEditMenu: _bukaEditor),
          ),
        );
      case 'label':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LabelHargaScreen(
              menus: widget.menus,
              businessName: widget.businessName.isNotEmpty ? widget.businessName : widget.branchName,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final tombolMenu = PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Pilihan produk',
      onSelected: _aksiMenu,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'massal', child: Text('Edit Harga Massal')),
        PopupMenuItem(
          value: 'bahan',
          // Keadaan nyala ditandai TEKS 'Aktif', bukan
          // centang (aturan permanen Adnan).
          child: Row(
            children: [
              const Expanded(child: Text('Tampilkan Bahan Baku')),
              if (_tampilBahan)
                Text('Aktif', style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const PopupMenuItem(value: 'pilih', child: Text('Pilih Produk')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'ekspor', child: Text('Ekspor Data')),
        const PopupMenuItem(value: 'impor', child: Text('Impor Data')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'resep', child: Text('Resep')),
        const PopupMenuItem(value: 'bundle', child: Text('Bundle')),
        PopupMenuItem(
          value: 'ojol',
          child: Row(
            children: [
              const Expanded(child: Text('Tampilkan Harga Ojol')),
              if (_tampilOjol)
                Text('Aktif', style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const PopupMenuItem(value: 'label', child: Text('Cetak Label Harga')),
      ],
    );
    return Stack(
      children: [
        // Kepala lengket yang MENYUSUT beranimasi mengikuti guliran
        // (permintaan Adnan 2026-11-15): judul + kolom cari besar
        // mengecil jadi baris ringkas, pill kategori tetap
        // menempel di bawahnya.
        CustomScrollView(
          controller: _gulirCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _KepalaProdukDelegate(
                subjudul: '${widget.menus.length} produk · ${widget.branchName}',
                cariCtrl: _cariCtrl,
                fokusCari: _fokusCari,
                onCari: (v) => setState(() => _query = v),
                onRingkas: _lompatKeCari,
                trailing: tombolMenu,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _KepalaTetapDelegate(
                tinggi: 50,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
                  child: FilterChipRow(
                    children: [
                      for (final c in categories)
                        AppChip(label: c, selected: _kategori == c, onSelected: (_) => setState(() => _kategori = c)),
                    ],
                  ),
                ),
              ),
            ),
            if (list.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxl),
                  child: EmptyState(message: 'Tidak ada produk yang cocok.\nCoba kata cari atau kategori lain.', icon: Icons.restaurant_menu_outlined),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    for (final m in list)
                      AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        onTap: () {
                          if (_modePilih) {
                            setState(() => _terpilih.contains(m.id) ? _terpilih.remove(m.id) : _terpilih.add(m.id));
                          } else {
                            _bukaEditor(m);
                          }
                        },
                        child: Row(
                          children: [
                            if (_modePilih) ...[
                              Checkbox(
                                value: _terpilih.contains(m.id),
                                onChanged: (v) => setState(() => v == true ? _terpilih.add(m.id) : _terpilih.remove(m.id)),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            MenuThumb(menu: m, size: 52),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: AppText.body.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                        child: Text(m.category, style: AppText.caption.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(skuOf(m), style: AppText.caption.copyWith(color: AppColors.muted)),
                                      if (m.isBundle) ...[
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                          child: Text('Bundle', style: AppText.caption.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(rupiah(m.price), style: AppText.body.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentDark)),
                                if (_tampilOjol)
                                  Text('Ojol ${rupiah(m.hargaOjolEfektif)}', style: AppText.caption.copyWith(color: AppColors.muted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_tampilBahan) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const SectionTitle('Bahan Baku'),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Daftar bahan dari Stok Bahan (atur di layar Stok Bahan).', style: AppText.caption.copyWith(color: AppColors.muted)),
                      const SizedBox(height: AppSpacing.md),
                      for (final ing in widget.ingredients)
                        AppCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: Icon(Icons.inventory_2_outlined, color: AppColors.muted, size: 22),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: Text(ing.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
                              Text('${stockText(ing.stock)} ${ing.unit}', style: AppText.small.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                    ],
                    if (_modePilih) const SizedBox(height: 64),
                  ]),
                ),
              ),
          ],
        ),
        if (_modePilih)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text('${_terpilih.length} dipilih', style: AppText.body.copyWith(fontWeight: FontWeight.w700))),
                  TextButton(onPressed: _keluarModePilih, child: const Text('Batal')),
                  PrimaryButton(
                    label: 'Hapus Terpilih',
                    backgroundColor: AppColors.danger,
                    onPressed: _terpilih.isEmpty ? null : _hapusTerpilih,
                  ),
                ],
              ),
            ),
          )
        else
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_sudahGulir) ...[
                  Material(
                    color: AppColors.card,
                    elevation: 5,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _lompatKeCari,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.search, color: AppColors.accentDark, size: 23),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                FloatingActionButton(
                  heroTag: 'tambahProduk',
                  onPressed: () => _bukaEditor(null),
                  tooltip: 'Tambah Produk',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kepala Produk yang menyusut mengikuti guliran: bentuk besar
/// (judul + subjudul + kolom cari) memudar jadi baris ringkas
/// (judul kecil + tombol cari + menu) — lengket di atas, animasi
/// sebanding jarak gulir, bukan berubah seketika.
class _KepalaProdukDelegate extends SliverPersistentHeaderDelegate {
  _KepalaProdukDelegate({
    required this.subjudul,
    required this.cariCtrl,
    required this.fokusCari,
    required this.onCari,
    required this.onRingkas,
    required this.trailing,
  });

  final String subjudul;
  final TextEditingController cariCtrl;
  final FocusNode fokusCari;
  final ValueChanged<String> onCari;
  final VoidCallback onRingkas;
  final Widget trailing;

  @override
  double get maxExtent => 168;

  @override
  double get minExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Opacity(
            opacity: 1 - t,
            child: IgnorePointer(
              ignoring: t > 0.5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Produk', style: AppText.pageTitle),
                          const SizedBox(height: 2),
                          Text(subjudul, style: AppText.small.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: cariCtrl,
                      focusNode: fokusCari,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari produk…'),
                      onChanged: onCari,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16 - 11 * t,
            right: AppSpacing.lg,
            child: trailing,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: minExtent,
              child: Opacity(
                opacity: t,
                child: IgnorePointer(
                  ignoring: t <= 0.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Text('Produk', style: AppText.title),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(subjudul, style: AppText.small.copyWith(color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(icon: const Icon(Icons.search), tooltip: 'Cari produk', onPressed: onRingkas),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _KepalaProdukDelegate oldDelegate) => oldDelegate.subjudul != subjudul;
}

/// Kepala lengket setinggi tetap (untuk pill kategori).
class _KepalaTetapDelegate extends SliverPersistentHeaderDelegate {
  _KepalaTetapDelegate({required this.tinggi, required this.child});

  final double tinggi;
  final Widget child;

  @override
  double get maxExtent => tinggi;

  @override
  double get minExtent => tinggi;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _KepalaTetapDelegate oldDelegate) => oldDelegate.child != child;
}
