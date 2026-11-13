import 'package:flutter/material.dart';

// ---------- Info aplikasi (satu sumber: popup Info Aplikasi, kaki sidebar) ----------
// appVersion WAJIB sama dengan angka di depan '+' pada version di pubspec.yaml.
const appName = 'Avoera POS';
const appVersion = '0.2.0';
const appStudio = 'Webtales Studio';

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
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.color,
    required this.icon,
    this.isDrink = false,
  });
  final String id;
  final String name;
  final String category;
  final int price;
  final Color color;
  final IconData icon;
  final bool isDrink;
}

const categories = ['Semua', 'Kopi', 'Non-Kopi', 'Makanan', 'Camilan', 'Paket'];

const menuItems = <MenuItem>[
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
  final int number;
  final int capacity;
  TableStatus status;
  String? guestName;
  int openAmount;
  String? since;
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
  const Ingredient({required this.name, required this.stock, required this.unit, required this.minStock, required this.maxStock});
  final String name;
  final double stock;
  final String unit;
  final double minStock;
  final double maxStock;
  StockStatus get status {
    if (stock <= 0) return StockStatus.habis;
    if (stock <= minStock) return StockStatus.kritis;
    return StockStatus.aman;
  }

  double get ratio => maxStock == 0 ? 0 : (stock / maxStock).clamp(0, 1).toDouble();
}

const ingredients = <Ingredient>[
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
