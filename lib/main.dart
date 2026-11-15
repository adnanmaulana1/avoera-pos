import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'data.dart';
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
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: gelap ? Brightness.light : Brightness.dark,
      ),
    );
    return MaterialApp(
      title: 'Avoera POS',
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
  _NavItem('Beranda', Icons.home_outlined, Icons.home),
  _NavItem('Kasir', Icons.point_of_sale_outlined, Icons.point_of_sale),
  _NavItem('Produk', Icons.inventory_2_outlined, Icons.inventory_2),
  _NavItem('Meja', Icons.table_restaurant_outlined, Icons.table_restaurant),
  _NavItem('Dapur', Icons.soup_kitchen_outlined, Icons.soup_kitchen),
  _NavItem('Laporan', Icons.bar_chart_outlined, Icons.bar_chart),
  _NavItem('Stok Bahan', Icons.inventory_outlined, Icons.inventory),
  _NavItem('Pengaturan', Icons.settings_outlined, Icons.settings),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onModeTema});

  /// Lapor perubahan pilihan tema ke KasirFnbApp (yang memegang
  /// MaterialApp): (mode, pakaiAnimasiIris).
  final void Function(String mode, bool animasi) onModeTema;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final List<CartItem> _cart = [];
  final List<KitchenOrder> _kitchen = seedKitchenOrders();
  CafeTable? _selectedTable;
  int _orderCounter = 1043;

  /// Gerbang PIN kasir: terbuka sekali per sesi aplikasi.
  bool _kasirUnlocked = false;

  /// Animasi perayaan sesudah wizard pertama selesai.
  bool _celebrate = false;

  // ---------- Sinkronisasi awan (Supabase) ----------
  StatusSinkron _syncStatus = StatusSinkron.belumDiatur;
  bool _syncing = false;
  Timer? _syncDebounce;
  Timer? _syncPeriodik;
  Timer? _syncTimeoutTimer;

  bool get _syncSiap => _settings.supabaseUrl.isNotEmpty && _settings.supabaseAnonKey.isNotEmpty && _settings.businessKey.isNotEmpty;

  /// Laporan sinkron terakhir per tabel + jumlah perubahan yang
  /// menunggu per tabel — bahan halaman Status Sinkronisasi.
  List<StatusTabel> _laporanSinkron = [];
  final Map<String, int> _kotor = {'menus': 0, 'ingredients': 0, 'branches': 0, 'transactions': 0, 'settings': 0};
  final ValueNotifier<int> _penandaSinkron = ValueNotifier<int>(0);

  /// Cloud Sync benar-benar jalan hanya bila diatur DAN saklarnya
  /// menyala (permintaan Adnan 2026-11-15).
  bool get _cloudAktif => _syncSiap && _settings.cloudSyncEnabled;

  // ---------- Pemberitahuan (tersimpan) ----------
  List<AppNotification> _notifications = [];
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
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _splashSelesai = true);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await LocalStore.load();
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
      _transactions = data.transactions;
      _notifications = data.notifications;
      _ready = true;
      _syncStatus = _cloudAktif ? StatusSinkron.tersinkron : StatusSinkron.belumDiatur;
    });
    // Meta sinkron tersimpan (menunggu + laporan terakhir).
    final meta = await LocalStore.loadSyncMeta();
    if (mounted) {
      final k = (meta['kotor'] as Map?)?.cast<String, dynamic>();
      if (k != null) {
        k.forEach((kunci, v) {
          if (_kotor.containsKey(kunci)) _kotor[kunci] = (v as num?)?.toInt() ?? 0;
        });
      }
      final lap = meta['laporan'] as List?;
      if (lap != null) {
        _laporanSinkron = lap.map((e) => StatusTabel.fromJson((e as Map).cast<String, dynamic>())).toList();
      }
      _penandaSinkron.value++;
    }
    widget.onModeTema(_settings.modeTema, false);
    _aturTimerSinkron();
    _periksaStokNotifikasi();
    if (_cloudAktif) _syncNow(diam: true);
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _syncPeriodik?.cancel();
    _syncTimeoutTimer?.cancel();
    _penandaSinkron.dispose();
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
    });
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
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  void _menuChanged() {
    setState(() {});
    LocalStore.saveMenus(_menus);
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  void _deleteMenu(MenuItem m) {
    setState(() {
      _menus.remove(m);
      _cart.removeWhere((c) => c.menu.id == m.id);
    });
    LocalStore.saveMenus(_menus);
    _tandaiKotor('menus');
    _jadwalkanSinkron();
  }

  // ---------- CRUD: Meja ----------
  void _addTable(CafeTable t) {
    setState(() {
      _tables.add(t);
      _tables.sort((a, b) => a.number.compareTo(b.number));
    });
    LocalStore.saveTables(_tables);
    _jadwalkanSinkron();
  }

  void _tableChanged() {
    setState(() => _tables.sort((a, b) => a.number.compareTo(b.number)));
    LocalStore.saveTables(_tables);
    _jadwalkanSinkron();
  }

  void _deleteTable(CafeTable t) {
    setState(() {
      _tables.remove(t);
      if (_selectedTable == t) _selectedTable = null;
    });
    LocalStore.saveTables(_tables);
    _jadwalkanSinkron();
  }

  // ---------- CRUD: Stok bahan ----------
  void _addIngredient(Ingredient i) {
    setState(() => _ingredients.add(i));
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    _periksaStokNotifikasi();
  }

  void _ingredientChanged() {
    setState(() {});
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
    _periksaStokNotifikasi();
  }

  void _deleteIngredient(Ingredient i) {
    setState(() => _ingredients.remove(i));
    LocalStore.saveIngredients(_ingredients);
    _tandaiKotor('ingredients');
    _jadwalkanSinkron();
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
        MaterialPageRoute(builder: (_) => RiwayatScreen(transactions: _transactions, branchId: _settings.activeBranchId)),
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

  /// Tambah pemberitahuan tersimpan. Kunci yang sama & belum
  /// dibaca = tidak ditambah lagi (mencegah banjir duplikat untuk
  /// keadaan yang sama, mis. stok yang memang sedang habis).
  void _tambahNotifikasi({required String jenis, required String judul, required String isi, required String kunci}) {
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
    LocalStore.saveNotifications(_notifications);
    if (mounted) setState(() {});
  }

  /// Periksa stok: bahan yang masuk keadaan kritis/habis
  /// melahirkan pemberitahuan (dijaga kunci per bahan+keadaan).
  void _periksaStokNotifikasi() {
    for (final i in _ingredients) {
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
      MaterialPageRoute(builder: (_) => NotifikasiScreen(notifications: _notifications)),
    );
    // Membuka pusat pemberitahuan = menandai semua sudah dibaca
    // (sedikit ditunda supaya halaman yang terbuka masih sempat
    // menampilkan penanda belum-dibacanya).
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _belumDibaca == 0) return;
      setState(() {
        for (final n in _notifications) {
          n.dibaca = true;
        }
      });
      LocalStore.saveNotifications(_notifications);
    });
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

  // ---------- Sinkronisasi Supabase ----------
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
    if (_syncing || !_syncSiap) return;
    if (!_settings.cloudSyncEnabled) {
      if (!diam && mounted) {
        tampilToast(context, 'Cloud Sync sedang mati — nyalakan di Pengaturan.', icon: Icons.cloud_off_outlined, warna: AppColors.warning);
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
      });
      LocalStore.saveMenus(_menus);
      LocalStore.saveIngredients(_ingredients);
      LocalStore.saveTransactions(_transactions);
      LocalStore.saveSettings(_settings);
      _simpanMetaSinkron();
      _syncing = false;
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
          tampilToast(context, hasil.ringkasan, icon: Icons.cloud_off_outlined, warna: AppColors.danger, durasi: const Duration(seconds: 5));
        }
      } else if (!diam && mounted) {
        tampilToast(context, hasil.ringkasan, icon: Icons.cloud_done_outlined);
      }
    } catch (e) {
      debugPrint('Sinkron gagal: $e');
      _syncing = false;
      final ringkas = ringkasErrorSinkron(e);
      _laporanSinkron = [
        for (final (kunci, label) in [
          ('branches', 'Cabang'),
          ('menus', 'Menu'),
          ('ingredients', 'Bahan'),
          ('transactions', 'Transaksi'),
          ('settings', 'Pengaturan'),
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
        tampilToast(context, 'Sinkron gagal: $ringkas', icon: Icons.cloud_off_outlined, warna: AppColors.danger, durasi: const Duration(seconds: 6));
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
    _jadwalkanSinkron();
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
  }

  void _inc(CartItem c) => setState(() => c.qty++);
  void _dec(CartItem c) => setState(() {
        if (c.qty > 1) {
          c.qty--;
        } else {
          _cart.remove(c);
        }
      });
  void _remove(CartItem c) => setState(() => _cart.remove(c));

  void _checkout(String paymentMethod, String tableLabel, String orderType) {
    // Total dihitung SEBELUM keranjang dikosongkan, untuk catatan
    // tagihan berjalan di kartu meja.
    final subtotal = _cart.fold(0, (a, c) => a + c.total);
    final serviceAmt = (subtotal * _settings.servicePercent / 100).round();
    final taxAmt = (subtotal * _settings.taxPercent / 100).round();
    final grandTotal = subtotal + serviceAmt + taxAmt;
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
        branchId: _settings.activeBranchId,
        uuid: 'u${DateTime.now().millisecondsSinceEpoch}-$_orderCounter',
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
            ing.stock = ing.stock - pakai < 0 ? 0 : ing.stock - pakai;
          }
        }
      }
      _cart.clear();
    });
    LocalStore.saveTables(_tables);
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
  }

  void _selectTable(CafeTable t) => setState(() => _selectedTable = t);

  /// Tumpukan layar utama dengan pudar singkat saat pindah tab
  /// (permintaan Adnan 2026-11-14): perpindahan menu terasa halus
  /// ±200 mdtk, BUKAN dorongan halaman. Keadaan tiap layar tetap
  /// utuh karena IndexedStack-nya sendiri tidak berubah.
  Widget _tumpukanLayar(List<Widget> screens) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_index),
      tween: Tween(begin: 0.45, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      // Tarik ke bawah di halaman mana pun = sinkron Supabase
      // (permintaan Adnan 23:51: data diambil dari internet,
      // semua halaman harus bisa ditarik untuk menyegarkan).
      child: RefreshIndicator(
        onRefresh: () => _syncNow(),
        child: IndexedStack(index: _index, children: screens),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_splashSelesai) {
      return const SplashScreen();
    }
    // Pemasangan pertama: onboarding + wizard cabang pertama dulu.
    if (!_settings.onboarded) {
      return OnboardingFlow(initial: _settings, onDone: _finishOnboarding);
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
      ),
      StokScreen(ingredients: _ingredients, onAdd: _addIngredient, onChanged: _ingredientChanged, onDelete: _deleteIngredient),
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
            builder: (barCtx) => NavigationBar(
              // Sedang di menu drawer → sorot 'Lainnya'.
              selectedIndex: mainNav.contains(_index) ? mainNav.indexOf(_index) : mainNav.length,
              onDestinationSelected: (pos) {
                if (pos == mainNav.length) {
                  Scaffold.of(barCtx).openDrawer();
                } else {
                  setState(() => _index = mainNav[pos]);
                }
              },
              destinations: [
                for (final i in mainNav)
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: i == 4 && _kitchen.where((o) => o.status == KitchenStatus.baru).isNotEmpty,
                      label: Text('${_kitchen.where((o) => o.status == KitchenStatus.baru).length}'),
                      child: Icon(_navItems[i].icon),
                    ),
                    selectedIcon: Icon(_navItems[i].selectedIcon),
                    label: _navItems[i].label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.menu),
                  selectedIcon: Icon(Icons.menu),
                  label: 'Lainnya',
                ),
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
      child: Icon(Icons.local_cafe, color: AppColors.card, size: 20),
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
                  color: index == i ? AppColors.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ListTile(
                    dense: true,
                    minTileHeight: 48,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    leading: Icon(
                      index == i ? _navItems[i].selectedIcon : _navItems[i].icon,
                      color: index == i ? AppColors.accentDark : AppColors.muted,
                      size: 24,
                    ),
                    title: Text(
                      _navItems[i].label,
                      style: AppText.body.copyWith(
                        fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                        color: index == i ? AppColors.accentDark : AppColors.ink,
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
              icon: Icons.storefront_outlined,
              label: 'Profil Usaha',
              onTap: () {
                Navigator.of(context).pop();
                onOpenProfile();
              },
            ),
            _BarisPintasan(
              icon: Icons.cloud_sync_outlined,
              label: 'Status Sinkronisasi',
              onTap: () {
                Navigator.of(context).pop();
                onOpenSyncStatus();
              },
            ),
            _BarisPintasan(
              icon: Icons.pin_outlined,
              label: 'PIN Kasir',
              onTap: () {
                Navigator.of(context).pop();
                onOpenPin();
              },
            ),
            _BarisPintasan(
              icon: Icons.notifications_outlined,
              label: 'Pemberitahuan',
              badge: unreadCount,
              onTap: () {
                Navigator.of(context).pop();
                onOpenNotices();
              },
            ),
            _BarisPintasan(
              icon: Icons.info_outlined,
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
                const Icon(Icons.circle, size: 8, color: AppColors.accent),
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
                        color: index == i ? AppColors.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: ListTile(
                          dense: true,
                          minTileHeight: 44,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          leading: Icon(
                            index == i ? _navItems[i].selectedIcon : _navItems[i].icon,
                            color: index == i ? AppColors.accentDark : AppColors.muted,
                            size: 24,
                          ),
                          title: Text(
                            _navItems[i].label,
                            style: AppText.body.copyWith(
                              fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                              color: index == i ? AppColors.accentDark : AppColors.ink,
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
                  _BarisPintasan(icon: Icons.storefront_outlined, label: 'Profil Usaha', onTap: onOpenProfile),
                  _BarisPintasan(icon: Icons.cloud_sync_outlined, label: 'Status Sinkronisasi', onTap: onOpenSyncStatus),
                  _BarisPintasan(icon: Icons.pin_outlined, label: 'PIN Kasir', onTap: onOpenPin),
                  _BarisPintasan(icon: Icons.notifications_outlined, label: 'Pemberitahuan', badge: unreadCount, onTap: onOpenNotices),
                  _BarisPintasan(icon: Icons.info_outlined, label: 'Info Aplikasi', onTap: onOpenAbout),
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
