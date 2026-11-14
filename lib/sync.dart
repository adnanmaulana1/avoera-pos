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

/// Ubah error sinkron mentah menjadi sebab singkat yang bisa dibaca
/// pemilik di layar (permintaan Adnan 2026-11-14: pesan "periksa URL,
/// kunci, internet" tidak membantu — sebut sebab aslinya).
String ringkasErrorSinkron(Object e) {
  if (e is PostgrestException) {
    final kode = (e.code ?? '').trim();
    final pesan = e.message.trim();
    return kode.isEmpty ? pesan : '$pesan (kode $kode)';
  }
  if (e.toString().contains('TimeoutException')) {
    return 'server terlalu lama menjawab — periksa koneksi internet, lalu coba lagi.';
  }
  final s = e.toString();
  if (s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('ClientException')) {
    return 'tidak bisa menjangkau server Supabase — periksa koneksi internet & alamat URL proyek.';
  }
  if (s.contains('Invalid argument') || s.contains('FormatException')) {
    return 'format URL proyek tidak sah — harus berbentuk https://xxxx.supabase.co.';
  }
  return s.length > 140 ? '${s.substring(0, 140)}…' : s;
}

class HasilSinkron {
  HasilSinkron({
    required this.menus,
    required this.ingredients,
    required this.branches,
    required this.transactions,
    required this.pengaturanServer,
    required this.ringkasan,
    required this.rincian,
  });
  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final List<Branch> branches;
  final List<TxRecord> transactions;
  final Map<String, dynamic>? pengaturanServer;
  final String ringkasan;

  /// Hasil per tabel (untuk halaman Status Sinkronisasi):
  /// mana yang berhasil terkirim, mana yang gagal + sebabnya.
  final List<StatusTabel> rincian;

  bool get adaGagal => rincian.any((r) => !r.berhasil);
}

/// Nasib satu tabel dalam sekali sinkron.
class StatusTabel {
  StatusTabel({required this.kunci, required this.label, required this.berhasil, required this.jumlah, this.galat});
  final String kunci;
  final String label;
  bool berhasil;
  int jumlah;
  String? galat;

  Map<String, dynamic> toJson() => {'kunci': kunci, 'label': label, 'berhasil': berhasil, 'jumlah': jumlah, 'galat': galat};
  factory StatusTabel.fromJson(Map<String, dynamic> j) => StatusTabel(
        kunci: j['kunci'] as String,
        label: j['label'] as String? ?? '',
        berhasil: j['berhasil'] as bool? ?? false,
        jumlah: (j['jumlah'] as num?)?.toInt() ?? 0,
        galat: j['galat'] as String?,
      );
}

Map<String, dynamic> _pengaturanAman(AppSettings s) {
  final j = s.toJson();
  // Jangan unggah rahasia & data khusus perangkat ini.
  for (final k in [
    'pinHash',
    'supabaseUrl',
    'supabaseAnonKey',
    'businessKey',
    'lastSyncLabel',
    'modeTema',
    'branches',
    'activeBranchId',
    'backendBawaanDitanam',
    'businessPhotoPath',
    'cloudSyncEnabled',
  ]) {
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
  bool perbaruiSemua = false,
}) async {
  final kode = settings.businessKey.trim();
  // Jaring pengaman kedua (selain pembersihan saat disimpan):
  // URL dibersihkan dari spasi & garis miring ujung, kunci dari spasi.
  var url = settings.supabaseUrl.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  final client = SupabaseClient(
    url,
    settings.supabaseAnonKey.trim(),
    headers: {'x-business-key': kode},
    // Aplikasi ini TIDAK memakai login Supabase (kunci anon saja),
    // jadi matikan auto-refresh auth: menyalakannya membuat timer
    // berkala yang tidak pernah berhenti (bocor + mengganggu tes).
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  try {
    return await _kerjakanSinkron(
      client,
      kode: kode,
      settings: settings,
      menus: menus,
      ingredients: ingredients,
      branches: branches,
      transactions: transactions,
      perbaruiSemua: perbaruiSemua,
    );
  } finally {
    // WAJIB dibuang: SupabaseClient menyalakan timer auto-refresh
    // auth di konstruktornya — tanpa dispose, timer itu hidup
    // selamanya (bocor di produksi, menggagalkan tes widget).
    await client.dispose();
  }
}

Future<HasilSinkron> _kerjakanSinkron(
  SupabaseClient client, {
  required String kode,
  required AppSettings settings,
  required List<MenuItem> menus,
  required List<Ingredient> ingredients,
  required List<Branch> branches,
  required List<TxRecord> transactions,
  bool perbaruiSemua = false,
}) async {
  final sekarang = DateTime.now().toUtc().toIso8601String();
  final rincian = <String, StatusTabel>{};

  void catat(String kunci, String label, bool ok, int jumlah, [Object? e]) {
    rincian[kunci] = StatusTabel(
      kunci: kunci,
      label: label,
      berhasil: ok,
      jumlah: jumlah,
      galat: e == null ? null : ringkasErrorSinkron(e),
    );
  }

  Map<String, dynamic> barisData(String id, Map<String, dynamic> data) => {
        'business_key': kode,
        'id': id,
        'data': data,
        'updated_at': sekarang,
      };

  // ---------- UNGGAH (per tabel dijaga sendiri-sendiri: satu
  // tabel gagal tidak membatalkan tabel lain, dan kegagalannya
  // tercatat untuk halaman Status Sinkronisasi) ----------
  Future<void> unggah(String kunci, String label, String tabel, List<Map<String, dynamic>> baris, {bool walauKosong = false}) async {
    if (baris.isEmpty && !walauKosong) {
      catat(kunci, label, true, 0);
      return;
    }
    try {
      await client.from(tabel).upsert(baris);
      catat(kunci, label, true, baris.length);
    } catch (e) {
      catat(kunci, label, false, 0, e);
    }
  }

  List<Map<String, dynamic>> barisTx(List<TxRecord> txs) => [
        for (final t in txs)
          {
            'business_key': kode,
            'uuid': t.uuid.isEmpty ? t.id : t.uuid,
            'at': t.at.toUtc().toIso8601String(),
            'data': t.toJson(),
            'updated_at': sekarang,
          },
      ];

  await unggah('branches', 'Cabang', 'avoera_branches', [for (final b in branches) barisData(b.id, b.toJson())]);
  await unggah('menus', 'Menu', 'avoera_menus', [for (final m in menus) barisData(m.id, m.toJson())]);
  await unggah('ingredients', 'Bahan', 'avoera_ingredients', [for (final i in ingredients) barisData(i.id, i.toJson())]);
  await unggah('transactions', 'Transaksi', 'avoera_transactions', barisTx(transactions));
  await unggah('settings', 'Pengaturan', 'avoera_settings', [barisData('main', _pengaturanAman(settings))], walauKosong: true);

  // ---------- TARIK & GABUNG (per tabel juga dijaga: tarik yang
  // gagal memakai data lokal apa adanya) ----------
  Future<List<Map<String, dynamic>>?> ambil(String kunci, String tabel) async {
    try {
      final rows = await client.from(tabel).select('data').eq('business_key', kode);
      return [for (final r in rows) (r['data'] as Map).cast<String, dynamic>()];
    } catch (e) {
      final lama = rincian[kunci];
      if (lama != null && lama.berhasil) {
        lama.berhasil = false;
        lama.galat = ringkasErrorSinkron(e);
      }
      return null;
    }
  }

  List<T> gabung<T>(List<T> lokal, List<T> server, String Function(T) idOf) {
    final hasil = <T>[...lokal];
    for (final sv in server) {
      final idx = hasil.indexWhere((e) => idOf(e) == idOf(sv));
      if (idx >= 0) {
        hasil[idx] = sv;
      } else {
        hasil.add(sv);
      }
    }
    return hasil;
  }

  final menuJson = await ambil('menus', 'avoera_menus');
  final menuGabung = menuJson == null ? menus : gabung(menus, [for (final j in menuJson) MenuItem.fromJson(j)], (m) => m.id);
  final bahanJson = await ambil('ingredients', 'avoera_ingredients');
  final bahanGabung = bahanJson == null ? ingredients : gabung(ingredients, [for (final j in bahanJson) Ingredient.fromJson(j)], (i) => i.id);
  final cabangJson = await ambil('branches', 'avoera_branches');
  final cabangGabung = cabangJson == null ? branches : gabung(branches, [for (final j in cabangJson) Branch.fromJson(j)], (b) => b.id);
  final txJson = await ambil('transactions', 'avoera_transactions');
  final txGabung = txJson == null
      ? transactions
      : (gabung(transactions, [for (final j in txJson) TxRecord.fromJson(j)], (t) => t.uuid.isEmpty ? t.id : t.uuid)
        ..sort((a, b) => a.at.compareTo(b.at)));
  final pengaturanJson = await ambil('settings', 'avoera_settings');
  final pengaturanServer = (pengaturanJson == null || pengaturanJson.isEmpty) ? null : pengaturanJson.first;

  // ---------- PERBARUI SEMUA: hasil gabungan diunggah sekali
  // lagi, supaya server persis mencerminkan keadaan gabungan
  // terakhir (permintaan Adnan: tombol 'Perbarui Semua Data').
  if (perbaruiSemua) {
    await unggah('branches', 'Cabang', 'avoera_branches', [for (final b in cabangGabung) barisData(b.id, b.toJson())]);
    await unggah('menus', 'Menu', 'avoera_menus', [for (final m in menuGabung) barisData(m.id, m.toJson())]);
    await unggah('ingredients', 'Bahan', 'avoera_ingredients', [for (final i in bahanGabung) barisData(i.id, i.toJson())]);
    await unggah('transactions', 'Transaksi', 'avoera_transactions', barisTx(txGabung));
  }

  final daftar = rincian.values.toList();
  final gagal = daftar.where((r) => !r.berhasil).length;
  return HasilSinkron(
    menus: menuGabung,
    ingredients: bahanGabung,
    branches: cabangGabung,
    transactions: txGabung,
    pengaturanServer: pengaturanServer,
    rincian: daftar,
    ringkasan: gagal == 0
        ? 'Sinkron selesai: ${menuGabung.length} menu, ${bahanGabung.length} bahan, ${cabangGabung.length} cabang, ${txGabung.length} transaksi.'
        : 'Sinkron belum tuntas: $gagal dari ${daftar.length} bagian gagal — rincian di Status Sinkronisasi.',
  );
}
