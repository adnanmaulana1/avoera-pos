import 'package:flutter/material.dart';
import 'package:avoera_pos/ikon.dart';

// ---------- Info aplikasi (satu sumber: popup Info Aplikasi, kaki sidebar) ----------
// appVersion WAJIB sama dengan angka di depan '+' pada version di pubspec.yaml.
const appName = 'Avoera POS';
const appVersion = '0.17.0';

/// Nomor build aplikasi — WAJIB sama dengan angka sesudah '+'
/// pada version di pubspec.yaml. Dipakai fitur pembaruan dalam
/// aplikasi (lib/update.dart) untuk membandingkan dengan versi
/// terbaru di server.
const appBuild = 57;
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
    List<String>? menuCategories,
  })  : branches = branches ?? [Branch(id: 'c1', name: 'Cabang Utama')],
        menuCategories = menuCategories ?? [];
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

  /// Daftar kategori menu yang dikelola pemilik (CRUD kategori,
  /// permintaan Adnan 2026-11-17). Kosong = belum pernah diatur
  /// → pakai [kategoriBawaan]. Daftar EFEKTIF selalu lewat
  /// [kategoriEfektif] supaya kategori yang dipakai menu lama
  /// tidak pernah hilang dari tampilan. Ikut tersinkron lewat
  /// pengaturan (bukan data khusus perangkat).
  List<String> menuCategories;

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
        'menuCategories': menuCategories,
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
        // Data lama belum punya kunci ini → kosong (bawaan).
        menuCategories: (j['menuCategories'] as List?)?.map((e) => e.toString()).toList(),
      );
}

String rupiah(int value) {
  // Negatif (laba rugi bisa minus) ditulis -Rp di depan, bukan
  // Rp- — pola yang sama dengan AnimatedRupiah.
  final neg = value < 0;
  final s = value.abs().toString();
  final buf = StringBuffer(neg ? '-Rp' : 'Rp');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Format ringkas untuk sumbu grafik: 1500000 → '1,5 jt',
/// 250000 → '250rb', 0 → '0'. Tanpa spasi sejak 2026-11-15: label di atas batang grafik sempit, spasi membuatnya membungkus & memotong.
String ringkas(int v) {
  if (v >= 1000000) {
    final jt = v / 1000000;
    final t = jt == jt.roundToDouble() ? '${jt.round()}' : jt.toStringAsFixed(1).replaceAll('.', ',');
    return '${t}jt';
  }
  if (v >= 1000) return '${(v / 1000).round()}rb';
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
  Ikon.local_cafe,
  Ikon.coffee,
  Ikon.coffee_maker,
  Ikon.emoji_food_beverage,
  Ikon.local_drink,
  Ikon.rice_bowl,
  Ikon.dinner_dining,
  Ikon.ramen_dining,
  Ikon.set_meal,
  Ikon.fastfood,
  Ikon.bakery_dining,
  Ikon.breakfast_dining,
  Ikon.tapas,
  Ikon.card_giftcard,
  Ikon.group,
  Ikon.cake,
  Ikon.groups, // dipakai menu paket contoh lama
];

int _iconIndexOf(IconData icon) {
  final i = menuIconChoices.indexWhere((c) => c.codePoint == icon.codePoint);
  return i < 0 ? 0 : i;
}

/// Kode ikon Material LAMA untuk daftar [menuIconChoices], dibekukan
/// apa adanya. Sejak v0.13.0 pilihan ikon memakai huruf Phosphor
/// (kodenya beda total), jadi data sangat lama (≤0.3.2) yang hanya
/// menyimpan codePoint Material dipetakan lewat daftar beku ini —
/// urutannya sama persis dengan [menuIconChoices].
const _kodeIkonMenuLama = <int>[58253, 57720, 57721, 57902, 58257, 58680, 57808, 58630, 58750, 57946, 57545, 57604, 58948, 57662, 58091, 57632, 58094];

int _iconIndexFromCodePoint(int codePoint) {
  final i = _kodeIkonMenuLama.indexOf(codePoint);
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

/// Kategori bawaan (tanpa 'Semua' — itu penanda filter UI,
/// bukan kategori). Dipakai selama pemilik belum mengatur
/// daftar kategorinya sendiri.
const kategoriBawaan = ['Kopi', 'Non-Kopi', 'Makanan', 'Camilan', 'Paket'];

/// Daftar kategori EFEKTIF untuk ditampilkan & dipilih:
/// daftar tersimpan pemilik (atau bawaan bila belum diatur),
/// DITAMBAH kategori apa pun yang sedang dipakai menu tapi
/// belum terdaftar — data lama tidak boleh kehilangan
/// kategorinya hanya karena daftarnya berganti.
List<String> kategoriEfektif(AppSettings settings, List<MenuItem> menus) {
  final dasar = settings.menuCategories.isNotEmpty ? settings.menuCategories : kategoriBawaan;
  final hasil = <String>[...dasar];
  for (final m in menus) {
    if (!hasil.contains(m.category)) hasil.add(m.category);
  }
  return hasil;
}

List<MenuItem> seedMenus() => <MenuItem>[
  MenuItem(id: 'k1', name: 'Kopi Susu Gula Aren', category: 'Kopi', price: 18000, color: Color(0xFF8D6E63), icon: Ikon.local_cafe, isDrink: true),
  MenuItem(id: 'k2', name: 'Americano', category: 'Kopi', price: 15000, color: Color(0xFF4E342E), icon: Ikon.coffee, isDrink: true),
  MenuItem(id: 'k3', name: 'Caffe Latte', category: 'Kopi', price: 22000, color: Color(0xFFA1887F), icon: Ikon.local_cafe, isDrink: true),
  MenuItem(id: 'k4', name: 'Butterscotch Latte', category: 'Kopi', price: 24000, color: Color(0xFFBCAAA4), icon: Ikon.coffee_maker, isDrink: true),
  MenuItem(id: 'k5', name: 'Kopi Tubruk', category: 'Kopi', price: 12000, color: Color(0xFF3E2723), icon: Ikon.coffee, isDrink: true),
  MenuItem(id: 'n1', name: 'Matcha Latte', category: 'Non-Kopi', price: 22000, color: Color(0xFF7CB342), icon: Ikon.emoji_food_beverage, isDrink: true),
  MenuItem(id: 'n2', name: 'Coklat Klasik', category: 'Non-Kopi', price: 20000, color: Color(0xFF6D4C41), icon: Ikon.emoji_food_beverage, isDrink: true),
  MenuItem(id: 'n3', name: 'Es Teh Lemon', category: 'Non-Kopi', price: 12000, color: Color(0xFFF9A825), icon: Ikon.local_drink, isDrink: true),
  MenuItem(id: 'n4', name: 'Red Velvet Latte', category: 'Non-Kopi', price: 22000, color: Color(0xFFC62828), icon: Ikon.local_drink, isDrink: true),
  MenuItem(id: 'm1', name: 'Nasi Ayam Geprek', category: 'Makanan', price: 25000, color: Color(0xFFEF6C00), icon: Ikon.rice_bowl),
  MenuItem(id: 'm2', name: 'Nasi Goreng Kampung', category: 'Makanan', price: 28000, color: Color(0xFFD84315), icon: Ikon.dinner_dining),
  MenuItem(id: 'm3', name: 'Mie Goreng Telur', category: 'Makanan', price: 22000, color: Color(0xFFFF8F00), icon: Ikon.ramen_dining),
  MenuItem(id: 'm4', name: 'Nasi Ayam Teriyaki', category: 'Makanan', price: 30000, color: Color(0xFF5D4037), icon: Ikon.set_meal),
  MenuItem(id: 'c1', name: 'Kentang Goreng', category: 'Camilan', price: 15000, color: Color(0xFFFBC02D), icon: Ikon.fastfood),
  MenuItem(id: 'c2', name: 'Pisang Goreng Coklat', category: 'Camilan', price: 16000, color: Color(0xFFFFA000), icon: Ikon.bakery_dining),
  MenuItem(id: 'c3', name: 'Roti Bakar Coklat Keju', category: 'Camilan', price: 18000, color: Color(0xFF8D6E63), icon: Ikon.breakfast_dining),
  MenuItem(id: 'c4', name: 'Dimsum Ayam (4 pcs)', category: 'Camilan', price: 17000, color: Color(0xFFAD1457), icon: Ikon.tapas),
  MenuItem(id: 'p1', name: 'Paket Hemat Kopi + Roti', category: 'Paket', price: 32000, color: Color(0xFF00695C), icon: Ikon.card_giftcard),
  MenuItem(id: 'p2', name: 'Paket Berdua', category: 'Paket', price: 68000, color: Color(0xFF00838F), icon: Ikon.group),
  MenuItem(id: 'p3', name: 'Paket Nongkrong Berempat', category: 'Paket', price: 119000, color: Color(0xFF4527A0), icon: Ikon.groups),
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

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'note': note};

  factory KitchenOrderLine.fromJson(Map<String, dynamic> j) => KitchenOrderLine(
        j['name'] as String? ?? '',
        (j['qty'] as num?)?.toInt() ?? 0,
        j['note'] as String? ?? '',
      );
}

class KitchenOrder {
  KitchenOrder({required this.id, required this.tableLabel, required this.lines, required this.status, required this.time, this.orderType = 'Dine-in'});
  final String id;
  final String tableLabel;
  final List<KitchenOrderLine> lines;
  KitchenStatus status;
  final String time;
  final String orderType;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableLabel': tableLabel,
        'lines': lines.map((l) => l.toJson()).toList(),
        'status': status.name,
        'time': time,
        'orderType': orderType,
      };

  factory KitchenOrder.fromJson(Map<String, dynamic> j) => KitchenOrder(
        id: j['id'] as String? ?? '',
        tableLabel: j['tableLabel'] as String? ?? '',
        lines: ((j['lines'] as List?) ?? const []).map((e) => KitchenOrderLine.fromJson((e as Map).cast<String, dynamic>())).toList(),
        status: KitchenStatus.values.asNameMap()[j['status'] as String?] ?? KitchenStatus.baru,
        time: j['time'] as String? ?? '',
        orderType: j['orderType'] as String? ?? 'Dine-in',
      );
}

/// Satu baris keranjang sebagaimana tersimpan di disk (v0.16.0):
/// menu dirujuk lewat id supaya sesudah aplikasi dibuka lagi
/// baris ini bisa disambung ke menu yang sama. Baris yang
/// menunya sudah dihapus pemilik dibuang saat pemulihan.
class BarisKeranjang {
  const BarisKeranjang({required this.menuId, required this.variant, this.note = '', required this.qty, required this.unitPrice});
  final String menuId;
  final String variant;
  final String note;
  final int qty;
  final int unitPrice;

  Map<String, dynamic> toJson() => {'menuId': menuId, 'variant': variant, 'note': note, 'qty': qty, 'unitPrice': unitPrice};

  factory BarisKeranjang.fromJson(Map<String, dynamic> j) => BarisKeranjang(
        menuId: j['menuId'] as String? ?? '',
        variant: j['variant'] as String? ?? '',
        note: j['note'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        unitPrice: (j['unitPrice'] as num?)?.toInt() ?? 0,
      );
}

/// Draf kasir yang sedang berjalan (v0.16.0): isi keranjang,
/// meja terpilih, nomor urut pesanan, jenis pesanan, dan promo
/// terpilih — disimpan lokal tiap ada perubahan supaya pesanan
/// yang belum dibayar TIDAK hilang bila aplikasi tertutup paksa
/// atau HP mati. Lokal saja, tidak ikut sinkron.
class DraftKasir {
  DraftKasir({this.items = const [], this.nomorMeja, this.counter = 1043, this.jenis = 'Dine-in', this.promoId});
  final List<BarisKeranjang> items;
  final int? nomorMeja;
  final int counter;
  final String jenis;
  final String? promoId;

  Map<String, dynamic> toJson() => {
        'items': items.map((b) => b.toJson()).toList(),
        'nomorMeja': nomorMeja,
        'counter': counter,
        'jenis': jenis,
        'promoId': promoId,
      };

  factory DraftKasir.fromJson(Map<String, dynamic> j) => DraftKasir(
        items: ((j['items'] as List?) ?? const []).map((e) => BarisKeranjang.fromJson((e as Map).cast<String, dynamic>())).toList(),
        nomorMeja: (j['nomorMeja'] as num?)?.toInt(),
        counter: (j['counter'] as num?)?.toInt() ?? 1043,
        jenis: j['jenis'] as String? ?? 'Dine-in',
        promoId: j['promoId'] as String?,
      );
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
    this.status = 'Lunas',
    this.diskon = 0,
    this.promoNama = '',
    this.tamu = 0,
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

  /// Status transaksi: 'Lunas' (bawaan, semua transaksi yang
  /// tercatat aplikasi sampai v0.10.11) | 'Batal' | 'Refund' |
  /// 'Belum bayar'. Belum ada alur yang menulis status selain
  /// Lunas — kolomnya disiapkan v0.10.11 supaya Riwayat bisa
  /// menandai status luar biasa dengan badge (permintaan
  /// Adnan: baris biasa TANPA badge).
  final String status;

  /// Diskon promo yang dipakai pada transaksi ini (Rp, 0 =
  /// tanpa promo) + nama promonya. Fitur Promo & Diskon
  /// v0.11.0. [total] SUDAH dikurangi diskon ini. Transaksi
  /// lama tidak punya kolomnya → 0 / ''.
  final int diskon;
  final String promoNama;

  /// Jumlah tamu pada transaksi ini (fitur Laporan Pengunjung
  /// v0.15.0), diisi kasir di halaman Pembayaran. 0 = tidak
  /// dicatat — semua transaksi sebelum fitur ini bernilai 0 dan
  /// TIDAK dihitung sebagai kunjungan tanpa tamu.
  final int tamu;

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
        'status': status,
        'diskon': diskon,
        'promoNama': promoNama,
        'tamu': tamu,
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
        status: j['status'] as String? ?? 'Lunas',
        diskon: (j['diskon'] as num?)?.toInt() ?? 0,
        promoNama: j['promoNama'] as String? ?? '',
        tamu: (j['tamu'] as num?)?.toInt() ?? 0,
      );
}

// ---------- Margin per menu (Laporan Margin Tipis, v0.15.0) ----------

/// Status hitungan margin satu menu: terhitung penuh, belum
/// ada resepnya, atau resep ada tapi harga beli bahannya belum
/// diisi (HPP terbaca 0 — bukan berarti marginnya 100%).
enum StatusMargin { terhitung, tanpaResep, hargaBahanKosong }

/// Margin satu menu dari harga jual vs HPP resep saat ini.
class MarginMenu {
  const MarginMenu({required this.menu, required this.hpp, required this.status});
  final MenuItem menu;
  final int hpp;
  final StatusMargin status;

  int get untung => menu.price - hpp;

  /// Persen margin dari harga jual: (harga − HPP) ÷ harga × 100.
  double get persen => menu.price <= 0 ? 0 : untung / menu.price * 100;
}

/// Margin SEMUA menu, terurut: yang terhitung dulu dengan
/// margin paling tipis di atas (itulah gunanya laporan ini),
/// sisanya menurut abjad nama.
List<MarginMenu> hitungMarginMenu({required List<MenuItem> menus, required List<Ingredient> ingredients}) {
  final hasil = <MarginMenu>[];
  for (final m in menus) {
    final kebutuhan = kebutuhanBahan(m, menus);
    if (kebutuhan.isEmpty) {
      hasil.add(MarginMenu(menu: m, hpp: 0, status: StatusMargin.tanpaResep));
      continue;
    }
    final hpp = hppMenu(m, menus, ingredients);
    hasil.add(MarginMenu(menu: m, hpp: hpp, status: hpp > 0 ? StatusMargin.terhitung : StatusMargin.hargaBahanKosong));
  }
  hasil.sort((a, b) {
    final aHitung = a.status == StatusMargin.terhitung;
    final bHitung = b.status == StatusMargin.terhitung;
    if (aHitung && bHitung) return a.persen.compareTo(b.persen);
    if (aHitung) return -1;
    if (bHitung) return 1;
    return a.menu.name.compareTo(b.menu.name);
  });
  return hasil;
}

/// Jumlah terjual per NAMA menu dari rincian transaksi Lunas
/// pada satu cabang + rentang (dasar kolom "terjual" di
/// Laporan Margin Tipis). Pencocokan per nama, sama seperti
/// Laba Rugi — transaksi lama tanpa rincian tidak terhitung.
Map<String, int> jumlahTerjualPerMenu({
  required List<TxRecord> transactions,
  required String branchId,
  required DateTime dari,
  required DateTime sampai,
}) {
  final awal = DateTime(dari.year, dari.month, dari.day);
  final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
  final hasil = <String, int>{};
  for (final t in transactions) {
    if (t.status != 'Lunas') continue;
    if (t.branchId.isNotEmpty && t.branchId != branchId) continue;
    if (t.at.isBefore(awal) || !t.at.isBefore(akhir)) continue;
    for (final l in t.lines) {
      hasil[l.nama] = (hasil[l.nama] ?? 0) + l.qty;
    }
  }
  return hasil;
}

// ---------- Laporan Pengunjung (v0.15.0) ----------

/// Tamu pada satu hari (baris rincian Laporan Pengunjung).
class TamuHari {
  const TamuHari({required this.tanggal, required this.tamu, required this.transaksi});
  final DateTime tanggal;
  final int tamu;
  final int transaksi;
}

/// Ringkasan pengunjung satu rentang: hanya transaksi Lunas
/// yang jumlah tamunya diisi kasir (tamu > 0) yang terhitung —
/// transaksi tanpa catatan tamu tidak dianggap kunjungan
/// kosong, hanya tidak ikut dihitung.
class HasilPengunjung {
  const HasilPengunjung({required this.totalTamu, required this.txTercatat, required this.totalTransaksi, required this.terbanyak, required this.perHari});
  final int totalTamu;

  /// Transaksi Lunas dengan catatan tamu (tamu > 0).
  final int txTercatat;

  /// Semua transaksi Lunas pada rentang + cabang ini.
  final int totalTransaksi;

  /// Tamu terbanyak dalam satu transaksi.
  final int terbanyak;

  /// Rincian per hari, terbaru dulu; hanya hari dengan tamu.
  final List<TamuHari> perHari;

  /// Rata-rata tamu per transaksi TERCATAT.
  double get rataRata => txTercatat == 0 ? 0 : totalTamu / txTercatat;
}

HasilPengunjung hitungPengunjung({
  required List<TxRecord> transactions,
  required String branchId,
  required DateTime dari,
  required DateTime sampai,
}) {
  final awal = DateTime(dari.year, dari.month, dari.day);
  final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
  var totalTamu = 0;
  var txTercatat = 0;
  var totalTransaksi = 0;
  var terbanyak = 0;
  final perHariMap = <DateTime, ({int tamu, int tx})>{};
  for (final t in transactions) {
    if (t.status != 'Lunas') continue;
    if (t.branchId.isNotEmpty && t.branchId != branchId) continue;
    if (t.at.isBefore(awal) || !t.at.isBefore(akhir)) continue;
    totalTransaksi++;
    if (t.tamu <= 0) continue;
    txTercatat++;
    totalTamu += t.tamu;
    if (t.tamu > terbanyak) terbanyak = t.tamu;
    final hari = DateTime(t.at.year, t.at.month, t.at.day);
    final lama = perHariMap[hari] ?? (tamu: 0, tx: 0);
    perHariMap[hari] = (tamu: lama.tamu + t.tamu, tx: lama.tx + 1);
  }
  final perHari = perHariMap.entries.map((e) => TamuHari(tanggal: e.key, tamu: e.value.tamu, transaksi: e.value.tx)).toList()
    ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
  return HasilPengunjung(totalTamu: totalTamu, txTercatat: txTercatat, totalTransaksi: totalTransaksi, terbanyak: terbanyak, perHari: perHari);
}

// ---------- Sesi Kasir (Buka & Tutup Kasir, v0.15.0) ----------

/// Satu sesi kasir: dibuka dengan modal awal, ditutup dengan
/// hitung fisik uang di laci. Penjualan TIDAK pernah diblokir
/// sesi — transaksi di luar sesi tetap tercatat, hanya tidak
/// masuk ringkasan sesi mana pun (aturan Adnan: peringatan
/// boleh, menghalangi jangan). Tersimpan LOKAL di perangkat
/// (belum ikut sinkron, seperti pengeluaran & mutasi).
class SesiKasir {
  SesiKasir({
    String? id,
    required this.branchId,
    required this.dibukaPada,
    required this.modalAwal,
    this.namaKasir = '',
    this.ditutupPada,
    this.tunaiFisik,
    this.pengeluaranLaci,
    this.catatan = '',
  }) : id = id ?? 's${dibukaPada.microsecondsSinceEpoch}';

  final String id;
  final String branchId;
  final DateTime dibukaPada;
  final int modalAwal;
  final String namaKasir;

  /// null = sesi masih terbuka. Kolom-kolom tutup di bawah
  /// terisi saat sesi ditutup.
  DateTime? ditutupPada;
  int? tunaiFisik;
  int? pengeluaranLaci;
  String catatan;

  bool get terbuka => ditutupPada == null;

  /// Uang tunai yang SEHARUSNYA ada di laci saat tutup:
  /// modal awal + penjualan tunai − pengeluaran dari laci.
  int tunaiSeharusnya(RingkasanSesi r) => modalAwal + r.totalTunai - (pengeluaranLaci ?? 0);

  /// Selisih hitung fisik vs seharusnya: 0 pas, positif lebih,
  /// negatif kurang.
  int selisih(RingkasanSesi r) => (tunaiFisik ?? 0) - tunaiSeharusnya(r);

  Map<String, dynamic> toJson() => {
        'id': id,
        'branchId': branchId,
        'dibukaPada': dibukaPada.toIso8601String(),
        'modalAwal': modalAwal,
        'namaKasir': namaKasir,
        'ditutupPada': ditutupPada?.toIso8601String(),
        'tunaiFisik': tunaiFisik,
        'pengeluaranLaci': pengeluaranLaci,
        'catatan': catatan,
      };

  factory SesiKasir.fromJson(Map<String, dynamic> j) => SesiKasir(
        id: j['id'] as String?,
        branchId: j['branchId'] as String? ?? '',
        dibukaPada: DateTime.tryParse(j['dibukaPada'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        modalAwal: (j['modalAwal'] as num?)?.toInt() ?? 0,
        namaKasir: j['namaKasir'] as String? ?? '',
        ditutupPada: DateTime.tryParse(j['ditutupPada'] as String? ?? ''),
        tunaiFisik: (j['tunaiFisik'] as num?)?.toInt(),
        pengeluaranLaci: (j['pengeluaranLaci'] as num?)?.toInt(),
        catatan: j['catatan'] as String? ?? '',
      );
}

/// Ringkasan angka satu sesi dari transaksi + pengeluaran
/// yang jatuh di jendela waktunya (dibuka s.d. ditutup;
/// sesi terbuka = sampai sekarang).
class RingkasanSesi {
  const RingkasanSesi({
    required this.jumlahTransaksi,
    required this.totalPenjualan,
    required this.totalTunai,
    required this.totalQris,
    required this.totalDiskon,
    required this.totalPengeluaran,
  });

  final int jumlahTransaksi;
  final int totalPenjualan;
  final int totalTunai;
  final int totalQris;
  final int totalDiskon;

  /// Semua pengeluaran tercatat pada jendela sesi (dasar
  /// isian awal "pengeluaran dari laci" saat tutup kasir —
  /// kasir boleh membetulkannya bila ada yang dibayar
  /// lewat transfer, bukan dari laci).
  final int totalPengeluaran;
}

RingkasanSesi ringkasSesi({
  required SesiKasir sesi,
  required List<TxRecord> transactions,
  required List<Pengeluaran> expenses,
}) {
  bool diJendela(DateTime t) => !t.isBefore(sesi.dibukaPada) && (sesi.ditutupPada == null || !t.isAfter(sesi.ditutupPada!));
  bool diCabang(String b) => b.isEmpty || b == sesi.branchId;
  var n = 0;
  var jual = 0;
  var tunai = 0;
  var qris = 0;
  var diskon = 0;
  var keluar = 0;
  for (final t in transactions) {
    if (t.status != 'Lunas' || !diCabang(t.branchId) || !diJendela(t.at)) continue;
    n++;
    jual += t.total;
    diskon += t.diskon;
    if (t.method == 'QRIS') {
      qris += t.total;
    } else {
      tunai += t.total;
    }
  }
  for (final e in expenses) {
    if (!diCabang(e.branchId) || !diJendela(e.tanggal)) continue;
    keluar += e.jumlah;
  }
  return RingkasanSesi(jumlahTransaksi: n, totalPenjualan: jual, totalTunai: tunai, totalQris: qris, totalDiskon: diskon, totalPengeluaran: keluar);
}

// ---------- Pengeluaran & Laba Rugi ----------

/// Kategori pengeluaran bawaan yang ditawarkan formulir
/// (nilainya disimpan sebagai teks biasa; kategori di luar
/// daftar ini dari data lama tetap tampil apa adanya).
const kategoriPengeluaran = ['Sewa', 'Gaji', 'Listrik & Air', 'Bahan Tambahan', 'Kemasan', 'Transport', 'Perawatan', 'Lainnya'];

/// Satu catatan pengeluaran operasional (fitur Laporan Laba
/// Rugi, diminta Adnan 2026-11-16): sewa, gaji, listrik, dll —
/// uang keluar di LUAR pembelian bahan lewat kasir. Tersimpan
/// LOKAL di perangkat (belum ikut sinkron, seperti mutasi &
/// pemberitahuan) dan tercatat per cabang.
class Pengeluaran {
  Pengeluaran({
    String? id,
    required this.tanggal,
    required this.kategori,
    this.keterangan = '',
    required this.jumlah,
    this.branchId = '',
  }) : id = id ?? 'p${DateTime.now().microsecondsSinceEpoch}';

  final String id;
  final DateTime tanggal;
  final String kategori;
  final String keterangan;

  /// Jumlah keluar (Rp, selalu positif).
  final int jumlah;
  final String branchId;

  Pengeluaran salin({DateTime? tanggal, String? kategori, String? keterangan, int? jumlah, String? branchId}) => Pengeluaran(
        id: id,
        tanggal: tanggal ?? this.tanggal,
        kategori: kategori ?? this.kategori,
        keterangan: keterangan ?? this.keterangan,
        jumlah: jumlah ?? this.jumlah,
        branchId: branchId ?? this.branchId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal.toIso8601String(),
        'kategori': kategori,
        'keterangan': keterangan,
        'jumlah': jumlah,
        'branchId': branchId,
      };

  factory Pengeluaran.fromJson(Map<String, dynamic> j) => Pengeluaran(
        id: j['id'] as String? ?? '',
        tanggal: DateTime.tryParse(j['tanggal'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        kategori: j['kategori'] as String? ?? 'Lainnya',
        keterangan: j['keterangan'] as String? ?? '',
        jumlah: (j['jumlah'] as num?)?.toInt() ?? 0,
        branchId: j['branchId'] as String? ?? '',
      );
}

/// Hasil hitung Laporan Laba Rugi satu periode & cabang.
/// HPP dihitung dari resep menu & harga beli bahan SAAT INI
/// (bukan saat transaksi terjadi — aplikasi tidak menyimpan
/// potret HPP per penjualan). Baris penjualan yang menunya
/// sudah dihapus / belum punya resep tidak bisa dihitung
/// modalnya: dihitung di [barisTakDikenal] supaya layar bisa
/// memperingatkan bahwa laba sebenarnya lebih kecil.
class HasilLabaRugi {
  HasilLabaRugi({
    required this.pendapatan,
    required this.jumlahTx,
    required this.hpp,
    required this.totalBiaya,
    required this.rincianBiaya,
    required this.barisTakDikenal,
    required this.adaTxTanpaRincian,
  });

  final int pendapatan;
  final int jumlahTx;
  final int hpp;
  final int totalBiaya;

  /// (kategori, total) terurut terbesar dulu.
  final List<(String, int)> rincianBiaya;
  final int barisTakDikenal;
  final bool adaTxTanpaRincian;

  int get labaKotor => pendapatan - hpp;
  int get labaBersih => labaKotor - totalBiaya;

  /// Margin laba kotor terhadap pendapatan (0..1); 0 bila
  /// belum ada pendapatan.
  double get marginKotor => pendapatan <= 0 ? 0 : labaKotor / pendapatan;
}

/// Hitung laba rugi murni dari data yang ada. [dari]/[sampai]
/// inklusif per hari kalender. Hanya transaksi 'Lunas' yang
/// dihitung sebagai pendapatan. Cabang mengikuti pola aplikasi:
/// catatan bercabang kosong (data lama) ikut di semua cabang.
HasilLabaRugi hitungLabaRugi({
  required List<TxRecord> transactions,
  required List<MenuItem> menus,
  required List<Ingredient> ingredients,
  required List<Pengeluaran> expenses,
  required String branchId,
  required DateTime dari,
  required DateTime sampai,
}) {
  final awal = DateTime(dari.year, dari.month, dari.day);
  final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
  bool diRentang(DateTime t) => !t.isBefore(awal) && t.isBefore(akhir);
  bool diCabang(String b) => b.isEmpty || b == branchId;

  final menuPerNama = <String, MenuItem>{};
  for (final m in menus) {
    menuPerNama.putIfAbsent(m.name, () => m);
  }

  var pendapatan = 0;
  var jumlahTx = 0;
  var hpp = 0;
  var takDikenal = 0;
  var adaTxLama = false;
  for (final t in transactions) {
    if (t.status != 'Lunas' || !diCabang(t.branchId) || !diRentang(t.at)) continue;
    pendapatan += t.total;
    jumlahTx++;
    if (t.lines.isEmpty) {
      adaTxLama = true;
      continue;
    }
    for (final l in t.lines) {
      final m = menuPerNama[l.nama];
      if (m == null || kebutuhanBahan(m, menus).isEmpty) {
        takDikenal++;
        continue;
      }
      hpp += hppMenu(m, menus, ingredients) * l.qty;
    }
  }

  var totalBiaya = 0;
  final perKategori = <String, int>{};
  for (final e in expenses) {
    if (!diCabang(e.branchId) || !diRentang(e.tanggal)) continue;
    totalBiaya += e.jumlah;
    perKategori[e.kategori] = (perKategori[e.kategori] ?? 0) + e.jumlah;
  }
  final rincian = perKategori.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));

  return HasilLabaRugi(
    pendapatan: pendapatan,
    jumlahTx: jumlahTx,
    hpp: hpp,
    totalBiaya: totalBiaya,
    rincianBiaya: rincian,
    barisTakDikenal: takDikenal,
    adaTxTanpaRincian: adaTxLama,
  );
}

// ---------- Hutang ----------

/// Satu catatan hutang usaha (fitur Laporan Hutang v0.11.0,
/// diminta Adnan sebagai bagian update besar): uang yang
/// dipinjam usaha dari pemasok / orang / pihak lain, dicatat
/// manual oleh pemilik. Tersimpan LOKAL di perangkat (belum
/// ikut sinkron, seperti pengeluaran & mutasi) dan tercatat
/// per cabang. Dipakai juga oleh Neraca (total belum lunas)
/// dan Arus Kas (hutang baru = masuk, pelunasan = keluar).
class Hutang {
  Hutang({
    String? id,
    required this.tanggal,
    required this.kreditur,
    this.keterangan = '',
    required this.jumlah,
    this.jatuhTempo,
    this.lunas = false,
    this.tanggalLunas,
    this.branchId = '',
  }) : id = id ?? 'h${DateTime.now().microsecondsSinceEpoch}';

  final String id;

  /// Tanggal hutang dibuat / uang diterima.
  final DateTime tanggal;

  /// Nama pihak yang memberi hutang (pemasok, orang, bank).
  final String kreditur;
  final String keterangan;

  /// Jumlah hutang (Rp, selalu positif).
  final int jumlah;

  /// Batas waktu bayar (boleh kosong).
  final DateTime? jatuhTempo;
  final bool lunas;

  /// Tanggal dilunasi (terisi saat ditandai lunas).
  final DateTime? tanggalLunas;
  final String branchId;

  /// Sudah lewat jatuh tempo & belum lunas pada [pada].
  bool terlambat(DateTime pada) => !lunas && jatuhTempo != null && DateTime(pada.year, pada.month, pada.day).isAfter(DateTime(jatuhTempo!.year, jatuhTempo!.month, jatuhTempo!.day));

  Hutang salin({DateTime? tanggal, String? kreditur, String? keterangan, int? jumlah, DateTime? jatuhTempo, bool adaJatuhTempo = true, bool? lunas, DateTime? tanggalLunas, bool adaTanggalLunas = true, String? branchId}) => Hutang(
        id: id,
        tanggal: tanggal ?? this.tanggal,
        kreditur: kreditur ?? this.kreditur,
        keterangan: keterangan ?? this.keterangan,
        jumlah: jumlah ?? this.jumlah,
        jatuhTempo: adaJatuhTempo ? (jatuhTempo ?? this.jatuhTempo) : null,
        lunas: lunas ?? this.lunas,
        tanggalLunas: adaTanggalLunas ? (tanggalLunas ?? this.tanggalLunas) : null,
        branchId: branchId ?? this.branchId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal.toIso8601String(),
        'kreditur': kreditur,
        'keterangan': keterangan,
        'jumlah': jumlah,
        'jatuhTempo': jatuhTempo?.toIso8601String(),
        'lunas': lunas,
        'tanggalLunas': tanggalLunas?.toIso8601String(),
        'branchId': branchId,
      };

  factory Hutang.fromJson(Map<String, dynamic> j) => Hutang(
        id: j['id'] as String? ?? '',
        tanggal: DateTime.tryParse(j['tanggal'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        kreditur: j['kreditur'] as String? ?? '',
        keterangan: j['keterangan'] as String? ?? '',
        jumlah: (j['jumlah'] as num?)?.toInt() ?? 0,
        jatuhTempo: DateTime.tryParse(j['jatuhTempo'] as String? ?? ''),
        lunas: j['lunas'] as bool? ?? false,
        tanggalLunas: DateTime.tryParse(j['tanggalLunas'] as String? ?? ''),
        branchId: j['branchId'] as String? ?? '',
      );
}

/// Total hutang BELUM lunas sampai akhir hari [tanggal]
/// (aturan cabang sama seperti laporan lain: cabang kosong
/// ikut di semua cabang).
int totalHutangBelumLunas(List<Hutang> hutang, {required String branchId, required DateTime tanggal}) {
  final batas = DateTime(tanggal.year, tanggal.month, tanggal.day).add(const Duration(days: 1));
  var total = 0;
  for (final h in hutang) {
    if (h.lunas) continue;
    if (h.branchId.isNotEmpty && h.branchId != branchId) continue;
    if (!h.tanggal.isBefore(batas)) continue;
    total += h.jumlah;
  }
  return total;
}

// ---------- Promo & Diskon ----------

/// Satu promo yang bisa dipakai di kasir (fitur Promo &
/// Diskon v0.11.0). [jenis] 'persen' (nilai = persen dari
/// subtotal) atau 'nominal' (nilai = Rp potongan langsung).
/// Tersimpan LOKAL di perangkat (belum ikut sinkron).
class Promo {
  Promo({
    String? id,
    required this.nama,
    required this.jenis,
    required this.nilai,
    this.minBelanja = 0,
    this.aktif = true,
  }) : id = id ?? 'pr${DateTime.now().microsecondsSinceEpoch}';

  final String id;
  final String nama;
  final String jenis; // 'persen' | 'nominal'
  final int nilai;
  final int minBelanja;
  final bool aktif;

  Promo salin({String? nama, String? jenis, int? nilai, int? minBelanja, bool? aktif}) => Promo(
        id: id,
        nama: nama ?? this.nama,
        jenis: jenis ?? this.jenis,
        nilai: nilai ?? this.nilai,
        minBelanja: minBelanja ?? this.minBelanja,
        aktif: aktif ?? this.aktif,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'jenis': jenis,
        'nilai': nilai,
        'minBelanja': minBelanja,
        'aktif': aktif,
      };

  factory Promo.fromJson(Map<String, dynamic> j) => Promo(
        id: j['id'] as String? ?? '',
        nama: j['nama'] as String? ?? '',
        jenis: j['jenis'] as String? ?? 'persen',
        nilai: (j['nilai'] as num?)?.toInt() ?? 0,
        minBelanja: (j['minBelanja'] as num?)?.toInt() ?? 0,
        aktif: j['aktif'] as bool? ?? true,
      );
}

/// Besar diskon (Rp) untuk [promo] pada [subtotal]. 0 bila
/// promo kosong / nonaktif / subtotal di bawah syarat minimal
/// belanja. Hasil TIDAK PERNAH melebihi subtotal dan tidak
/// pernah negatif — satu-satunya sumber kebenaran hitungan
/// diskon, dipakai tampilan kasir DAN pencatatan transaksi
/// supaya keduanya tidak pernah berbeda.
int hitungDiskonPromo(Promo? promo, int subtotal) {
  if (promo == null || !promo.aktif || subtotal <= 0) return 0;
  if (subtotal < promo.minBelanja) return 0;
  final mentah = promo.jenis == 'persen' ? (subtotal * promo.nilai.clamp(0, 100) / 100).round() : promo.nilai;
  if (mentah < 0) return 0;
  return mentah > subtotal ? subtotal : mentah;
}

// ---------- Persediaan ----------

/// Nilai persediaan satu bahan: stok kini × harga pokok.
class RincianPersediaan {
  RincianPersediaan({required this.bahan, required this.stok, required this.satuan, required this.hargaPokok, required this.nilai});
  final Ingredient bahan;
  final double stok;
  final String satuan;
  final int hargaPokok;
  final int nilai;
}

/// Nilai persediaan semua bahan dari stok & harga pokok
/// TERKINI. Mengembalikan (total, rincian terurut nilai
/// terbesar dulu). Dipakai Laporan Persediaan & Neraca.
(int, List<RincianPersediaan>) nilaiPersediaan(List<Ingredient> ingredients) {
  final rincian = <RincianPersediaan>[];
  var total = 0;
  for (final ing in ingredients) {
    final nilai = ing.stock <= 0 ? 0 : (ing.stock * ing.costPerUnit).round();
    total += nilai;
    rincian.add(RincianPersediaan(bahan: ing, stok: ing.stock, satuan: ing.unit, hargaPokok: ing.costPerUnit, nilai: nilai));
  }
  rincian.sort((a, b) => b.nilai.compareTo(a.nilai));
  return (total, rincian);
}

// ---------- Neraca ----------

/// Hasil hitung Neraca (laporan posisi keuangan) per akhir
/// hari [tanggal]. Semua angka diturunkan dari catatan yang
/// ADA di aplikasi — kas adalah PERKIRAAN (penjualan tunai
/// lunas tercatat dikurangi pengeluaran tercatat; pembelian
/// bahan & pergerakan di luar aplikasi tidak tercatat).
/// Modal pemilik adalah angka PENYEIMBANG (aktiva −
/// kewajiban − laba ditahan) supaya neraca selalu seimbang;
/// layar menuliskannya apa adanya.
class HasilNeraca {
  HasilNeraca({
    required this.kasTunai,
    required this.saldoQris,
    required this.nilaiPersediaan,
    required this.rincianPersediaan,
    required this.piutang,
    required this.jumlahPiutang,
    required this.utang,
    required this.jumlahUtang,
    required this.labaDitahan,
    required this.pendapatanKumulatif,
    required this.hppKumulatif,
    required this.biayaKumulatif,
  });

  final int kasTunai;
  final int saldoQris;
  final int nilaiPersediaan;
  final List<RincianPersediaan> rincianPersediaan;
  final int piutang;
  final int jumlahPiutang;
  final int utang;
  final int jumlahUtang;
  final int labaDitahan;
  final int pendapatanKumulatif;
  final int hppKumulatif;
  final int biayaKumulatif;

  int get totalAktiva => kasTunai + saldoQris + nilaiPersediaan + piutang;
  int get totalKewajiban => utang;

  /// Angka penyeimbang: modal awal pemilik yang tersirat
  /// dari catatan (aktiva − kewajiban − laba ditahan).
  int get modalPenyeimbang => totalAktiva - totalKewajiban - labaDitahan;
  int get totalModal => modalPenyeimbang + labaDitahan;
  int get totalPasiva => totalKewajiban + totalModal;
  bool get seimbang => totalAktiva == totalPasiva;
}

HasilNeraca hitungNeraca({
  required List<TxRecord> transactions,
  required List<MenuItem> menus,
  required List<Ingredient> ingredients,
  required List<Pengeluaran> expenses,
  required List<Hutang> hutang,
  required String branchId,
  required DateTime tanggal,
}) {
  final batas = DateTime(tanggal.year, tanggal.month, tanggal.day).add(const Duration(days: 1));
  bool sampaikah(DateTime t) => t.isBefore(batas);
  bool diCabang(String b) => b.isEmpty || b == branchId;

  var kasMasuk = 0;
  var qris = 0;
  var piutang = 0;
  var jumlahPiutang = 0;
  for (final t in transactions) {
    if (!diCabang(t.branchId) || !sampaikah(t.at)) continue;
    if (t.status == 'Lunas') {
      if (t.method == 'QRIS') {
        qris += t.total;
      } else {
        kasMasuk += t.total;
      }
    } else if (t.status == 'Belum bayar') {
      piutang += t.total;
      jumlahPiutang++;
    }
  }
  var biaya = 0;
  for (final e in expenses) {
    if (diCabang(e.branchId) && sampaikah(e.tanggal)) biaya += e.jumlah;
  }
  var utangTotal = 0;
  var jumlahUtang = 0;
  for (final h in hutang) {
    if (h.lunas || !diCabang(h.branchId) || !sampaikah(h.tanggal)) continue;
    utangTotal += h.jumlah;
    jumlahUtang++;
  }
  final (totalStok, rincianStok) = nilaiPersediaan(ingredients);
  final laba = hitungLabaRugi(
    transactions: transactions,
    menus: menus,
    ingredients: ingredients,
    expenses: expenses,
    branchId: branchId,
    dari: DateTime(2000),
    sampai: tanggal,
  );
  return HasilNeraca(
    kasTunai: kasMasuk - biaya,
    saldoQris: qris,
    nilaiPersediaan: totalStok,
    rincianPersediaan: rincianStok,
    piutang: piutang,
    jumlahPiutang: jumlahPiutang,
    utang: utangTotal,
    jumlahUtang: jumlahUtang,
    labaDitahan: laba.labaBersih,
    pendapatanKumulatif: laba.pendapatan,
    hppKumulatif: laba.hpp,
    biayaKumulatif: laba.totalBiaya,
  );
}

// ---------- Arus Kas ----------

/// Hasil hitung Laporan Arus Kas satu periode & cabang.
/// Masuk: penjualan tunai + QRIS lunas + hutang baru. Keluar:
/// pembelian bahan (mutasi barang masuk, dinilai harga pokok
/// kini), pengeluaran operasional, pelunasan hutang. Mutasi
/// gudang tidak tercatat per cabang → pembelian bahan selalu
/// angka seluruh usaha (dijelaskan di layar). [saldoAwal]
/// dihitung dengan aturan yang sama untuk semua catatan
/// SEBELUM periode mulai, jadi saldo akhir = saldo awal +
/// arus bersih konsisten.
class HasilArusKas {
  HasilArusKas({
    required this.masukTunai,
    required this.masukQris,
    required this.hutangBaru,
    required this.pembelianBahan,
    required this.biayaOperasional,
    required this.rincianBiaya,
    required this.bayarHutang,
    required this.saldoAwal,
  });

  final int masukTunai;
  final int masukQris;
  final int hutangBaru;
  final int pembelianBahan;
  final int biayaOperasional;
  final List<(String, int)> rincianBiaya;
  final int bayarHutang;
  final int saldoAwal;

  int get totalMasuk => masukTunai + masukQris + hutangBaru;
  int get totalKeluar => pembelianBahan + biayaOperasional + bayarHutang;
  int get arusBersih => totalMasuk - totalKeluar;
  int get saldoAkhir => saldoAwal + arusBersih;
}

HasilArusKas hitungArusKas({
  required List<TxRecord> transactions,
  required List<Pengeluaran> expenses,
  required List<MutasiStok> mutasi,
  required List<Ingredient> ingredients,
  required List<Hutang> hutang,
  required String branchId,
  required DateTime dari,
  required DateTime sampai,
}) {
  final awal = DateTime(dari.year, dari.month, dari.day);
  final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
  bool diCabang(String b) => b.isEmpty || b == branchId;
  final hargaPokok = <String, int>{for (final i in ingredients) i.id: i.costPerUnit};
  final hargaPerNama = <String, int>{for (final i in ingredients) i.name: i.costPerUnit};
  int nilaiMasuk(MutasiStok m) {
    final harga = hargaPokok[m.ingredientId] ?? hargaPerNama[m.namaBahan] ?? 0;
    return (m.jumlah * harga).round();
  }

  /// (tunai, qris, hutangBaru, pembelian, biaya, bayarHutang)
  /// untuk catatan yang tanggalnya lolos [uji].
  (int, int, int, int, int, int) jumlahkan(bool Function(DateTime) uji) {
    var tunai = 0, qris = 0, hBaru = 0, beli = 0, biaya = 0, bayar = 0;
    for (final t in transactions) {
      if (t.status != 'Lunas' || !diCabang(t.branchId) || !uji(t.at)) continue;
      if (t.method == 'QRIS') {
        qris += t.total;
      } else {
        tunai += t.total;
      }
    }
    for (final m in mutasi) {
      if (m.jenis == 'masuk' && uji(m.waktu)) beli += nilaiMasuk(m);
    }
    for (final e in expenses) {
      if (diCabang(e.branchId) && uji(e.tanggal)) biaya += e.jumlah;
    }
    for (final h in hutang) {
      if (!diCabang(h.branchId)) continue;
      if (uji(h.tanggal)) hBaru += h.jumlah;
      if (h.lunas && h.tanggalLunas != null && uji(h.tanggalLunas!)) bayar += h.jumlah;
    }
    return (tunai, qris, hBaru, beli, biaya, bayar);
  }

  final (tunai, qris, hBaru, beli, biaya, bayar) = jumlahkan((t) => !t.isBefore(awal) && t.isBefore(akhir));
  final (aTunai, aQris, aHBaru, aBeli, aBiaya, aBayar) = jumlahkan((t) => t.isBefore(awal));
  final perKategori = <String, int>{};
  for (final e in expenses) {
    if (diCabang(e.branchId) && !e.tanggal.isBefore(awal) && e.tanggal.isBefore(akhir)) {
      perKategori[e.kategori] = (perKategori[e.kategori] ?? 0) + e.jumlah;
    }
  }
  final rincian = perKategori.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
  return HasilArusKas(
    masukTunai: tunai,
    masukQris: qris,
    hutangBaru: hBaru,
    pembelianBahan: beli,
    biayaOperasional: biaya,
    rincianBiaya: rincian,
    bayarHutang: bayar,
    saldoAwal: (aTunai + aQris + aHBaru) - (aBeli + aBiaya + aBayar),
  );
}

// ---------- Arus Stok & Pembelian ----------

/// Rekap pergerakan stok satu bahan dalam periode (dari
/// riwayat mutasi gudang). [terpakai] = jumlah terjual
/// (mutasi 'jual' tersimpan negatif → dibalik positif).
class RekapArusStok {
  RekapArusStok({required this.nama, required this.satuan, required this.masuk, required this.terpakai, required this.opname, required this.edit, required this.peristiwa});
  final String nama;
  final String satuan;
  final double masuk;
  final double terpakai;
  final double opname;
  final double edit;
  final int peristiwa;
  double get perubahanBersih => masuk - terpakai + opname + edit;
}

/// Ringkas mutasi stok per bahan untuk periode [dari]–[sampai]
/// (inklusif per hari). Terurut nama bahan.
List<RekapArusStok> ringkasArusStok(List<MutasiStok> mutasi, {required DateTime dari, required DateTime sampai}) {
  final awal = DateTime(dari.year, dari.month, dari.day);
  final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
  final per = <String, ({String nama, String satuan, double masuk, double jual, double opname, double edit, int peristiwa})>{};
  for (final m in mutasi) {
    if (m.waktu.isBefore(awal) || !m.waktu.isBefore(akhir)) continue;
    final lama = per[m.ingredientId];
    var masuk = lama?.masuk ?? 0.0;
    var jual = lama?.jual ?? 0.0;
    var opname = lama?.opname ?? 0.0;
    var edit = lama?.edit ?? 0.0;
    switch (m.jenis) {
      case 'masuk':
        masuk += m.jumlah;
      case 'jual':
        jual += m.jumlah;
      case 'opname':
        opname += m.jumlah;
      default:
        edit += m.jumlah;
    }
    per[m.ingredientId] = (
      nama: m.namaBahan,
      satuan: m.satuan,
      masuk: masuk,
      jual: jual,
      opname: opname,
      edit: edit,
      peristiwa: (lama?.peristiwa ?? 0) + 1,
    );
  }
  final hasil = per.values
      .map((r) => RekapArusStok(nama: r.nama, satuan: r.satuan, masuk: r.masuk, terpakai: -r.jual, opname: r.opname, edit: r.edit, peristiwa: r.peristiwa))
      .toList()
    ..sort((a, b) => a.nama.compareTo(b.nama));
  return hasil;
}

/// Hasil hitung Laporan Pembelian: semua mutasi barang masuk
/// dalam periode, dinilai harga pokok bahan SAAT INI (mutasi
/// tidak menyimpan harga saat kejadian — dijelaskan di
/// layar). [entri] terurut terbaru dulu.
class HasilPembelian {
  HasilPembelian({required this.totalNilai, required this.totalQty, required this.entri, required this.perBahan});
  final int totalNilai;
  final double totalQty;
  final List<(MutasiStok, int)> entri; // (mutasi, nilai Rp)
  final List<(String, String, double, int)> perBahan; // (nama, satuan, qty, nilai)
}

HasilPembelian ringkasPembelian(List<MutasiStok> mutasi, List<Ingredient> ingredients, {required DateTime dari, required DateTime sampai}) {
  final awal = DateTime(dari.year, dari.month, dari.day);
  final akhir = DateTime(sampai.year, sampai.month, sampai.day).add(const Duration(days: 1));
  final hargaPokok = <String, int>{for (final i in ingredients) i.id: i.costPerUnit};
  final hargaPerNama = <String, int>{for (final i in ingredients) i.name: i.costPerUnit};
  final entri = <(MutasiStok, int)>[];
  final per = <String, ({String nama, String satuan, double qty, int nilai})>{};
  var totalNilai = 0;
  var totalQty = 0.0;
  final masuk = mutasi.where((m) => m.jenis == 'masuk' && !m.waktu.isBefore(awal) && m.waktu.isBefore(akhir)).toList()
    ..sort((a, b) => b.waktu.compareTo(a.waktu));
  for (final m in masuk) {
    final harga = hargaPokok[m.ingredientId] ?? hargaPerNama[m.namaBahan] ?? 0;
    final nilai = (m.jumlah * harga).round();
    entri.add((m, nilai));
    totalNilai += nilai;
    totalQty += m.jumlah;
    final lama = per[m.ingredientId];
    per[m.ingredientId] = (
      nama: m.namaBahan,
      satuan: m.satuan,
      qty: (lama?.qty ?? 0) + m.jumlah,
      nilai: (lama?.nilai ?? 0) + nilai,
    );
  }
  final perBahan = per.values.map((r) => (r.nama, r.satuan, r.qty, r.nilai)).toList()..sort((a, b) => b.$4.compareTo(a.$4));
  return HasilPembelian(totalNilai: totalNilai, totalQty: totalQty, entri: entri, perBahan: perBahan);
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
