import 'package:avoera_pos/data.dart';
import 'package:avoera_pos/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bukti simpan permanen: data yang disimpan LocalStore harus kembali
// persis sama saat dimuat lagi (seperti aplikasi ditutup lalu dibuka).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Model bolak-balik JSON tanpa ada yang berubah', () {
    final menu = MenuItem.fromJson(
      MenuItem(id: 'x1', name: 'Es Kopi', category: 'Kopi', price: 21000, color: const Color(0xFF00695C), icon: Icons.coffee, isDrink: true).toJson(),
    );
    expect(menu.id, 'x1');
    expect(menu.name, 'Es Kopi');
    expect(menu.price, 21000);
    expect(menu.color, const Color(0xFF00695C));
    expect(menu.icon.codePoint, Icons.coffee.codePoint);
    expect(menu.isDrink, isTrue);

    final table = CafeTable.fromJson(
      CafeTable(number: 7, capacity: 4, status: TableStatus.terisi, guestName: 'Andi', openAmount: 74000, since: '19:20').toJson(),
    );
    expect(table.number, 7);
    expect(table.status, TableStatus.terisi);
    expect(table.guestName, 'Andi');
    expect(table.openAmount, 74000);

    final ing = Ingredient.fromJson(
      Ingredient(name: 'Susu Segar', stock: 3.5, unit: 'liter', minStock: 4, maxStock: 20).toJson(),
    );
    expect(ing.name, 'Susu Segar');
    expect(ing.stock, 3.5);
    expect(ing.status, StockStatus.kritis);
  });

  test('LocalStore: simpan lalu muat lagi hasilnya sama', () async {
    SharedPreferences.setMockInitialValues({});

    final menus = seedMenus()
      ..add(MenuItem(id: 'baru1', name: 'Menu Uji', category: 'Paket', price: 99000, color: const Color(0xFF4527A0), icon: Icons.cake));
    await LocalStore.saveMenus(menus);
    await LocalStore.saveTables([CafeTable(number: 99, capacity: 10, status: TableStatus.kosong)]);
    await LocalStore.saveIngredients([Ingredient(name: 'Bahan Uji', stock: 7, unit: 'pcs', minStock: 2, maxStock: 50)]);
    await LocalStore.saveSettings(AppSettings(businessName: 'Warung Uji', servicePercent: 7, taxPercent: 11));

    final loaded = await LocalStore.load();
    expect(loaded.menus.length, menus.length);
    expect(loaded.menus.last.name, 'Menu Uji');
    expect(loaded.menus.last.price, 99000);
    expect(loaded.tables.single.number, 99);
    expect(loaded.ingredients.single.name, 'Bahan Uji');
    expect(loaded.settings.businessName, 'Warung Uji');
    expect(loaded.settings.servicePercent, 7);
    expect(loaded.settings.taxPercent, 11);
  });

  test('LocalStore: belum pernah simpan → dapat data contoh', () async {
    SharedPreferences.setMockInitialValues({});
    final loaded = await LocalStore.load();
    expect(loaded.menus, isNotEmpty);
    expect(loaded.tables, isNotEmpty);
    expect(loaded.ingredients, isNotEmpty);
    expect(loaded.settings.servicePercent, 5);
  });
}
