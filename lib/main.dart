import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'update.dart';
import 'backend_bawaan.dart';
import 'store.dart';
import 'sync.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens/beranda_screen.dart';
import 'screens/kasir_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/notifikasi_screen.dart';
import 'screens/laporan_detail_screens.dart';
import 'screens/onboarding_screen.dart';
import 'screens/meja_screen.dart';
import 'screens/dapur_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/stok_screen.dart';
import 'screens/pengaturan_screen.dart';
import 'screens/kelola_menu_screen.dart';
import 'screens/kelola_meja_screen.dart';
import 'screens/kelola_stok_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/branch_wizard_screen.dart';
import 'screens/profil_usaha_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/status_sinkron_screen.dart';
import 'screens/laba_rugi_screen.dart';
import 'screens/gudang_screen.dart';
import 'screens/neraca_screen.dart';
import 'screens/arus_kas_screen.dart';
import 'screens/arus_stok_screen.dart';
import 'screens/persediaan_screen.dart';
import 'screens/pembelian_screen.dart';
import 'screens/hutang_screen.dart';
import 'screens/promo_screen.dart';
import 'screens/margin_tipis_screen.dart';
import 'screens/pengunjung_screen.dart';
import 'screens/sesi_kasir_screen.dart';
import 'screens/struk_screen.dart';
import 'screens/desain_struk_screen.dart';
import 'struk.dart';
import 'printer.dart';
import 'package:avoera_pos/ikon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Layar penuh dari ujung ke ujung, TAPI status bar & tombol navigasi
  // Android tetap terlihat. Isi aplikasi dijaga SafeArea di HomeShell
  // supaya tidak ada konten yang tertutup kedua bar itu.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KasirFnbApp());
}

class KasirFnbApp extends StatefulWidget {
  const KasirFnbApp({super.key});

  @override
  State<KasirFnbApp> createState() => _KasirFnbAppState();
}

class _KasirFnbAppState extends State<KasirFnbApp> {
  /// Pilihan tema dari Pengaturan: 'terang' | 'gelap' | 'sistem'.
  /// Keadaan awal sebelum data termuat = terang, sama dengan
  /// bawaan pemasangan pertama di AppSettings.
  String _modeTema = 'terang';

  /// Kunci RepaintBoundary akar tampilan — sumber tangkapan gambar
  /// tema lama untuk animasi iris.
  final GlobalKey _akarKey = GlobalKey();

  /// Tangkapan tampilan tema LAMA selama animasi iris berjalan;
  /// null = tidak ada animasi.
  ui.Image? _gambarTemaLama;

  /// Titik pusat iris (dari ketukan tombol tema); null = fallback.
  Offset? _pusatIris;

  /// Penjaga supaya tangkapan tidak tumpang tindih.
  bool _irisBerjalan = false;

  bool _gelapEfektif(String mode, Brightness platform) => switch (mode) {
        'gelap' => true,
        'terang' => false,
        _ => platform == Brightness.dark,
      };

  /// Dipanggil HomeShell: sesudah data dimuat (terapkan tanpa
  /// animasi) dan tiap pemilik mengganti pilihan tema (animasi).
  Future<void> _temaBerubah(String mode, {required bool animasi, required Brightness platform}) async {
    if (mode == _modeTema) return;
    final berubahNyata = _gelapEfektif(mode, platform) != _gelapEfektif(_modeTema, platform);
    if (!animasi || !berubahNyata || _irisBerjalan) {
      setState(() => _modeTema = mode);
      return;
    }
    // Metode iris: tangkap dulu tampilan tema LAMA, baru ganti
    // tema. Tema baru langsung terpasang di bawah; gambar lama
    // di-clip lingkaran membesar oleh AnimasiIrisTema.
    _irisBerjalan = true;
    ui.Image? gambar;
    try {
      final batas = _akarKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      gambar = await batas?.toImage(pixelRatio: 1.5);
    } catch (_) {
      gambar = null; // tangkapan gagal → ganti tema tanpa animasi
    }
    if (!mounted) {
      gambar?.dispose();
      _irisBerjalan = false;
      return;
    }
    if (gambar == null) {
      _irisBerjalan = false;
      setState(() => _modeTema = mode);
      return;
    }
    setState(() {
      _modeTema = mode;
      _gambarTemaLama = gambar;
      _pusatIris = AnimasiIrisTema.pusatDariKetukan;
      AnimasiIrisTema.pusatDariKetukan = null;
    });
  }

  /// Animasi iris selesai (atau overlay dibuang di tengah):
  /// bersihkan gambar lama dari state & memori.
  void _irisSelesai() {
    if (!mounted || _gambarTemaLama == null) return;
    final gambar = _gambarTemaLama;
    setState(() {
      _gambarTemaLama = null;
      _pusatIris = null;
      _irisBerjalan = false;
    });
    gambar?.dispose();
  }

  @override
  void dispose() {
    _gambarTemaLama?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final gelap = _gelapEfektif(_modeTema, platform);
    AppColors.gelap = gelap;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: gelap ? Brightness.light : Brightness.dark,
        statusBarBrightness: gelap ? Brightness.dark : Brightness.light,
        // Warna navbar Android = warna latar aplikasi tema aktif,
        // supaya tidak ada pita putih asing di bawah (edge-to-edge
        // tetap: ikon navbar digambar di atas warna ini).
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: gelap ? Brightness.light : Brightness.dark,
      ),
    );
    return MaterialApp(
      title: 'Avorea POS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: switch (_modeTema) {
        'gelap' => ThemeMode.dark,
        'terang' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      home: Stack(
        children: [
          // Akar tampilan dibungkus RepaintBoundary: dari sinilah
          // gambar tema lama ditangkap sebelum tema diganti.
          RepaintBoundary(
            key: _akarKey,
            child: HomeShell(
              onModeTema: (mode, animasi) => _temaBerubah(mode, animasi: animasi, platform: platform),
            ),
          ),
          if (_gambarTemaLama != null)
            Positioned.fill(
              child: AnimasiIrisTema(
                gambarLama: _gambarTemaLama!,
                pusat: _pusatIris,
                onSelesai: _irisSelesai,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _navItems = <_NavItem>[
  _NavItem('Beranda', Ikon.home_outlined, Ikon.home),
  _NavItem('Kasir', Ikon.point_of_sale_outlined, Ikon.point_of_sale),
  _NavItem('Produk', Ikon.inventory_2_outlined, Ikon.inventory_2),
  _NavItem('Meja', Ikon.table_restaurant_outlined, Ikon.table_restaurant),
  _NavItem('Dapur', Ikon.soup_kitchen_outlined, Ikon.soup_kitchen),
  _NavItem('Laporan', Ikon.bar_chart_outlined, Ikon.bar_chart),
  _NavItem('Stok Bahan', Ikon.inventory_outlined, Ikon.inventory),
  _NavItem('Pengaturan', Ikon.settings_outlined, Ikon.settings),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onModeTema});

  /// Lapor perubahan pilihan tema ke KasirFnbApp (yang memegang
  /// MaterialApp): (mode, pakaiAnimasiIris).
  final void Function(String mode, bool animasi) onModeTema;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  final List<CartItem> _cart = [];
  List<KitchenOrder> _kitchen = seedKitchenOrders();
  CafeTable? _selectedTable;
  int _orderCounter = 1043;

  /// Draf kasir berjalan (v0.16.0): jenis pesanan + promo
  /// terpilih tinggal di layar Kasir, induk memegang salinannya
  /// di sini untuk disimpan ke disk bersama isi keranjang.
  String _draftJenis = 'Dine-in';
  String? _draftPromoId;

  /// Gerbang PIN kasir: terbuka sekali per sesi aplikasi.
  bool _kasirUnlocked = false;

  /// Animasi perayaan sesudah wizard pertama selesai.
  bool _celebrate = false;

  // ---------- Sinkronisasi awan (Supabase) ----------
  StatusSinkron _syncStatus = StatusSinkron.belumDiatur;
  bool _syncing = false;

  /// Reset Total sedang berjalan (v0.20.0): sinkron dibekukan
  /// supaya unggahan lama tidak menimpa penghapusan awan dan
  /// hasil gabungan lama tidak diterapkan ke data yang baru
  /// direset.
  bool _resetBerlangsung = false;
  Timer? _syncDebounce;
  Timer? _syncPeriodik;
  Timer? _syncTimeoutTimer;

  bool get _syncSiap => _settings.supabaseUrl.isNotEmpty && _settings.supabaseAnonKey.isNotEmpty && _settings.businessKey.isNotEmpty;

  /// Laporan sinkron terakhir per tabel + jumlah perubahan yang
  /// menunggu per tabel — bahan halaman Status Sinkronisasi.
  List<StatusTabel> _laporanSinkron = [];
  final Map<String, int> _kotor = {'menus': 0, 'ingredients': 0, 'branches': 0, 'transactions': 0, 'settings': 0, 'extras': 0};

  /// Id per tabel yang PERNAH terlihat perangkat ini (untuk
  /// membedakan barang yang dihapus di sini dari barang baru
  /// perangkat lain saat sinkron — lihat idHantuDiServer).
  /// Kunci 'x:' = sub-daftar data ekstra (v0.22.0).
  final Map<String, Set<String>> _dikenal = {
    'menus': {},
    'ingredients': {},
    'branches': {},
    'x:tables': {},
    'x:promos': {},
    'x:expenses': {},
    'x:hutang': {},
    'x:mutasi': {},
    'x:sesi': {},
    'x:dapur': {},
  };

  /// Bendera benda tunggal data ekstra (v0.22.0): true berarti
  /// desain struk / draf keranjang di perangkat INI berubah
  /// sejak sinkron terakhir yang berhasil — penentu sisi mana
  /// yang menang saat gabungan (lihat gabungEkstra). Ikut
  /// disimpan di meta sinkron supaya selamat dari mulai ulang.
  bool _strukKotor = false;
  bool _draftKotor = false;

  /// Sudah pernah ada sinkron yang tuntas (berhasil/gagal)
  /// selama aplikasi berjalan — dipakai wizard awal untuk
  /// memutuskan perlu menunggu sinkron atau tidak.
  bool _pernahSinkron = false;
  final ValueNotifier<int> _penandaSinkron = ValueNotifier<int>(0);

  /// Cloud Sync benar-benar jalan hanya bila diatur DAN saklarnya
  /// menyala (permintaan Adnan 2026-11-15).
  bool get _cloudAktif => _syncSiap && _settings.cloudSyncEnabled;

  // ---------- Pemberitahuan (tersimpan) ----------
  List<AppNotification> _notifications = [];
  List<MutasiStok> _mutasi = [];

  // ---------- Pengeluaran operasional (Laba Rugi) ----------
  List<Pengeluaran> _expenses = [];

  // ---------- Hutang & Promo (update besar v0.11.0) ----------
  List<Hutang> _hutang = [];
  List<Promo> _promos = [];

  // ---------- Sesi Kasir (v0.15.0) ----------
  List<SesiKasir> _sesi = [];

  /// Sesi yang sedang terbuka untuk cabang aktif (null = kasir
  /// belum dibuka). Penjualan tidak pernah diblokir ini.
  SesiKasir? get _sesiTerbuka => _sesi.where((s) => s.terbuka && s.branchId == _settings.activeBranchId).firstOrNull;

  // ---------- Desain struk & printer (v0.15.0) ----------
  DesainStruk _desainStruk = DesainStruk();
  final Map<String, double> _stokDikenal = {};
  int get _belumDibaca => _notifications.where((n) => !n.dibaca).length;

  /// Layar sambut brand: tampil selama data dimuat + sekejap
  /// sesudahnya (1500 mdtk) supaya logo sempat terlihat.
  bool _splashSelesai = false;

  /// Tekan-kembali ganda untuk keluar (hanya di Beranda).
  DateTime? _lastBackPress;
  final _phoneScaffoldKey = GlobalKey<ScaffoldState>();

  // ---------- Data tersimpan (dimuat dari LocalStore) ----------
  bool _ready = false;
  List<MenuItem> _menus = [];
  List<CafeTable> _tables = [];
  List<Ingredient> _ingredients = [];
  AppSettings _settings = AppSettings();
  List<TxRecord> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _splashSelesai = true);
        _tawarkanUpdate();
      }
    });
    // Penjaga tawaran pembaruan: mencoba lagi berkala —
    // tawaran hanya tampil bila semua syaratnya pas (Beranda
    // aktif, splash selesai, versi belum pernah ditawarkan).
    _timerTawaran = Timer.periodic(const Duration(seconds: 20), (_) => _tawarkanUpdate());
    _loadData();
  }

  /// Aplikasi kembali ke depan → periksa pembaruan lagi
  /// (paling sering 5 menit sekali): rilis yang terbit saat
  /// aplikasi sedang terbuka tetap tertangkap tanpa mulai
  /// ulang (v0.10.12).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final terakhir = _cekUpdateTerakhir;
    if (terakhir == null || DateTime.now().difference(terakhir) > const Duration(minutes: 5)) {
      _cekUpdateOtomatis();
    }
  }

  Future<void> _loadData() async {
    final data = await LocalStore.load();
    _desainStruk = await LocalStore.loadStruk();
    final draft = await LocalStore.loadDraftKasir();
    if (!mounted) return;
    setState(() {
      _menus = data.menus;
      _tables = data.tables;
      _ingredients = data.ingredients;
      _settings = data.settings;
      // Migrasi backend bawaan (sekali jalan): tanam nilai
      // Supabase usaha ini ke pengaturan, menimpa isian lama —
      // isian manual kemarin terbukti meleset & bikin sinkron
      // gagal terus. Sesudah ini kolom Pengaturan yang menang.
      if (!_settings.backendBawaanDitanam) {
        _settings.supabaseUrl = kSupabaseUrlBawaan;
        _settings.supabaseAnonKey = kSupabaseAnonKeyBawaan;
        _settings.businessKey = kKodeUsahaBawaan;
        _settings.backendBawaanDitanam = true;
        LocalStore.saveSettings(_settings);
      }
      // Ganti nama Avoera → Avorea (permintaan Adnan
      // 2026-11-17): nama usaha yang MASIH bawaan lama persis
      // ikut diganti; nama yang sudah diubah pemilik sendiri
      // tidak disentuh.
      if (_settings.businessName == 'Avoera Cafe & Resto') {
        _settings.businessName = 'Avorea Cafe & Resto';
        LocalStore.saveSettings(_settings);
      }
      _transactions = data.transactions;
      _notifications = data.notifications;
      _mutasi = data.mutasi;
      _expenses = data.expenses;
      _hutang = data.hutang;
      _promos = data.promos;
      _sesi = data.sesi;
      _kitchen = data.dapur;
      // Pulihkan draf kasir (v0.16.0): keranjang yang belum
      // dibayar, meja terpilih, nomor urut, jenis & promo —
      // supaya pesanan tidak hilang bila aplikasi tertutup
      // paksa. Baris yang menunya sudah dihapus dibuang.
      _draftJenis = draft.jenis;
      _draftPromoId = draft.promoId;
      _orderCounter = draft.counter;
      _cart
        ..clear()
        ..addAll([
          for (final b in draft.items)
            if (_menus.any((m) => m.id == b.menuId))
              CartItem(menu: _menus.firstWhere((m) => m.id == b.menuId), variant: b.variant, note: b.note, qty: b.qty, unitPrice: b.unitPrice),
        ]);
      _selectedTable = draft.nomorMeja == null ? null : _tables.where((t) => t.number == draft.nomorMeja).firstOrNull;
      _stokDikenal
        ..clear()
        ..addAll({for (final i in _ingredients) i.id: i.stock});
      _ready = true;
      _syncStatus = _cloudAktif ? StatusSinkron.tersinkron : StatusSinkron.belumDiatur;
    });
    // Meta pembaruan: versi tertinggi yang sudah pernah
    // ditawarkan otomatis (tawaran hanya sekali per versi).
    final metaUpdate = await LocalStore.loadUpdateMeta();
    _kodeTawaranTerakhir = (metaUpdate['tawaranKode'] as num?)?.toInt() ?? 0;
    // Kunci episode pemberitahuan yang sedang berjalan.
    _kunciNotifAktif = await LocalStore.loadKunciNotif();
    // Migrasi: pemberitahuan lama di daftar (stok & pembaruan)
    // dianggap episode berjalan, supaya tidak lahir lagi
    // sebagai belum dibaca pada pemeriksaan pertama.
    var kunciBerubah = false;
    for (final n in _notifications) {
      if ((n.jenis == 'stok' || n.kunci.startsWith('update-')) && _kunciNotifAktif.add(n.kunci)) kunciBerubah = true;
    }
    if (kunciBerubah) LocalStore.saveKunciNotif(_kunciNotifAktif);
    // Meta sinkron tersimpan (menunggu + laporan terakhir).
    final meta = await LocalStore.loadSyncMeta();
    if (mounted) {
      final k = (meta['kotor'] as Map?)?.cast<String, dynamic>();
      if (k != null) {
        k.forEach((kunci, v) {
          if (_kotor.containsKey(kunci)) _kotor[kunci] = (v as num?)?.toInt() ?? 0;
        });
      }
      final d = (meta['dikenal'] as Map?)?.cast<String, dynamic>();
      if (d != null) {
        d.forEach((kunci, v) {
          if (_dikenal.containsKey(kunci) && v is List) {
            _dikenal[kunci] = {for (final e in v) e.toString()};
          }
        });
      }
      final lap = meta['laporan'] as List?;
      if (lap != null) {
        _laporanSinkron = lap.map((e) => StatusTabel.fromJson((e as Map).cast<String, dynamic>())).toList();
      }
      _strukKotor = meta['strukKotor'] as bool? ?? false;
      _draftKotor = meta['draftKotor'] as bool? ?? false;
      _penandaSinkron.value++;
    }
    widget.onModeTema(_settings.modeTema, false);
    _aturTimerSinkron();
    _periksaStokNotifikasi();
    _cekUpdateOtomatis();
    if (_cloudAktif) _syncNow(diam: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerTawaran?.cancel();
    _syncDebounce?.cancel();
    _syncPeriodik?.cancel();
    _syncTimeoutTimer?.cancel();
    _penandaSinkron.dispose();
    _tarikProgres.dispose();
    _tarikSiap.dispose();
    super.dispose();
  }

  /// Timer tarik-berkala: selama aplikasi terbuka & sinkron
  /// diatur, data dari perangkat lain ditarik tiap 45 detik.
  void _aturTimerSinkron() {
    _syncPeriodik?.cancel();
    _syncPeriodik = null;
    if (_cloudAktif) {
      _syncPeriodik = Timer.periodic(const Duration(seconds: 45), (_) => _syncNow(diam: true));
    }
    if (mounted) setState(() => _syncStatus = _cloudAktif ? (_syncStatus == StatusSinkron.belumDiatur ? StatusSinkron.tersinkron : _syncStatus) : StatusSinkron.belumDiatur);
  }

  /// Jadwalkan sinkron otomatis sesudah data berubah (debounce
  /// 2 detik supaya simpan beruntun tidak membanjiri server).
  void _jadwalkanSinkron() {
    if (!_cloudAktif) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () => _syncNow(diam: true));
  }

  /// Sedang menampilkan shimmer penyegaran (tarik-ke-bawah).
  bool _menyegarkan = false;

  /// Tarik-ke-bawah di halaman mana pun (permintaan Adnan
  /// 2026-11-15): tampilkan SHIMMER selama sinkron berjalan,
  /// TANPA toast apa pun (mode diam — kegagalan tetap tercatat
  /// sebagai pemberitahuan tersimpan). Shimmer tampil minimal
  /// 750ms supaya tidak berkedip bila jaringan sangat cepat.
  Future<void> _segarkan() async {
    if (_menyegarkan) return;
    setState(() => _menyegarkan = true);
    try {
      await Future.wait([
        _syncNow(diam: true),
        Future.delayed(const Duration(milliseconds: 750)),
      ]);
    } finally {
      if (mounted) setState(() => _menyegarkan = false);
    }
  }

  /// Akumulasi jarak tarikan melewati tepi atas pada gestur
  /// yang sedang berjalan.
  double _tarikJarak = 0;
  bool _gesturDiPuncak = false;

  /// Kemajuan tarikan 0..1 untuk indikator lingkaran di puncak
  /// layar — pengguna melihat seberapa jauh lagi harus menarik.
  final _tarikProgres = ValueNotifier<double>(0);

  /// Tarikan sudah mencapai ambang ("siap"): lingkaran
  /// indikator berubah hijau penuh. Penyegaran BARU jalan saat
  /// jari DILEPAS dalam keadaan siap — keluhan Adnan
  /// 2026-11-15 21:49: versi sebelumnya menyegarkan di tengah
  /// tarikan, sebelum lingkarannya terasa "sampai bawah".
  final _tarikSiap = ValueNotifier<bool>(false);

  /// Jarak tarikan melewati tepi atas (px) agar siap menyegar.
  static const double _tarikAmbang = 110;

  /// Detektor tarik-untuk-segar yang DISENGAJA: RefreshIndicator
  /// bawaan memicu hanya dari tarikan ±40px di puncak daftar,
  /// jadi menggulir biasa pun sering menyalakan shimmer (keluhan
  /// Adnan 2026-11-15 12:03). Kini jarak tarikan jari melewati
  /// tepi atas diakumulasi dari OverscrollNotification
  /// (ScrollUpdateNotification kelaparan di tepi yang mentok —
  /// posisi tidak berubah jadi tidak ada update), gestur WAJIB
  /// mulai di puncak, dan penyegaran hanya jalan saat jari
  /// dilepas sesudah tarikan mencapai ambang penuh.
  bool _padaNotifikasiGulir(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollStartNotification) {
      // Penjaga utama: gestur harus DIMULAI saat daftar sudah di
      // puncak. Tarikan yang mulai dari tengah (menggulir naik
      // lalu jarinya kelewat di atas) tidak pernah dihitung —
      // itulah tarikan "tidak sengaja" yang dikeluhkan Adnan.
      _gesturDiPuncak = n.dragDetails != null && n.metrics.pixels <= n.metrics.minScrollExtent + 1;
      _tarikJarak = 0;
      _tarikSiap.value = false;
      _tarikProgres.value = 0;
      return false;
    }
    if (n is ScrollEndNotification) {
      final siap = _tarikSiap.value;
      _tarikJarak = 0;
      _gesturDiPuncak = false;
      _tarikSiap.value = false;
      _tarikProgres.value = 0;
      // Segar hanya saat dilepas dalam keadaan siap — bukan di
      // tengah tarikan.
      if (siap && !_menyegarkan) _segarkan();
      return false;
    }
    if (_menyegarkan || !_gesturDiPuncak) return false;
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _tarikJarak += -n.overscroll;
      _tarikProgres.value = (_tarikJarak / _tarikAmbang).clamp(0.0, 1.0);
      if (_tarikJarak >= _tarikAmbang) _tarikSiap.value = true;
    }
    return false;
  }

  // ---------- Pembaruan dalam aplikasi ----------

  /// Rilis lebih baru yang ditemukan di server (null = belum
  /// ada / belum diperiksa). Ditampilkan sebagai banner di
  /// Beranda.
  InfoUpdate? _infoUpdate;

  /// Kode tertinggi yang sudah pernah DITAWARKAN OTOMATIS
  /// lewat dialog (v0.10.12) + penanda dialog sedang tampil +
  /// cap waktu cek terakhir (untuk cek saat aplikasi kembali
  /// ke depan).
  int _kodeTawaranTerakhir = 0;

  /// Kunci pemberitahuan yang episodenya sedang berjalan
  /// (v0.14.3) — lihat LocalStore.loadKunciNotif.
  Set<String> _kunciNotifAktif = {};
  bool _tawaranSedangTampil = false;
  DateTime? _cekUpdateTerakhir;
  Timer? _timerTawaran;

  /// v0.10.8: kata cari Stok Bahan yang dipasang dari ketukan
  /// pemberitahuan stok (+ nomor urut pemicunya).
  String? _stokQueryAwal;
  int _stokFokusKode = 0;

  /// Cek diam-diam saat aplikasi dibuka + saat kembali ke
  /// depan. Ada versi lebih baru → dialog tawaran otomatis
  /// (sekali per versi) + banner Beranda + pemberitahuan
  /// tersimpan (kunci per versi, tidak banjir). Gagal cek =
  /// diam saja.
  Future<void> _cekUpdateOtomatis() async {
    _cekUpdateTerakhir = DateTime.now();
    final info = await ambilInfoUpdate();
    if (info == null) return;
    // Episode pembaruan lama berakhir: sudah versi terbaru,
    // atau versi yang ditawarkan sudah berganti.
    for (final k in _kunciNotifAktif.where((k) => k.startsWith('update-')).toList()) {
      if (info.kode <= appBuild || k != 'update-${info.kode}') _akhiriEpisodeNotif(k);
    }
    if (info.kode <= appBuild || !mounted) return;
    setState(() => _infoUpdate = info);
    _tambahNotifikasi(
      jenis: 'info',
      judul: 'Pembaruan tersedia',
      isi: 'Avorea POS v${info.nama} siap dipasang. Ketuk pemberitahuan ini untuk memasangnya.',
      kunci: 'update-${info.kode}',
    );
    _tawarkanUpdate();
  }

  /// Tawarkan pembaruan lewat DIALOG YANG MUNCUL SENDIRI
  /// (permintaan Adnan 2026-11-16 00:43: "harusnya muncul
  /// otomatis kalau ada pembaruan, ga harus masuk ke
  /// pengaturan dulu"). Syaratnya dijaga ketat supaya tidak
  /// mengganggu: splash sudah lewat, pengguna sedang di
  /// Beranda, wizard awal sudah selesai, tidak ada dialog
  /// tawaran lain, dan versi ini belum pernah ditawarkan.
  /// Mengetuk 'Nanti' tidak menawarkannya lagi untuk versi
  /// yang sama — banner tetap tinggal sebagai pengingat.
  void _tawarkanUpdate() {
    final info = _infoUpdate;
    if (!mounted || info == null || _tawaranSedangTampil) return;
    if (!_splashSelesai || !_ready || _index != 0 || !_settings.onboarded) return;
    if (!perluTawaranUpdate(kodeTersedia: info.kode, buildSaatIni: appBuild, kodeTawaranTerakhir: _kodeTawaranTerakhir)) return;
    _kodeTawaranTerakhir = info.kode;
    LocalStore.saveUpdateMeta({'tawaranKode': info.kode});
    _tawaranSedangTampil = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ada versi baru — v${info.nama}'),
        content: Text(info.catatan.isNotEmpty ? info.catatan : 'Versi terbaru Avorea POS sudah tersedia.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Nanti')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _mulaiUpdate(info);
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    ).whenComplete(() => _tawaranSedangTampil = false);
  }

  /// Cek atas permintaan dari Pengaturan → umpan balik selalu
  /// tampil (toast / dialog tawar), tidak diam seperti cek
  /// otomatis.
  Future<void> _cekUpdateManual() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppSpacing.lg),
            Text('Memeriksa pembaruan…'),
          ],
        ),
      ),
    );
    final info = await ambilInfoUpdate();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (info == null) {
      tampilToast(context, 'Tidak bisa memeriksa pembaruan. Periksa koneksi internet.', icon: Ikon.wifi_off_outlined);
      return;
    }
    if (info.kode <= appBuild) {
      tampilToast(context, 'Sudah versi terbaru (v$appVersion).', icon: Ikon.check_circle_outline);
      return;
    }
    setState(() => _infoUpdate = info);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ada versi baru — v${info.nama}'),
        content: Text(info.catatan.isNotEmpty ? info.catatan : 'Versi terbaru Avorea POS sudah tersedia.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Nanti')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _mulaiUpdate(info);
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }

  /// Buka dialog unduh + pasang untuk rilis ini.
  void _mulaiUpdate(InfoUpdate info) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogUnduhUpdate(info: info),
    );
  }

  /// Ketuk ikon awan di Beranda: belum diatur → buka Pengaturan;
  /// sudah diatur → sinkron sekarang.
  void _syncTap() {
    if (!_syncSiap) {
      setState(() => _index = 7);
    } else if (!_settings.cloudSyncEnabled) {
      _openSyncStatus();
    } else {
      _syncNow();
    }
  }

  // ---------- Meta sinkron (menunggu & laporan) ----------
  void _tandaiKotor(String kunci) {
    _kotor[kunci] = (_kotor[kunci] ?? 0) + 1;
    _penandaSinkron.value++;
    _simpanMetaSinkron();
  }

  void _simpanMetaSinkron() {
    LocalStore.saveSyncMeta({
      'kotor': _kotor,
      'laporan': _laporanSinkron.map((r) => r.toJson()).toList(),
      'dikenal': {for (final e in _dikenal.entries) e.key: e.value.toList()},
      'strukKotor': _strukKotor,
      'draftKotor': _draftKotor,
    });
  }

  /// Penanda data ekstra berubah (v0.22.0): hitungan menunggu
  /// naik + sinkron dijadwalkan, sama seperti tabel utama.
  void _extraBerubah() {
    _tandaiKotor('extras');
    _jadwalkanSinkron();
  }

  /// Ringkasan satu baris untuk baris Status Sinkronisasi di
  /// Pengaturan.
  String get _ringkasanStatusSinkron {
    if (!_syncSiap) return 'Belum diatur';
    if (!_settings.cloudSyncEnabled) return 'Cloud Sync mati';
    final gagal = _laporanSinkron.where((r) => !r.berhasil).length;
    if (gagal > 0) return '$gagal bagian gagal';
    final tunggu = _kotor.values.fold(0, (a, b) => a + b);
    if (tunggu > 0) return '$tunggu menunggu';
    return _settings.lastSyncLabel.isEmpty ? 'Siap sinkron' : 'Tersinkron';
  }

  void _openSyncStatus() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StatusSinkronScreen(
            penanda: _penandaSinkron,
            ambilLaporan: () => _laporanSinkron,
            ambilKotor: () => Map<String, int>.of(_kotor),
            ambilSedang: () => _syncing,
            ambilRingkasan: () {
              if (!_syncSiap) return 'Isi pengaturan Supabase di bawah untuk mulai menyinkron.';
              if (!_settings.cloudSyncEnabled) return 'Nyalakan Cloud Sync di Pengaturan untuk menyinkron.';
              return _settings.lastSyncLabel.isEmpty ? 'Belum pernah sinkron.' : 'Terakhir sinkron: ${_settings.lastSyncLabel}';
            },
            cloudSyncEnabled: _settings.cloudSyncEnabled,
            siap: _syncSiap,
            supabaseUrl: _settings.supabaseUrl,
            supabaseAnonKey: _settings.supabaseAnonKey,
            businessKey: _settings.businessKey,
            onSupabaseChanged: (u, k, b) => _settingChanged(() {
              var url = u.trim();
              while (url.endsWith('/')) {
                url = url.substring(0, url.length - 1);
              }
              _settings.supabaseUrl = url;
              _settings.supabaseAnonKey = k.trim();
              _settings.businessKey = b.trim();
            }),
            onSinkron: () => _syncNow(),
            onPerbaruiSemua: () => _syncNow(perbaruiSemua: true),
          ),
        ),
      );

  // ---------- CRUD: Menu ----------
  void _addMenu(MenuItem m) {
    setState(() => _menus.add(m));
    LocalStore.saveMenus(_menus);
    _daftarkanKategoriMenu();
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  void _menuChanged() {
    setState(() {});
    LocalStore.saveMenus(_menus);
    _daftarkanKategoriMenu();
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  void _deleteMenu(MenuItem m) {
    setState(() {
      _menus.remove(m);
      _cart.removeWhere((c) => c.menu.id == m.id);
    });
    _simpanDraft();
    LocalStore.saveMenus(_menus);
    _tandaiKotor('menus');
    _jadwalkanSinkron();
    // Tindakan seperti hapus harus ada toast penegas (permintaan
    // Adnan 2026-11-15).
    if (mounted) tampilToast(context, 'Produk "${m.name}" dihapus.', icon: Ikon.delete_outline);
  }

  // ---------- CRUD: Meja ----------
  void _addTable(CafeTable t) {
    setState(() {
      _tables.add(t);
      _tables.sort((a, b) => a.number.compareTo(b.number));
    });
    LocalStore.saveTables(_tables);
    _extraBerubah();
    _jadwalkanSinkron();
  }

  void _tableChanged() {
    setState(() => _tables.sort((a, b) => a.number.compareTo(b.number)));
    LocalStore.saveTables(_tables);
    _extraBerubah();
    _jadwalkanSinkron();
  }

  void _deleteTable(CafeTable t) {
    setState(() {
      _tables.remove(t);
      if (_selectedTable == t) _selectedTable = null;
    });
    LocalStore.saveTables(_tables);
    _extraBerubah();
    _jadwalkanSinkron();
    if (mounted) tampilToast(context, 'Meja ${t.number} dihapus.', icon: Ikon.delete_outline);
  }

  // ---------- Gudang: mutasi stok ----------
  /// Catat satu pergerakan stok. [ing.stock] harus SUDAH berubah
  /// sebelum dipanggil (stokSesudah dibaca darinya, kecuali diberi
  /// [stokSesudah] eksplisit — mis. bahan yang dihapus).
  void _catatMutasi(Ingredient ing, String jenis, double jumlah, {String catatan = '', double? stokSesudah}) {
    _mutasi.insert(
      0,
      MutasiStok(
        ingredientId: ing.id,
        namaBahan: ing.name,
        jenis: jenis,
        jumlah: jumlah,
        stokSesudah: stokSesudah ?? ing.stock,
        satuan: ing.unit,
        catatan: catatan,
      ),
    );
    if (_mutasi.length > 800) _mutasi.removeRange(800, _mutasi.length);
    _stokDikenal[ing.id] = stokSesudah ?? ing.stock;
    LocalStore.saveMutasi(_mutasi);
    _extraBerubah();
  }

  void _barangMasuk(Ingredient ing, double qty, int hargaBeli, String catatan) {
    setState(() {
      ing.stock += qty;
      if (hargaBeli > 0) ing.costPerUnit = hargaBeli;
    });
    _catatMutasi(ing, 'masuk', qty, catatan: catatan.isEmpty ? 'Barang masuk' : catatan);
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    tampilToast(context, '${ing.name} bertambah ${stockText(qty)} ${ing.unit}.', icon: Ikon.add_box_outlined);
  }

  void _opname(Ingredient ing, double stokFisik, String catatan) {
    final selisih = stokFisik - ing.stock;
    setState(() => ing.stock = stokFisik);
    _catatMutasi(ing, 'opname', selisih, catatan: catatan.isEmpty ? 'Opname stok' : catatan);
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    tampilToast(context, 'Opname ${ing.name} tersimpan.', icon: Ikon.fact_check_outlined);
  }

  // ---------- CRUD: Stok bahan ----------
  void _addIngredient(Ingredient i) {
    setState(() => _ingredients.add(i));
    if (i.stock > 0) _catatMutasi(i, 'masuk', i.stock, catatan: 'Stok awal bahan baru');
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    _periksaStokNotifikasi();
  }

  void _ingredientChanged() {
    // Ubah jumlah stok lewat editor tercatat sebagai mutasi
    // 'edit' — selisih dihitung dari stok terakhir yang dikenal.
    for (final ing in _ingredients) {
      final dikenal = _stokDikenal[ing.id];
      if (dikenal != null && dikenal != ing.stock) {
        _catatMutasi(ing, 'edit', ing.stock - dikenal, catatan: 'Ubah manual di editor');
      }
    }
    setState(() {});
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    _periksaStokNotifikasi();
  }

  void _deleteIngredient(Ingredient i) {
    setState(() => _ingredients.remove(i));
    if (i.stock > 0) _catatMutasi(i, 'edit', -i.stock, catatan: 'Bahan dihapus', stokSesudah: 0);
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    if (mounted) tampilToast(context, 'Bahan "${i.name}" dihapus.', icon: Ikon.delete_outline);
  }

  // ---------- Pengaturan ----------
  void _settingChanged(void Function() apply) {
    setState(apply);
    LocalStore.saveSettings(_settings);
    _tandaiKotor('settings');
    _aturTimerSinkron();
    _jadwalkanSinkron();
  }

  // ---------- Buka layar kelola ----------
  void _openKelolaMenu() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KelolaMenuScreen(menus: _menus, onAdd: _addMenu, onChanged: _menuChanged, onDelete: _deleteMenu, ingredients: _ingredients),
        ),
      );

  void _openKelolaMeja() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KelolaMejaScreen(tables: _tables, onAdd: _addTable, onChanged: _tableChanged, onDelete: _deleteTable),
        ),
      );

  void _openKelolaStok() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KelolaStokScreen(ingredients: _ingredients, onAdd: _addIngredient, onChanged: _ingredientChanged, onDelete: _deleteIngredient),
        ),
      );

  // ---------- Laporan & pemberitahuan ----------
  void _openRiwayat() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiwayatScreen(
            transactions: _transactions,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
            onLihatStruk: _openStruk,
            onUbahStatusTx: _ubahStatusTx,
          ),
        ),
      );

  /// Batal/Refund transaksi (v0.23.0, diminta Adnan): status
  /// diganti (transaksi tidak dihitung lagi di omzet/laporan
  /// mana pun — semua penghitung hanya membaca yang 'Lunas')
  /// dan stok bahan dari resep pesanan ini DIKEMBALIKAN,
  /// kebalikan dari potongan saat _checkout. Mutasi jenis
  /// 'batal' mencatat pengembaliannya. Transaksi lama tanpa
  /// rincian pesanan tidak bisa mengembalikan stok — dialog
  /// konfirmasinya sudah menyebut itu.
  void _ubahStatusTx(TxRecord tx, String statusBaru) {
    final kunci = tx.uuid.isNotEmpty ? tx.uuid : tx.id;
    final i = _transactions.indexWhere((t) => (t.uuid.isNotEmpty ? t.uuid : t.id) == kunci);
    if (i < 0) return;
    final lama = _transactions[i];
    if (lama.status != 'Lunas') return;
    setState(() {
      _transactions[i] = lama.denganStatus(statusBaru);
      if (lama.lines.isNotEmpty) {
        final kebutuhan = <String, double>{};
        for (final l in lama.lines) {
          final menu = _menus.where((m) => m.name == l.nama).firstOrNull;
          if (menu == null) continue;
          kebutuhanBahan(menu, _menus).forEach((idBahan, qty) {
            kebutuhan[idBahan] = (kebutuhan[idBahan] ?? 0) + qty * l.qty;
          });
        }
        for (final ing in _ingredients) {
          final kembali = kebutuhan[ing.id];
          if (kembali != null && kembali > 0) {
            ing.stock += kembali;
            _catatMutasi(ing, 'batal', kembali, catatan: 'Stok kembali — ${lama.id} ${statusBaru == 'Refund' ? 'direfund' : 'dibatalkan'}');
          }
        }
      }
    });
    LocalStore.saveTransactions(_transactions);
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('transactions');
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    _periksaStokNotifikasi();
    if (mounted) {
      tampilToast(
        context,
        statusBaru == 'Refund' ? 'Transaksi ${lama.id} sudah direfund.' : 'Transaksi ${lama.id} sudah dibatalkan.',
        icon: statusBaru == 'Refund' ? Ikon.undo : Ikon.block_outlined,
      );
    }
  }

  // ---------- Struk & printer (v0.15.0) ----------

  void _simpanDesainStruk(DesainStruk d) {
    setState(() => _desainStruk = d);
    LocalStore.saveStruk(d);
    _strukKotor = true;
    _extraBerubah();
  }

  void _openDesainStruk() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DesainStrukScreen(
            awal: _desainStruk,
            namaUsaha: _settings.businessName,
            alamat: _settings.businessAddress,
            telepon: _settings.businessPhone,
            branchName: _settings.activeBranch.name,
            onSimpan: _simpanDesainStruk,
          ),
        ),
      );

  Future<String?> _cetakStruk(TxRecord tx) {
    if (!_desainStruk.printerSiap) {
      return Future.value('Printer belum diatur. Buka Pengaturan → Struk & Printer untuk menghubungkan.');
    }
    final bytes = strukKeEscPos(
      susunStruk(
        tx: tx,
        desain: _desainStruk,
        namaUsaha: _settings.businessName,
        alamat: _settings.businessAddress,
        telepon: _settings.businessPhone,
        branchName: _settings.activeBranch.name,
      ),
      _desainStruk.lebarKarakter,
    );
    return PrinterTermal.cetak(_desainStruk.idPrinter, bytes);
  }

  void _openStruk(TxRecord tx) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StrukScreen(
            tx: tx,
            desain: _desainStruk,
            namaUsaha: _settings.businessName,
            alamat: _settings.businessAddress,
            telepon: _settings.businessPhone,
            branchName: _settings.activeBranch.name,
            onCetak: () => _cetakStruk(tx),
            onEditDesain: _openDesainStruk,
          ),
        ),
      );

  void _openBulanan() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanBulananScreen(transactions: _transactions, branchId: _settings.activeBranchId)),
      );

  void _openPajak() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanPajakScreen(transactions: _transactions, branchId: _settings.activeBranchId)),
      );

  void _openPiutang() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanPiutangScreen(tables: _tables)),
      );

  void _openLabaRugi() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LabaRugiScreen(
            transactions: _transactions,
            menus: _menus,
            ingredients: _ingredients,
            expenses: _expenses,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
            onAddExpense: _addExpense,
            onEditExpense: _editExpense,
            onDeleteExpense: _deleteExpense,
          ),
        ),
      );

  void _addExpense(Pengeluaran e) {
    setState(() => _expenses = [e, ..._expenses]);
    LocalStore.saveExpenses(_expenses);
    _extraBerubah();
  }

  void _editExpense(Pengeluaran e) {
    setState(() => _expenses = [for (final x in _expenses) x.id == e.id ? e : x]);
    LocalStore.saveExpenses(_expenses);
    _extraBerubah();
  }

  void _deleteExpense(Pengeluaran e) {
    setState(() => _expenses = _expenses.where((x) => x.id != e.id).toList());
    LocalStore.saveExpenses(_expenses);
    _extraBerubah();
  }

  // ---------- Hutang & Promo: simpan lokal ----------

  void _addHutang(Hutang h) {
    setState(() => _hutang = [h, ..._hutang]);
    LocalStore.saveHutang(_hutang);
    _extraBerubah();
  }

  void _editHutang(Hutang h) {
    setState(() => _hutang = [for (final x in _hutang) x.id == h.id ? h : x]);
    LocalStore.saveHutang(_hutang);
    _extraBerubah();
  }

  void _deleteHutang(Hutang h) {
    setState(() => _hutang = _hutang.where((x) => x.id != h.id).toList());
    LocalStore.saveHutang(_hutang);
    _extraBerubah();
  }

  void _addPromo(Promo p) {
    setState(() => _promos = [p, ..._promos]);
    LocalStore.savePromos(_promos);
    _extraBerubah();
  }

  void _editPromo(Promo p) {
    setState(() => _promos = [for (final x in _promos) x.id == p.id ? p : x]);
    LocalStore.savePromos(_promos);
    _extraBerubah();
  }

  void _deletePromo(Promo p) {
    setState(() => _promos = _promos.where((x) => x.id != p.id).toList());
    LocalStore.savePromos(_promos);
    _extraBerubah();
  }

  // ---------- Pembuka laporan baru (v0.11.0) ----------

  void _openNeraca() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NeracaScreen(
            transactions: _transactions,
            menus: _menus,
            ingredients: _ingredients,
            expenses: _expenses,
            hutang: _hutang,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
          ),
        ),
      );

  void _openArusKas() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArusKasScreen(
            transactions: _transactions,
            expenses: _expenses,
            mutasi: _mutasi,
            ingredients: _ingredients,
            hutang: _hutang,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
          ),
        ),
      );

  void _openArusStok() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArusStokScreen(mutasi: _mutasi)),
      );

  void _openPersediaan() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PersediaanScreen(ingredients: _ingredients)),
      );

  void _openPembelian() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PembelianScreen(mutasi: _mutasi, ingredients: _ingredients)),
      );

  void _openHutang() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HutangScreen(
            hutang: _hutang,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
            onAdd: _addHutang,
            onEdit: _editHutang,
            onDelete: _deleteHutang,
          ),
        ),
      );

  void _openPromo() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PromoScreen(
            promos: _promos,
            transactions: _transactions,
            onAdd: _addPromo,
            onEdit: _editPromo,
            onDelete: _deletePromo,
          ),
        ),
      );

  // ---------- Pembuka laporan v0.15.0 ----------

  void _openMarginTipis() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarginTipisScreen(
            menus: _menus,
            ingredients: _ingredients,
            transactions: _transactions,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
          ),
        ),
      );

  void _openPengunjung() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PengunjungScreen(
            transactions: _transactions,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
          ),
        ),
      );

  // ---------- Sesi Kasir (v0.15.0) ----------

  void _bukaSesi(String namaKasir, int modalAwal) {
    final s = SesiKasir(branchId: _settings.activeBranchId, dibukaPada: DateTime.now(), modalAwal: modalAwal, namaKasir: namaKasir);
    setState(() => _sesi = [s, ..._sesi]);
    LocalStore.saveSesi(_sesi);
    _extraBerubah();
  }

  void _tutupSesi(int tunaiFisik, int pengeluaranLaci, String catatan) {
    final s = _sesiTerbuka;
    if (s == null) return;
    setState(() {
      s.ditutupPada = DateTime.now();
      s.tunaiFisik = tunaiFisik;
      s.pengeluaranLaci = pengeluaranLaci;
      s.catatan = catatan;
    });
    LocalStore.saveSesi(_sesi);
    _extraBerubah();
  }

  void _openSesiKasir() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SesiKasirScreen(
            sesi: _sesi,
            transactions: _transactions,
            expenses: _expenses,
            branchId: _settings.activeBranchId,
            branchName: _settings.activeBranch.name,
            onBuka: _bukaSesi,
            onTutup: _tutupSesi,
          ),
        ),
      );

  /// Akhiri episode pemberitahuan: kunci dicabut dari daftar
  /// aktif, sehingga keadaan yang sama BOLEH memberitahu lagi
  /// bila benar-benar terjadi lagi dari awal (stok pulih lalu
  /// habis lagi; sinkron berhasil lalu gagal lagi).
  void _akhiriEpisodeNotif(String kunci) {
    if (_kunciNotifAktif.remove(kunci)) {
      LocalStore.saveKunciNotif(_kunciNotifAktif);
    }
  }

  /// Tambah pemberitahuan tersimpan. Satu kunci = satu
  /// pemberitahuan per EPISODE keadaan — dibaca atau belum.
  /// (Perbaikan v0.14.3, keluhan Adnan 2026-11-17: pemberitahuan
  /// yang sudah dibaca muncul lagi sebagai belum dibaca sesudah
  /// refresh. Sebabnya penjaga lama hanya menolak bila salinan
  /// BELUM dibaca masih ada; salinan yang sudah dibaca tidak
  /// menghalangi, jadi setiap pemeriksaan ulang — mis. sinkron
  /// sesudah tarik-refresh — melahirkan salinan baru.)
  void _tambahNotifikasi({required String jenis, required String judul, required String isi, required String kunci}) {
    if (_kunciNotifAktif.contains(kunci)) return;
    if (_notifications.any((n) => n.kunci == kunci && !n.dibaca)) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}-$kunci',
        judul: judul,
        isi: isi,
        waktu: DateTime.now(),
        jenis: jenis,
        kunci: kunci,
      ),
    );
    if (_notifications.length > 60) _notifications.removeRange(60, _notifications.length);
    _kunciNotifAktif.add(kunci);
    LocalStore.saveKunciNotif(_kunciNotifAktif);
    LocalStore.saveNotifications(_notifications);
    if (mounted) setState(() {});
  }

  /// Periksa stok: bahan yang masuk keadaan kritis/habis
  /// melahirkan pemberitahuan (dijaga kunci per bahan+keadaan).
  void _periksaStokNotifikasi() {
    for (final i in _ingredients) {
      // Episode berakhir untuk keadaan yang sudah tidak
      // berlaku: bahan pulih → kunci habis & kritis bebas;
      // bahan kritis → kunci habis bebas (dan sebaliknya).
      if (i.status != StockStatus.habis) _akhiriEpisodeNotif('stok-${i.id}-habis');
      if (i.status != StockStatus.kritis) _akhiriEpisodeNotif('stok-${i.id}-kritis');
      if (i.status == StockStatus.habis) {
        _tambahNotifikasi(
          jenis: 'stok',
          judul: 'Stok habis: ${i.name}',
          isi: 'Sisa ${stockText(i.stock)} ${i.unit} — segera pesan lagi supaya menu tetap bisa dijual.',
          kunci: 'stok-${i.id}-habis',
        );
      } else if (i.status == StockStatus.kritis) {
        _tambahNotifikasi(
          jenis: 'stok',
          judul: 'Stok kritis: ${i.name}',
          isi: 'Sisa ${stockText(i.stock)} ${i.unit}, di bawah batas minimum ${stockText(i.minStock)} ${i.unit}. Siapkan pesanan pembelian.',
          kunci: 'stok-${i.id}-kritis',
        );
      }
    }
  }

  void _openNotices() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotifikasiScreen(notifications: _notifications, onTandaiSemuaDibaca: _tandaiSemuaDibaca, onTapNotification: _bukaDariNotifikasi),
      ),
    );
  }

  /// v0.10.8 (permintaan Adnan 2026-11-15 22:38): ketukan pada
  /// pemberitahuan MEMBUKA tujuannya — stok → halaman Stok
  /// Bahan tersaring ke bahan itu, sinkron → Status
  /// Sinkronisasi, info pembaruan → mulai memperbarui.
  /// Pemberitahuan yang diketuk ditandai terbaca.
  void _bukaDariNotifikasi(AppNotification n) {
    if (!n.dibaca) {
      n.dibaca = true;
      LocalStore.saveNotifications(_notifications);
      setState(() {});
    }
    if (n.jenis == 'stok') {
      var id = n.kunci;
      if (id.startsWith('stok-')) id = id.substring(5);
      if (id.endsWith('-habis')) id = id.substring(0, id.length - 6);
      if (id.endsWith('-kritis')) id = id.substring(0, id.length - 7);
      Ingredient? bahan;
      for (final i in _ingredients) {
        if (i.id == id) {
          bahan = i;
          break;
        }
      }
      Navigator.of(context).pop();
      setState(() {
        _index = 6;
        if (bahan != null) {
          _stokQueryAwal = bahan.name;
          _stokFokusKode++;
        }
      });
    } else if (n.jenis == 'sinkron') {
      Navigator.of(context).pop();
      _openSyncStatus();
    } else if (n.jenis == 'info' && n.kunci.startsWith('update-')) {
      Navigator.of(context).pop();
      final info = _infoUpdate;
      if (info != null) _mulaiUpdate(info);
    }
  }

  /// v0.10.1: menandai dibaca kini eksplisit lewat tombol di
  /// halaman Pemberitahuan (dulu otomatis saat halaman dibuka).
  void _tandaiSemuaDibaca() {
    if (_belumDibaca == 0) return;
    setState(() {
      for (final n in _notifications) {
        n.dibaca = true;
      }
    });
    LocalStore.saveNotifications(_notifications);
  }

  void _switchBranch(Branch b) => _settingChanged(() => _settings.activeBranchId = b.id);

  void _finishOnboarding(AppSettings s) {
    setState(() {
      _settings = s;
      _celebrate = true;
    });
    LocalStore.saveSettings(_settings);
  }

  // ---------- Halaman pengaturan lanjutan ----------
  void _openProfile() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfilUsahaScreen(
            nama: _settings.businessName,
            alamat: _settings.businessAddress,
            telepon: _settings.businessPhone,
            fotoPath: _settings.businessPhotoPath,
            onSaveFoto: (p) => _settingChanged(() => _settings.businessPhotoPath = p),
            onSave: (n, a, t) => _settingChanged(() {
              _settings.businessName = n;
              _settings.businessAddress = a;
              _settings.businessPhone = t;
            }),
          ),
        ),
      );

  void _openPinSettings() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PinSettingsScreen(
            currentHash: _settings.pinHash,
            onSaveHash: (h) => _settingChanged(() => _settings.pinHash = h),
          ),
        ),
      );

  void _openBranchWizard() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BranchWizardScreen(
            onCreate: (b, aktif) {
              _tandaiKotor('branches');
              _settingChanged(() {
                _settings.branches = [..._settings.branches, b];
                if (aktif) _settings.activeBranchId = b.id;
              });
            },
          ),
        ),
      );

  /// Ubah nama/alamat/telepon cabang (v0.19.0): id tetap, jadi
  /// transaksi lama tidak berubah; nama baru ikut sinkron karena
  /// daftar cabang diunggah utuh pada setiap sinkron.
  void _bukaUbahCabang(Branch b) => showUbahCabangSheet(
        context,
        awal: b,
        onSimpan: (hasil) {
          _tandaiKotor('branches');
          _settingChanged(() {
            _settings.branches = [
              for (final lama in _settings.branches) lama.id == hasil.id ? hasil : lama,
            ];
          });
        },
      );

  /// Hapus cabang (v0.24.0, diminta Adnan): cabang dibuang
  /// dari daftar + id-nya dicatat di penanda hapus
  /// (cabangTerhapus) yang ikut sinkron — perangkat lain
  /// menyaringnya keluar dan baris awannya dibersihkan.
  /// Transaksinya TIDAK dihapus. Cabang aktif dan cabang
  /// terakhir tidak bisa dihapus (jaga di sini juga, bukan
  /// hanya di tampilan).
  void _hapusCabang(Branch b) {
    if (_settings.branches.length <= 1 || b.id == _settings.activeBranchId) return;
    if (!_settings.branches.any((c) => c.id == b.id)) return;
    _tandaiKotor('branches');
    _tandaiKotor('settings');
    _settingChanged(() {
      _settings.branches = [for (final c in _settings.branches) if (c.id != b.id) c];
      if (!_settings.cabangTerhapus.contains(b.id)) {
        _settings.cabangTerhapus = [..._settings.cabangTerhapus, b.id];
      }
    });
    if (mounted) {
      tampilToast(context, 'Cabang ${b.name} dihapus.', icon: Ikon.delete_outline);
    }
  }

  // ---------- Reset Total (v0.20.0) ----------
  /// Hapus SEMUA data — awan dulu, lalu HP ini — dan muat
  /// ulang dari nol seperti pemasangan baru. Mengembalikan
  /// null bila berhasil, atau pesan galat bila penghapusan
  /// awan gagal (dalam hal itu data HP TIDAK diubah sama
  /// sekali, supaya tidak hilang setengah).
  Future<String?> _resetTotal() async {
    if (_resetBerlangsung) return 'Reset sedang berjalan.';
    _resetBerlangsung = true;
    try {
      // Bekukan jadwal sinkron, lalu tunggu sinkron yang
      // sedang terbang selesai — unggahannya harus tuntas
      // SEBELUM baris awan dihapus, kalau tidak data lama
      // naik lagi sesudah penghapusan.
      _syncDebounce?.cancel();
      var tunggu = 0;
      while (_syncing && tunggu < 300) {
        await Future.delayed(const Duration(milliseconds: 100));
        tunggu++;
      }
      if (_syncSiap) {
        try {
          await (jahitanHapusCloud ?? hapusSemuaDataCloud)(_settings);
        } catch (e) {
          return 'Data di awan gagal dihapus (${ringkasErrorSinkron(e)}). Data di HP ini TIDAK diubah — periksa internet, lalu coba lagi.';
        }
      }
      // Foto usaha adalah berkas lokal: ikut dibuang.
      final foto = _settings.businessPhotoPath;
      if (foto != null && foto.isNotEmpty) {
        try {
          await File(foto).delete();
        } catch (_) {
          // Berkas sudah tidak ada — abaikan.
        }
      }
      await LocalStore.hapusSemuaData();
      if (!mounted) return null;
      setState(() {
        _index = 0;
        _kasirUnlocked = false;
        _celebrate = false;
        _laporanSinkron = [];
        _strukKotor = false;
        _draftKotor = false;
        _pernahSinkron = false;
        for (final k in _kotor.keys) {
          _kotor[k] = 0;
        }
        for (final k in _dikenal.keys) {
          _dikenal[k] = {};
        }
      });
      await _loadData();
      // _loadData menjalankan sinkron awal dalam keadaan
      // beku, jadi jalankan sekali lagi di sini — persis
      // seperti pemasangan baru: data awal naik ke awan yang
      // sudah kosong.
      _resetBerlangsung = false;
      if (_cloudAktif) _syncNow(diam: true);
      if (mounted) {
        tampilToast(
          context,
          'Semua data sudah direset — aplikasi seperti baru dipasang.',
          icon: Ikon.delete_outline,
          durasi: const Duration(seconds: 4),
        );
      }
      return null;
    } finally {
      _resetBerlangsung = false;
    }
  }

  // ---------- Sinkronisasi Supabase ----------

  /// Gerbang wizard awal (v0.22.0): sebelum wizard boleh
  /// selesai, pastikan sinkron pertama SUDAH mendarat — kalau
  /// belum, wizard bisa keburu mengganti daftar cabang sebelum
  /// cabang lama dari awan terlihat (kejadian 2026-11-20:
  /// pasang baru di HP lain, cabang lama tidak ketemu, malah
  /// terdaftar cabang pertama baru). Sinkron yang sedang
  /// terbang ditunggu (batas sinkronnya sendiri 25 detik);
  /// belum pernah sinkron sama sekali → jalankan sekarang.
  /// Gagal pun tidak apa: wizard lanjut dengan data lokal.
  Future<void> _sinkronSebelumWizard() async {
    if (!_cloudAktif) return;
    if (_syncing) {
      var t = 0;
      while (_syncing && t < 300) {
        await Future.delayed(const Duration(milliseconds: 100));
        t++;
      }
    } else if (!_pernahSinkron) {
      await _syncNow(diam: true);
    }
  }

  /// Sinkron dengan batas 25 detik: koneksi menggantung tidak
  /// boleh membuat status 'menyinkron' selamanya — gagalkan saja,
  /// ikon jadi merah dan sinkron berikutnya mencoba lagi. Timer
  /// batasnya milik shell ini (dibatalkan di dispose), BUKAN
  /// Future.timeout yang timernya menggantung tanpa pemilik.
  Future<HasilSinkron> _sinkronDenganBatasWaktu({bool perbaruiSemua = false}) {
    final selesai = Completer<HasilSinkron>();
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 25), () {
      if (!selesai.isCompleted) {
        selesai.completeError(TimeoutException('Sinkron melewati batas 25 detik'));
      }
    });
    sinkronkanSupabase(
      settings: _settings,
      menus: _menus,
      ingredients: _ingredients,
      branches: _settings.branches,
      transactions: _transactions,
      perbaruiSemua: perbaruiSemua,
      dikenal: _dikenal,
      extras: DataEkstra(
        tables: _tables,
        promos: _promos,
        expenses: _expenses,
        hutang: _hutang,
        mutasi: _mutasi,
        sesi: _sesi,
        dapur: _kitchen,
        struk: _desainStruk,
        draft: _draftSekarang,
      ),
      strukKotor: _strukKotor,
      draftKotor: _draftKotor,
    ).then((h) {
      _syncTimeoutTimer?.cancel();
      if (!selesai.isCompleted) selesai.complete(h);
    }, onError: (Object e) {
      _syncTimeoutTimer?.cancel();
      if (!selesai.isCompleted) selesai.completeError(e);
    });
    return selesai.future;
  }

  Future<void> _syncNow({bool diam = false, bool perbaruiSemua = false}) async {
    if (_syncing || !_syncSiap || _resetBerlangsung) return;
    if (!_settings.cloudSyncEnabled) {
      if (!diam && mounted) {
        tampilToast(context, 'Cloud Sync sedang mati — nyalakan di Pengaturan.', icon: Ikon.cloud_off_outlined, warna: AppColors.warning);
      }
      return;
    }
    _syncing = true;
    _penandaSinkron.value++;
    // Ikon berputar hanya untuk sinkron MANUAL (ketuk awan /
    // tombol Sinkronkan). Sinkron otomatis berjalan diam-diam —
    // ikon cukup berubah ke hasil akhir (centang / merah), tidak
    // berputar terus setiap ada perubahan data.
    if (!diam && mounted) setState(() => _syncStatus = StatusSinkron.menyinkron);
    // TANPA toast 'Menyinkronkan…' (permintaan Adnan 2026-11-15):
    // penanda prosesnya sudah cukup dari putaran ikon awan /
    // indikator tarik-untuk-segar. Toast hanya untuk HASIL akhir.
    try {
      final hasil = await _sinkronDenganBatasWaktu(perbaruiSemua: perbaruiSemua);
      if (!mounted) return;
      // Reset Total mulai saat sinkron ini terbang: hasil
      // gabungan lama TIDAK diterapkan dan TIDAK disimpan —
      // datanya sedang dihapus. Unggahannya sendiri sudah
      // selesai di dalam sinkron, jadi penghapusan awan oleh
      // reset tetap berjalan sesudahnya dengan urutan benar.
      if (_resetBerlangsung) {
        _syncing = false;
        _penandaSinkron.value++;
        return;
      }
      setState(() {
        _menus = hasil.menus;
        _ingredients = hasil.ingredients;
        _transactions = hasil.transactions;
        _settings.branches = hasil.branches;
        if (!_settings.branches.any((b) => b.id == _settings.activeBranchId)) {
          _settings.activeBranchId = _settings.branches.first.id;
        }
        // Pengaturan usaha dari server diterapkan hanya untuk
        // kolom usaha (bukan PIN/kredensial yang memang lokal).
        final srv = hasil.pengaturanServer;
        if (srv != null) {
          _settings.businessName = srv['businessName'] as String? ?? _settings.businessName;
          _settings.businessAddress = srv['businessAddress'] as String? ?? _settings.businessAddress;
          _settings.businessPhone = srv['businessPhone'] as String? ?? _settings.businessPhone;
          _settings.servicePercent = (srv['servicePercent'] as num?)?.toInt() ?? _settings.servicePercent;
          _settings.taxPercent = (srv['taxPercent'] as num?)?.toInt() ?? _settings.taxPercent;
          // Penanda cabang terhapus (v0.24.0): gabungan dari
          // semua perangkat — penanda hanya boleh bertambah.
          final srvTerhapus = (srv['cabangTerhapus'] as List?)?.map((e) => e.toString()) ?? const <String>[];
          _settings.cabangTerhapus = {..._settings.cabangTerhapus, ...srvTerhapus}.toList();
        }
        // Saringan pengaman: cabang berpenanda hapus tidak
        // boleh tampil lagi di perangkat ini.
        if (_settings.cabangTerhapus.isNotEmpty) {
          final saring = [for (final b in _settings.branches) if (!_settings.cabangTerhapus.contains(b.id)) b];
          if (saring.isNotEmpty && saring.length != _settings.branches.length) {
            _settings.branches = saring;
            if (!_settings.branches.any((b) => b.id == _settings.activeBranchId)) {
              _settings.activeBranchId = _settings.branches.first.id;
            }
          }
        }
        // Data ekstra hasil gabungan (v0.22.0): daftar diganti
        // dengan hasil gabungan awan+lokal.
        final ex = hasil.extras;
        if (ex != null) {
          _tables = ex.tables;
          _promos = ex.promos;
          _expenses = ex.expenses;
          _hutang = ex.hutang;
          _mutasi = ex.mutasi;
          _sesi = ex.sesi;
          _kitchen = ex.dapur;
          if (ex.struk != null) _desainStruk = ex.struk!;
          // Meja terpilih disambung ulang ke objek di daftar
          // baru (daftar lama sudah dibuang).
          if (_selectedTable != null) {
            _selectedTable = _tables.where((t) => t.number == _selectedTable!.number).firstOrNull;
          }
          // Draf dari perangkat lain hanya diterapkan bila
          // keranjang di sini SEDANG KOSONG dan tidak ada meja
          // terpilih — pesanan yang sedang diketik kasir tidak
          // boleh ditimpa draf dari HP lain.
          final d = ex.draft;
          if (d != null && _cart.isEmpty && _selectedTable == null) {
            _draftJenis = d.jenis;
            _draftPromoId = d.promoId;
            _orderCounter = d.counter;
            _cart
              ..clear()
              ..addAll([
                for (final b in d.items)
                  if (_menus.any((m) => m.id == b.menuId))
                    CartItem(menu: _menus.firstWhere((m) => m.id == b.menuId), variant: b.variant, note: b.note, qty: b.qty, unitPrice: b.unitPrice),
              ]);
            _selectedTable = d.nomorMeja == null ? null : _tables.where((t) => t.number == d.nomorMeja).firstOrNull;
          }
        }
        final n = DateTime.now();
        _settings.lastSyncLabel =
            '${n.day}/${n.month}/${n.year} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
        // Laporan per tabel + bersihkan penanda menunggu untuk
        // tabel yang berhasil terkirim.
        _laporanSinkron = hasil.rincian;
        for (final r in hasil.rincian) {
          if (r.berhasil) _kotor[r.kunci] = 0;
        }
        // Ingatan id perangkat diperbarui dari hasil gabungan —
        // dasar keputusan hapus-di-server pada sinkron berikut.
        hasil.dikenalBaru.forEach((kunci, ids) {
          if (_dikenal.containsKey(kunci)) _dikenal[kunci] = ids;
        });
      });
      LocalStore.saveMenus(_menus);
      LocalStore.saveIngredients(_ingredients);
      LocalStore.saveTransactions(_transactions);
      LocalStore.saveSettings(_settings);
      if (hasil.extras != null) {
        LocalStore.saveTables(_tables);
        LocalStore.savePromos(_promos);
        LocalStore.saveExpenses(_expenses);
        LocalStore.saveHutang(_hutang);
        LocalStore.saveMutasi(_mutasi);
        LocalStore.saveSesi(_sesi);
        LocalStore.saveStruk(_desainStruk);
        _tulisDraft();
        // Bagian ekstra terkirim utuh → perubahan lokal untuk
        // benda tunggalnya sudah tersimpan di awan.
        if (hasil.rincian.any((r) => r.kunci == 'extras' && r.berhasil)) {
          _strukKotor = false;
          _draftKotor = false;
        }
      }
      _simpanMetaSinkron();
      _syncing = false;
      _pernahSinkron = true;
      _penandaSinkron.value++;
      if (mounted) setState(() => _syncStatus = hasil.adaGagal ? StatusSinkron.gagal : StatusSinkron.tersinkron);
      _periksaStokNotifikasi();
      if (hasil.adaGagal) {
        final pertama = hasil.rincian.firstWhere((r) => !r.berhasil);
        _tambahNotifikasi(
          jenis: 'sinkron',
          judul: 'Sinkron belum tuntas',
          isi: '${pertama.label} gagal terkirim: ${pertama.galat ?? 'sebab tidak diketahui'} — rincian di Status Sinkronisasi.',
          kunci: 'sinkron-gagal',
        );
        if (!diam && mounted) {
          tampilToast(context, hasil.ringkasan, icon: Ikon.cloud_off_outlined, warna: AppColors.danger, durasi: const Duration(seconds: 5));
        }
      } else {
        // Sinkron tuntas: episode gagal berakhir — kegagalan
        // berikutnya adalah kejadian baru yang boleh
        // memberitahu lagi.
        _akhiriEpisodeNotif('sinkron-gagal');
        if (!diam && mounted) {
          tampilToast(context, hasil.ringkasan, icon: Ikon.cloud_done_outlined);
        }
      }
    } catch (e) {
      debugPrint('Sinkron gagal: $e');
      _syncing = false;
      _pernahSinkron = true;
      final ringkas = ringkasErrorSinkron(e);
      _laporanSinkron = [
        for (final (kunci, label) in [
          ('branches', 'Cabang'),
          ('menus', 'Menu'),
          ('ingredients', 'Bahan'),
          ('transactions', 'Transaksi'),
          ('settings', 'Pengaturan'),
          ('extras', 'Data Lainnya'),
        ])
          StatusTabel(kunci: kunci, label: label, berhasil: false, jumlah: 0, galat: ringkas),
      ];
      _simpanMetaSinkron();
      _penandaSinkron.value++;
      if (mounted) setState(() => _syncStatus = StatusSinkron.gagal);
      _tambahNotifikasi(
        jenis: 'sinkron',
        judul: 'Sinkron gagal',
        isi: '$ringkas — data tetap aman di perangkat ini dan akan dicoba lagi otomatis.',
        kunci: 'sinkron-gagal',
      );
      if (!diam && mounted) {
        tampilToast(context, 'Sinkron gagal: $ringkas', icon: Ikon.cloud_off_outlined, warna: AppColors.danger, durasi: const Duration(seconds: 6));
      }
    }
  }

  // ---------- Harga massal & impor produk ----------
  void _applyBulkPrice(int percent) {
    setState(() {
      for (final m in _menus) {
        final mentah = (m.price * (100 + percent) / 100).round();
        m.price = (((mentah + 50) ~/ 100) * 100).clamp(100, 100000000);
      }
    });
    LocalStore.saveMenus(_menus);
    _jadwalkanSinkron();
  }

  void _importMenus(List<MenuItem> items) {
    setState(() => _menus.addAll(items));
    LocalStore.saveMenus(_menus);
    _daftarkanKategoriMenu();
    _jadwalkanSinkron();
  }

  // ---------- Kategori menu (v0.17.0) ----------

  /// Daftar kategori efektif saat ini (daftar tersimpan +
  /// kategori apa pun yang sedang dipakai menu).
  List<String> get _kategoriEfektif => kategoriEfektif(_settings, _menus);

  /// Daftarkan kategori yang dipakai menu tapi belum ada di
  /// daftar tersimpan (dibuat dari editor menu / hasil impor).
  /// Dipanggil sesudah menu disimpan.
  void _daftarkanKategoriMenu() {
    final eff = _kategoriEfektif;
    if (eff.length != _settings.menuCategories.length) {
      _settings.menuCategories = eff;
      LocalStore.saveSettings(_settings);
      _tandaiKotor('settings');
    }
  }

  void _tambahKategori(String nama) {
    setState(() => _settings.menuCategories = [..._kategoriEfektif, nama]);
    LocalStore.saveSettings(_settings);
    _tandaiKotor('settings');
    _jadwalkanSinkron();
  }

  void _ubahNamaKategori(String lama, String baru) {
    setState(() {
      _settings.menuCategories = [for (final k in _kategoriEfektif) k == lama ? baru : k];
      for (final m in _menus) {
        if (m.category == lama) m.category = baru;
      }
    });
    LocalStore.saveSettings(_settings);
    LocalStore.saveMenus(_menus);
    _tandaiKotor('settings');
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  void _hapusKategori(String nama) {
    setState(() {
      final sisa = _kategoriEfektif.where((k) => k != nama).toList();
      // Menu di kategori terhapus pindah ke 'Lainnya' (dibuat
      // bila belum ada); menghapus 'Lainnya' sendiri → pindah
      // ke kategori pertama yang tersisa.
      final tujuan = nama == 'Lainnya' ? (sisa.isNotEmpty ? sisa.first : 'Lainnya') : 'Lainnya';
      if (!sisa.contains(tujuan)) sisa.add(tujuan);
      _settings.menuCategories = sisa;
      for (final m in _menus) {
        if (m.category == nama) m.category = tujuan;
      }
    });
    LocalStore.saveSettings(_settings);
    LocalStore.saveMenus(_menus);
    _tandaiKotor('settings');
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  // ---------- Draf kasir & dapur (v0.16.0) ----------

  /// Simpan keadaan kasir yang sedang berjalan ke disk:
  /// isi keranjang, meja, nomor urut, jenis, promo, dan
  /// seluruh antrean dapur. Dipanggil sesudah SETIAP perubahan
  /// supaya tidak ada pesanan yang hilang bila aplikasi
  /// tertutup paksa atau HP mati di tengah pesanan.
  /// Potret draf kasir saat ini (untuk disimpan & disinkronkan).
  DraftKasir get _draftSekarang => DraftKasir(
        items: [for (final c in _cart) BarisKeranjang(menuId: c.menu.id, variant: c.variant, note: c.note, qty: c.qty, unitPrice: c.unitPrice)],
        nomorMeja: _selectedTable?.number,
        counter: _orderCounter,
        jenis: _draftJenis,
        promoId: _draftPromoId,
      );

  /// Tulis dapur + draf ke disk TANPA menandai perubahan
  /// (dipakai jalur penerapan hasil sinkron).
  void _tulisDraft() {
    LocalStore.saveDapur(_kitchen);
    LocalStore.saveDraftKasir(_draftSekarang);
  }

  void _simpanDraft() {
    _tulisDraft();
    _draftKotor = true;
    _extraBerubah();
  }

  void _jenisBerubah(String jenis) {
    _draftJenis = jenis;
    _simpanDraft();
  }

  void _promoBerubah(String? promoId) {
    _draftPromoId = promoId;
    _simpanDraft();
  }

  // ---------- Cart actions ----------
  void _addToCart(MenuItem menu, String variant, int unitPrice, String note) {
    setState(() {
      final key = '${menu.id}|$variant';
      final idx = _cart.indexWhere((c) => c.key == key && c.note == note);
      if (idx >= 0) {
        _cart[idx].qty++;
      } else {
        _cart.add(CartItem(menu: menu, variant: variant, unitPrice: unitPrice, note: note));
      }
    });
    _simpanDraft();
  }

  void _inc(CartItem c) {
    setState(() => c.qty++);
    _simpanDraft();
  }

  void _dec(CartItem c) {
    setState(() {
      if (c.qty > 1) {
        c.qty--;
      } else {
        _cart.remove(c);
      }
    });
    _simpanDraft();
  }

  void _remove(CartItem c) {
    setState(() => _cart.remove(c));
    _simpanDraft();
  }

  void _checkout(String paymentMethod, String tableLabel, String orderType, Promo? promo, {int tamu = 0}) {
    // Total dihitung SEBELUM keranjang dikosongkan, untuk catatan
    // tagihan berjalan di kartu meja.
    final subtotal = _cart.fold(0, (a, c) => a + c.total);
    final serviceAmt = (subtotal * _settings.servicePercent / 100).round();
    final taxAmt = (subtotal * _settings.taxPercent / 100).round();
    // Diskon promo dihitung dari fungsi yang sama dengan yang
    // dipakai tampilan kasir (hitungDiskonPromo) — tidak boleh
    // ada dua hitungan yang bisa berbeda.
    final diskonAmt = hitungDiskonPromo(promo, subtotal);
    final grandTotal = subtotal + serviceAmt + taxAmt - diskonAmt;
    final orderId = 'A-${_orderCounter++}';
    final itemCount = _cart.fold(0, (a, c) => a + c.qty);
    setState(() {
      // Tiket dapur hanya dibuat bila fitur dapur menyala.
      if (_settings.kitchenEnabled) {
        final lines = _cart
            .map((c) => KitchenOrderLine(c.menu.name, c.qty, [c.variant, c.note].where((s) => s.isNotEmpty).join(' · ')))
            .toList();
        _kitchen.insert(
          0,
          KitchenOrder(
            id: orderId,
            tableLabel: tableLabel,
            orderType: orderType,
            lines: lines,
            status: KitchenStatus.baru,
            time: 'Baru saja',
          ),
        );
      }
      if (_selectedTable != null) {
        if (_selectedTable!.status == TableStatus.kosong) {
          _selectedTable!.status = TableStatus.terisi;
          _selectedTable!.guestName = 'Pelanggan';
        }
        // Kartu meja wajib mencerminkan pesanan yang masuk — dulu
        // jumlahnya diam di Rp0 walau sudah pesan & bayar.
        _selectedTable!.openAmount += grandTotal;
        _selectedTable!.since ??= _nowHHmm();
      }
      // Catat transaksi ASLI untuk Beranda & laporan (penjualan
      // hari ini, pajak terkumpul, per cabang).
      _transactions.add(TxRecord(
        id: orderId,
        total: grandTotal,
        method: paymentMethod,
        at: DateTime.now(),
        items: itemCount,
        subtotal: subtotal,
        service: serviceAmt,
        tax: taxAmt,
        diskon: diskonAmt,
        promoNama: diskonAmt > 0 ? (promo?.nama ?? '') : '',
        tamu: tamu,
        branchId: _settings.activeBranchId,
        uuid: 'u${DateTime.now().millisecondsSinceEpoch}-$_orderCounter',
        // Rincian item disimpan sejak v0.10.6 supaya halaman
        // Detail Transaksi bisa menampilkan pesanan aslinya
        // (dulu hanya jumlah item yang tercatat).
        lines: [
          for (final c in _cart)
            TxLine(
              nama: c.menu.name,
              keterangan: [
                if (c.variant.isNotEmpty && c.variant != 'Reguler') c.variant,
                if (c.note.isNotEmpty) c.note,
              ].join(' · '),
              qty: c.qty,
              total: c.total,
            ),
        ],
      ));
      // Potong stok bahan dari resep (permintaan Adnan
      // 2026-11-15): menu beresep mengurangi bahan per porsi;
      // bundle mengurangi lewat resep komponennya. Stok tidak
      // pernah minus — berhenti di 0.
      final kebutuhan = <String, double>{};
      for (final c in _cart) {
        kebutuhanBahan(c.menu, _menus).forEach((idBahan, qty) {
          kebutuhan[idBahan] = (kebutuhan[idBahan] ?? 0) + qty * c.qty;
        });
      }
      if (kebutuhan.isNotEmpty) {
        for (final ing in _ingredients) {
          final pakai = kebutuhan[ing.id];
          if (pakai != null && pakai > 0) {
            final sebelum = ing.stock;
            ing.stock = ing.stock - pakai < 0 ? 0 : ing.stock - pakai;
            if (ing.stock != sebelum) {
              _catatMutasi(ing, 'jual', ing.stock - sebelum, catatan: 'Terpotong penjualan');
            }
          }
        }
      }
      _cart.clear();
    });
    _simpanDraft();
    LocalStore.saveTables(_tables);
    _extraBerubah();
    LocalStore.saveTransactions(_transactions);
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('transactions');
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    _periksaStokNotifikasi();
  }

  String _nowHHmm() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  // ---------- Kitchen ----------
  void _advanceKitchen(KitchenOrder order) {
    setState(() {
      switch (order.status) {
        case KitchenStatus.baru:
          order.status = KitchenStatus.dimasak;
        case KitchenStatus.dimasak:
          order.status = KitchenStatus.selesai;
        case KitchenStatus.selesai:
          _kitchen.remove(order);
      }
    });
    _simpanDraft();
  }

  void _selectTable(CafeTable t) {
    setState(() => _selectedTable = t);
    _simpanDraft();
  }

  /// Tumpukan layar utama dengan pudar singkat saat pindah tab
  /// (permintaan Adnan 2026-11-14): perpindahan menu terasa halus
  /// ±200 mdtk, BUKAN dorongan halaman. Keadaan tiap layar tetap
  /// utuh karena IndexedStack-nya sendiri tidak berubah.
  Widget _tumpukanLayar(List<Widget> screens) {
    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey(_index),
          tween: Tween(begin: 0.45, end: 1),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          // Tarik jauh ke bawah di halaman mana pun = sinkron
          // Supabase lewat detektor _padaNotifikasiGulir (bukan
          // RefreshIndicator bawaan yang terlalu mudah terpicu).
          child: NotificationListener<ScrollNotification>(
            onNotification: _padaNotifikasiGulir,
            child: IndexedStack(index: _index, children: screens),
          ),
        ),
        // Indikator tarikan: lingkaran panah segar meluncur
        // turun & berputar mengikuti jauhnya tarikan.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _tarikProgres,
            builder: (_, p, _) {
              if (p <= 0) return const SizedBox.shrink();
              return IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, -40 + 54 * p),
                    child: Opacity(
                      opacity: p.clamp(0.15, 1.0),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _tarikSiap,
                        builder: (_, siap, _) => Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            // Siap (ambang tercapai): lingkaran
                            // hijau penuh = "lepas sekarang,
                            // aplikasi akan menyegar".
                            color: siap ? AppColors.accent : AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: siap ? AppColors.accent : AppColors.border),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Transform.rotate(
                            angle: p * 3.5,
                            child: Icon(Ikon.refresh, size: 20, color: siap ? Colors.white : AppColors.accent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Lapisan shimmer selama penyegaran tarik-ke-bawah.
        if (_menyegarkan) const Positioned.fill(child: ShimmerSkeleton()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashSelesai) {
      return const SplashScreen();
    }
    // Data lokal belum siap sesudah layar pembuka selesai:
    // rangka shimmer. Shimmer HANYA tampil saat muat awal dan
    // saat tarik jauh untuk menyegarkan (keputusan Adnan
    // 2026-11-15 12:04) — tidak pernah dari sinkron otomatis
    // atau tarikan kecil saat menggulir biasa.
    if (!_ready) {
      return const Scaffold(body: ShimmerSkeleton());
    }
    // Pemasangan pertama: onboarding + wizard cabang pertama dulu.
    if (!_settings.onboarded) {
      return OnboardingFlow(
        initial: _settings,
        onDone: _finishOnboarding,
        sebelumSelesai: _cloudAktif ? _sinkronSebelumWizard : null,
      );
    }
    final screens = <Widget>[
      BerandaScreen(
        businessName: _settings.businessName,
        branch: _settings.activeBranch,
        branches: _settings.branches,
        transactions: _transactions,
        syncStatus: _syncStatus,
        onSyncTap: _syncTap,
        kitchenActive: _kitchen.length,
        kitchenEnabled: _settings.kitchenEnabled,
        menuCount: _menus.length,
        tablesEnabled: _settings.tablesEnabled,
        tablesOccupied: _tables.where((t) => t.status != TableStatus.kosong).length,
        tablesTotal: _tables.length,
        noticeCount: _belumDibaca,
        onOpenKasir: () => setState(() => _index = 1),
        onNavigate: (i) => setState(() => _index = i),
        onManageTables: _openKelolaMeja,
        onManageIngredients: _openKelolaStok,
        onSwitchBranch: _switchBranch,
        onOpenNotices: _openNotices,
        onOpenRiwayat: _openRiwayat,
        infoUpdate: _infoUpdate,
        onTapUpdate: _infoUpdate == null ? null : () => _mulaiUpdate(_infoUpdate!),
      ),
      // Gerbang PIN: kasir terkunci sampai PIN benar dimasukkan
      // (hanya bila pemilik mengatur PIN; sekali per sesi).
      if (_settings.pinHash.isNotEmpty && !_kasirUnlocked)
        PinGateScreen(
          pinHash: _settings.pinHash,
          businessName: _settings.businessName,
          onUnlock: () => setState(() => _kasirUnlocked = true),
        )
      else
        KasirScreen(
          cart: _cart,
          menus: _menus,
        // Meja mati → kasir tidak membawa meja sama sekali.
        selectedTable: _settings.tablesEnabled ? _selectedTable : null,
        tables: _tables,
        servicePercent: _settings.servicePercent,
        taxPercent: _settings.taxPercent,
        tablesEnabled: _settings.tablesEnabled,
        kitchenEnabled: _settings.kitchenEnabled,
        onSelectTable: _selectTable,
        onAdd: _addToCart,
        onInc: _inc,
        onDec: _dec,
        onRemove: _remove,
        onCheckout: _checkout,
        sesiTerbuka: _sesiTerbuka != null,
        onBukaKasir: _openSesiKasir,
        promos: _promos,
        // Draf kasir (v0.16.0): nilai awal hanya dikirim
        // sesudah data selesai dimuat (_ready) supaya layar
        // Kasir tidak menerapkan draf kosong lebih dulu.
        jenisAwal: _ready ? _draftJenis : null,
        promoIdAwal: _ready ? _draftPromoId : null,
        onJenisBerubah: _jenisBerubah,
        onPromoBerubah: _promoBerubah,
        kategoriList: _ready ? _kategoriEfektif : null,
      ),
      ProdukScreen(
        menus: _menus,
        onAdd: _addMenu,
        onChanged: _menuChanged,
        onDelete: _deleteMenu,
        branchName: _settings.activeBranch.name,
        ingredients: _ingredients,
        onBulkPrice: _applyBulkPrice,
        onImport: _importMenus,
        businessName: _settings.businessName,
        kategoriList: _ready ? _kategoriEfektif : null,
        onTambahKategori: _tambahKategori,
        onUbahNamaKategori: _ubahNamaKategori,
        onHapusKategori: _hapusKategori,
      ),
      MejaScreen(
        tables: _tables,
        selectedTable: _selectedTable,
        onSelect: _selectTable,
        // Kasir sekarang indeks 1 (indeks 0 = Beranda).
        onGoKasir: () => setState(() => _index = 1),
      ),
      DapurScreen(orders: _kitchen, onAdvance: _advanceKitchen),
      LaporanScreen(
        transactions: _transactions,
        branchId: _settings.activeBranchId,
        tables: _tables,
        onOpenRiwayat: _openRiwayat,
        onOpenBulanan: _openBulanan,
        onOpenPajak: _openPajak,
        onOpenPiutang: _openPiutang,
        onOpenLabaRugi: _openLabaRugi,
        onOpenNeraca: _openNeraca,
        onOpenArusKas: _openArusKas,
        onOpenArusStok: _openArusStok,
        onOpenPersediaan: _openPersediaan,
        onOpenPembelian: _openPembelian,
        onOpenHutang: _openHutang,
        onOpenPromo: _openPromo,
        onOpenMarginTipis: _openMarginTipis,
        onOpenPengunjung: _openPengunjung,
      ),
      StokScreen(
        ingredients: _ingredients,
        onAdd: _addIngredient,
        onChanged: _ingredientChanged,
        onDelete: _deleteIngredient,
        queryAwal: _stokQueryAwal,
        queryAwalKode: _stokFokusKode,
        onBarangMasuk: _barangMasuk,
        onOpname: _opname,
        onBukaRiwayat: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RiwayatMutasiScreen(mutasi: _mutasi, ingredients: _ingredients)),
        ),
      ),
      PengaturanScreen(
        businessName: _settings.businessName,
        businessAddress: _settings.businessAddress,
        businessPhone: _settings.businessPhone,
        servicePercent: _settings.servicePercent,
        taxPercent: _settings.taxPercent,
        menuCount: _menus.length,
        tableCount: _tables.length,
        ingredientCount: _ingredients.length,
        onServicePercentChanged: (v) => _settingChanged(() => _settings.servicePercent = v),
        onTaxPercentChanged: (v) => _settingChanged(() => _settings.taxPercent = v),
        tablesEnabled: _settings.tablesEnabled,
        onTablesEnabledChanged: (v) => _settingChanged(() {
          _settings.tablesEnabled = v;
          if (!v) {
            // Meja mati: lepas meja terpilih & jangan tinggal di
            // layar Meja yang sudah tidak ada di navigasi.
            _selectedTable = null;
            if (_index == 3) _index = 0;
          }
        }),
        kitchenEnabled: _settings.kitchenEnabled,
        onKitchenEnabledChanged: (v) => _settingChanged(() {
          _settings.kitchenEnabled = v;
          if (!v && _index == 4) _index = 0;
        }),
        onManageMenus: _openKelolaMenu,
        onManageTables: _openKelolaMeja,
        onManageIngredients: _openKelolaStok,
        branches: _settings.branches,
        activeBranchId: _settings.activeBranchId,
        pinSet: _settings.pinHash.isNotEmpty,
        onSwitchBranch: _switchBranch,
        onOpenProfile: _openProfile,
        onOpenPinSettings: _openPinSettings,
        onOpenBranchWizard: _openBranchWizard,
        onEditBranch: _bukaUbahCabang,
        onDeleteBranch: _hapusCabang,
        businessPhotoPath: _settings.businessPhotoPath,
        cloudSyncEnabled: _settings.cloudSyncEnabled,
        onCloudSyncChanged: (v) => _settingChanged(() => _settings.cloudSyncEnabled = v),
        statusSinkronRingkasan: _ringkasanStatusSinkron,
        onOpenSyncStatus: _openSyncStatus,
        modeTema: _settings.modeTema,
        onModeTemaChanged: (v) {
          _settingChanged(() => _settings.modeTema = v);
          widget.onModeTema(v, true);
        },
        onCekUpdate: _cekUpdateManual,
        statusSesiKasir: _sesiTerbuka == null ? 'Belum dibuka' : 'Buka sejak ${SesiKasirScreen.teksJam(_sesiTerbuka!.dibukaPada)}',
        onOpenSesiKasir: _openSesiKasir,
        statusPrinter: _desainStruk.printerSiap ? (_desainStruk.namaPrinter.isEmpty ? 'Terhubung' : _desainStruk.namaPrinter) : 'Belum diatur',
        onOpenStruk: _openDesainStruk,
        onResetTotal: _resetTotal,
      ),
    ];

    // Indeks layar yang tampil di navigasi. Meja (indeks 3) dan
    // Dapur (indeks 4) hilang dari SEMUA navigasi saat fiturnya
    // dimatikan di Pengaturan/wizard.
    final visible = <int>[
      for (var i = 0; i < _navItems.length; i++)
        if ((i != 3 || _settings.tablesEnabled) && (i != 4 || _settings.kitchenEnabled)) i,
    ];
    // Bar bawah HP (urutan pilihan): Beranda, Kasir, Produk, Dapur —
    // Produk masuk bar atas permintaan Adnan (meniru Bisakasir);
    // Meja & sisanya di sidebar geser 'Lainnya'. Tablet: semua tampil.
    const barOrder = [0, 1, 2, 4];
    final mainNav = <int>[for (final i in barOrder) if (visible.contains(i)) i];
    final drawerNav = <int>[for (final i in visible) if (!mainNav.contains(i)) i];

    final shell = LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _SideBar(
                    index: _index,
                    items: visible,
                    kitchenCount: _kitchen.where((o) => o.status == KitchenStatus.baru).length,
                    onChanged: (i) => setState(() => _index = i),
                    businessName: _settings.businessName,
                    branchName: _settings.activeBranch.name,
                    businessPhotoPath: _settings.businessPhotoPath,
                    unreadCount: _belumDibaca,
                    onOpenProfile: _openProfile,
                    onOpenSyncStatus: _openSyncStatus,
                    onOpenPin: _openPinSettings,
                    onOpenNotices: _openNotices,
                    onOpenAbout: () => showAppInfoDialog(context),
                  ),
                  Expanded(child: _tumpukanLayar(screens)),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          key: _phoneScaffoldKey,
          // Atas dilindungi SafeArea supaya judul tidak tertutup status bar.
          // Bawah tidak perlu: NavigationBar sudah menjaga jarak dari
          // tombol navigasi Android.
          body: SafeArea(
            bottom: false,
            child: _tumpukanLayar(screens),
          ),
          // Menu utama (Beranda, Kasir, Meja, Dapur) tinggal di bar
          // bawah; menu lain (Laporan, Stok, Pengaturan) pindah ke
          // sidebar geser yang dibuka dari tombol 'Lainnya' —
          // permintaan Adnan 2026-11-14: bar bawah lega, menu harian
          // gampang dijangkau. Saat meja mati, Meja keluar dari daftar
          // dan Dapur naik mengisi bar bawah.
          drawer: _PhoneDrawer(
            index: _index,
            items: drawerNav,
            businessName: _settings.businessName,
            businessPhotoPath: _settings.businessPhotoPath,
            unreadCount: _belumDibaca,
            onSelect: (i) => setState(() => _index = i),
            onOpenProfile: _openProfile,
            onOpenSyncStatus: _openSyncStatus,
            onOpenPin: _openPinSettings,
            onOpenNotices: _openNotices,
            onOpenAbout: () => showAppInfoDialog(context),
          ),
          bottomNavigationBar: Builder(
            builder: (barCtx) => BarNavigasiBawah(
              // Sedang di menu drawer → sorot 'Lainnya'.
              selectedIndex: mainNav.contains(_index) ? mainNav.indexOf(_index) : mainNav.length,
              onTap: (pos) {
                if (pos == mainNav.length) {
                  Scaffold.of(barCtx).openDrawer();
                } else {
                  setState(() => _index = mainNav[pos]);
                }
              },
              items: [
                for (final i in mainNav)
                  TujuanBar(
                    icon: _navItems[i].icon,
                    selectedIcon: _navItems[i].selectedIcon,
                    label: _navItems[i].label,
                    badge: i == 4 ? _kitchen.where((o) => o.status == KitchenStatus.baru).length : 0,
                  ),
                const TujuanBar(icon: Ikon.menu, selectedIcon: Ikon.menu, label: 'Lainnya'),
              ],
            ),
          ),
        );
      },
    );

    // Perayaan sesudah wizard: bundaran melebar lalu menyusut
    // membuka Beranda di belakangnya.
    final denganPerayaan = _celebrate
        ? Stack(
            children: [
              shell,
              Positioned.fill(
                child: SetupCelebration(
                  judul: 'Toko Sudah Siap!',
                  subjudul: '${_settings.businessName} · ${_settings.activeBranch.name}',
                  onSelesai: () => setState(() => _celebrate = false),
                ),
              ),
            ],
          )
        : shell;

    // Tombol kembali Android (permintaan Adnan): di menu lain →
    // pulang ke Beranda; di Beranda → tekan DUA kali untuk keluar.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _celebrate) return;
        if (_phoneScaffoldKey.currentState?.isDrawerOpen ?? false) {
          _phoneScaffoldKey.currentState?.closeDrawer();
          return;
        }
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }
        final kini = DateTime.now();
        if (_lastBackPress != null && kini.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = kini;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tekan sekali lagi untuk keluar'), duration: Duration(seconds: 2)),
        );
      },
      child: denganPerayaan,
    );
  }
}

/// Satu baris pintasan di drawer/sidebar (Profil, Status
/// Sinkronisasi, PIN, Pemberitahuan, Info) — isi sidebar ditambah
/// atas permintaan Adnan 2026-11-15 ('isinya masih sedikit').
class _BarisPintasan extends StatelessWidget {
  const _BarisPintasan({required this.icon, required this.label, required this.onTap, this.badge = 0});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ListTile(
          dense: true,
          minTileHeight: 48,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          leading: Icon(icon, color: AppColors.muted, size: 24),
          title: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
          trailing: badge > 0 ? StatusChip(label: '$badge', color: AppColors.danger) : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Avatar usaha 40px: foto profil usaha bila ada, selain itu
/// kotak aksen + ikon kafe seperti sebelumnya.
class _AvatarUsaha extends StatelessWidget {
  const _AvatarUsaha({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Icon(Ikon.local_cafe, color: AppColors.card, size: 20),
    );
    if (path == null || path!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.file(
        File(path!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Sidebar geser (drawer) khusus HP: menampung menu selain tiga menu
/// utama di bar bawah. Tampilannya meniru sidebar tablet supaya
/// rasanya satu keluarga.
class _PhoneDrawer extends StatelessWidget {
  const _PhoneDrawer({
    required this.index,
    required this.items,
    required this.businessName,
    required this.businessPhotoPath,
    required this.unreadCount,
    required this.onSelect,
    required this.onOpenProfile,
    required this.onOpenSyncStatus,
    required this.onOpenPin,
    required this.onOpenNotices,
    required this.onOpenAbout,
  });
  final int index;

  /// Indeks layar yang masuk drawer (menu selain bar bawah).
  final List<int> items;
  final String businessName;
  final String? businessPhotoPath;
  final int unreadCount;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSyncStatus;
  final VoidCallback onOpenPin;
  final VoidCallback onOpenNotices;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
              child: Row(
                children: [
                  _AvatarUsaha(path: businessPhotoPath),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
                        Text(businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Text('MENU LAINNYA', style: AppText.caption.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Material(
                  color: index == i ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ListTile(
                    dense: true,
                    minTileHeight: 48,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    leading: Icon(
                      index == i ? _navItems[i].selectedIcon : _navItems[i].icon,
                      color: index == i ? Colors.white : AppColors.muted,
                      size: 24,
                    ),
                    title: Text(
                      _navItems[i].label,
                      style: AppText.body.copyWith(
                        fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                        color: index == i ? Colors.white : AppColors.ink,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(i);
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Text('PINTASAN', style: AppText.caption.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ),
            _BarisPintasan(
              icon: Ikon.storefront_outlined,
              label: 'Profil Usaha',
              onTap: () {
                Navigator.of(context).pop();
                onOpenProfile();
              },
            ),
            _BarisPintasan(
              icon: Ikon.cloud_sync_outlined,
              label: 'Status Sinkronisasi',
              onTap: () {
                Navigator.of(context).pop();
                onOpenSyncStatus();
              },
            ),
            _BarisPintasan(
              icon: Ikon.pin_outlined,
              label: 'PIN Kasir',
              onTap: () {
                Navigator.of(context).pop();
                onOpenPin();
              },
            ),
            _BarisPintasan(
              icon: Ikon.notifications_outlined,
              label: 'Pemberitahuan',
              badge: unreadCount,
              onTap: () {
                Navigator.of(context).pop();
                onOpenNotices();
              },
            ),
            _BarisPintasan(
              icon: Ikon.info_outlined,
              label: 'Info Aplikasi',
              onTap: () {
                Navigator.of(context).pop();
                onOpenAbout();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('$appName v$appVersion · by $appStudio', style: AppText.caption.copyWith(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.index,
    required this.items,
    required this.onChanged,
    required this.kitchenCount,
    required this.businessName,
    required this.branchName,
    required this.businessPhotoPath,
    required this.unreadCount,
    required this.onOpenProfile,
    required this.onOpenSyncStatus,
    required this.onOpenPin,
    required this.onOpenNotices,
    required this.onOpenAbout,
  });
  final int index;

  /// Indeks layar yang tampil (Meja bisa hilang saat fiturnya mati).
  final List<int> items;
  final ValueChanged<int> onChanged;
  final int kitchenCount;
  final String businessName;
  final String branchName;
  final String? businessPhotoPath;
  final int unreadCount;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSyncStatus;
  final VoidCallback onOpenPin;
  final VoidCallback onOpenNotices;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 218,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
            child: Row(
              children: [
                _AvatarUsaha(path: businessPhotoPath),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
                      Text(appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                const Icon(Ikon.circle, size: 8, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Cabang aktif: $branchName', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Daftar menu bisa digulir — 8 menu di layar pendek tidak
          // boleh meluber (tes tablet 800px menangkap luber 5px).
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      child: Material(
                        color: index == i ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: ListTile(
                          dense: true,
                          minTileHeight: 44,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          leading: Icon(
                            index == i ? _navItems[i].selectedIcon : _navItems[i].icon,
                            color: index == i ? Colors.white : AppColors.muted,
                            size: 24,
                          ),
                          title: Text(
                            _navItems[i].label,
                            style: AppText.body.copyWith(
                              fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                              color: index == i ? Colors.white : AppColors.ink,
                            ),
                          ),
                          trailing: (i == 4 && kitchenCount > 0) ? StatusChip(label: '$kitchenCount baru', color: AppColors.danger) : null,
                          onTap: () => onChanged(i),
                        ),
                      ),
                    ),
                  const Divider(height: AppSpacing.xl, indent: AppSpacing.xl, endIndent: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('PINTASAN', style: AppText.caption.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  _BarisPintasan(icon: Ikon.storefront_outlined, label: 'Profil Usaha', onTap: onOpenProfile),
                  _BarisPintasan(icon: Ikon.cloud_sync_outlined, label: 'Status Sinkronisasi', onTap: onOpenSyncStatus),
                  _BarisPintasan(icon: Ikon.pin_outlined, label: 'PIN Kasir', onTap: onOpenPin),
                  _BarisPintasan(icon: Ikon.notifications_outlined, label: 'Pemberitahuan', badge: unreadCount, onTap: onOpenNotices),
                  _BarisPintasan(icon: Ikon.info_outlined, label: 'Info Aplikasi', onTap: onOpenAbout),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Data tersimpan di perangkat ini.\n\n$appName v$appVersion · by $appStudio', style: AppText.caption.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
