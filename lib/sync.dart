import 'package:supabase/supabase.dart';

import 'data.dart';

/// Sinkronisasi Supabase (permintaan Adnan 2026-11-14 — backend
/// gratis). Modelnya: data LOKAL tetap utama (aplikasi jalan penuh
/// tanpa internet); tombol "Sinkronkan Sekarang" mengunggah data
/// lokal lalu menarik data server dan menggabungkannya:
/// menu/bahan/cabang/pengaturan = server menang bila perangkat ini
/// masih kosong datanya? Tidak — penggabungan per id, yang di
/// server menimpa lokal untuk id yang sama (terakhir sinkron
/// menang), transaksi digabung berdasarkan uuid (tidak dobel).
///
/// Keamanan: baris ditandai Kode Usaha; RLS di server hanya
/// melayani baris yang kodenya cocok dengan header yang dikirim.
/// PIN & kredensial TIDAK ikut diunggah (dibuang dari salinan
/// pengaturan sebelum kirim).

class HasilSinkron {
  HasilSinkron({required this.menus, required this.ingredients, required this.branches, required this.transactions, required this.pengaturanServer, required this.ringkasan});
  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final List<Branch> branches;
  final List<TxRecord> transactions;
  final Map<String, dynamic>? pengaturanServer;
  final String ringkasan;
}

Map<String, dynamic> _pengaturanAman(AppSettings s) {
  final j = s.toJson();
  // Jangan unggah rahasia & data khusus perangkat ini.
  for (final k in ['pinHash', 'supabaseUrl', 'supabaseAnonKey', 'businessKey', 'lastSyncLabel', 'modeTema', 'branches', 'activeBranchId']) {
    j.remove(k);
  }
  return j;
}

Future<HasilSinkron> sinkronkanSupabase({
  required AppSettings settings,
  required List<MenuItem> menus,
  required List<Ingredient> ingredients,
  required List<Branch> branches,
  required List<TxRecord> transactions,
}) async {
  final kode = settings.businessKey;
  final client = SupabaseClient(
    settings.supabaseUrl,
    settings.supabaseAnonKey,
    headers: {'x-business-key': kode},
  );
  final sekarang = DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> barisData(String id, Map<String, dynamic> data) => {
        'business_key': kode,
        'id': id,
        'data': data,
        'updated_at': sekarang,
      };

  // ---------- UNGGAH ----------
  if (branches.isNotEmpty) {
    await client.from('avoera_branches').upsert([for (final b in branches) barisData(b.id, b.toJson())]);
  }
  if (menus.isNotEmpty) {
    await client.from('avoera_menus').upsert([for (final m in menus) barisData(m.id, m.toJson())]);
  }
  if (ingredients.isNotEmpty) {
    await client.from('avoera_ingredients').upsert([for (final i in ingredients) barisData(i.id, i.toJson())]);
  }
  if (transactions.isNotEmpty) {
    await client.from('avoera_transactions').upsert([
      for (final t in transactions)
        {
          'business_key': kode,
          'uuid': t.uuid.isEmpty ? t.id : t.uuid,
          'at': t.at.toUtc().toIso8601String(),
          'data': t.toJson(),
          'updated_at': sekarang,
        },
    ]);
  }
  await client.from('avoera_settings').upsert([barisData('main', _pengaturanAman(settings))]);

  // ---------- TARIK & GABUNG ----------
  Future<List<Map<String, dynamic>>> ambil(String tabel) async {
    final rows = await client.from(tabel).select('data').eq('business_key', kode);
    return [for (final r in rows) (r['data'] as Map).cast<String, dynamic>()];
  }

  final menuServer = [for (final j in await ambil('avoera_menus')) MenuItem.fromJson(j)];
  final bahanServer = [for (final j in await ambil('avoera_ingredients')) Ingredient.fromJson(j)];
  final cabangServer = [for (final j in await ambil('avoera_branches')) Branch.fromJson(j)];
  final txServer = [for (final j in await ambil('avoera_transactions')) TxRecord.fromJson(j)];
  final pengaturanRows = await ambil('avoera_settings');
  final pengaturanServer = pengaturanRows.isEmpty ? null : pengaturanRows.first;

  // Gabung per id: server menimpa lokal untuk id yang sama,
  // data lokal yang belum ada di server tetap dipertahankan.
  List<T> gabung<T>(List<T> lokal, List<T> server, String Function(T) idOf) {
    final hasil = <T>[...lokal];
    for (final s in server) {
      final idx = hasil.indexWhere((e) => idOf(e) == idOf(s));
      if (idx >= 0) {
        hasil[idx] = s;
      } else {
        hasil.add(s);
      }
    }
    return hasil;
  }

  final menuGabung = gabung(menus, menuServer, (m) => m.id);
  final bahanGabung = gabung(ingredients, bahanServer, (i) => i.id);
  final cabangGabung = gabung(branches, cabangServer, (b) => b.id);
  final txGabung = gabung(transactions, txServer, (t) => t.uuid.isEmpty ? t.id : t.uuid)
    ..sort((a, b) => a.at.compareTo(b.at));

  return HasilSinkron(
    menus: menuGabung,
    ingredients: bahanGabung,
    branches: cabangGabung,
    transactions: txGabung,
    pengaturanServer: pengaturanServer,
    ringkasan: 'Sinkron selesai: ${menuGabung.length} menu, ${bahanGabung.length} bahan, ${cabangGabung.length} cabang, ${txGabung.length} transaksi.',
  );
}
