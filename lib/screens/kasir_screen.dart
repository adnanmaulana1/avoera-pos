import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({
    super.key,
    required this.cart,
    required this.selectedTable,
    required this.tables,
    required this.onSelectTable,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
    required this.onCheckout,
  });

  final List<CartItem> cart;
  final CafeTable? selectedTable;
  final List<CafeTable> tables;
  final ValueChanged<CafeTable> onSelectTable;
  final void Function(MenuItem menu, String variant, int unitPrice, String note) onAdd;
  final ValueChanged<CartItem> onInc;
  final ValueChanged<CartItem> onDec;
  final ValueChanged<CartItem> onRemove;
  final void Function(String paymentMethod) onCheckout;

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String _category = 'Semua';
  String _query = '';
  String _orderType = 'Dine-in';

  int get _subtotal => widget.cart.fold(0, (a, c) => a + c.total);
  int get _service => (_subtotal * 0.05).round();
  int get _tax => (_subtotal * 0.10).round();
  int get _grandTotal => _subtotal + _service + _tax;
  int get _itemCount => widget.cart.fold(0, (a, c) => a + c.qty);

  List<MenuItem> get _filtered => menuItems.where((m) {
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kasir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('Ketuk menu untuk memilih varian. Ketuk + untuk tambah cepat.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              _tablePicker(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari menu…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Dine-in', label: Text('Dine-in')),
                  ButtonSegment(value: 'Bungkus', label: Text('Bungkus')),
                ],
                selected: {_orderType},
                onSelectionChanged: (s) => setState(() => _orderType = s.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final active = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: active,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Menu tidak ditemukan.', style: TextStyle(color: AppColors.muted)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisExtent: 168,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _MenuCard(
                      item: _filtered[i],
                      onTap: () => _openVariantSheet(_filtered[i]),
                      onQuickAdd: () => widget.onAdd(_filtered[i], 'Reguler · Gula normal', _filtered[i].price, ''),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: cardDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_restaurant_outlined, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              widget.selectedTable == null ? 'Pilih Meja' : 'Meja ${widget.selectedTable!.number}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_itemCount item', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                Text(rupiah(_grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          FilledButton(
            onPressed: widget.cart.isEmpty ? null : () => _openCartSheet(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            child: const Text('Lihat Keranjang'),
          ),
        ],
      ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: _CartPanel(
          cart: widget.cart,
          selectedTable: widget.selectedTable,
          orderType: _orderType,
          subtotal: _subtotal,
          service: _service,
          tax: _tax,
          grandTotal: _grandTotal,
          onInc: (c) { widget.onInc(c); setState(() {}); },
          onDec: (c) { widget.onDec(c); setState(() {}); },
          onRemove: (c) { widget.onRemove(c); setState(() {}); },
          onPay: () {
            Navigator.pop(context);
            _openPayment(context);
          },
        ),
      ),
    );
  }

  Future<void> _openVariantSheet(MenuItem item) async {
    var size = 'Reguler';
    var sugar = 'Gula normal';
    var qty = 1;
    final noteCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final extra = size == 'Besar' ? 4000 : 0;
          final unit = item.price + extra;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                    Text(rupiah(unit), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentDark)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Ukuran', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in ['Reguler', 'Besar (+Rp4.000)'])
                      ChoiceChip(
                        label: Text(s),
                        selected: (s.startsWith('Besar') ? 'Besar' : 'Reguler') == size,
                        onSelected: (_) => setSheet(() => size = s.startsWith('Besar') ? 'Besar' : 'Reguler'),
                      ),
                  ],
                ),
                if (item.isDrink) ...[
                  const SizedBox(height: 12),
                  const Text('Level Gula', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ['Gula normal', 'Less sugar', 'Tanpa gula'])
                        ChoiceChip(label: Text(s), selected: sugar == s, onSelected: (_) => setSheet(() => sugar = s)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Catatan, contoh: tidak pedas, es sedikit…',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton.outlined(onPressed: qty > 1 ? () => setSheet(() => qty--) : null, icon: const Icon(Icons.remove)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$qty', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    IconButton.outlined(onPressed: () => setSheet(() => qty++), icon: const Icon(Icons.add)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          final variant = item.isDrink ? '$size · $sugar' : size;
                          for (var i = 0; i < qty; i++) {
                            widget.onAdd(item, variant, unit, noteCtrl.text.trim());
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text('Tambah · ${rupiah(unit * qty)}'),
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
    noteCtrl.dispose();
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
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(m),
                          selected: method == m,
                          onSelected: (_) => setDlg(() => method = m),
                          selectedColor: AppColors.accent,
                          labelStyle: TextStyle(color: method == m ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total bayar'),
                    Text(rupiah(_grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (method == 'Tunai') ...[
                  const SizedBox(height: 12),
                  const Text('Uang diterima', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final amt in [_grandTotal, 50000, 100000, 200000])
                        ActionChip(
                          label: Text(amt == _grandTotal ? 'Uang pas' : rupiah(amt)),
                          onPressed: amt >= _grandTotal ? () => setDlg(() => paid = amt) : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paid == null ? 'Pilih nominal uang diterima.' : 'Kembalian: ${rupiah(change < 0 ? 0 : change)}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: cardDecoration(),
                    child: const Column(
                      children: [
                        Icon(Icons.qr_code_2, size: 64, color: AppColors.ink),
                        SizedBox(height: 6),
                        Text('Tampilkan QR ini ke pelanggan', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
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
    widget.onCheckout(methodResult);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Pembayaran Berhasil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Metode: $methodResult · ${rupiah(paidTotal)}',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 4),
            const Text('Pesanan diteruskan ke dapur.', style: TextStyle(color: AppColors.muted)),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                width: double.infinity,
                decoration: BoxDecoration(color: item.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(13))),
                child: Center(child: Icon(item.icon, color: Colors.white, size: 34)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ),
                      Row(
                        children: [
                          Expanded(child: Text(rupiah(item.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                          IconButton.filled(
                            onPressed: onQuickAdd,
                            icon: const Icon(Icons.add, size: 18),
                            style: IconButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, minimumSize: const Size(30, 30)),
                          ),
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
  final ValueChanged<CartItem> onInc, onDec, onRemove;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Expanded(child: Text('Pesanan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
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
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Keranjang masih kosong.\nKetuk menu untuk menambah.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: cart.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) {
                    final c = cart[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(c.menu.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text(rupiah(c.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Text(c.variant, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          if (c.note.isNotEmpty) Text('Catatan: ${c.note}', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton.outlined(
                                onPressed: () => onDec(c),
                                icon: const Icon(Icons.remove, size: 16),
                                style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                              ),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${c.qty}', style: const TextStyle(fontWeight: FontWeight.w800))),
                              IconButton.outlined(
                                onPressed: () => onInc(c),
                                icon: const Icon(Icons.add, size: 16),
                                style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => onRemove(c),
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                label: const Text('Hapus', style: TextStyle(color: AppColors.danger, fontSize: 12)),
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(
            children: [
              _row('Subtotal', subtotal),
              _row('Biaya layanan (5%)', service),
              _row('Pajak (10%)', tax),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(rupiah(grandTotal), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: cart.isEmpty ? null : onPay,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            Text(rupiah(value), style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}
