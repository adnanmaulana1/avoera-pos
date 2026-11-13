import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'theme.dart';
import 'screens/kasir_screen.dart';
import 'screens/meja_screen.dart';
import 'screens/dapur_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/stok_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Layar penuh dari ujung ke ujung, TAPI status bar & tombol navigasi
  // Android tetap terlihat. Isi aplikasi dijaga SafeArea di HomeShell
  // supaya tidak ada konten yang tertutup kedua bar itu.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KasirFnbApp());
}

class KasirFnbApp extends StatelessWidget {
  const KasirFnbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avoera POS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _navItems = <_NavItem>[
  _NavItem('Kasir', Icons.point_of_sale_outlined, Icons.point_of_sale),
  _NavItem('Meja', Icons.table_restaurant_outlined, Icons.table_restaurant),
  _NavItem('Dapur', Icons.soup_kitchen_outlined, Icons.soup_kitchen),
  _NavItem('Laporan', Icons.bar_chart_outlined, Icons.bar_chart),
  _NavItem('Stok Bahan', Icons.inventory_2_outlined, Icons.inventory_2),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final List<CartItem> _cart = [];
  final List<CafeTable> _tables = seedTables();
  final List<KitchenOrder> _kitchen = seedKitchenOrders();
  CafeTable? _selectedTable;
  int _orderCounter = 1043;

  // ---------- Cart actions ----------
  void _addToCart(MenuItem menu, String variant, int unitPrice, String note) {
    setState(() {
      final key = '${menu.id}|$variant';
      final idx = _cart.indexWhere((c) => c.key == key && c.note == note);
      if (idx >= 0) {
        _cart[idx].qty++;
      } else {
        _cart.add(CartItem(menu: menu, variant: variant, unitPrice: unitPrice, note: note));
      }
    });
  }

  void _inc(CartItem c) => setState(() => c.qty++);
  void _dec(CartItem c) => setState(() {
        if (c.qty > 1) {
          c.qty--;
        } else {
          _cart.remove(c);
        }
      });
  void _remove(CartItem c) => setState(() => _cart.remove(c));

  void _checkout(String paymentMethod) {
    setState(() {
      final lines = _cart
          .map((c) => KitchenOrderLine(c.menu.name, c.qty, [c.variant, c.note].where((s) => s.isNotEmpty).join(' · ')))
          .toList();
      _kitchen.insert(
        0,
        KitchenOrder(
          id: 'A-${_orderCounter++}',
          tableLabel: _selectedTable == null ? 'Bungkus' : 'Meja ${_selectedTable!.number}',
          orderType: _selectedTable == null ? 'Takeaway' : 'Dine-in',
          lines: lines,
          status: KitchenStatus.baru,
          time: 'Baru saja',
        ),
      );
      if (_selectedTable != null && _selectedTable!.status == TableStatus.kosong) {
        _selectedTable!.status = TableStatus.terisi;
        _selectedTable!.guestName = 'Pelanggan';
      }
      _cart.clear();
    });
  }

  // ---------- Kitchen ----------
  void _advanceKitchen(KitchenOrder order) {
    setState(() {
      switch (order.status) {
        case KitchenStatus.baru:
          order.status = KitchenStatus.dimasak;
        case KitchenStatus.dimasak:
          order.status = KitchenStatus.selesai;
        case KitchenStatus.selesai:
          _kitchen.remove(order);
      }
    });
  }

  void _selectTable(CafeTable t) => setState(() => _selectedTable = t);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      KasirScreen(
        cart: _cart,
        selectedTable: _selectedTable,
        tables: _tables,
        onSelectTable: _selectTable,
        onAdd: _addToCart,
        onInc: _inc,
        onDec: _dec,
        onRemove: _remove,
        onCheckout: _checkout,
      ),
      MejaScreen(
        tables: _tables,
        selectedTable: _selectedTable,
        onSelect: _selectTable,
        onGoKasir: () => setState(() => _index = 0),
      ),
      DapurScreen(orders: _kitchen, onAdvance: _advanceKitchen),
      const LaporanScreen(),
      const StokScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _SideBar(
                    index: _index,
                    kitchenCount: _kitchen.where((o) => o.status == KitchenStatus.baru).length,
                    onChanged: (i) => setState(() => _index = i),
                  ),
                  Expanded(child: IndexedStack(index: _index, children: screens)),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          // Atas dilindungi SafeArea supaya judul tidak tertutup status bar.
          // Bawah tidak perlu: NavigationBar sudah menjaga jarak dari
          // tombol navigasi Android.
          body: SafeArea(
            bottom: false,
            child: IndexedStack(index: _index, children: screens),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (var i = 0; i < _navItems.length; i++)
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: i == 2 && _kitchen.where((o) => o.status == KitchenStatus.baru).isNotEmpty,
                    label: Text('${_kitchen.where((o) => o.status == KitchenStatus.baru).length}'),
                    child: Icon(_navItems[i].icon),
                  ),
                  selectedIcon: Icon(_navItems[i].selectedIcon),
                  label: _navItems[i].label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({required this.index, required this.onChanged, required this.kitchenCount});
  final int index;
  final ValueChanged<int> onChanged;
  final int kitchenCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 218,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: const Icon(Icons.local_cafe, color: AppColors.card, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avoera POS', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
                      Text('Resto · Cafe · Kopi', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Shift pagi · Kasir: Rina', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _navItems.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Material(
                color: index == i ? AppColors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ListTile(
                  dense: true,
                  minTileHeight: 44,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  leading: Icon(
                    index == i ? _navItems[i].selectedIcon : _navItems[i].icon,
                    color: index == i ? AppColors.accentDark : AppColors.muted,
                    size: 24,
                  ),
                  title: Text(
                    _navItems[i].label,
                    style: AppText.body.copyWith(
                      fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                      color: index == i ? AppColors.accentDark : AppColors.ink,
                    ),
                  ),
                  trailing: (i == 2 && kitchenCount > 0) ? StatusChip(label: '$kitchenCount baru', color: AppColors.danger) : null,
                  onTap: () => onChanged(i),
                ),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('UI contoh · Tanpa backend\nData tidak tersimpan permanen.', style: AppText.caption.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
