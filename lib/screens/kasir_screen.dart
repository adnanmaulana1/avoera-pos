import 'dart:io';

import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'pembayaran_screen.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({
    super.key,
    required this.cart,
    required this.menus,
    required this.selectedTable,
    required this.tables,
    required this.servicePercent,
    required this.taxPercent,
    required this.tablesEnabled,
    this.kitchenEnabled = true,
    required this.onSelectTable,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
    required this.onCheckout,
    this.promos = const [],
  });

  final List<CartItem> cart;

  /// Daftar menu dari data tersimpan (bisa berubah lewat Kelola Menu).
  final List<MenuItem> menus;
  final CafeTable? selectedTable;
  final List<CafeTable> tables;

  /// Persen biaya dari Pengaturan — berlaku langsung di hitungan kasir.
  final int servicePercent;
  final int taxPercent;

  /// Fitur meja dari Pengaturan. Mati → tombol Pilih Meja disembunyikan
  /// (kedai tanpa meja tidak perlu memilih meja).
  final bool tablesEnabled;

  /// Fitur dapur menyala? Menentukan bunyi dialog sesudah bayar:
  /// mati = tidak ada tiket, dialog TIDAK boleh mengaku pesanan
  /// diteruskan ke dapur (laporan Adnan 23:51: dialog lama selalu
  /// mengaku diteruskan walau dapur mati — tiketnya memang tidak
  /// dibuat, tapi tulisannya berbohong).
  final bool kitchenEnabled;
  final ValueChanged<CafeTable> onSelectTable;
  final void Function(MenuItem menu, String variant, int unitPrice, String note) onAdd;
  final ValueChanged<CartItem> onInc;
  final ValueChanged<CartItem> onDec;
  final ValueChanged<CartItem> onRemove;
  final void Function(String paymentMethod, String tableLabel, String orderType, Promo? promo) onCheckout;

  /// Promo yang bisa dipilih kasir (v0.11.0). Pilihan kasir
  /// hidup di state layar ini dan diteruskan ke onCheckout;
  /// besar diskon selalu dihitung hitungDiskonPromo.
  final List<Promo> promos;

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String _category = 'Semua';
  String _query = '';
  String _orderType = 'Dine-in';

  /// Promo pilihan kasir untuk pesanan ini (v0.11.0). Direset
  /// sesudah pembayaran berhasil supaya tidak terbawa ke
  /// pelanggan berikutnya.
  Promo? _promo;

  /// Promo pilihan yang MASIH berlaku (ada di daftar & aktif).
  /// Promo yang dihapus/dinonaktifkan pemilik di tengah jalan
  /// berhenti berlaku tanpa kasir sadar ada yang berubah.
  Promo? get _promoBerlaku {
    final p = _promo;
    if (p == null) return null;
    for (final x in widget.promos) {
      if (x.id == p.id && x.aktif) return x;
    }
    return null;
  }

  int get _subtotal => widget.cart.fold(0, (a, c) => a + c.total);
  int get _service => (_subtotal * widget.servicePercent / 100).round();
  int get _tax => (_subtotal * widget.taxPercent / 100).round();
  int get _diskon => hitungDiskonPromo(_promoBerlaku, _subtotal);
  int get _grandTotal => _subtotal + _service + _tax - _diskon;
  int get _itemCount => widget.cart.fold(0, (a, c) => a + c.qty);

  List<MenuItem> get _filtered => widget.menus.where((m) {
        final inCat = _category == 'Semua' || m.category == _category;
        final inQuery = m.name.toLowerCase().contains(_query.toLowerCase());
        return inCat && inQuery;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final menuArea = _buildMenuArea();
    if (!wide) {
      return Column(
        children: [
          Expanded(child: menuArea),
          _buildMobileCartBar(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: menuArea),
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: _CartPanel(
            cart: widget.cart,
            selectedTable: widget.selectedTable,
            orderType: _orderType,
            subtotal: _subtotal,
            service: _service,
            tax: _tax,
            servicePercent: widget.servicePercent,
            taxPercent: widget.taxPercent,
            grandTotal: _grandTotal,
            diskon: _diskon,
            promoNama: _promoBerlaku?.nama ?? '',
            promoKurang: _promoBerlaku != null && _diskon == 0 ? _promoBerlaku!.minBelanja - _subtotal : 0,
            onTapPromo: widget.promos.where((p) => p.aktif).isEmpty ? null : () => _pilihPromo(context, () {}),
            onInc: widget.onInc,
            onDec: widget.onDec,
            onRemove: widget.onRemove,
            onPay: () => _openPayment(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Kasir',
            subtitle: 'Ketuk menu untuk memilih varian. Ketuk + untuk tambah cepat.',
            trailing: widget.tablesEnabled ? _tablePicker() : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari menu…',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SegmentedButton<String>(
                // Tanpa ikon centang pada pilihan aktif (aturan
                // permanen Adnan) — cukup warna dari tema segmented.
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'Dine-in', label: Text('Dine-in')),
                  ButtonSegment(value: 'Bungkus', label: Text('Bungkus')),
                ],
                selected: {_orderType},
                onSelectionChanged: (s) => setState(() => _orderType = s.first),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilterChipRow(
            children: [
              for (final c in categories)
                AppChip(
                  label: c,
                  selected: c == _category,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(message: 'Menu tidak ditemukan.\nCoba kata kunci atau kategori lain.', icon: Icons.search_off_outlined)
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      // 184: nama menu 2 baris (mis. "Nasi Goreng Kampung")
                      // butuh ruang penuh; di 168 baris keduanya kepotong.
                      mainAxisExtent: 184,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _MenuCard(
                      item: _filtered[i],
                      onTap: () => _openVariantSheet(_filtered[i]),
                      // Tambah cepat: makanan tidak pakai varian gula.
                      onQuickAdd: () => widget.onAdd(_filtered[i], _filtered[i].isDrink ? 'Reguler · Gula normal' : 'Reguler', _filtered[i].price, ''),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tablePicker() {
    return PopupMenuButton<CafeTable>(
      onSelected: widget.onSelectTable,
      itemBuilder: (_) => widget.tables
          .map((t) => PopupMenuItem(
                value: t,
                child: Text('Meja ${t.number} — ${t.status.label}'),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: cardDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_restaurant_outlined, size: 20, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              widget.selectedTable == null ? 'Pilih Meja' : 'Meja ${widget.selectedTable!.number}',
              style: AppText.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: _Denyut(
              pemicu: _itemCount,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_itemCount item', style: AppText.small.copyWith(color: AppColors.muted)),
                  AnimatedRupiah(value: _grandTotal, style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: 'Lihat Keranjang',
            onPressed: widget.cart.isEmpty ? null : () => _openCartSheet(),
          ),
        ],
      ),
    );
  }

  void _openCartSheet() {
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      // WAJIB StatefulBuilder: sheet adalah rute terpisah — tanpa ini
      // isi sheet digambar sekali saat dibuka dan tidak pernah segar
      // lagi, jadi tombol +/−/Hapus mengubah data tapi tampilan diam
      // (bug yang dilaporkan dari HP: keranjang "tidak berfungsi").
      // Angka total juga dihitung ulang di dalam builder ini.
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => SizedBox(
          height: MediaQuery.sizeOf(sheetCtx).height * 0.78,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: SheetHandle(),
              ),
              Expanded(
                child: _CartPanel(
                  cart: widget.cart,
                  selectedTable: widget.selectedTable,
                  orderType: _orderType,
                  subtotal: _subtotal,
                  service: _service,
                  tax: _tax,
                  servicePercent: widget.servicePercent,
                  taxPercent: widget.taxPercent,
                  grandTotal: _grandTotal,
                  diskon: _diskon,
                  promoNama: _promoBerlaku?.nama ?? '',
                  promoKurang: _promoBerlaku != null && _diskon == 0 ? _promoBerlaku!.minBelanja - _subtotal : 0,
                  onTapPromo: widget.promos.where((p) => p.aktif).isEmpty ? null : () => _pilihPromo(sheetCtx, () => setSheet(() {})),
                  onInc: (c) { widget.onInc(c); setSheet(() {}); },
                  onDec: (c) { widget.onDec(c); setSheet(() {}); },
                  onRemove: (c) { widget.onRemove(c); setSheet(() {}); },
                  onPay: () {
                    Navigator.pop(sheetCtx);
                    _openPayment(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVariantSheet(MenuItem item) async {
    var size = 'Reguler';
    var sugar = 'Gula normal';
    var qty = 1;
    final noteCtrl = TextEditingController();
    await showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final extra = size == 'Besar' ? 4000 : 0;
          final unit = item.price + extra;
          return Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg + MediaQuery.viewInsetsOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: AppText.title.copyWith(fontWeight: FontWeight.w800))),
                    Text(rupiah(unit), style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentDark)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Ukuran', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final s in ['Reguler', 'Besar (+Rp4.000)'])
                      AppChip(
                        label: s,
                        selected: (s.startsWith('Besar') ? 'Besar' : 'Reguler') == size,
                        onSelected: (_) => setSheet(() => size = s.startsWith('Besar') ? 'Besar' : 'Reguler'),
                      ),
                  ],
                ),
                if (item.isDrink) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Level Gula', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final s in ['Gula normal', 'Less sugar', 'Tanpa gula'])
                        AppChip(label: s, selected: sugar == s, onSelected: (_) => setSheet(() => sugar = s)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Catatan, contoh: tidak pedas, es sedikit…',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    QtyButton(icon: Icons.remove, onPressed: qty > 1 ? () => setSheet(() => qty--) : null),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('$qty', style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    QtyButton(icon: Icons.add, onPressed: () => setSheet(() => qty++)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Tambah · ${rupiah(unit * qty)}',
                        onPressed: () {
                          final variant = item.isDrink ? '$size · $sugar' : size;
                          for (var i = 0; i < qty; i++) {
                            widget.onAdd(item, variant, unit, noteCtrl.text.trim());
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    disposeControllersLater([noteCtrl]);
  }

  /// Sheet pemilih promo (v0.11.0): daftar promo aktif dengan
  /// besar diskon untuk subtotal SAAT INI + pilihan Tanpa
  /// Promo. [segarkanInduk] menyegarkan sheet keranjang di
  /// belakangnya (di panel lebar tidak perlu — setState layar
  /// ini sudah menggambar ulang panelnya).
  Future<void> _pilihPromo(BuildContext ctx, VoidCallback segarkanInduk) async {
    final aktif = widget.promos.where((p) => p.aktif).toList();
    // Hasil dibungkus record: pop dengan pilihan mengembalikan
    // (dipilih: true, promo: ...) — termasuk 'Tanpa Promo' yang
    // promonya null. Geser-tutup mengembalikan null polos dan
    // TIDAK mengubah pilihan yang sudah ada.
    final hasil = await showAppSheet<({bool dipilih, Promo? promo})>(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg + MediaQuery.viewInsetsOf(sheetCtx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.md),
            Text('Pilih Promo', style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            _BarisPilihPromo(
              nama: 'Tanpa Promo',
              keterangan: 'Harga normal',
              nilaiKanan: '',
              terpilih: _promoBerlaku == null,
              onTap: () => Navigator.of(sheetCtx).pop((dipilih: true, promo: null)),
            ),
            for (final p in aktif)
              _BarisPilihPromo(
                nama: p.nama,
                keterangan: p.minBelanja > 0 && _subtotal < p.minBelanja
                    ? 'Min. belanja ${rupiah(p.minBelanja)} · kurang ${rupiah(p.minBelanja - _subtotal)} lagi'
                    : (p.jenis == 'persen' ? 'Diskon ${p.nilai}% dari subtotal' : 'Potongan langsung'),
                nilaiKanan: hitungDiskonPromo(p, _subtotal) > 0 ? '-${rupiah(hitungDiskonPromo(p, _subtotal))}' : '',
                terpilih: _promoBerlaku?.id == p.id,
                onTap: () => Navigator.of(sheetCtx).pop((dipilih: true, promo: p)),
              ),
          ],
        ),
      ),
    );
    if (hasil == null || !hasil.dipilih || !ctx.mounted) return;
    setState(() => _promo = hasil.promo);
    segarkanInduk();
  }

  Future<void> _openPayment(BuildContext context) async {
    // v0.10.1: pembayaran kini HALAMAN penuh (PembayaranScreen),
    // bukan dialog — permintaan Adnan 2026-11-15 (dialog sempit,
    // tombol menimpa kolom saat keyboard naik).
    final methodResult = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PembayaranScreen(
          subtotal: _subtotal,
          service: _service,
          tax: _tax,
          grandTotal: _grandTotal,
          diskon: _diskon,
          promoNama: _promoBerlaku?.nama ?? '',
          servicePercent: widget.servicePercent,
          taxPercent: widget.taxPercent,
          items: widget.cart
              .map((c) => BarisBayar(
                    nama: c.menu.name,
                    keterangan: [
                      if (c.variant.isNotEmpty && c.variant != 'Reguler') c.variant,
                      if (c.note.isNotEmpty) c.note,
                    ].join(' · '),
                    qty: c.qty,
                    total: c.total,
                  ))
              .toList(),
        ),
      ),
    );
    if (methodResult == null || !context.mounted) return;
    final paidTotal = _grandTotal;
    // Label tiket dapur mengikuti pilihan kasir: meja terpilih selalu
    // Dine-in; tanpa meja mengikuti tombol Dine-in/Bungkus di atas.
    final tableLabel = widget.selectedTable != null
        ? 'Meja ${widget.selectedTable!.number}'
        : (_orderType == 'Bungkus' ? 'Bungkus' : 'Dine-in');
    final orderTypeLabel = widget.selectedTable != null
        ? 'Dine-in'
        : (_orderType == 'Bungkus' ? 'Takeaway' : 'Dine-in');
    widget.onCheckout(methodResult, tableLabel, orderTypeLabel, _promoBerlaku);
    // Promo sekali pakai per pesanan: kosongkan pilihan supaya
    // pelanggan berikutnya mulai dari harga normal.
    if (mounted) setState(() => _promo = null);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Pembayaran Berhasil', style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text('Metode: $methodResult · ${rupiah(paidTotal)}',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.kitchenEnabled ? 'Pesanan diteruskan ke dapur.' : 'Transaksi tercatat di laporan.', style: TextStyle(color: AppColors.muted)),
          ],
        ),
        actions: [
          PrimaryButton(
            label: 'Selesai',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

class _Denyut extends StatefulWidget {
  const _Denyut({required this.pemicu, required this.child});

  /// Nilai yang kenaikannya memicu denyut (mis. jumlah item).
  final int pemicu;
  final Widget child;

  @override
  State<_Denyut> createState() => _DenyutState();
}

class _DenyutState extends State<_Denyut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void didUpdateWidget(_Denyut old) {
    super.didUpdateWidget(old);
    if (widget.pemicu > old.pemicu) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = _c.value;
        final skala = 1 + 0.16 * (t == 0 || t == 1 ? 0 : (t < 0.5 ? t * 2 : (1 - t) * 2));
        return Transform.scale(scale: skala, alignment: Alignment.centerLeft, child: child);
      },
    );
  }
}

class _MenuCard extends StatefulWidget {
  const _MenuCard({required this.item, required this.onTap, required this.onQuickAdd});
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  int _tekanan = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final adaFoto = item.imagePath != null && item.imagePath!.isNotEmpty;
    // Desain v0.6.0 dipertahankan: kartu putih bersih, warna menu
    // sebagai identitas. v0.8.0: menu dengan foto memakai foto
    // sebagai kepala kartu; tombol + berdenyut saat ditekan dan
    // total di bar keranjang ikut bergerak (animasi masuk
    // keranjang yang diminta Adnan).
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: cardDecoration(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (adaFoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.file(
                    File(item.imagePath!),
                    width: double.infinity,
                    height: 62,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _kotakIkon(item),
                  ),
                )
              else
                _kotakIkon(item),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.category, style: AppText.caption.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(child: Text(rupiah(item.price), style: AppText.body.copyWith(fontWeight: FontWeight.w800))),
                  _Denyut(
                    pemicu: _tekanan,
                    child: QtyButton(
                      icon: Icons.add,
                      filled: true,
                      onPressed: () {
                        setState(() => _tekanan++);
                        widget.onQuickAdd();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kotakIkon(MenuItem item) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(item.icon, color: item.color, size: 22),
      );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.selectedTable,
    required this.orderType,
    required this.subtotal,
    required this.service,
    required this.tax,
    required this.servicePercent,
    required this.taxPercent,
    required this.grandTotal,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
    required this.onPay,
    this.diskon = 0,
    this.promoNama = '',
    this.promoKurang = 0,
    this.onTapPromo,
  });

  final List<CartItem> cart;
  final CafeTable? selectedTable;
  final String orderType;
  final int subtotal, service, tax, grandTotal;
  final int servicePercent, taxPercent;
  final ValueChanged<CartItem> onInc, onDec, onRemove;
  final VoidCallback onPay;

  /// Promo di panel keranjang (v0.11.0): [diskon] yang sedang
  /// berlaku, nama promo terpilih, sisa belanja untuk memenuhi
  /// syaratnya (0 = syarat terpenuhi / tanpa promo), dan aksi
  /// membuka pemilih (null = tidak ada promo aktif sama sekali,
  /// baris promo disembunyikan).
  final int diskon;
  final String promoNama;
  final int promoKurang;
  final VoidCallback? onTapPromo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text('Pesanan', style: AppText.title.copyWith(fontWeight: FontWeight.w800))),
              StatusChip(
                label: selectedTable == null ? orderType : 'Meja ${selectedTable!.number}',
                color: AppColors.accentDark,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const EmptyState(message: 'Keranjang masih kosong.\nKetuk menu untuk menambah.', icon: Icons.shopping_basket_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: cart.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                  itemBuilder: (_, i) {
                    final c = cart[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(c.menu.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text(rupiah(c.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Text(c.variant, style: AppText.small.copyWith(color: AppColors.muted)),
                          if (c.note.isNotEmpty) Text('Catatan: ${c.note}', style: AppText.small.copyWith(color: AppColors.muted, fontStyle: FontStyle.italic)),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              QtyButton(icon: Icons.remove, onPressed: () => onDec(c)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs), child: Text('${c.qty}', style: const TextStyle(fontWeight: FontWeight.w800))),
                              QtyButton(icon: Icons.add, onPressed: () => onInc(c)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => onRemove(c),
                                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                icon: const Icon(Icons.delete_outline, size: 20),
                                label: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(
            children: [
              _row('Subtotal', subtotal),
              _row('Biaya layanan ($servicePercent%)', service),
              _row('Pajak ($taxPercent%)', tax),
              if (onTapPromo != null)
                InkWell(
                  onTap: onTapPromo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 17, color: AppColors.accentDark),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            promoNama.isEmpty ? 'Pakai Promo' : 'Promo · $promoNama',
                            style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (promoKurang > 0)
                          Text('kurang ${rupiah(promoKurang)} lagi', style: AppText.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700))
                        else
                          Icon(Icons.chevron_right, size: 17, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              if (diskon > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diskon promo', style: AppText.small.copyWith(color: AppColors.muted)),
                      Text('-${rupiah(diskon)}', style: AppText.small.copyWith(color: AppColors.accentDark, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
                  AnimatedRupiah(value: grandTotal, style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Bayar Sekarang',
                  onPressed: cart.isEmpty ? null : onPay,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.small.copyWith(color: AppColors.muted)),
            Text(rupiah(value), style: AppText.small),
          ],
        ),
      );
}

/// Satu baris pilihan di sheet pemilih promo kasir.
class _BarisPilihPromo extends StatelessWidget {
  const _BarisPilihPromo({required this.nama, required this.keterangan, required this.nilaiKanan, required this.terpilih, required this.onTap});
  final String nama;
  final String keterangan;
  final String nilaiKanan;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Row(
          children: [
            Icon(terpilih ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 21, color: terpilih ? AppColors.accentDark : AppColors.muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(keterangan, style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            if (nilaiKanan.isNotEmpty) Text(nilaiKanan, style: AppText.body.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentDark)),
          ],
        ),
      ),
    );
  }
}
