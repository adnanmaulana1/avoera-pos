import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({
    super.key,
    required this.cart,
    required this.menus,
    required this.selectedTable,
    required this.tables,
    required this.servicePercent,
    required this.taxPercent,
    required this.onSelectTable,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
    required this.onCheckout,
  });

  final List<CartItem> cart;

  /// Daftar menu dari data tersimpan (bisa berubah lewat Kelola Menu).
  final List<MenuItem> menus;
  final CafeTable? selectedTable;
  final List<CafeTable> tables;

  /// Persen biaya dari Pengaturan — berlaku langsung di hitungan kasir.
  final int servicePercent;
  final int taxPercent;
  final ValueChanged<CafeTable> onSelectTable;
  final void Function(MenuItem menu, String variant, int unitPrice, String note) onAdd;
  final ValueChanged<CartItem> onInc;
  final ValueChanged<CartItem> onDec;
  final ValueChanged<CartItem> onRemove;
  final void Function(String paymentMethod, String tableLabel, String orderType) onCheckout;

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String _category = 'Semua';
  String _query = '';
  String _orderType = 'Dine-in';

  int get _subtotal => widget.cart.fold(0, (a, c) => a + c.total);
  int get _service => (_subtotal * widget.servicePercent / 100).round();
  int get _tax => (_subtotal * widget.taxPercent / 100).round();
  int get _grandTotal => _subtotal + _service + _tax;
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
          decoration: const BoxDecoration(
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
            trailing: _tablePicker(),
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
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final c = categories[i];
                return AppChip(
                  label: c,
                  selected: c == _category,
                  onSelected: (_) => setState(() => _category = c),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(message: 'Menu tidak ditemukan.\nCoba kata kunci atau kategori lain.', icon: Icons.search_off_outlined)
                : GridView.builder(
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
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_itemCount item', style: AppText.small.copyWith(color: AppColors.muted)),
                Text(rupiah(_grandTotal), style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
              ],
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

  Future<void> _openPayment(BuildContext context) async {
    var method = 'Tunai';
    int? paid;
    final methodResult = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final change = (paid ?? 0) - _grandTotal;
          return AlertDialog(
            title: const Text('Pembayaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final m in ['Tunai', 'QRIS'])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppChip(
                          label: m,
                          selected: method == m,
                          onSelected: (_) => setDlg(() => method = m),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total bayar'),
                    Text(rupiah(_grandTotal), style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                if (method == 'Tunai') ...[
                  const SizedBox(height: AppSpacing.md),
                  const Text('Uang diterima', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final amt in [_grandTotal, 50000, 100000, 200000])
                        ActionChip(
                          label: Text(amt == _grandTotal ? 'Uang pas' : rupiah(amt)),
                          onPressed: amt >= _grandTotal ? () => setDlg(() => paid = amt) : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(prefixText: 'Rp ', hintText: 'atau ketik nominal sendiri'),
                    onChanged: (v) => setDlg(() => paid = int.tryParse(v)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    paid == null ? 'Pilih nominal uang diterima.' : 'Kembalian: ${rupiah(change < 0 ? 0 : change)}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_2, size: 64, color: AppColors.ink),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Tampilkan QR ini ke pelanggan', style: AppText.small.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                onPressed: (method == 'Tunai' && (paid == null || paid! < _grandTotal)) ? null : () => Navigator.pop(ctx, method),
                child: const Text('Proses Bayar'),
              ),
            ],
          );
        },
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
    widget.onCheckout(methodResult, tableLabel, orderTypeLabel);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Pembayaran Berhasil', style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text('Metode: $methodResult · ${rupiah(paidTotal)}',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.xs),
            const Text('Pesanan diteruskan ke dapur.', style: TextStyle(color: AppColors.muted)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onTap, required this.onQuickAdd});
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                width: double.infinity,
                decoration: BoxDecoration(color: item.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md))),
                child: Center(child: Icon(item.icon, color: AppColors.card, size: 32)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Row(
                        children: [
                          Expanded(child: Text(rupiah(item.price), style: AppText.body.copyWith(fontWeight: FontWeight.w800))),
                          QtyButton(icon: Icons.add, filled: true, onPressed: onQuickAdd),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  });

  final List<CartItem> cart;
  final CafeTable? selectedTable;
  final String orderType;
  final int subtotal, service, tax, grandTotal;
  final int servicePercent, taxPercent;
  final ValueChanged<CartItem> onInc, onDec, onRemove;
  final VoidCallback onPay;

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
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(
            children: [
              _row('Subtotal', subtotal),
              _row('Biaya layanan ($servicePercent%)', service),
              _row('Pajak ($taxPercent%)', tax),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
                  Text(rupiah(grandTotal), style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
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
