import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'struk.dart';

/// Data aplikasi yang tersimpan permanen di perangkat.
class AppData {
  AppData({required this.menus, required this.tables, required this.ingredients, required this.settings, this.transactions = const [], this.notifications = const [], this.mutasi = const [], this.expenses = const [], this.hutang = const [], this.promos = const [], this.sesi = const [], this.dapur = const []});
  final List<MenuItem> menus;
  final List<CafeTable> tables;
  final List<Ingredient> ingredients;
  final AppSettings settings;
  final List<TxRecord> transactions;
  final List<AppNotification> notifications;
  final List<MutasiStok> mutasi;
  final List<Pengeluaran> expenses;
  final List<Hutang> hutang;
  final List<Promo> promos;
  final List<SesiKasir> sesi;
  final List<KitchenOrder> dapur;
}

/// Tempat simpan lokal (SharedPreferences + JSON).
///
/// Data contoh (seed) hanya dipakai pada jalan pertama atau bila data
/// tersimpan rusak/tidak terbaca — sesudah itu semua perubahan CRUD
/// dan Pengaturan disimpan di sini dan dimuat lagi saat aplikasi dibuka.
class LocalStore {
  static const _kMenus = 'avoera.menus.v1';
  static const _kTables = 'avoera.tables.v1';
  static const _kIngredients = 'avoera.ingredients.v1';
  static const _kSettings = 'avoera.settings.v1';
  static const _kTx = 'avoera.tx.v1';
  static const _kNotif = 'avoera.notifications.v1';
  static const _kMutasi = 'avoera.mutasi.v1';
  static const _kExpenses = 'avoera.expenses.v1';
  static const _kHutang = 'avoera.hutang.v1';
  static const _kPromos = 'avoera.promos.v1';
  static const _kSesi = 'avoera.sesi.v1';
  static const _kDapur = 'avoera.dapur.v1';
  static const _kSyncMeta = 'avoera.syncmeta.v1';
  static const _kUpdateMeta = 'avoera.updatemeta.v1';
  static const _kNotifKunci = 'avoera.notifkunci.v1';

  static Future<AppData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppData(
        menus: _decodeList(prefs.getString(_kMenus), MenuItem.fromJson) ?? seedMenus(),
        tables: _decodeList(prefs.getString(_kTables), CafeTable.fromJson) ?? seedTables(),
        ingredients: _decodeList(prefs.getString(_kIngredients), Ingredient.fromJson) ?? seedIngredients(),
        settings: _decodeSettings(prefs.getString(_kSettings)),
        transactions: _decodeList(prefs.getString(_kTx), TxRecord.fromJson) ?? <TxRecord>[],
        notifications: _decodeList(prefs.getString(_kNotif), AppNotification.fromJson) ?? <AppNotification>[],
        mutasi: _decodeList(prefs.getString(_kMutasi), MutasiStok.fromJson) ?? <MutasiStok>[],
        expenses: _decodeList(prefs.getString(_kExpenses), Pengeluaran.fromJson) ?? <Pengeluaran>[],
        hutang: _decodeList(prefs.getString(_kHutang), Hutang.fromJson) ?? <Hutang>[],
        promos: _decodeList(prefs.getString(_kPromos), Promo.fromJson) ?? <Promo>[],
        sesi: _decodeList(prefs.getString(_kSesi), SesiKasir.fromJson) ?? <SesiKasir>[],
        dapur: _decodeList(prefs.getString(_kDapur), KitchenOrder.fromJson) ?? seedKitchenOrders(),
      );
    } catch (_) {
      // Penyimpanan tidak tersedia (mis. lingkungan tes) → data contoh.
      return AppData(menus: seedMenus(), tables: seedTables(), ingredients: seedIngredients(), settings: AppSettings());
    }
  }

  static List<T>? _decodeList<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return null;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(fromJson).toList();
    } catch (_) {
      return null;
    }
  }

  static AppSettings _decodeSettings(String? raw) {
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  static Future<void> _save(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (_) {
      // Gagal simpan tidak boleh menjatuhkan aplikasi.
    }
  }

  static Future<void> saveMenus(List<MenuItem> menus) => _save(_kMenus, menus.map((m) => m.toJson()).toList());
  static Future<void> saveTables(List<CafeTable> tables) => _save(_kTables, tables.map((t) => t.toJson()).toList());
  static Future<void> saveIngredients(List<Ingredient> ings) => _save(_kIngredients, ings.map((i) => i.toJson()).toList());
  static Future<void> saveSettings(AppSettings settings) => _save(_kSettings, settings.toJson());
  static Future<void> saveTransactions(List<TxRecord> tx) => _save(_kTx, tx.map((t) => t.toJson()).toList());
  static Future<void> saveNotifications(List<AppNotification> n) => _save(_kNotif, n.map((e) => e.toJson()).toList());
  static Future<void> saveMutasi(List<MutasiStok> m) => _save(_kMutasi, m.map((e) => e.toJson()).toList());
  static Future<void> saveExpenses(List<Pengeluaran> e) => _save(_kExpenses, e.map((x) => x.toJson()).toList());
  static Future<void> saveHutang(List<Hutang> h) => _save(_kHutang, h.map((x) => x.toJson()).toList());
  static Future<void> savePromos(List<Promo> p) => _save(_kPromos, p.map((x) => x.toJson()).toList());
  static Future<void> saveSesi(List<SesiKasir> s) => _save(_kSesi, s.map((x) => x.toJson()).toList());
  static Future<void> saveDapur(List<KitchenOrder> d) => _save(_kDapur, d.map((x) => x.toJson()).toList());

  /// Meta sinkron untuk halaman Status Sinkronisasi: jumlah
  /// perubahan yang menunggu per tabel + laporan sinkron terakhir.
  static Future<Map<String, dynamic>> loadSyncMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSyncMeta);
      if (raw == null) return <String, dynamic>{};
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> saveSyncMeta(Map<String, dynamic> meta) => _save(_kSyncMeta, meta);

  /// Meta pembaruan dalam aplikasi: kode tertinggi yang sudah
  /// pernah DITAWARKAN OTOMATIS lewat dialog (v0.10.12) —
  /// supaya tawaran hanya muncul sekali per versi.
  static Future<Map<String, dynamic>> loadUpdateMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUpdateMeta);
      if (raw == null) return <String, dynamic>{};
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> saveUpdateMeta(Map<String, dynamic> meta) => _save(_kUpdateMeta, meta);

  /// Kunci pemberitahuan yang episodenya SEDANG berjalan
  /// (v0.14.3): satu kunci hanya melahirkan satu pemberitahuan
  /// sampai episodenya dinyatakan berakhir. Mencegah
  /// pemberitahuan yang sudah dibaca lahir lagi sebagai belum
  /// dibaca setiap kali keadaan diperiksa ulang (refresh).
  static Future<Set<String>> loadKunciNotif() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kNotifKunci);
      if (raw == null) return <String>{};
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> saveKunciNotif(Set<String> kunci) => _save(_kNotifKunci, kunci.toList());

  // ---------- Desain struk & printer (v0.15.0) ----------
  static const _kStruk = 'avoera.struk.v1';

  static Future<DesainStruk> loadStruk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStruk);
      if (raw == null) return DesainStruk();
      return DesainStruk.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return DesainStruk();
    }
  }

  static Future<void> saveStruk(DesainStruk d) => _save(_kStruk, d.toJson());

  // ---------- Draf kasir berjalan (v0.16.0) ----------
  static const _kKeranjang = 'avoera.keranjang.v1';

  static Future<DraftKasir> loadDraftKasir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKeranjang);
      if (raw == null) return DraftKasir();
      return DraftKasir.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return DraftKasir();
    }
  }

  static Future<void> saveDraftKasir(DraftKasir d) => _save(_kKeranjang, d.toJson());
}
