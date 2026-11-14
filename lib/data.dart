import 'package:flutter/material.dart';

// ---------- Info aplikasi (satu sumber: popup Info Aplikasi, kaki sidebar) ----------
// appVersion WAJIB sama dengan angka di depan '+' pada version di pubspec.yaml.
const appName = 'Avoera POS';
const appVersion = '0.6.0';
const appStudio = 'Webtales Studio';

// ---------- Pengaturan (tersimpan permanen) ----------
class AppSettings {
  AppSettings({
    this.businessName = 'Avoera Cafe & Resto',
    this.businessAddress = 'Jl. Merdeka No. 10, Polewali Mandar',
    this.businessPhone = '0812-3456-7890',
    this.servicePercent = 5,
    this.taxPercent = 10,
    this.tablesEnabled = true,
  });
  String businessName;
  String businessAddress;
  String businessPhone;
  int servicePercent;
  int taxPercent;

  /// Meja TIDAK wajib (permintaan Adnan 2026-11-14): kedai tanpa
  /// meja bisa mematikan ini dari Pengaturan — menu Meja hilang dari
  /// navigasi dan kasir tidak lagi menawarkan pilihan meja.
  bool tablesEnabled;

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'businessAddress': businessAddress,
        'businessPhone': businessPhone,
        'servicePercent': servicePercent,
        'taxPercent': taxPercent,
        'tablesEnabled': tablesEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        businessName: j['businessName'] as String? ?? 'Avoera Cafe & Resto',
        businessAddress: j['businessAddress'] as String? ?? '',
        businessPhone: j['businessPhone'] as String? ?? '',
        servicePercent: (j['servicePercent'] as num?)?.toInt() ?? 5,
        taxPercent: (j['taxPercent'] as num?)?.toInt() ?? 10,
        // Data lama belum punya kunci ini → meja tetap aktif.
        tablesEnabled: j['tablesEnabled'] as bool? ?? true,
      );
}

String rupiah(int value) {
  final s = value.toString();
  final buf = StringBuffer('Rp');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ---------- Menu ----------

/// Daftar ikon menu resmi. MenuItem menyimpan NOMOR URUT di daftar
/// ini — BUKAN IconData rakitan dari codePoint. Alasannya teknis tapi
/// penting: build release Flutter membuang ikon font yang tak dipakai
/// (tree-shake), dan IconData rakitan membuat build release GAGAL
/// total (ketahuan 2026-11-14 saat pertama kali build release lokal).
/// Urutan daftar ini TIDAK BOLEH digeser — nomor urut tersimpan di
/// data pengguna. Boleh menambah di paling belakang.
const menuIconChoices = <IconData>[
  Icons.local_cafe,
  Icons.coffee,
  Icons.coffee_maker,
  Icons.emoji_food_beverage,
  Icons.local_drink,
  Icons.rice_bowl,
  Icons.dinner_dining,
  Icons.ramen_dining,
  Icons.set_meal,
  Icons.fastfood,
  Icons.bakery_dining,
  Icons.breakfast_dining,
  Icons.tapas,
  Icons.card_giftcard,
  Icons.group,
  Icons.cake,
  Icons.groups, // dipakai menu paket contoh lama
];

int _iconIndexOf(IconData icon) {
  final i = menuIconChoices.indexWhere((c) => c.codePoint == icon.codePoint);
  return i < 0 ? 0 : i;
}

int _iconIndexFromCodePoint(int codePoint) {
  final i = menuIconChoices.indexWhere((c) => c.codePoint == codePoint);
  return i < 0 ? 0 : i;
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.color,
    required IconData icon,
    this.isDrink = false,
  }) : iconIndex = _iconIndexOf(icon);
  final String id;
  String name;
  String category;
  int price;
  Color color;
  int iconIndex;
  bool isDrink;

  IconData get icon => menuIconChoices[iconIndex.clamp(0, menuIconChoices.length - 1)];
  set icon(IconData v) => iconIndex = _iconIndexOf(v);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'color': color.toARGB32(),
        'icon': icon.codePoint,
        'iconIndex': iconIndex,
        'isDrink': isDrink,
      };

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    // Data baru menyimpan iconIndex; data lama (≤0.3.2) hanya
    // menyimpan codePoint di 'icon' — petakan tanpa merakit IconData.
    final idx = (j['iconIndex'] as num?)?.toInt() ?? _iconIndexFromCodePoint((j['icon'] as num).toInt());
    return MenuItem(
      id: j['id'] as String,
      name: j['name'] as String,
      category: j['category'] as String,
      price: (j['price'] as num).toInt(),
      color: Color((j['color'] as num).toInt()),
      icon: menuIconChoices[idx.clamp(0, menuIconChoices.length - 1)],
      isDrink: j['isDrink'] as bool? ?? false,
    );
  }
}

const categories = ['Semua', 'Kopi', 'Non-Kopi', 'Makanan', 'Camilan', 'Paket'];

List<MenuItem> seedMenus() => <MenuItem>[
  MenuItem(id: 'k1', name: 'Kopi Susu Gula Aren', category: 'Kopi', price: 18000, color: Color(0xFF8D6E63), icon: Icons.local_cafe, isDrink: true),
  MenuItem(id: 'k2', name: 'Americano', category: 'Kopi', price: 15000, color: Color(0xFF4E342E), icon: Icons.coffee, isDrink: true),
  MenuItem(id: 'k3', name: 'Caffe Latte', category: 'Kopi', price: 22000, color: Color(0xFFA1887F), icon: Icons.local_cafe, isDrink: true),
  MenuItem(id: 'k4', name: 'Butterscotch Latte', category: 'Kopi', price: 24000, color: Color(0xFFBCAAA4), icon: Icons.coffee_maker, isDrink: true),
  MenuItem(id: 'k5', name: 'Kopi Tubruk', category: 'Kopi', price: 12000, color: Color(0xFF3E2723), icon: Icons.coffee, isDrink: true),
  MenuItem(id: 'n1', name: 'Matcha Latte', category: 'Non-Kopi', price: 22000, color: Color(0xFF7CB342), icon: Icons.emoji_food_beverage, isDrink: true),
  MenuItem(id: 'n2', name: 'Coklat Klasik', category: 'Non-Kopi', price: 20000, color: Color(0xFF6D4C41), icon: Icons.emoji_food_beverage, isDrink: true),
  MenuItem(id: 'n3', name: 'Es Teh Lemon', category: 'Non-Kopi', price: 12000, color: Color(0xFFF9A825), icon: Icons.local_drink, isDrink: true),
  MenuItem(id: 'n4', name: 'Red Velvet Latte', category: 'Non-Kopi', price: 22000, color: Color(0xFFC62828), icon: Icons.local_drink, isDrink: true),
  MenuItem(id: 'm1', name: 'Nasi Ayam Geprek', category: 'Makanan', price: 25000, color: Color(0xFFEF6C00), icon: Icons.rice_bowl),
  MenuItem(id: 'm2', name: 'Nasi Goreng Kampung', category: 'Makanan', price: 28000, color: Color(0xFFD84315), icon: Icons.dinner_dining),
  MenuItem(id: 'm3', name: 'Mie Goreng Telur', category: 'Makanan', price: 22000, color: Color(0xFFFF8F00), icon: Icons.ramen_dining),
  MenuItem(id: 'm4', name: 'Nasi Ayam Teriyaki', category: 'Makanan', price: 30000, color: Color(0xFF5D4037), icon: Icons.set_meal),
  MenuItem(id: 'c1', name: 'Kentang Goreng', category: 'Camilan', price: 15000, color: Color(0xFFFBC02D), icon: Icons.fastfood),
  MenuItem(id: 'c2', name: 'Pisang Goreng Coklat', category: 'Camilan', price: 16000, color: Color(0xFFFFA000), icon: Icons.bakery_dining),
  MenuItem(id: 'c3', name: 'Roti Bakar Coklat Keju', category: 'Camilan', price: 18000, color: Color(0xFF8D6E63), icon: Icons.breakfast_dining),
  MenuItem(id: 'c4', name: 'Dimsum Ayam (4 pcs)', category: 'Camilan', price: 17000, color: Color(0xFFAD1457), icon: Icons.tapas),
  MenuItem(id: 'p1', name: 'Paket Hemat Kopi + Roti', category: 'Paket', price: 32000, color: Color(0xFF00695C), icon: Icons.card_giftcard),
  MenuItem(id: 'p2', name: 'Paket Berdua', category: 'Paket', price: 68000, color: Color(0xFF00838F), icon: Icons.group),
  MenuItem(id: 'p3', name: 'Paket Nongkrong Berempat', category: 'Paket', price: 119000, color: Color(0xFF4527A0), icon: Icons.groups),
];

// ---------- Meja ----------
enum TableStatus { kosong, terisi, belumBayar }

extension TableStatusLabel on TableStatus {
  String get label => switch (this) {
        TableStatus.kosong => 'Kosong',
        TableStatus.terisi => 'Terisi',
        TableStatus.belumBayar => 'Belum Bayar',
      };
  Color get color => switch (this) {
        TableStatus.kosong => const Color(0xFF059669),
        TableStatus.terisi => const Color(0xFFD97706),
        TableStatus.belumBayar => const Color(0xFFDC2626),
      };
}

class CafeTable {
  CafeTable({required this.number, required this.capacity, required this.status, this.guestName, this.openAmount = 0, this.since});
  int number;
  int capacity;
  TableStatus status;
  String? guestName;
  int openAmount;
  String? since;

  Map<String, dynamic> toJson() => {
        'number': number,
        'capacity': capacity,
        'status': status.index,
        'guestName': guestName,
        'openAmount': openAmount,
        'since': since,
      };

  factory CafeTable.fromJson(Map<String, dynamic> j) => CafeTable(
        number: (j['number'] as num).toInt(),
        capacity: (j['capacity'] as num).toInt(),
        status: TableStatus.values[(j['status'] as num).toInt()],
        guestName: j['guestName'] as String?,
        openAmount: (j['openAmount'] as num?)?.toInt() ?? 0,
        since: j['since'] as String?,
      );
}

List<CafeTable> seedTables() => [
      CafeTable(number: 1, capacity: 2, status: TableStatus.kosong),
      CafeTable(number: 2, capacity: 2, status: TableStatus.terisi, guestName: 'Rina', openAmount: 56000, since: '19:12'),
      CafeTable(number: 3, capacity: 4, status: TableStatus.belumBayar, guestName: 'Budi', openAmount: 124000, since: '18:47'),
      CafeTable(number: 4, capacity: 4, status: TableStatus.kosong),
      CafeTable(number: 5, capacity: 6, status: TableStatus.terisi, guestName: 'Kantor PT Sinar', openAmount: 238000, since: '19:05'),
      CafeTable(number: 6, capacity: 2, status: TableStatus.kosong),
      CafeTable(number: 7, capacity: 4, status: TableStatus.belumBayar, guestName: 'Andi', openAmount: 74000, since: '19:20'),
      CafeTable(number: 8, capacity: 8, status: TableStatus.kosong),
      CafeTable(number: 9, capacity: 2, status: TableStatus.terisi, guestName: 'Sari', openAmount: 40000, since: '19:31'),
      CafeTable(number: 10, capacity: 4, status: TableStatus.kosong),
      CafeTable(number: 11, capacity: 4, status: TableStatus.kosong),
      CafeTable(number: 12, capacity: 6, status: TableStatus.kosong),
    ];

// ---------- Keranjang ----------
class CartItem {
  CartItem({required this.menu, required this.variant, this.note = '', this.qty = 1, required this.unitPrice});
  final MenuItem menu;
  final String variant;
  String note;
  int qty;
  final int unitPrice;
  int get total => unitPrice * qty;
  String get key => '${menu.id}|$variant';
}

// ---------- Dapur ----------
enum KitchenStatus { baru, dimasak, selesai }

extension KitchenStatusLabel on KitchenStatus {
  String get label => switch (this) {
        KitchenStatus.baru => 'Baru Masuk',
        KitchenStatus.dimasak => 'Dimasak',
        KitchenStatus.selesai => 'Selesai',
      };
  String get nextLabel => switch (this) {
        KitchenStatus.baru => 'Mulai Masak',
        KitchenStatus.dimasak => 'Tandai Selesai',
        KitchenStatus.selesai => 'Sudah Diantar',
      };
}

class KitchenOrderLine {
  const KitchenOrderLine(this.name, this.qty, [this.note = '']);
  final String name;
  final int qty;
  final String note;
}

class KitchenOrder {
  KitchenOrder({required this.id, required this.tableLabel, required this.lines, required this.status, required this.time, this.orderType = 'Dine-in'});
  final String id;
  final String tableLabel;
  final List<KitchenOrderLine> lines;
  KitchenStatus status;
  final String time;
  final String orderType;
}

List<KitchenOrder> seedKitchenOrders() => [
      KitchenOrder(id: 'A-1042', tableLabel: 'Meja 3', time: '19:42', status: KitchenStatus.baru, lines: const [
        KitchenOrderLine('Kopi Susu Gula Aren', 2, 'Less sugar'),
        KitchenOrderLine('Nasi Ayam Geprek', 1, 'Pedas sedang'),
        KitchenOrderLine('Kentang Goreng', 1),
      ]),
      KitchenOrder(id: 'A-1041', tableLabel: 'Meja 5', time: '19:36', status: KitchenStatus.baru, lines: const [
        KitchenOrderLine('Caffe Latte', 3),
        KitchenOrderLine('Mie Goreng Telur', 2),
      ]),
      KitchenOrder(id: 'A-1040', tableLabel: 'Bungkus', orderType: 'Takeaway', time: '19:29', status: KitchenStatus.dimasak, lines: const [
        KitchenOrderLine('Americano', 1),
        KitchenOrderLine('Roti Bakar Coklat Keju', 1),
      ]),
      KitchenOrder(id: 'A-1039', tableLabel: 'Meja 2', time: '19:21', status: KitchenStatus.dimasak, lines: const [
        KitchenOrderLine('Matcha Latte', 1),
        KitchenOrderLine('Nasi Goreng Kampung', 1, 'Tidak pedas'),
      ]),
      KitchenOrder(id: 'A-1038', tableLabel: 'Meja 9', time: '19:14', status: KitchenStatus.selesai, lines: const [
        KitchenOrderLine('Kopi Tubruk', 2),
        KitchenOrderLine('Pisang Goreng Coklat', 1),
      ]),
    ];

// ---------- Stok bahan ----------
enum StockStatus { aman, kritis, habis }

class Ingredient {
  Ingredient({required this.name, required this.stock, required this.unit, required this.minStock, required this.maxStock});
  String name;
  double stock;
  String unit;
  double minStock;
  double maxStock;

  Map<String, dynamic> toJson() => {
        'name': name,
        'stock': stock,
        'unit': unit,
        'minStock': minStock,
        'maxStock': maxStock,
      };

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: j['name'] as String,
        stock: (j['stock'] as num).toDouble(),
        unit: j['unit'] as String,
        minStock: (j['minStock'] as num).toDouble(),
        maxStock: (j['maxStock'] as num).toDouble(),
      );
  StockStatus get status {
    if (stock <= 0) return StockStatus.habis;
    if (stock <= minStock) return StockStatus.kritis;
    return StockStatus.aman;
  }

  double get ratio => maxStock == 0 ? 0 : (stock / maxStock).clamp(0, 1).toDouble();
}

List<Ingredient> seedIngredients() => <Ingredient>[
  Ingredient(name: 'Biji Kopi Arabika', stock: 0.85, unit: 'kg', minStock: 1, maxStock: 10),
  Ingredient(name: 'Susu Segar', stock: 3.5, unit: 'liter', minStock: 4, maxStock: 20),
  Ingredient(name: 'Gula Aren Cair', stock: 1.2, unit: 'liter', minStock: 1.5, maxStock: 8),
  Ingredient(name: 'Bubuk Matcha', stock: 0, unit: 'kg', minStock: 0.3, maxStock: 2),
  Ingredient(name: 'Bubuk Coklat', stock: 1.8, unit: 'kg', minStock: 0.5, maxStock: 5),
  Ingredient(name: 'Beras', stock: 18, unit: 'kg', minStock: 5, maxStock: 25),
  Ingredient(name: 'Ayam Fillet', stock: 4.2, unit: 'kg', minStock: 3, maxStock: 15),
  Ingredient(name: 'Telur', stock: 42, unit: 'butir', minStock: 20, maxStock: 90),
  Ingredient(name: 'Kentang Beku', stock: 6, unit: 'kg', minStock: 2, maxStock: 12),
  Ingredient(name: 'Roti Tawar', stock: 5, unit: 'pak', minStock: 2, maxStock: 10),
  Ingredient(name: 'Mie Telur', stock: 0.9, unit: 'kg', minStock: 1, maxStock: 6),
  Ingredient(name: 'Gelas Cup 12oz', stock: 68, unit: 'pcs', minStock: 100, maxStock: 500),
];

// ---------- Laporan (contoh) ----------
class DaySales {
  const DaySales(this.day, this.amount);
  final String day;
  final int amount;
}

const weeklySales = <DaySales>[
  DaySales('Sen', 1850000),
  DaySales('Sel', 2100000),
  DaySales('Rab', 1975000),
  DaySales('Kam', 2650000),
  DaySales('Jum', 3420000),
  DaySales('Sab', 4180000),
  DaySales('Min', 3890000),
];

class TopMenu {
  const TopMenu(this.name, this.sold, this.revenue);
  final String name;
  final int sold;
  final int revenue;
}

const topMenus = <TopMenu>[
  TopMenu('Kopi Susu Gula Aren', 86, 1548000),
  TopMenu('Nasi Ayam Geprek', 54, 1350000),
  TopMenu('Caffe Latte', 47, 1034000),
  TopMenu('Matcha Latte', 39, 858000),
  TopMenu('Kentang Goreng', 36, 540000),
];

// ---------- Transaksi ----------

/// Satu pembayaran yang selesai di kasir. Dicatat permanen supaya
/// Beranda menampilkan penjualan ASLI hasil jualan — bukan angka
/// contoh. (Laporan masih contoh karena butuh rentang tanggal dsb.)
class TxRecord {
  TxRecord({required this.id, required this.total, required this.method, required this.at, required this.items});
  final String id;
  final int total;
  final String method; // 'Tunai' | 'QRIS'
  final DateTime at;
  final int items; // jumlah barang pada transaksi ini

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'method': method,
        'at': at.toIso8601String(),
        'items': items,
      };

  factory TxRecord.fromJson(Map<String, dynamic> j) => TxRecord(
        id: j['id'] as String,
        total: (j['total'] as num).toInt(),
        method: j['method'] as String? ?? 'Tunai',
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        items: (j['items'] as num?)?.toInt() ?? 0,
      );
}
