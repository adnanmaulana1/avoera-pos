import 'package:supabase/supabase.dart';

import 'data.dart';
import 'struk.dart';

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

/// Id yang aman dihapus dari server (PERBAIKAN BUG 2026-11-15:
/// barang yang dihapus di HP BALIK LAGI sesudah sinkron, karena
/// unggah hanya upsert — tidak pernah menghapus baris server —
/// lalu tarik-gabung menganggapnya barang baru dan
/// mengembalikannya).
///
/// Aturannya: sebuah id server boleh dihapus HANYA bila perangkat
/// ini PERNAH mengenalnya (pernah terlihat pada sinkron
/// sebelumnya) DAN sekarang tidak ada lagi di daftar lokal —
/// artinya memang dihapus di perangkat ini. Id server yang belum
/// dikenal tidak disentuh: itu barang baru dari perangkat lain.
List<String> idHantuDiServer({required Set<String> idServer, required Set<String> idLokal, required Set<String> idDikenal}) =>
    idServer.intersection(idDikenal).difference(idLokal).toList();

/// Data "lainnya" yang ikut sinkron sejak v0.22.0 (permintaan
/// Adnan: SEMUA data harus masuk awan, termasuk yang kecil-kecil
/// seperti resep & bundle — resep/bundle sendiri adalah kolom di
/// dalam data menu, jadi sudah tersinkron sejak awal; yang baru
/// di sini adalah data yang sebelumnya hanya lokal).
///
/// Disimpan sebagai SATU baris blob id 'extras' di tabel
/// avoera_settings yang sudah ada — tanpa tabel baru di server.
/// Isinya: meja, promo, pengeluaran, hutang, mutasi stok, sesi
/// kasir, antrean dapur, desain struk, dan draf keranjang.
/// Notifikasi SENGAJA tidak ikut: isinya peringatan yang dibuat
/// otomatis di tiap perangkat dari datanya (datanya sendiri
/// sudah tersinkron, jadi peringatannya muncul sendiri).
class DataEkstra {
  DataEkstra({
    this.tables = const [],
    this.promos = const [],
    this.expenses = const [],
    this.hutang = const [],
    this.mutasi = const [],
    this.sesi = const [],
    this.dapur = const [],
    this.struk,
    this.draft,
  });

  final List<CafeTable> tables;
  final List<Promo> promos;
  final List<Pengeluaran> expenses;
  final List<Hutang> hutang;
  final List<MutasiStok> mutasi;
  final List<SesiKasir> sesi;
  final List<KitchenOrder> dapur;
  final DesainStruk? struk;
  final DraftKasir? draft;

  int get jumlah => tables.length + promos.length + expenses.length + hutang.length + mutasi.length + sesi.length + dapur.length;

  Map<String, dynamic> toJson() => {
        'tables': [for (final t in tables) t.toJson()],
        'promos': [for (final p in promos) p.toJson()],
        'expenses': [for (final e in expenses) e.toJson()],
        'hutang': [for (final h in hutang) h.toJson()],
        'mutasi': [for (final m in mutasi) m.toJson()],
        'sesi': [for (final s in sesi) s.toJson()],
        'dapur': [for (final d in dapur) d.toJson()],
        if (struk != null) 'struk': struk!.toJson(),
        if (draft != null) 'draft': draft!.toJson(),
      };

  static List<T> _daftar<T>(Map<String, dynamic> j, String kunci, T Function(Map<String, dynamic>) dari) {
    final mentah = j[kunci];
    if (mentah is! List) return <T>[];
    return [for (final e in mentah) if (e is Map) dari(e.cast<String, dynamic>())];
  }

  factory DataEkstra.fromJson(Map<String, dynamic> j) => DataEkstra(
        tables: _daftar(j, 'tables', CafeTable.fromJson),
        promos: _daftar(j, 'promos', Promo.fromJson),
        expenses: _daftar(j, 'expenses', Pengeluaran.fromJson),
        hutang: _daftar(j, 'hutang', Hutang.fromJson),
        mutasi: _daftar(j, 'mutasi', MutasiStok.fromJson),
        sesi: _daftar(j, 'sesi', SesiKasir.fromJson),
        dapur: _daftar(j, 'dapur', KitchenOrder.fromJson),
        struk: j['struk'] is Map ? DesainStruk.fromJson((j['struk'] as Map).cast<String, dynamic>()) : null,
        draft: j['draft'] is Map ? DraftKasir.fromJson((j['draft'] as Map).cast<String, dynamic>()) : null,
      );
}

/// Gabungan data ekstra (fungsi murni — bisa dites tanpa
/// jaringan). Per daftar: gabung per id, server menang untuk id
/// yang sama; lalu id HANTU dibuang (pernah dikenal perangkat
/// ini, sudah tidak ada di lokal = dihapus di sini, walau server
/// masih punya salinannya). Benda tunggal (desain struk & draf
/// keranjang): yang menang adalah sisi yang BERUBAH sejak
/// sinkron terakhir menurut bendera kotor dari shell — lokal
/// kotor berarti lokal menang; tidak kotor berarti server
/// menang bila punya (perubahan dari perangkat lain masuk).
DataEkstra gabungEkstra({
  required DataEkstra lokal,
  required DataEkstra server,
  required Map<String, Set<String>> dikenal,
  required bool strukKotor,
  required bool draftKotor,
}) {
  List<T> per<T>(String sub, List<T> lo, List<T> sv, String Function(T) idOf) {
    final hasil = <T>[...lo];
    for (final s in sv) {
      final i = hasil.indexWhere((e) => idOf(e) == idOf(s));
      if (i >= 0) {
        hasil[i] = s;
      } else {
        hasil.add(s);
      }
    }
    final hantu = idHantuDiServer(
      idServer: {for (final e in sv) idOf(e)},
      idLokal: {for (final e in lo) idOf(e)},
      idDikenal: dikenal['x:$sub'] ?? const <String>{},
    );
    if (hantu.isNotEmpty) hasil.removeWhere((e) => hantu.contains(idOf(e)));
    return hasil;
  }

  // Mutasi disimpan terbaru-di-depan (penulisnya insert(0, …)),
  // jadi hasil gabungan diurutkan menurun menurut waktu.
  final mutasi = per('mutasi', lokal.mutasi, server.mutasi, (m) => m.id)..sort((a, b) => b.waktu.compareTo(a.waktu));
  return DataEkstra(
    tables: per('tables', lokal.tables, server.tables, (t) => '${t.number}'),
    promos: per('promos', lokal.promos, server.promos, (p) => p.id),
    expenses: per('expenses', lokal.expenses, server.expenses, (e) => e.id),
    hutang: per('hutang', lokal.hutang, server.hutang, (h) => h.id),
    mutasi: mutasi,
    sesi: per('sesi', lokal.sesi, server.sesi, (s) => s.id),
    dapur: per('dapur', lokal.dapur, server.dapur, (d) => d.id),
    struk: strukKotor ? (lokal.struk ?? server.struk) : (server.struk ?? lokal.struk),
    draft: draftKotor ? (lokal.draft ?? server.draft) : (server.draft ?? lokal.draft),
  );
}

/// Keanggotaan id data ekstra sesudah gabungan — dicatat shell
/// sebagai dasar keputusan hantu pada sinkron berikutnya.
Map<String, Set<String>> dikenalEkstra(DataEkstra g) => {
      'x:tables': {for (final t in g.tables) '${t.number}'},
      'x:promos': {for (final p in g.promos) p.id},
      'x:expenses': {for (final e in g.expenses) e.id},
      'x:hutang': {for (final h in g.hutang) h.id},
      'x:mutasi': {for (final m in g.mutasi) m.id},
      'x:sesi': {for (final s in g.sesi) s.id},
      'x:dapur': {for (final d in g.dapur) d.id},
    };

class HasilSinkron {
  HasilSinkron({
    required this.menus,
    required this.ingredients,
    required this.branches,
    required this.transactions,
    required this.pengaturanServer,
    required this.ringkasan,
    required this.rincian,
    required this.dikenalBaru,
    this.extras,
  });
  final List<MenuItem> menus;
  final List<Ingredient> ingredients;
  final List<Branch> branches;
  final List<TxRecord> transactions;
  final Map<String, dynamic>? pengaturanServer;

  /// Data ekstra hasil gabungan (v0.22.0). Null bila tidak
  /// diminta, atau tarikan blob gagal (data lokal dibiarkan).
  final DataEkstra? extras;
  final String ringkasan;

  /// Hasil per tabel (untuk halaman Status Sinkronisasi):
  /// mana yang berhasil terkirim, mana yang gagal + sebabnya.
  final List<StatusTabel> rincian;

  /// Keanggotaan id per tabel SESUDAH gabungan sinkron ini —
  /// perangkat mengingatnya untuk membedakan 'dihapus di sini'
  /// dari 'baru dari perangkat lain' pada sinkron berikutnya.
  final Map<String, Set<String>> dikenalBaru;

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

/// Jahitan tes untuk Reset Total: bila diisi, dipakai
/// menggantikan penghapusan awan sungguhan (lingkungan tes
/// tidak punya jaringan). Produksi selalu null.
Future<void> Function(AppSettings settings)? jahitanHapusCloud;

/// Hapus SEMUA baris usaha ini di awan (Reset Total, v0.20.0):
/// transaksi, menu, bahan, cabang, dan pengaturan. Melempar
/// error bila ada tabel yang gagal dihapus — pemanggil
/// membatalkan reset lokal, supaya data tidak hilang setengah
/// (awan kosong tapi HP utuh akan mengunggah ulang semuanya).
Future<void> hapusSemuaDataCloud(AppSettings settings) async {
  final kode = settings.businessKey.trim();
  var url = settings.supabaseUrl.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  final client = SupabaseClient(
    url,
    settings.supabaseAnonKey.trim(),
    headers: {'x-business-key': kode},
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  try {
    for (final tabel in ['avoera_transactions', 'avoera_menus', 'avoera_ingredients', 'avoera_branches', 'avoera_settings']) {
      await client.from(tabel).delete().eq('business_key', kode);
    }
  } finally {
    await client.dispose();
  }
}

Future<HasilSinkron> sinkronkanSupabase({
  required AppSettings settings,
  required List<MenuItem> menus,
  required List<Ingredient> ingredients,
  required List<Branch> branches,
  required List<TxRecord> transactions,
  bool perbaruiSemua = false,
  Map<String, Set<String>> dikenal = const {},
  DataEkstra? extras,
  bool strukKotor = false,
  bool draftKotor = false,
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
      dikenal: dikenal,
      extras: extras,
      strukKotor: strukKotor,
      draftKotor: draftKotor,
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
  Map<String, Set<String>> dikenal = const {},
  DataEkstra? extras,
  bool strukKotor = false,
  bool draftKotor = false,
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

  // ---------- BERSIHKAN HANTU: baris server yang sudah
  // dihapus di perangkat ini dihapus juga dari server, SEBELUM
  // unggah & tarik — kalau tidak, gabungan akan
  // mengembalikannya (bug barang terhapus balik lagi).
  // Kegagalan di sini tidak membatalkan sinkron: hantu cukup
  // dibersihkan pada sinkron berikutnya.
  Future<void> bersihkanHantu(String kunci, String tabel, Set<String> idLokal) async {
    final dikenalTabel = dikenal[kunci] ?? const <String>{};
    if (dikenalTabel.isEmpty) return;
    try {
      final rows = await client.from(tabel).select('id').eq('business_key', kode);
      final idServer = {for (final r in rows) r['id'] as String};
      final hantu = idHantuDiServer(idServer: idServer, idLokal: idLokal, idDikenal: dikenalTabel);
      if (hantu.isNotEmpty) {
        await client.from(tabel).delete().eq('business_key', kode).inFilter('id', hantu);
      }
    } catch (e) {
      // Diamkan — dicoba lagi pada sinkron berikutnya.
      // ignore: avoid_print
      print('Bersihkan hantu $tabel gagal: $e');
    }
  }

  // Cabang TIDAK dibersihkan dengan aturan umum "dikenal tapi
  // tidak lokal": itu pernah menghapus baris cabang di server
  // dan memutus transaksinya (kejadian 2026-11-17). Sejak
  // v0.24.0 cabang bisa SENGAJA dihapus pengguna — baris
  // servernya dibersihkan lewat daftar penanda hapus
  // (cabangTerhapus), hanya untuk id yang memang ditandai DAN
  // pernah dikenal perangkat ini.
  await bersihkanHantu('menus', 'avoera_menus', {for (final m in menus) m.id});
  await bersihkanHantu('ingredients', 'avoera_ingredients', {for (final i in ingredients) i.id});
  final dikenalCabang = dikenal['branches'] ?? const <String>{};
  if (settings.cabangTerhapus.isNotEmpty && dikenalCabang.isNotEmpty) {
    try {
      final rows = await client.from('avoera_branches').select('id').eq('business_key', kode);
      final idServer = {for (final r in rows) r['id'] as String};
      final target = idServer.intersection(settings.cabangTerhapus.toSet()).intersection(dikenalCabang).toList();
      if (target.isNotEmpty) {
        await client.from('avoera_branches').delete().eq('business_key', kode).inFilter('id', target);
      }
    } catch (e) {
      // Diamkan — dicoba lagi pada sinkron berikutnya.
      // ignore: avoid_print
      print('Bersihkan cabang terhapus gagal: $e');
    }
  }

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
  Future<List<Map<String, dynamic>>?> ambil(String kunci, String tabel, {String? idSaja}) async {
    try {
      var tanya = client.from(tabel).select('data').eq('business_key', kode);
      final rows = idSaja == null ? await tanya : await tanya.eq('id', idSaja);
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
  // Baris pengaturan WAJIB disaring id 'main': sejak v0.22.0
  // tabel yang sama juga menyimpan baris blob 'extras', dan
  // mengambil baris pertama tanpa saringan bisa tertukar.
  // Ditarik SEBELUM gabungan cabang karena penanda cabang
  // terhapus (v0.24.0) ikut menentukan hasil gabungan.
  final pengaturanJson = await ambil('settings', 'avoera_settings', idSaja: 'main');
  final pengaturanServer = (pengaturanJson == null || pengaturanJson.isEmpty) ? null : pengaturanJson.first;
  final cabangJson = await ambil('branches', 'avoera_branches');
  final cabangGabung = cabangJson == null ? branches : gabung(branches, [for (final j in cabangJson) Branch.fromJson(j)], (b) => b.id);
  final txJson = await ambil('transactions', 'avoera_transactions');
  final txGabung = txJson == null
      ? transactions
      : (gabung(transactions, [for (final j in txJson) TxRecord.fromJson(j)], (t) => t.uuid.isEmpty ? t.id : t.uuid)
        ..sort((a, b) => a.at.compareTo(b.at)));

  // Penanda cabang terhapus = gabungan penanda lokal + server
  // (penanda hanya boleh bertambah). Cabang berpenanda disaring
  // keluar dari hasil gabungan di semua perangkat.
  final terhapusSet = <String>{
    ...settings.cabangTerhapus,
    ...((pengaturanServer?['cabangTerhapus'] as List?)?.map((e) => e.toString()) ?? const <String>[]),
  };
  final cabangTersaring = [for (final b in cabangGabung) if (!terhapusSet.contains(b.id)) b];
  // Cabang yatim: transaksi hasil gabungan yang cabangnya tidak ada
  // di daftar cabang → cabangnya dibuatkan lagi dengan id yang sama,
  // supaya transaksi itu nyambung dan cabangnya bisa dipakai lagi.
  // Cabang berpenanda hapus TIDAK dipulihkan.
  final cabangFinal = pulihkanCabangYatim(cabangTersaring, txGabung, terhapus: terhapusSet);

  // ---------- DATA LAINNYA (v0.22.0): meja, promo,
  // pengeluaran, hutang, mutasi, sesi, dapur, desain struk &
  // draf keranjang — satu baris blob id 'extras' di tabel
  // pengaturan. Alurnya beda dari tabel utama: TARIK DULU,
  // gabung di sini, lalu unggah hasil gabungan. Mengunggah
  // lokal lebih dulu akan menimpa blob perangkat lain sebelum
  // sempat digabung. Tarikan gagal = bagian ini gagal dan data
  // lokal dibiarkan (tidak ada unggahan buta).
  DataEkstra? ekstraGabung;
  final ekstraDikenal = <String, Set<String>>{};
  if (extras != null) {
    try {
      final rows = await client.from('avoera_settings').select('data').eq('business_key', kode).eq('id', 'extras');
      final serverJson = rows.isEmpty ? null : (rows.first['data'] as Map).cast<String, dynamic>();
      final server = serverJson == null ? DataEkstra() : DataEkstra.fromJson(serverJson);
      final gab = gabungEkstra(lokal: extras, server: server, dikenal: dikenal, strukKotor: strukKotor, draftKotor: draftKotor);
      ekstraGabung = gab;
      try {
        await client.from('avoera_settings').upsert([barisData('extras', gab.toJson())]);
        catat('extras', 'Data Lainnya', true, gab.jumlah);
        ekstraDikenal.addAll(dikenalEkstra(gab));
      } catch (e) {
        catat('extras', 'Data Lainnya', false, 0, e);
      }
    } catch (e) {
      catat('extras', 'Data Lainnya', false, 0, e);
    }
  }

  // ---------- PERBARUI SEMUA: hasil gabungan diunggah sekali
  // lagi, supaya server persis mencerminkan keadaan gabungan
  // terakhir (permintaan Adnan: tombol 'Perbarui Semua Data').
  if (perbaruiSemua) {
    await unggah('branches', 'Cabang', 'avoera_branches', [for (final b in cabangFinal) barisData(b.id, b.toJson())]);
    await unggah('menus', 'Menu', 'avoera_menus', [for (final m in menuGabung) barisData(m.id, m.toJson())]);
    await unggah('ingredients', 'Bahan', 'avoera_ingredients', [for (final i in bahanGabung) barisData(i.id, i.toJson())]);
    await unggah('transactions', 'Transaksi', 'avoera_transactions', barisTx(txGabung));
  }

  // Keanggotaan baru = id hasil gabungan per tabel.
  final dikenalBaru = <String, Set<String>>{
    'menus': {for (final m in menuGabung) m.id},
    'ingredients': {for (final i in bahanGabung) i.id},
    'branches': {for (final b in cabangFinal) b.id},
    ...ekstraDikenal,
  };

  final daftar = rincian.values.toList();
  final gagal = daftar.where((r) => !r.berhasil).length;
  return HasilSinkron(
    menus: menuGabung,
    ingredients: bahanGabung,
    branches: cabangFinal,
    transactions: txGabung,
    pengaturanServer: pengaturanServer,
    extras: ekstraGabung,
    rincian: daftar,
    dikenalBaru: dikenalBaru,
    ringkasan: gagal == 0
        ? 'Sinkron selesai: ${menuGabung.length} menu, ${bahanGabung.length} bahan, ${cabangFinal.length} cabang, ${txGabung.length} transaksi${extras != null ? ', ${ekstraGabung?.jumlah ?? 0} data lainnya' : ''}.'
        : 'Sinkron belum tuntas: $gagal dari ${daftar.length} bagian gagal — rincian di Status Sinkronisasi.',
  );
}
