import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// Data aplikasi yang tersimpan permanen di perangkat.
class AppData {
  AppData({required this.menus, required this.tables, required this.ingredients, required this.settings});
  final List<MenuItem> menus;
  final List<CafeTable> tables;
  final List<Ingredient> ingredients;
  final AppSettings settings;
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

  static Future<AppData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppData(
        menus: _decodeList(prefs.getString(_kMenus), MenuItem.fromJson) ?? seedMenus(),
        tables: _decodeList(prefs.getString(_kTables), CafeTable.fromJson) ?? seedTables(),
        ingredients: _decodeList(prefs.getString(_kIngredients), Ingredient.fromJson) ?? seedIngredients(),
        settings: _decodeSettings(prefs.getString(_kSettings)),
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
}
