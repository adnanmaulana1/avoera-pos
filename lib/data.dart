import 'package:flutter/material.dart';

// ---------- Info aplikasi (satu sumber: popup Info Aplikasi, kaki sidebar) ----------
// appVersion WAJIB sama dengan angka di depan '+' pada version di pubspec.yaml.
const appName = 'Avoera POS';
const appVersion = '0.10.7';

/// Nomor build aplikasi — WAJIB sama dengan angka sesudah '+'
/// pada version di pubspec.yaml. Dipakai fitur pembaruan dalam
/// aplikasi (lib/update.dart) untuk membandingkan dengan versi
/// terbaru di server.
const appBuild = 33;
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
    this.kitchenEnabled = true,
    List<Branch>? branches,
    this.activeBranchId = 'c1',
    this.pinHash = '',
    this.onboarded = false,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.businessKey = '',
    this.lastSyncLabel = '',
    this.backendBawaanDitanam = false,
    this.cloudSyncEnabled = true,
    this.businessPhotoPath,
    // Bawaan pemasangan pertama = TERANG (permintaan Adnan
    // 2026-11-14). Pilihan yang sudah tersimpan tidak ditimpa.
    this.modeTema = 'terang',
  }) : branches = branches ?? [Branch(id: 'c1', name: 'Cabang Utama')];
  String businessName;
  String businessAddress;
  String businessPhone;
  int servicePercent;
  int taxPercent;

  /// Meja TIDAK wajib (permintaan Adnan 2026-11-14): kedai tanpa
  /// meja bisa mematikan ini dari Pengaturan — menu Meja hilang dari
  /// navigasi dan kasir tidak lagi menawarkan pilihan meja.
  bool tablesEnabled;

  /// Dapur juga fitur opsional (permintaan Adnan 2026-11-14):
  /// kedai yang masakannya tidak lewat layar dapur bisa mematikannya
  /// — menu Dapur hilang & pembayaran tidak membuat tiket dapur.
  bool kitchenEnabled;

  /// Multi-cabang + wizard pertama (2026-11-14): daftar cabang,
  /// cabang yang sedang aktif, hash PIN kasir (bukan PIN mentah),
  /// dan penanda wizard pembuka sudah selesai.
  List<Branch> branches;
  String activeBranchId;
  String pinHash;
  bool onboarded;

  /// Sinkronisasi Supabase (permintaan Adnan 2026-11-14 — backend
  /// gratis): alamat proyek + kunci anon + kode usaha bersama.
  /// Kosong = aplikasi murni lokal seperti sebelumnya.
  String supabaseUrl;
  String supabaseAnonKey;
  String businessKey;
  String lastSyncLabel;

  /// Penanda backend bawaan (lib/backend_bawaan.dart) sudah
  /// ditulis ke pengaturan — migrasi sekali jalan saat aplikasi
  /// pertama kali memakai build yang menanam backend.
  bool backendBawaanDitanam;

  /// Pilihan tema tampilan: 'terang' | 'gelap' | 'sistem'.
  String modeTema;

  /// Saklar Cloud Sync (permintaan Adnan 2026-11-15): mati =
  /// aplikasi murni lokal, tidak ada sinkron otomatis maupun
  /// manual. Pilihan khusus perangkat ini (tidak disinkronkan).
  bool cloudSyncEnabled;

  /// Foto/logo usaha (permintaan Adnan 2026-11-15): berkas lokal
  /// di folder dokumen aplikasi. Khusus perangkat (tidak ikut
  /// diunggah ke server), sama seperti foto menu.
  String? businessPhotoPath;

  Branch get activeBranch => branches.firstWhere((b) => b.id == activeBranchId, orElse: () => branches.first);

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'businessAddress': businessAddress,
        'businessPhone': businessPhone,
        'servicePercent': servicePercent,
        'taxPercent': taxPercent,
        'tablesEnabled': tablesEnabled,
        'kitchenEnabled': kitchenEnabled,
        'branches': branches.map((b) => b.toJson()).toList(),
        'activeBranchId': activeBranchId,
        'pinHash': pinHash,
        'onboarded': onboarded,
        'supabaseUrl': supabaseUrl,
        'supabaseAnonKey': supabaseAnonKey,
        'businessKey': businessKey,
        'lastSyncLabel': lastSyncLabel,
        'backendBawaanDitanam': backendBawaanDitanam,
        'modeTema': modeTema,
        'cloudSyncEnabled': cloudSyncEnabled,
        'businessPhotoPath': businessPhotoPath,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        businessName: j['businessName'] as String? ?? 'Avoera Cafe & Resto',
        businessAddress: j['businessAddress'] as String? ?? '',
        businessPhone: j['businessPhone'] as String? ?? '',
        servicePercent: (j['servicePercent'] as num?)?.toInt() ?? 5,
        taxPercent: (j['taxPercent'] as num?)?.toInt() ?? 10,
        // Data lama belum punya kunci ini → meja tetap aktif.
        tablesEnabled: j['tablesEnabled'] as bool? ?? true,
        // Data lama belum punya kunci ini → dapur tetap aktif.
        kitchenEnabled: j['kitchenEnabled'] as bool? ?? true,
        branches: (j['branches'] as List?)?.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList(),
        activeBranchId: j['activeBranchId'] as String? ?? 'c1',
        pinHash: j['pinHash'] as String? ?? '',
        onboarded: j['onboarded'] as bool? ?? false,
        supabaseUrl: j['supabaseUrl'] as String? ?? '',
        supabaseAnonKey: j['supabaseAnonKey'] as String? ?? '',
        businessKey: j['businessKey'] as String? ?? '',
        lastSyncLabel: j['lastSyncLabel'] as String? ?? '',
        backendBawaanDitanam: j['backendBawaanDitanam'] as bool? ?? false,
        // Data lama tanpa kunci ini → terang (bawaan baru);
        // nilai yang tersimpan ('terang'/'gelap'/'sistem') utuh.
        modeTema: j['modeTema'] as String? ?? 'terang',
        // Data lama belum punya kunci ini → sinkron awan menyala.
        cloudSyncEnabled: j['cloudSyncEnabled'] as bool? ?? true,
        businessPhotoPath: j['businessPhotoPath'] as String?,
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

/// Format ringkas untuk sumbu grafik: 1500000 → '1,5 jt',
/// 250000 → '250 rb', 0 → '0'. (Gaya Bisakasir di referensi Adnan.)
String ringkas(int v) {
  if (v >= 1000000) {
    final jt = v / 1000000;
    final t = jt == jt.roundToDouble() ? '${jt.round()}' : jt.toStringAsFixed(1).replaceAll('.', ',');
    return '$t jt';
  }
  if (v >= 1000) return '${(v / 1000).round()} rb';
  return '$v';
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

/// Satu baris resep: bahan + takaran per SATU porsi menu.
/// Takaran memakai satuan bahan itu sendiri (gram/kg/liter/pcs
/// sesuai satuan yang diisi pemilik di Stok Bahan).
class RecipeLine {
  RecipeLine({required this.ingredientId, required this.qty});
  final String ingredientId;
  double qty;

  Map<String, dynamic> toJson() => {'ingredientId': ingredientId, 'qty': qty};
  factory RecipeLine.fromJson(Map<String, dynamic> j) => RecipeLine(
        ingredientId: j['ingredientId'] as String,
        qty: (j['qty'] as num?)?.toDouble() ?? 0,
      );
}

/// Satu baris isi bundle: menu komponen + jumlahnya.
class BundleLine {
  BundleLine({required this.menuId, required this.qty});
  final String menuId;
  int qty;

  Map<String, dynamic> toJson() => {'menuId': menuId, 'qty': qty};
  factory BundleLine.fromJson(Map<String, dynamic> j) => BundleLine(
        menuId: j['menuId'] as String,
        qty: (j['qty'] as num?)?.toInt() ?? 1,
      );
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
    this.imagePath,
    this.priceOjol = 0,
    List<RecipeLine>? recipe,
    List<BundleLine>? bundle,
  })  : iconIndex = _iconIndexOf(icon),
        recipe = recipe ?? <RecipeLine>[],
        bundle = bundle ?? <BundleLine>[];
  final String id;
  String name;
  String category;
  int price;
  Color color;
  int iconIndex;
  bool isDrink;

  /// Harga khusus ojol (permintaan Adnan 2026-11-15, fitur yang
  /// dulu 'Segera'). 0 = belum diatur (tampilan memakai harga
  /// biasa). Hanya untuk ditampilkan/dibandingkan — kasir tetap
  /// memakai harga biasa.
  int priceOjol;

  /// Resep per porsi (dulu 'Segera'). Kosong = menu ini tidak
  /// memotong stok bahan saat terjual.
  List<RecipeLine> recipe;

  /// Isi bundle (dulu 'Segera'). Tidak kosong = menu PAKET:
  /// menjualnya memotong stok lewat resep menu komponennya.
  List<BundleLine> bundle;

  bool get isBundle => bundle.isNotEmpty;

  /// Harga ojol efektif untuk tampilan.
  int get hargaOjolEfektif => priceOjol > 0 ? priceOjol : price;

  /// Foto produk (permintaan Adnan 2026-11-14): berkas lokal di
  /// folder dokumen aplikasi. Null = tampilkan ikon & warna seperti
  /// biasa. Berkas bisa hilang (mis. data dibersihkan) — semua
  /// tampilan gambar WAJIB punya jalan kembali ke ikon.
  String? imagePath;

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
        'imagePath': imagePath,
        'priceOjol': priceOjol,
        'recipe': recipe.map((r) => r.toJson()).toList(),
        'bundle': bundle.map((b) => b.toJson()).toList(),
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
      imagePath: j['imagePath'] as String?,
      priceOjol: (j['priceOjol'] as num?)?.toInt() ?? 0,
      recipe: (j['recipe'] as List?)?.map((e) => RecipeLine.fromJson(e as Map<String, dynamic>)).toList(),
      bundle: (j['bundle'] as List?)?.map((e) => BundleLine.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Kebutuhan bahan untuk SATU porsi [m]: resepnya sendiri, atau —
/// bila [m] bundle — gabungan resep semua komponennya (dikali
/// jumlah komponen). Bundle di dalam bundle tidak diperluas lagi
/// (satu tingkat) supaya tidak ada lingkaran tak berujung.
Map<String, double> kebutuhanBahan(MenuItem m, List<MenuItem> semuaMenu) {
  final hasil = <String, double>{};
  void tambah(RecipeLine r, double kali) {
    if (r.qty <= 0) return;
    hasil[r.ingredientId] = (hasil[r.ingredientId] ?? 0) + r.qty * kali;
  }

  if (m.isBundle) {
    for (final b in m.bundle) {
      final komponen = semuaMenu.where((x) => x.id == b.menuId);
      if (komponen.isEmpty) continue;
      for (final r in komponen.first.recipe) {
        tambah(r, b.qty.toDouble());
      }
    }
  } else {
    for (final r in m.recipe) {
      tambah(r, 1);
    }
  }
  return hasil;
}

/// HPP (modal bahan) satu porsi [m] dari harga beli bahan.
/// Bundle = jumlah HPP komponen × jumlahnya. Bahan yang harga
/// belinya belum diisi menyumbang 0.
int hppMenu(MenuItem m, List<MenuItem> semuaMenu, List<Ingredient> bahan) {
  final kebutuhan = kebutuhanBahan(m, semuaMenu);
  var total = 0;
  kebutuhan.forEach((idBahan, qty) {
    final b = bahan.where((i) => i.id == idBahan);
    if (b.isNotEmpty) total += (qty * b.first.costPerUnit).round();
  });
  return total;
}

/// Kode produk tampilan (gaya PRD-001 di referensi Kasaba) — diturunkan
/// dari id menu supaya stabil walau urutan daftar berubah.
String skuOf(MenuItem m) => 'PRD-${(m.id.hashCode.abs() % 900) + 100}';

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

/// Status sinkronisasi awan (Supabase) untuk ikon indikator di
/// Beranda: belum diatur / sedang menyinkron / tersinkron / gagal.
enum StatusSinkron { belumDiatur, menyinkron, tersinkron, gagal }

class Ingredient {
  Ingredient({String? id, required this.name, required this.stock, required this.unit, required this.minStock, required this.maxStock, this.costPerUnit = 0})
      : id = id ?? 'b${name.hashCode.abs()}';

  /// Id stabil untuk sinkronisasi (data lama diturunkan dari nama).
  final String id;
  String name;
  double stock;
  String unit;
  double minStock;
  double maxStock;

  /// Harga beli per satuan (Rp) — dasar hitung HPP menu dari
  /// resep (permintaan Adnan 2026-11-15). 0 = belum diisi.
  int costPerUnit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stock': stock,
        'unit': unit,
        'minStock': minStock,
        'maxStock': maxStock,
        'costPerUnit': costPerUnit,
      };

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String?,
        name: j['name'] as String,
        stock: (j['stock'] as num).toDouble(),
        unit: j['unit'] as String,
        minStock: (j['minStock'] as num).toDouble(),
        maxStock: (j['maxStock'] as num).toDouble(),
        costPerUnit: (j['costPerUnit'] as num?)?.toInt() ?? 0,
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

// ---------- Transaksi ----------

/// Satu pembayaran yang selesai di kasir. Dicatat permanen supaya
/// Beranda & Laporan menampilkan penjualan ASLI hasil jualan —
/// bukan angka contoh.
/// Satu baris item di dalam transaksi (nama, keterangan
/// varian/catatan, jumlah, total baris). Disimpan sejak
/// v0.10.6 supaya halaman Detail Transaksi bisa menampilkan
/// rincian pesanan; transaksi lama tidak punya baris ini.
class TxLine {
  TxLine({required this.nama, this.keterangan = '', required this.qty, required this.total});

  final String nama;
  final String keterangan;
  final int qty;
  final int total;

  Map<String, dynamic> toJson() => {'nama': nama, 'keterangan': keterangan, 'qty': qty, 'total': total};

  factory TxLine.fromJson(Map<String, dynamic> j) => TxLine(
        nama: j['nama'] as String? ?? 'Item',
        keterangan: j['keterangan'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class TxRecord {
  TxRecord({
    required this.id,
    required this.total,
    required this.method,
    required this.at,
    required this.items,
    this.subtotal = 0,
    this.service = 0,
    this.tax = 0,
    this.branchId = '',
    this.uuid = '',
    this.lines = const [],
  });
  final String id;

  /// Id unik lintas perangkat untuk sinkronisasi (id tampilan
  /// 'A-1043' bisa sama di dua HP berbeda). Data lama memakai id.
  final String uuid;
  final int total;
  final String method; // 'Tunai' | 'QRIS'
  final DateTime at;
  final int items; // jumlah barang pada transaksi ini

  /// Rincian uang (untuk Laporan Pajak & Laba Rugi kelak) + cabang
  /// asal transaksi (multi-cabang). Transaksi lama (v0.5–v0.6) belum
  /// punya rincian ini → fromJson memberi nilai aman.
  final int subtotal;
  final int service;
  final int tax;
  final String branchId;

  /// Rincian item transaksi (kosong untuk transaksi lama
  /// sebelum v0.10.6).
  final List<TxLine> lines;

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'method': method,
        'at': at.toIso8601String(),
        'items': items,
        'subtotal': subtotal,
        'service': service,
        'tax': tax,
        'branchId': branchId,
        'uuid': uuid.isEmpty ? id : uuid,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory TxRecord.fromJson(Map<String, dynamic> j) => TxRecord(
        id: j['id'] as String,
        total: (j['total'] as num).toInt(),
        method: j['method'] as String? ?? 'Tunai',
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        items: (j['items'] as num?)?.toInt() ?? 0,
        subtotal: (j['subtotal'] as num?)?.toInt() ?? (j['total'] as num).toInt(),
        service: (j['service'] as num?)?.toInt() ?? 0,
        tax: (j['tax'] as num?)?.toInt() ?? 0,
        branchId: j['branchId'] as String? ?? '',
        uuid: j['uuid'] as String? ?? (j['id'] as String? ?? ''),
        lines: (j['lines'] as List<dynamic>? ?? const [])
            .map((e) => TxLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

// ---------- Cabang ----------

/// Satu cabang usaha. Multi-cabang: menu/stok masih bersama
/// (menu pusat), transaksi tercatat per cabang.
class Branch {
  Branch({required this.id, required this.name, this.address = '', this.phone = ''});
  final String id;
  String name;

  /// Alamat & telepon cabang (diisi lewat wizard tambah cabang).
  String address;
  String phone;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'address': address, 'phone': phone};
  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Cabang',
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
      );
}

// ---------- Pemberitahuan ----------

/// Satu pemberitahuan TERSIMPAN (permintaan Adnan 2026-11-15:
/// notifikasi difungsikan beneran — bukan daftar hitungan sesaat).
/// Dibuat dari kejadian nyata: stok kritis/habis, sinkron gagal.
/// [kunci] dipakai mencegah duplikat untuk keadaan yang sama.
class AppNotification {
  AppNotification({
    required this.id,
    required this.judul,
    required this.isi,
    required this.waktu,
    required this.jenis,
    this.kunci = '',
    this.dibaca = false,
  });
  final String id;
  final String judul;
  final String isi;
  final DateTime waktu;

  /// 'stok' | 'sinkron' | 'info'
  final String jenis;
  final String kunci;
  bool dibaca;

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'isi': isi,
        'waktu': waktu.toIso8601String(),
        'jenis': jenis,
        'kunci': kunci,
        'dibaca': dibaca,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        judul: j['judul'] as String? ?? '',
        isi: j['isi'] as String? ?? '',
        waktu: DateTime.tryParse(j['waktu'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        jenis: j['jenis'] as String? ?? 'info',
        kunci: j['kunci'] as String? ?? '',
        dibaca: j['dibaca'] as bool? ?? false,
      );
}

/// Satu baris riwayat pergerakan stok (modul Gudang, v0.10.0):
/// setiap perubahan jumlah bahan WAJIB lewat sini supaya ketahuan
/// berubah karena apa — barang masuk, terpotong penjualan, opname,
/// atau ubah manual. Nama bahan & satuan DISALIN (snapshot) supaya
/// riwayat tetap utuh walau bahan diganti nama atau dihapus.
/// [jumlah] bertanda: positif = stok bertambah, negatif = berkurang.
class MutasiStok {
  MutasiStok({
    String? id,
    required this.ingredientId,
    required this.namaBahan,
    required this.jenis,
    required this.jumlah,
    required this.stokSesudah,
    required this.satuan,
    this.catatan = '',
    DateTime? waktu,
  })  : id = id ?? 'm${DateTime.now().microsecondsSinceEpoch}',
        waktu = waktu ?? DateTime.now();

  final String id;
  final String ingredientId;
  final String namaBahan;

  /// 'masuk' | 'jual' | 'opname' | 'edit'
  final String jenis;
  final double jumlah;
  final double stokSesudah;
  final String satuan;
  final String catatan;
  final DateTime waktu;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'namaBahan': namaBahan,
        'jenis': jenis,
        'jumlah': jumlah,
        'stokSesudah': stokSesudah,
        'satuan': satuan,
        'catatan': catatan,
        'waktu': waktu.toIso8601String(),
      };

  factory MutasiStok.fromJson(Map<String, dynamic> j) => MutasiStok(
        id: j['id'] as String?,
        ingredientId: j['ingredientId'] as String? ?? '',
        namaBahan: j['namaBahan'] as String? ?? '',
        jenis: j['jenis'] as String? ?? 'edit',
        jumlah: (j['jumlah'] as num?)?.toDouble() ?? 0,
        stokSesudah: (j['stokSesudah'] as num?)?.toDouble() ?? 0,
        satuan: j['satuan'] as String? ?? '',
        catatan: j['catatan'] as String? ?? '',
        waktu: DateTime.tryParse(j['waktu'] as String? ?? ''),
      );
}
