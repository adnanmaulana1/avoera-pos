import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'store.dart';
import 'theme.dart';
import 'screens/beranda_screen.dart';
import 'screens/kasir_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/notifikasi_screen.dart';
import 'screens/laporan_detail_screens.dart';
import 'screens/onboarding_screen.dart';
import 'screens/meja_screen.dart';
import 'screens/dapur_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/stok_screen.dart';
import 'screens/pengaturan_screen.dart';
import 'screens/kelola_menu_screen.dart';
import 'screens/kelola_meja_screen.dart';
import 'screens/kelola_stok_screen.dart';

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
  _NavItem('Beranda', Icons.home_outlined, Icons.home),
  _NavItem('Kasir', Icons.point_of_sale_outlined, Icons.point_of_sale),
  _NavItem('Produk', Icons.inventory_2_outlined, Icons.inventory_2),
  _NavItem('Meja', Icons.table_restaurant_outlined, Icons.table_restaurant),
  _NavItem('Dapur', Icons.soup_kitchen_outlined, Icons.soup_kitchen),
  _NavItem('Laporan', Icons.bar_chart_outlined, Icons.bar_chart),
  _NavItem('Stok Bahan', Icons.inventory_outlined, Icons.inventory),
  _NavItem('Pengaturan', Icons.settings_outlined, Icons.settings),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final List<CartItem> _cart = [];
  final List<KitchenOrder> _kitchen = seedKitchenOrders();
  CafeTable? _selectedTable;
  int _orderCounter = 1043;

  // ---------- Data tersimpan (dimuat dari LocalStore) ----------
  bool _ready = false;
  List<MenuItem> _menus = [];
  List<CafeTable> _tables = [];
  List<Ingredient> _ingredients = [];
  AppSettings _settings = AppSettings();
  List<TxRecord> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await LocalStore.load();
    if (!mounted) return;
    setState(() {
      _menus = data.menus;
      _tables = data.tables;
      _ingredients = data.ingredients;
      _settings = data.settings;
      _transactions = data.transactions;
      _ready = true;
    });
  }

  // ---------- CRUD: Menu ----------
  void _addMenu(MenuItem m) {
    setState(() => _menus.add(m));
    LocalStore.saveMenus(_menus);
  }

  void _menuChanged() {
    setState(() {});
    LocalStore.saveMenus(_menus);
  }

  void _deleteMenu(MenuItem m) {
    setState(() {
      _menus.remove(m);
      _cart.removeWhere((c) => c.menu.id == m.id);
    });
    LocalStore.saveMenus(_menus);
  }

  // ---------- CRUD: Meja ----------
  void _addTable(CafeTable t) {
    setState(() {
      _tables.add(t);
      _tables.sort((a, b) => a.number.compareTo(b.number));
    });
    LocalStore.saveTables(_tables);
  }

  void _tableChanged() {
    setState(() => _tables.sort((a, b) => a.number.compareTo(b.number)));
    LocalStore.saveTables(_tables);
  }

  void _deleteTable(CafeTable t) {
    setState(() {
      _tables.remove(t);
      if (_selectedTable == t) _selectedTable = null;
    });
    LocalStore.saveTables(_tables);
  }

  // ---------- CRUD: Stok bahan ----------
  void _addIngredient(Ingredient i) {
    setState(() => _ingredients.add(i));
    LocalStore.saveIngredients(_ingredients);
  }

  void _ingredientChanged() {
    setState(() {});
    LocalStore.saveIngredients(_ingredients);
  }

  void _deleteIngredient(Ingredient i) {
    setState(() => _ingredients.remove(i));
    LocalStore.saveIngredients(_ingredients);
  }

  // ---------- Pengaturan ----------
  void _settingChanged(void Function() apply) {
    setState(apply);
    LocalStore.saveSettings(_settings);
  }

  // ---------- Buka layar kelola ----------
  void _openKelolaMenu() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KelolaMenuScreen(menus: _menus, onAdd: _addMenu, onChanged: _menuChanged, onDelete: _deleteMenu),
        ),
      );

  void _openKelolaMeja() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KelolaMejaScreen(tables: _tables, onAdd: _addTable, onChanged: _tableChanged, onDelete: _deleteTable),
        ),
      );

  void _openKelolaStok() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KelolaStokScreen(ingredients: _ingredients, onAdd: _addIngredient, onChanged: _ingredientChanged, onDelete: _deleteIngredient),
        ),
      );

  // ---------- Laporan & pemberitahuan ----------
  void _openRiwayat() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RiwayatScreen(transactions: _transactions, branchId: _settings.activeBranchId)),
      );

  void _openBulanan() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanBulananScreen(transactions: _transactions, branchId: _settings.activeBranchId)),
      );

  void _openPajak() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanPajakScreen(transactions: _transactions, branchId: _settings.activeBranchId)),
      );

  void _openPiutang() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanPiutangScreen(tables: _tables)),
      );

  /// Pemberitahuan dari keadaan nyata: stok habis & kritis.
  List<AppNotice> get _notices => [
        for (final i in _ingredients)
          if (i.status == StockStatus.habis)
            AppNotice(title: 'Stok habis: ${i.name}', body: 'Sisa ${stockText(i.stock)} ${i.unit} — segera pesan lagi supaya menu tetap bisa dijual.', danger: true)
          else if (i.status == StockStatus.kritis)
            AppNotice(title: 'Stok kritis: ${i.name}', body: 'Sisa ${stockText(i.stock)} ${i.unit}, di bawah batas minimum ${stockText(i.minStock)} ${i.unit}. Siapkan pesanan pembelian.', danger: false),
      ];

  void _openNotices() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NotifikasiScreen(notices: _notices)),
      );

  void _switchBranch(Branch b) => _settingChanged(() => _settings.activeBranchId = b.id);

  void _finishOnboarding(AppSettings s) {
    setState(() => _settings = s);
    LocalStore.saveSettings(_settings);
  }

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

  void _checkout(String paymentMethod, String tableLabel, String orderType) {
    // Total dihitung SEBELUM keranjang dikosongkan, untuk catatan
    // tagihan berjalan di kartu meja.
    final subtotal = _cart.fold(0, (a, c) => a + c.total);
    final serviceAmt = (subtotal * _settings.servicePercent / 100).round();
    final taxAmt = (subtotal * _settings.taxPercent / 100).round();
    final grandTotal = subtotal + serviceAmt + taxAmt;
    final orderId = 'A-${_orderCounter++}';
    final itemCount = _cart.fold(0, (a, c) => a + c.qty);
    setState(() {
      final lines = _cart
          .map((c) => KitchenOrderLine(c.menu.name, c.qty, [c.variant, c.note].where((s) => s.isNotEmpty).join(' · ')))
          .toList();
      _kitchen.insert(
        0,
        KitchenOrder(
          id: orderId,
          tableLabel: tableLabel,
          orderType: orderType,
          lines: lines,
          status: KitchenStatus.baru,
          time: 'Baru saja',
        ),
      );
      if (_selectedTable != null) {
        if (_selectedTable!.status == TableStatus.kosong) {
          _selectedTable!.status = TableStatus.terisi;
          _selectedTable!.guestName = 'Pelanggan';
        }
        // Kartu meja wajib mencerminkan pesanan yang masuk — dulu
        // jumlahnya diam di Rp0 walau sudah pesan & bayar.
        _selectedTable!.openAmount += grandTotal;
        _selectedTable!.since ??= _nowHHmm();
      }
      // Catat transaksi ASLI untuk Beranda & laporan (penjualan
      // hari ini, pajak terkumpul, per cabang).
      _transactions.add(TxRecord(
        id: orderId,
        total: grandTotal,
        method: paymentMethod,
        at: DateTime.now(),
        items: itemCount,
        subtotal: subtotal,
        service: serviceAmt,
        tax: taxAmt,
        branchId: _settings.activeBranchId,
      ));
      _cart.clear();
    });
    LocalStore.saveTables(_tables);
    LocalStore.saveTransactions(_transactions);
  }

  String _nowHHmm() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
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
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Pemasangan pertama: onboarding + wizard cabang pertama dulu.
    if (!_settings.onboarded) {
      return OnboardingFlow(initial: _settings, onDone: _finishOnboarding);
    }
    final screens = <Widget>[
      BerandaScreen(
        businessName: _settings.businessName,
        branch: _settings.activeBranch,
        branches: _settings.branches,
        transactions: _transactions,
        kitchenActive: _kitchen.length,
        tablesEnabled: _settings.tablesEnabled,
        tablesOccupied: _tables.where((t) => t.status != TableStatus.kosong).length,
        tablesTotal: _tables.length,
        noticeCount: _notices.length,
        onOpenKasir: () => setState(() => _index = 1),
        onNavigate: (i) => setState(() => _index = i),
        onManageTables: _openKelolaMeja,
        onManageIngredients: _openKelolaStok,
        onSwitchBranch: _switchBranch,
        onOpenNotices: _openNotices,
        onOpenRiwayat: _openRiwayat,
      ),
      KasirScreen(
        cart: _cart,
        menus: _menus,
        // Meja mati → kasir tidak membawa meja sama sekali.
        selectedTable: _settings.tablesEnabled ? _selectedTable : null,
        tables: _tables,
        servicePercent: _settings.servicePercent,
        taxPercent: _settings.taxPercent,
        tablesEnabled: _settings.tablesEnabled,
        onSelectTable: _selectTable,
        onAdd: _addToCart,
        onInc: _inc,
        onDec: _dec,
        onRemove: _remove,
        onCheckout: _checkout,
      ),
      ProdukScreen(menus: _menus, onAdd: _addMenu, onChanged: _menuChanged, onDelete: _deleteMenu),
      MejaScreen(
        tables: _tables,
        selectedTable: _selectedTable,
        onSelect: _selectTable,
        // Kasir sekarang indeks 1 (indeks 0 = Beranda).
        onGoKasir: () => setState(() => _index = 1),
      ),
      DapurScreen(orders: _kitchen, onAdvance: _advanceKitchen),
      LaporanScreen(
        transactions: _transactions,
        branchId: _settings.activeBranchId,
        tables: _tables,
        onOpenRiwayat: _openRiwayat,
        onOpenBulanan: _openBulanan,
        onOpenPajak: _openPajak,
        onOpenPiutang: _openPiutang,
      ),
      StokScreen(ingredients: _ingredients),
      PengaturanScreen(
        businessName: _settings.businessName,
        businessAddress: _settings.businessAddress,
        businessPhone: _settings.businessPhone,
        servicePercent: _settings.servicePercent,
        taxPercent: _settings.taxPercent,
        menuCount: _menus.length,
        tableCount: _tables.length,
        ingredientCount: _ingredients.length,
        onBusinessNameChanged: (v) => _settingChanged(() => _settings.businessName = v),
        onBusinessAddressChanged: (v) => _settingChanged(() => _settings.businessAddress = v),
        onBusinessPhoneChanged: (v) => _settingChanged(() => _settings.businessPhone = v),
        onServicePercentChanged: (v) => _settingChanged(() => _settings.servicePercent = v),
        onTaxPercentChanged: (v) => _settingChanged(() => _settings.taxPercent = v),
        tablesEnabled: _settings.tablesEnabled,
        onTablesEnabledChanged: (v) => _settingChanged(() {
          _settings.tablesEnabled = v;
          if (!v) {
            // Meja mati: lepas meja terpilih & jangan tinggal di
            // layar Meja yang sudah tidak ada di navigasi.
            _selectedTable = null;
            if (_index == 3) _index = 0;
          }
        }),
        onManageMenus: _openKelolaMenu,
        onManageTables: _openKelolaMeja,
        onManageIngredients: _openKelolaStok,
        branches: _settings.branches,
        activeBranchId: _settings.activeBranchId,
        pinSet: _settings.pinHash.isNotEmpty,
        onSwitchBranch: _switchBranch,
        onAddBranch: (name) => _settingChanged(() {
          final id = 'c${DateTime.now().millisecondsSinceEpoch}';
          _settings.branches = [..._settings.branches, Branch(id: id, name: name)];
        }),
        onPinHashChanged: (hash) => _settingChanged(() => _settings.pinHash = hash),
      ),
    ];

    // Indeks layar yang tampil di navigasi. Meja (indeks 3) hilang
    // dari SEMUA navigasi saat fiturnya dimatikan di Pengaturan.
    final visible = <int>[
      for (var i = 0; i < _navItems.length; i++)
        if (i != 3 || _settings.tablesEnabled) i,
    ];
    // Bar bawah HP (urutan pilihan): Beranda, Kasir, Produk, Dapur —
    // Produk masuk bar atas permintaan Adnan (meniru Bisakasir);
    // Meja & sisanya di sidebar geser 'Lainnya'. Tablet: semua tampil.
    const barOrder = [0, 1, 2, 4];
    final mainNav = <int>[for (final i in barOrder) if (visible.contains(i)) i];
    final drawerNav = <int>[for (final i in visible) if (!mainNav.contains(i)) i];

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
                    items: visible,
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
          // Menu utama (Beranda, Kasir, Meja, Dapur) tinggal di bar
          // bawah; menu lain (Laporan, Stok, Pengaturan) pindah ke
          // sidebar geser yang dibuka dari tombol 'Lainnya' —
          // permintaan Adnan 2026-11-14: bar bawah lega, menu harian
          // gampang dijangkau. Saat meja mati, Meja keluar dari daftar
          // dan Dapur naik mengisi bar bawah.
          drawer: _PhoneDrawer(
            index: _index,
            items: drawerNav,
            businessName: _settings.businessName,
            onSelect: (i) => setState(() => _index = i),
          ),
          bottomNavigationBar: Builder(
            builder: (barCtx) => NavigationBar(
              // Sedang di menu drawer → sorot 'Lainnya'.
              selectedIndex: mainNav.contains(_index) ? mainNav.indexOf(_index) : mainNav.length,
              onDestinationSelected: (pos) {
                if (pos == mainNav.length) {
                  Scaffold.of(barCtx).openDrawer();
                } else {
                  setState(() => _index = mainNav[pos]);
                }
              },
              destinations: [
                for (final i in mainNav)
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: i == 4 && _kitchen.where((o) => o.status == KitchenStatus.baru).isNotEmpty,
                      label: Text('${_kitchen.where((o) => o.status == KitchenStatus.baru).length}'),
                      child: Icon(_navItems[i].icon),
                    ),
                    selectedIcon: Icon(_navItems[i].selectedIcon),
                    label: _navItems[i].label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.menu),
                  selectedIcon: Icon(Icons.menu),
                  label: 'Lainnya',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sidebar geser (drawer) khusus HP: menampung menu selain tiga menu
/// utama di bar bawah. Tampilannya meniru sidebar tablet supaya
/// rasanya satu keluarga.
class _PhoneDrawer extends StatelessWidget {
  const _PhoneDrawer({required this.index, required this.items, required this.businessName, required this.onSelect});
  final int index;

  /// Indeks layar yang masuk drawer (menu selain bar bawah).
  final List<int> items;
  final String businessName;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
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
                        Text(appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
                        Text(businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Text('MENU LAINNYA', style: AppText.caption.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Material(
                  color: index == i ? AppColors.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ListTile(
                    dense: true,
                    minTileHeight: 48,
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
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(i);
                    },
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('$appName v$appVersion · by $appStudio', style: AppText.caption.copyWith(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({required this.index, required this.items, required this.onChanged, required this.kitchenCount});
  final int index;

  /// Indeks layar yang tampil (Meja bisa hilang saat fiturnya mati).
  final List<int> items;
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
          // Daftar menu bisa digulir — 8 menu di layar pendek tidak
          // boleh meluber (tes tablet 800px menangkap luber 5px).
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final i in items)
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
                          trailing: (i == 4 && kitchenCount > 0) ? StatusChip(label: '$kitchenCount baru', color: AppColors.danger) : null,
                          onTap: () => onChanged(i),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Data tersimpan di perangkat ini.\n\n$appName v$appVersion · by $appStudio', style: AppText.caption.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
