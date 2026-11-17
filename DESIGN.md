# Sistem Desain Avoera POS

Satu-satunya sumber aturan tampilan aplikasi ini. Semua layar WAJIB memakai
token dari `lib/theme.dart` dan komponen bersama dari `lib/widgets.dart`.
Tidak ada angka radius / ukuran teks / warna mentah di file layar.

Prinsip (antislop-ui): tanpa glassmorphism, tanpa gradasi, tanpa glow.
Satu aksen dipakai hemat, hanya di momen penting (aksi utama, keadaan
terpilih, status). Radius dan bayangan adalah penanda hierarki, bukan dekorasi.

Font dipatok **Roboto** (font sistem Android, aman offline) di `AppText`
dan di tema — font bawaan tiap merek HP berbeda dan bikin tampilan bergeser.

## Warna (AppColors)

| Token | Nilai | Pakai untuk |
|---|---|---|
| accent | #059669 | Aksi utama, keadaan terpilih, status aman |
| accentDark | #047857 | Teks/ikon di atas accentSoft, harga sorotan |
| accentSoft | #ECFDF5 | Latar keadaan terpilih (chip, nav, sidebar, lingkaran ikon) |
| ink | #111827 | Teks utama, tombol netral gelap (selesai di dapur) |
| muted | #6B7280 | Teks sekunder (di atas bg/card tetap terbaca) |
| bg | #F7F7F5 | Latar halaman |
| card | #FFFFFF | Latar kartu, chip tak terpilih, sheet, dialog |
| border | #E5E7EB | Garis tepi kartu, chip, pemisah |
| warning | #D97706 | Status perhatian (dimasak, stok kritis, meja terisi) |
| warningSoft | #FFFBEB | Latar kartu peringatan |
| warningBorder | #FDE68A | Tepi kartu peringatan |
| danger | #DC2626 | Status darurat (pesanan baru, stok habis, belum bayar, hapus) |
| track | #F3F4F6 | Rel bar stok |
| chartBar | #A7F3D0 | Batang grafik tidak aktif |
| chartBarActive | = accent | Batang grafik hari sorotan |

Warna blok menu di `data.dart` adalah identitas produk (pengganti foto),
bukan token UI — boleh tetap di data.

## Jarak (AppSpacing) — kelipatan 4

`xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32`

- Padding halaman: 16. Padding kartu: 16 (kartu statistik kompak: 12).
- Jarak antar seksi: 20. Jarak antar kartu sejenis: 12.
- Jarak di dalam kartu antar baris: 4 / 8.

## Radius (AppRadius)

| Token | Nilai | Pakai untuk |
|---|---|---|
| xs | 6 | Khusus elemen kecil: ujung batang grafik |
| sm | 10 | Logo, item navigasi sidebar |
| md | 14 | Kartu, tombol, kolom isian, dialog kecil |
| lg | 20 | Sheet bawah (sudut atas), dialog, kartu utama Beranda |
| pill | 999 | Chip status, chip pilihan, bar stok |

## Bayangan (AppShadows) — dosis ketat

Hanya SATU elemen boleh berbayangan: kartu penjualan Beranda
(`AppShadows.heroCard`, emerald gelap, blur 24, offset y10) — karena
ia angka pertama yang dicek pemilik tiap membuka aplikasi. Semua
kartu/ tombol/daftar lain duduk RATA dengan garis tepi. Bayangan di
mana-mana = tidak ada hierarki (antislop-ui R-12).

## Keputusan v0.6.0 (polesan UI/UX)

- **Kartu menu kasir:** blok warna penuh 76px dihapus — terkesan
  kekanakan. Warna menu tetap identitas produk, tapi cukup sebagai
  rona (alpha 0,14) kotak ikon 40px; ikon memakai warna menu itu
  sendiri. Sisa kartu: nama (w600), kategori (caption muted), harga
  (w800), tombol +.
- **Kartu penjualan Beranda:** emerald pekat + dua lingkaran putih
  sangat tipis (alpha 0,07/0,05) sebagai tekstur sewarna — bukan
  gradasi, bukan orbe cahaya. Angka memakai `AppText.display`.
- **Tanggal asli** di bawah sapaan Beranda (hari, tanggal, bulan,
  tahun Bahasa Indonesia) — detail nyata, bukan ornamen.

Radius menandai tingkat: pill = label/pilihan, md = permukaan kerja,
lg = permukaan yang melayang di atas layar (sheet/dialog).

## Teks (AppText) — tidak ada ukuran di luar skala ini

| Token | Ukuran | Pakai untuk |
|---|---|---|
| caption | 11 | Label mikro: sub-info sidebar, waktu, nilai batang grafik |
| small | 12 | Teks sekunder: subjudul halaman, petunjuk, label chip, varian |
| body | 14 | Teks utama: nama menu, nama bahan, isi daftar |
| subtitle | 15 | Penekanan ringan: nama bahan, ID pesanan, teks tombol utama |
| title | 17 | Judul blok dalam kartu/panel, total bayar, judul sheet/dialog |
| pageTitle | 20 | Judul halaman (satu per layar, lewat PageHeader) |
| number | 22 | Angka statistik di kartu laporan |
| hero | 26 | Angka paling menonjol tunggal (nomor meja) |
| display | 32 | KHUSUS angka penjualan hari ini di Beranda — satu-satunya |

Berat yang dipakai: 400 normal, 600 semibold, 700 bold, 800 extrabold.
Teks tidak pernah lebih kecil dari 11.

## Komponen (lib/widgets.dart + theme.dart)

- **PageHeader** — satu-satunya bentuk kepala layar: judul pageTitle,
  subjudul small muted di bawahnya (jarak 4), aksi opsional di kanan.
- **AppCard** — card putih, radius md, tepi border, padding 16, tanpa bayangan.
- **AppChip** — chip pilihan tunggal di semua layar (kategori, filter stok,
  varian, metode bayar). Terpilih: latar accent, teks putih. Tak terpilih:
  latar card, teks ink, tepi border. Bentuk pill.
- **StatusChip** — label status pill: latar = warna status dilembutkan 12%,
  teks = warna status, caption tebal. Warna status selalu dari token yang
  sama (aman=accentDark, perhatian=warning, darurat=danger).
- **QtyButton** — tombol +/− bulat: daerah sentuh 44px, lingkaran 36px.
  Varian filled (accent, ikon putih) untuk tambah cepat di kartu menu;
  varian outlined (tepi border) untuk pengatur jumlah.
- **PrimaryButton** — tombol aksi utama: tinggi 52, radius md, teks
  subtitle tebal (15/700), latar accent. Satu-satunya pengecualian warna:
  aksi "selesai" dapur memakai ink. Semua FilledButton mengikuti gaya ini
  lewat tema (termasuk tombol di dialog).
- **SearchField / kolom isian** — gaya dari tema: latar card, radius md,
  tepi border, tepi accent saat fokus.
- **SegmentedButton** (Dine-in/Bungkus) — radius md; terpilih latar
  accentSoft + teks accentDark; tinggi minimum 44.
- **Sheet bawah** — latar card, sudut atas radius lg, ada handle
  (40×4 pill, warna border) di tengah atas, padding 20/16.
- **Dialog** — latar card, radius lg, judul title. Tombol utama =
  PrimaryButton style; tombol batal = TextButton accentDark.
- **EmptyState** — ikon opsional + pesan muted di tengah, padding 24.
  Pesan harus menyebut keadaan ("Keranjang masih kosong…"), bukan "No data".
- **Navigasi** — keadaan terpilih selalu sama di HP dan tablet:
  latar accentSoft, ikon/teks accentDark, ikon 24, label small.
  Badge jumlah memakai danger.

## Sentuh & bayangan

- Daerah sentuh minimum 44×44px untuk semua tombol dan chip.
- Hampir semua permukaan DATAR (tanpa bayangan). Bayangan hanya boleh
  muncul dari bawaan Material pada sheet bawah dan dialog — tidak ada
  BoxShadow dekoratif di kartu, termasuk kartu terpilih (cukup tepi accent).

## Keputusan v0.7.0 (fondasi produk asli)

- **Navigasi:** 8 layar. Bar bawah HP = Beranda, Kasir, Produk,
  Dapur, Lainnya — Produk masuk bar (permintaan Adnan, meniru
  Bisakasir); Meja pindah ke drawer di HP (di tablet tetap di
  sidebar penuh). Meja mati → hilang dari semua navigasi.
- **Beranda** meniru pola Bisakasir dengan angka ASLI: grafik
  "Penjualan 8 Hari Terakhir" (Mingguan) / 4 minggu (Bulanan),
  Transaksi Terbaru (kosong → ajakan Buka Kasir), lonceng
  pemberitahuan dengan lencana jumlah stok bermasalah.
- **Onboarding:** 3 halaman SVG beranimasi (melayang halus) +
  wizard cabang pertama. SVG TIDAK memakai elemen teks (rusak di
  flutter_svg) — hanya bentuk.
- **Laporan = hub jujur:** yang datanya ada bisa dibuka
  (Transaksi, Bulanan, Pajak, Piutang); sisanya berchip 'Segera'
  + keterangan data yang dibutuhkan. Angka contoh DIHAPUS.
- Transaksi kini mencatat rincian subtotal/biaya/pajak + cabang —
  fondasi Laporan Pajak, Laba Rugi, dan multi-cabang.

## Keputusan v0.8.0 (permintaan besar Adnan 2026-11-14)

- **Pill/filter SATU bentuk di semua layar:** FilterChipRow
  (gulir mendatar, AppChip) — Kasir, Produk, Stok, Meja, Dapur
  (HP), Riwayat, Pajak, Pengaturan tema. Tidak ada lagi Wrap /
  Row / ListView chip versi masing-masing layar.
- **Angka statistik selalu utuh:** FitNumber (FittedBox scaleDown)
  di kartu Beranda, Laporan, Riwayat, Piutang — Rp1.000.000 dan
  Rp123.456.789 tampil penuh, tidak dibulatkan, tidak kepotong.
- **Harga selalu berformat titik:** ThousandsFormatter dipakai
  formulir menu, dialog bayar, dan semua kolom harga baru.
- **Formulir dijaga:** editor (menu/bahan/meja) + halaman formulir
  (Profil Usaha, PIN, Wizard Cabang, dialog teks/persen) memakai
  GuardBack — tombol kembali / ketuk luar saat isi berubah →
  peringatan "Perubahan belum disimpan" dulu. FormSheet dibatasi
  92% tinggi layar & bergulir (tombol bawah tidak boleh jatuh di
  luar layar).
- **Ekspor di mana-mana:** TombolEkspor (ikon bagikan) membuka
  menu yang sama: ringkasan teks (WhatsApp), CSV, PDF —
  Riwayat, Bulanan, Pajak, Piutang, Stok, Produk.
- **PIN kasir:** halaman pengaturan sendiri; gerbang PIN (papan
  angka sendiri) mengunci Kasir bila PIN diatur, sekali per sesi.
- **Animasi yang hidup tapi hemat:** denyut cepat tombol + dan
  total keranjang bergerak (AnimatedRupiah) di kasir; bundaran
  perayaan sesudah wizard; iris melingkar saat ganti tema
  (gambar tema lama di-clip lingkaran membesar dari tombol yang
  diketuk, tema baru mengintip dari dalam lingkaran). Semua
  ±300–2300 mdtk, tanpa dekorasi lain.
- **Mode gelap:** warna permukaan/teks jadi getter sadar mode di
  AppColors (aksen tetap); palet gelap = arang kehijauan
  (#121614 latar, #1C211E kartu). Pilihan Terang/Gelap/Ikuti
  Sistem di Pengaturan → Tampilan, bawaan Ikuti Sistem.
- **Sinkron awan (Supabase):** data lokal tetap utama; sinkron
  otomatis (sesudah data berubah + tiap 45 detik + saat buka)
  dan manual. Indikator = ikon awan di Beranda (abu = belum
  diatur, berputar = menyinkron, centang = tersinkron, merah =
  gagal). Skema & panduan di folder supabase/.
- **Produk ala Kasaba:** baris foto + nama + chip kategori + SKU
  + harga kanan; menu ⋯ = Harga Massal, Tampilkan Bahan Baku,
  Pilih Produk, Ekspor/Impor — sisanya (Resep, Bundle, Harga
  Ojol, Cetak Label) ditandai 'Segera' dengan jujur.

## Catatan v0.8.1+18 (permintaan + laporan Adnan 2026-11-14 malam)

- **Kolom isian SATU gaya baru:** label kecil tebal DI ATAS kolom
  (FormLabel), kotak isi beralas lembut (AppColors.fieldFill),
  TANPA garis tepi & tanpa label melayang di garis (gaya lama
  dibuang dari semua formulir: Profil Usaha, wizard, PIN,
  editor kelola, dialog). Garis hanya muncul saat kolom aktif
  (accent 1,5px).
- **Aturan warna tema:** widget yang bisa dibuat const dan membaca
  warna AppColors di build (SectionTitle, PageHeader, EmptyState)
  WAJIB membaca Theme.of(context) di build-nya — kalau tidak,
  warnanya basi saat mode terang/gelap diganti di tengah jalan
  (kejadian nyata: judul seksi Pengaturan tak terlihat di gelap).

## v0.9.0 — Brand Avorea, Fitur "Segera" Tuntas, Status Sinkron (2026-11-15)

Diminta Adnan 2026-11-15 pagi (dengan artwork banner Avorea — "Maestro
Alpukat Kocok"): splash screen dari artwork, rombak kunci kasir, tombol
cari Produk saat tergulir, sidebar ditambah isi, semua fitur "Segera"
dituntaskan, foto profil usaha, notifikasi difungsikan, menu
Sinkronisasi Online dirapikan, toast didesain ulang. Catatan tambahan
Adnan di tengah jalan: toast "Menyinkronkan…" DIBUANG — penanda proses
cukup dari putaran ikon awan / indikator tarik-untuk-segar; toast hanya
untuk hasil akhir.

- **Identitas brand:** logo dipotong dari banner (kotak logo saja;
  berkas asli banner TIDAK ikut APK — disimpan di luar repo).
  Warna brand: hijau alpukat tua #1E3A2A (latar splash), kuning
  #F5B921 (slogan), krem #F7F8F2 (kartu logo). Aset:
  assets/branding/avorea-logo.png.
- **Splash:** layar penuh hijau brand, kartu krem berisi logo, slogan
  kuning "Bikin Harimu Lebih Segar!", penanda muat kecil, footer
  "Avoera POS · by Webtales Studio". Tampil selama data dimuat,
  minimal ±0,5 detik, animasi masuk fade+scale halus. Ukuran logo
  ditetapkan eksplisit + fallback teks "AVOREA" bila aset gagal —
  pelajaran: widget gambar tanpa ukuran membuat tata letak runtuh
  saat gambar belum termuat.
- **Kunci kasir:** kepala bergaya brand (kartu logo + nama usaha +
  chip "Kasir Terkunci"), tombol angka kini lingkaran terisi lembut.
  Semua perilaku lama dipertahankan: titik PIN membesar saat ditekan,
  goyang + titik merah + getar saat salah, tekan-lama hapus =
  kosongkan.
- **Produk:** tombol cari bulat melayang muncul di atas tombol +
  sesudah daftar digulir jauh; ketuk = kembali ke atas + fokus ke
  kolom cari. Menu ⋯: empat item "Segera" kini berfungsi semua.
- **Resep & HPP:** tiap menu bisa punya resep (bahan + takaran per
  porsi). Bahan kini punya "Harga Beli per Satuan" → HPP per porsi
  dihitung dan margin ditampilkan langsung di editor menu. Saat
  pembayaran berhasil, stok bahan DIPOTONG otomatis sesuai resep
  (bundle diperluas ke isi-isinya), tidak pernah di bawah nol.
- **Bundle:** menu bisa ditandai paket berisi menu lain (isi + jumlah
  diatur di editor); lencana "Bundle" di daftar Produk; layar kelola
  Resep & Bundle tersendiri dari menu ⋯ Produk.
- **Harga Ojol:** kolom harga khusus ojek online per menu (boleh
  kosong); saklar "Tampilkan Harga Ojol" di menu ⋯ menampilkannya di
  daftar Produk. Sifatnya tampilan/informasi — belum ada integrasi
  ojol sungguhan.
- **Cetak Label Harga:** pratinjau label (nama usaha, nama menu,
  kategori, harga) dalam kisi bergaya kertas + tombol "Bagikan /
  Cetak PDF" (PDF A4 siap cetak).
- **Foto profil usaha:** halaman Profil Usaha kini bisa memasang foto
  (kamera/galeri/hapus); foto tampil juga sebagai avatar kecil di
  kartu profil Pengaturan dan di kepala sidebar/drawer. Foto hanya
  tersimpan lokal di HP (tidak ikut sinkron).
- **Notifikasi difungsikan:** pemberitahuan kini DISIMPAN (riwayat
  tetap ada sesudah aplikasi ditutup), dibuat otomatis untuk stok
  habis & stok kritis (tanpa dobel selama belum dibaca) dan untuk
  sinkron yang gagal. Lonceng Beranda + baris Pemberitahuan di drawer
  menampilkan jumlah belum dibaca; membuka halaman = menandai semua
  dibaca (ditunda ±0,7 detik supaya penanda sempat terlihat).
- **Sinkronisasi Online dirapikan:** di Pengaturan kini hanya 2 baris
  — saklar "Cloud Sync" (matikan = semua sinkron otomatis berhenti)
  dan "Status Sinkronisasi". Halaman Status khusus berisi: kartu
  status terakhir, daftar "Menunggu Terkirim" (perubahan lokal yang
  belum terkirim, dihitung per jenis data dan disimpan persisten),
  "Hasil Sinkron Terakhir" per tabel (termasuk pesan galatnya),
  tombol "Sinkronkan Sekarang", "Perbarui Semua Data" (kirim ulang
  semua data lokal ke server, dengan dialog konfirmasi), dan
  pengaturan Supabase (URL/Kunci/Kode Usaha) yang PINDAH ke halaman
  ini dari Pengaturan. Sinkron kini tahan banting per tabel: satu
  tabel gagal tidak membatalkan tabel lain.
- **Toast baru:** pemberitahuan melayang bergaya pil gelap dengan
  lingkaran ikon berwarna (hijau berhasil, merah gagal, oranye
  peringatan) + bayangan; dipakai di seluruh aplikasi.
- **FormSheet (semua formulir sheet):** tombol Simpan/Hapus kini
  TETAP di bawah, isi yang bergulir — perbaikan dari temuan uji:
  formulir yang makin panjang (editor menu + resep + bundle) membuat
  tombol yang ikut bergulir berhenti beberapa piksel di luar tepi
  bawah layar 800px dan tidak terjangkau ketukan.

## v0.9.1 (2026-11-15) — Desain ulang splash & wizard pertama (permintaan Adnan dari screenshot HP)
- Splash TOTAL: logo tidak lagi di dalam kotak putih. Berkas baru assets/branding/avorea-logo-gelap.png = varian logo asli untuk latar gelap (pola latar dibuang via keying PIL; hijau gelap badan alpukat + teks 'MAESTRO ALPUKAT KOCOK' diangkat ke hijau muda sage agar terbaca di emerald; kuning & bentuk asli utuh). Latar emerald gradasi halus 3 titik + cahaya radial lembut + cincin tipis di sudut (CustomPainter). Loader = garis tipis kuning brand (bukan spinner). Footer huruf renggang samar. Mekanisme tampil & alur startup TIDAK berubah. Pelajaran: Stack di body Scaffold WAJIB fit: StackFit.expand — tanpa itu Stack menyusut selebar isi & konten bergeser kiri (ketahuan dari bedah frame: ada garis sambungan vertikal di 79% lebar).
- Wizard 'Atur Cabang Pertama': kepala ringkas (lencana ikon emerald + judul 22 + subjudul), seksi berlabel huruf renggang (USAHA/KEAMANAN/MODE OPERASIONAL), kolom isian KHUSUS wizard berlatar putih + garis tepi tipis + fokus aksen (halaman lain tetap gaya global), PIN dapat show/hide (ikon mata), kartu saklar berikon samping + rel emerald, galat jadi spanduk merah lembut berikon, tombol Mulai Berjualan lebar penuh, lebar formulir dibatasi 520 di layar lebar. Semua label/validasi/logika sama persis.

## v0.9.2 (2026-11-15) — Splash lebih lama + tanda tangan rilis TETAP
- Splash minimum 500ms -> 1500ms (permintaan Adnan: terlalu cepat). Gerbang di HomeShell (Timer initState); mekanisme sama.
- AKAR MASALAH "tiap update wajib uninstall": build Codemagic selama ini ditandatangani kunci DEBUG mesin build, dan mesin Codemagic berganti tiap build -> kuncinya ikut berganti -> Android menolak update. Obat: keystore rilis tetap avoera-release.jks (alias avoera, RSA 2048, 10000 hari; berkas di ~/workspace/avoera-keystore/, JANGAN masuk repo) diunggah SEKALI oleh Adnan ke Codemagic (Code signing identities, referensi avoera_release); codemagic.yaml android-release kini memuat android_signing: [avoera_release]; build.gradle.kts membuat signingConfig rilisTetap dari CM_KEYSTORE_PATH/CM_KEYSTORE_PASSWORD/CM_KEY_ALIAS/CM_KEY_PASSWORD bila ada, selain itu fallback debug (build lokal tidak berubah). Konsekuensi: APK bertanda tangan tetap PERTAMA tetap perlu uninstall sekali (kunci berubah dari debug ke rilis), sesudah itu semua update langsung timpa.

## v0.10.0 (2026-11-15) — Modul Gudang: barang masuk, opname, riwayat mutasi (permintaan Adnan)
- **MutasiStok (kartu stok):** SETIAP perubahan jumlah bahan tercatat — jenis masuk/jual/opname/edit, jumlah bertanda (+/−), stok sesudah, catatan, waktu; nama bahan & satuan disimpan sebagai salinan (riwayat utuh walau bahan diganti nama/dihapus). Maks 800 baris terakhir. Tersimpan lokal (avoera.mutasi.v1); stoknya sendiri tetap tersinkron lewat tabel ingredients, riwayatnya per perangkat.
- **Yang mencatat:** formulir Barang Masuk (stok + harga beli terbaru → dasar HPP), Opname (hitung fisik; selisih tampil langsung sebelum simpan), potongan resep saat bayar (jenis jual), ubah stok manual di editor (jenis edit, dari selisih stok yang dikenal shell), bahan baru (stok awal) & bahan dihapus.
- **Tampilan:** tiga ubin aksi di halaman Stok Bahan (ikon di atas, label di bawah). Keputusan bentuk dari audit frame anti-slop: tombol sebaris ikon+teks mematahkan kata di tengah pada lebar HP ("Opnam/e", "Riwaya/t") — ubin muat di semua lebar. Sheet Barang Masuk & Opname mengikuti pola FormSheet (label di atas kolom, tombol simpan tetap di bawah); Riwayat = daftar kartu dengan ikon berwarna semantik per jenis + saringan jenis/bahan. Tanpa gradasi/kaca/glow; warna hanya emerald brand + semantik stok.
- Controller sheet WAJIB dibuang tunda (disposeControllersLater) — dibuang langsung bikin TextField meledak saat animasi tutup sheet (ketahuan dari tes gudang pertama).

## v0.10.1 (2026-11-15) — Patch gabungan dari screenshot Adnan + perbaikan bug sinkron
- **Sheet lebih bersahabat:** FormSheet punya tombol X opsional (showClose) dan tinggi maks 85% layar (dari 92%). Sheet gudang (Barang Masuk/Opname) kini bisa ditutup 3 cara: X, ketuk di luar, tombol kembali. PELAJARAN KERAS: tombol X WAJIB memanggil maybePop(), BUKAN pop() — pop() menembus PopScope(canPop:false) sehingga dialog "buang perubahan" di editor kotor tidak pernah muncul (dibuktikan tes gagal→lulus).
- **Pemberitahuan:** pill saring kategori (Semua/Stok/Sinkron/Info, hanya yang ada datanya; tanpa ikon centang sesuai aturan) + tombol "Tandai semua terbaca". Membuka halaman TIDAK lagi menandai terbaca otomatis — eksplisit lewat tombol. Notifikasi dibuat & disimpan di perangkat (stok + kegagalan sinkron); datanya sendiri yang tersinkron, notifikasinya tidak.
- **Beranda bisa diketuk:** kartu Penjualan → Riwayat, Transaksi/Rata-rata → Riwayat, Di Dapur → Dapur, Menu Dijual → Produk, grafik → Laporan. Persen vs kemarin kini tampil juga saat hari ini Rp0 (kemarin > 0 → −100%); kemarin Rp0 & hari ini ada → pill "Mulai tercatat". Tiga kartu statistik dikunci sebaris setinggi 88px (seukuran di semua HP). Ubin Menu Cepat rasio 1:1 (childAspectRatio), bukan tinggi tetap.
- **PIN:** tombol angka 88px (jarak antar lingkaran 20px), lingkaran 68px + garis tepi tipis; titik PIN 15px. Perilaku tetap (goyang saat salah, tekan lama hapus = kosongkan).
- **Pembayaran = halaman penuh** (PembayaranScreen), bukan dialog: metode Tunai/QRIS, kartu rincian, chip nominal + kolom ketik berbagi satu nilai, bar bawah berisi status (kurang/kembalian) + tombol Proses Bayar selebar layar. Menghapus cacat lama: tombol melayang menutupi kolom uang diterima. Alur sesudah bayar (sukses, stok, dapur) tidak berubah.
- **Produk:** kepala menyusut beranimasi proporsional guliran (CustomScrollView + SliverPersistentHeader 168→58px; judul+kolom cari memudar, baris ringkas berisi judul + ikon cari + menu ⋯). Baris chip kategori tetap menempel (header kedua 50px). Tombol ⋯ hanya SATU instance melayang kanan-atas (posisi ikut menyusut) — dua instance bikin ketuk ambigu. Sesudah editor produk ditutup (termasuk habis hapus), fokus kolom cari dilepas supaya keyboard tidak menyembul lagi.
- **Tarik-untuk-segar:** tampil rangka shimmer (ShimmerSkeleton, gelombang denyut per balok di atas latar buram yang menyerap ketukan), TANPA toast — sinkron diam (diam:true); kegagalan tetap jadi notifikasi tersimpan.
- **Toast tindakan:** hapus produk/bahan/meja kini memunculkan toast penegas ("Produk X dihapus.").
- **Navbar Android:** warna bar navigasi sistem + NavigationBar aplikasi = warna latar aplikasi (AppColors.bg), bukan putih — pita putih asing di bawah aplikasi hilang, termasuk di mode gelap. Layar Status Sinkronisasi: bantalan bawah ditambah tinggi inset sistem (konten tidak lagi tertutup navbar).
- **BUG SINKRON — barang terhapus hidup lagi (akar masalah):** unggah hanya upsert, tidak pernah menghapus baris server; gabung tarikan menambah lagi baris server yang tidak ada di lokal → hapusan lokal selalu kalah. Obat: perangkat mengingat id yang pernah dikenal per tabel (dikenal, tersimpan di syncmeta); sebelum unggah, id yang dikenal tapi sudah tidak ada di lokal DIHAPUS dari server (cabang/menu/bahan saja; transaksi & pengaturan dikecualikan). Id server yang tidak dikenal = barang baru dari perangkat lain, tidak disentuh. Fungsi murni idHantuDiServer teruji unit. Batas jujur: perang hapus antar perangkat masih bisa menghidupkan barang (perangkat B yang masih menyimpan akan mengunggahnya lagi) — batu nisan (tombstone) belum dibuat.

## v0.10.2 (2026-11-15) — Halaman Pembayaran diperkaya (keluhan Adnan: "terlalu sederhana")
- **Kartu total emerald besar:** total bayar angka display putih + jumlah item + rincian Subtotal/Biaya layanan/Pajak sebagai baris putih di dalamnya — bahasa visual yang sama dengan kartu penjualan Beranda, tanpa bayangan hero (disiplin bayangan tetap: hero Beranda satu-satunya).
- **Rincian pesanan asli:** PembayaranScreen menerima items (BarisBayar: nama, keterangan varian/catatan, qty, total baris) dari keranjang kasir; tampil sebagai kartu dengan lencana ×qty. Kasir akhirnya bisa memeriksa yang dibayar TANPA kembali ke keranjang.
- **Metode = kartu pilih bergambar** (Tunai/QRIS, ikon + label; terpilih = latar accentSoft + garis accent 1.5) menggantikan chip kecil. **Nominal = ubin 2×2 besar**; Uang pas membawa keterangan totalnya; nominal di bawah total redup & mati. Status pindah ke kartu di badan halaman: Kembalian (accentSoft + ikon tabungan, teks tunggal "Kembalian: RpX") / Masih kurang (warningSoft + garis peringatan). Bar bawah tinggal petunjuk saat kosong + tombol Proses Bayar.
- **QRIS:** kotak QR besar di atas rel track + instruksi + nominal + catatan jujur "Kode QR asli muncul saat QRIS SoraPay aktif."
- Perilaku & alur uang TIDAK berubah (chip⇄kolom satu nilai, kunci tombol, metode kembali ke kasir); semua tes lama lolos tanpa diubah selain penyesuaian versi.

## v0.10.3 (2026-11-15) — Shimmer hanya saat muat awal & tarik jauh (keputusan Adnan 12:04)
- **Keluhan:** shimmer terasa selalu muncul saat menggulir biasa. Akar masalah: RefreshIndicator bawaan memicu hanya dari tarikan ±40px di puncak daftar. Sinkron otomatis BUKAN penyebabnya (tidak pernah menyalakan shimmer di kode).
- **Obat:** RefreshIndicator dibuang, diganti detektor sendiri (_padaNotifikasiGulir): jarak tarikan jari melewati tepi atas diakumulasi dari OverscrollNotification; shimmer + sinkron hanya jalan bila tarikan ≥120px dalam satu gestur (tarikan yang disengaja). Lemparan (ballistic, tanpa dragDetails) tidak dihitung; kunci per gestur direset di ScrollEndNotification.
- **PELAJARAN KERAS:** akumulasi dari ScrollUpdateNotification KELAPARAN — saat posisi mentok di puncak, posisi tidak berubah sehingga notifikasi update berhenti terkirim. Sinyal yang benar untuk tarikan melewati tepi adalah OverscrollNotification (overscroll negatif di tepi awal). Dibuktikan tes: tarik 340px → shimmer menyala; tarik 60px → diam.
- **Muat awal:** gerbang start dipecah — layar pembuka selama minimumnya; bila data lokal belum siap sesudah itu, yang tampil rangka ShimmerSkeleton (bukan layar pembuka berkepanjangan). Shimmer kini punya tepat dua pemicu sah: muat awal & tarik jauh.

## v0.10.4 (2026-11-15) — Tarik-untuk-segar terasa hilang di HP asli; detektor diperbaiki
- **Keluhan Adnan (12:32):** "kok ga ada pull to refresh nya sih". Akar masalah v0.10.3: ambang 120px hanya menghitung gerak MELEWATI tepi — di HP asli sebagian gerak jari habis untuk menggulir balik ke puncak dulu, dan tidak ada tanda visual saat menarik, jadi fitur terasa tidak ada.
- **Detektor v2:** penjaga utama dipindah ke AWAL gestur — ScrollStartNotification mencatat apakah gestur dimulai saat daftar sudah di puncak (dragDetails ada + pixels ≤ min+1); hanya gestur itu yang overscroll-nya dihitung. Tarikan dari tengah yang kelewat melewati puncak tidak pernah memicu (tes khusus lulus). Ambang turun ke 72px.
- **Indikator tarikan:** lingkaran panah segar (ValueNotifier _tarikProgres, tanpa rebuild cangkang) meluncur turun −40→+14px & berputar 0→3.5 rad mengikuti kemajuan tarikan; hilang saat gestur selesai/terpicu. Kini pengguna bisa melihat seberapa jauh lagi harus menarik.
- Tes: 65/65 hijau (patch 10: tarik jauh menyala, tarik 60px diam, tarik dari tengah diam).

## v0.10.5 (2026-11-15) — Gerbang PIN ganti tampilan: Padat Bawah (pilihan Adnan)
- Adnan minta "beberapa tampilan untuk masukkan PIN" (16:28) — dibuat 4 varian render Flutter asli: (1) Kartu, (2) Avorea Gelap, (3) Rata Minimal, (4) Padat Bawah. Adnan tanya yang paling nyaman di jari → dijawab Padat Bawah (papan tombol menempel di bawah = jangkauan jempol; pola yang sama dengan PIN GoPay/DANA) → Adnan PILIH Varian 4 (16:49).
- **PinGateScreen ditulis ulang tampilannya, perilaku utuh:** kepala ringkas (kotak emerald + nama usaha + "Kasir Terkunci"), titik PIN dalam pil abu (titik kosong kini transparan), medali gembok di tengah yang memerah saat PIN salah (teks galat menggantikan petunjuk), panel tombol putih menempel di bawah (tombol kotak membulat bergaris tepi, menyala accentSoft saat ditekan; angka memakai AppText.number). Animasi titik memantul, goyang, getar, tekan-lama-hapus tetap. Lebar isi dibatasi 460px (tablet tetap ringkas).
- **PELAJARAN KERAS:** Column ber-Expanded di dalam SingleChildScrollView WAJIB dibungkus IntrinsicHeight + ConstrainedBox(minHeight) — tanpa itu meledak "non-zero flex but incoming height constraints are unbounded" (ketahuan dari tes PIN yang merah).

## v0.10.6 (2026-11-15) — Detail Transaksi, filter tanggal, tarik-segar picu saat dilepas
- **Keluhan Adnan (21:49):** "pull to refresh nya belom ampe bawah dah kerefresh" — penyegaran jalan di tengah tarikan, sebelum indikator terasa sampai bawah. **Obat:** detektor kini dua tahap — tarikan melewati ambang 110px hanya membuat status "siap" (lingkaran indikator berubah hijau penuh = "lepas sekarang"); sinkron + shimmer BARU jalan pada ScrollEndNotification dalam keadaan siap. Tarikan yang dilepas sebelum ambang tidak menyegarkan apa pun. Tes baru membuktikan: jari masih menahan melewati ambang → tidak ada shimmer; dilepas → shimmer.
- **Halaman Detail Transaksi (diminta Adnan 21:49):** baris Riwayat kini bisa diketuk (panah chevron di kanan) → DetailTransaksiScreen: kepala (ikon metode, id · metode, waktu, cabang, pil "Lunas"), kartu total emerald (bahasa visual halaman Pembayaran), Rincian Pesanan, Rincian Pembayaran (Subtotal/Biaya layanan/Pajak/Total).
- **TxRecord kini menyimpan rincian item** (`lines`: TxLine nama/keterangan/qty/total, diisi dari keranjang saat pembayaran dicatat; ikut toJson/fromJson & sinkron sebagai blob data). Transaksi lama tidak punya baris ini — detailnya menampilkan jumlah item + catatan jujur "dibuat sebelum rincian item disimpan".
- **Filter tanggal di Riwayat (diminta Adnan 21:49):** chip "Pilih Tanggal" membuka pemilih rentang tanggal bawaan; selama rentang aktif, saringan periode tidak dipakai (chip periode tampil tak terpilih) dan muncul chip "Hapus Tanggal". Memilih chip periode menghapus rentang. Logika batas = fungsi murni `txDalamRentang` (hari terakhir inklusif penuh), teruji unit + widget (dialog asli didorong di tes).

## v0.10.7 (2026-11-15) — Pembaruan dari dalam aplikasi (diminta Adnan 22:02)
- **Batas jujur Android:** aplikasi di luar Play Store TIDAK bisa memasang pembaruan diam-diam — jendela "Pasang" sistem selalu wajib ditekan pengguna. Versi ini melakukan semua sisanya: cek, unduh, dan membuka pemasang.
- **Alur:** aplikasi membaca `https://webtales.my.id/avoera/version.json` sekali saat dibuka (gagal = diam). Nomor build server > aplikasi → banner "Ada versi baru" di puncak Beranda + pemberitahuan tersimpan (kunci `update-<kode>`, tidak banjir). Ketuk banner → DialogUnduhUpdate (kemajuan unduh %, PopScope terkunci selama mengunduh) → pemasang Android dibuka lewat kanal native. Cek manual: Pengaturan > Tentang > "Pembaruan Aplikasi" (selalu memberi umpan balik: toast sudah terbaru / tidak bisa memeriksa / dialog tawar berisi catatan rilis).
- **Sisi server (baru):** nginx `location /avoera/` menyajikan folder statis /opt/avoera-update (version.json + avoera.apk); layanan unggah Python (systemd `avoera-upload`, 127.0.0.1:8099) menerima POST bertoken (header X-Upload-Token, token di /etc/avoera-update/token) + header versi, menulis APK & version.json secara atomik. Terverifikasi ujung ke ujung (403 tanpa token; unggah dummy → version.json berubah → seed dikembalikan).
- **Sisi Codemagic:** langkah baru sesudah build rilis mengunggah APK + versi dari pubspec + catatan dari subjek commit — HANYA bila variable AVOERA_UPLOAD_TOKEN diatur (belum diatur = dilewati, build tetap hijau). Satu kali tugas Adnan: isi variable itu di Codemagic.
- **Native:** izin REQUEST_INSTALL_PACKAGES + FileProvider (`${applicationId}.fileprovider`, file_paths = cache+files) + MethodChannel 'avoera/installer' di MainActivity (ACTION_VIEW + FLAG_GRANT_READ_URI_PERMISSION). Terbukti: build debug lokal lolos kompilasi Kotlin & aapt memastikan izin + provider ada di APK. APK diunduh ke Directory.systemTemp (cache aplikasi).
- **Konstanta baru:** `appBuild` di data.dart (nomor build, WAJIB seirama pubspec) — pembanding versi tanpa plugin baru.
- Rantai pertama: v0.10.7 sendiri masih dipasang manual sekali (aplikasi lama belum punya fitur ini); bila build-nya terunggah (token diatur), rilis SESUDAHNYA tiba lewat banner.

## v0.10.8 (2026-11-15) — Pemberitahuan bisa diketuk menuju tujuannya (diminta Adnan 22:38)
- **Keluhan:** kartu di Pemberitahuan mati — diketuk tidak terjadi apa-apa. Sekarang kartu yang punya tujuan berpanah › dan bisa diketuk: **stok** → halaman Stok Bahan dengan kotak cari terisi nama bahan itu (daftar tersaring, bahan lain sembunyi; id bahan dibaca dari kunci `stok-<id>-habis/kritis`); **sinkron** → halaman Status Sinkronisasi; **info pembaruan** → mulai memperbarui. Info tanpa tujuan tetap tidak bisa diketuk. Yang diketuk otomatis ditandai terbaca.
- **Mekanisme Stok:** parameter baru `queryAwal`/`queryAwalKode` di StokScreen — diterapkan sekali tiap kode berubah (filter direset ke Semua, controller cari diisi). Layar Stok kini memegang TextEditingController sendiri.
- **Ikut rilis ini — perbaikan label grafik Beranda** (commit 79c29a1, ketahuan saat membuat pratinjau banner): label '175 rb' di atas batang tertinggi membungkus jadi 2 baris di kolom sempit → kolom meluap 6px dari kotak 150px (di rilis: terpotong diam-diam). Obat: softWrap mati + ringkas() tanpa spasi ('175rb', '1,5jt').

## v0.10.9 (2026-11-15) — Rombak desain Riwayat Transaksi (diminta Adnan 23:17, 6 poin dari screenshot)
- **Saringan SATU baris geser:** periode + metode + kalender dalam satu FilterChipRow. "Pilih Tanggal" jadi tombol ikon kalender (lingkaran berbingkai, tooltip 'Pilih tanggal'); rentang aktif tampil sebagai pil hijau penuh berisi label rentang — badan pil membuka pemilih lagi, tanda ✕ menghapus. Memilih chip periode tetap menghapus rentang.
- **Kelompok per tanggal:** header 'Hari ini · Min, 15 Nov 2026' / 'Kemarin · …' / 'Sel, 10 Nov 2026' + subtotal hari di kanan. Helper murni: kelompokTxPerHari + labelHariTx.
- **Judul baris = nama produk** (ringkasanProdukTx: nama produk pertama); "+N lainnya" pindah ke subjudul (labelTambahanTx) — menempel di judul membuat judul panjang terpotong persis di sufiksnya (ketahuan dari render pertama). Subjudul baris berproduk: 'A-1045 · Tunai · 12:10 · +1 lainnya'; transaksi lama tanpa rincian: judul tetap 'id · metode', subjudul 'jam · N item'.
- **Badge 'Lunas'** di semua baris (pil accentSoft, teks accentDark, TANPA ikon — aturan anti-centang).
- **Padat berdivider:** satu AppCard per hari (padding 0), baris 40px ikon + padding vertikal md, Divider tipis indent 68 di antara baris. Ketuk baris tetap membuka Detail Transaksi.
- **Kartu total + rincian metode:** di bawah garis pemisah, dua kolom Tunai/QRIS dengan ikon + jumlah masing-masing (dihitung dari daftar tersaring).

## v0.10.10 (2026-11-15) — Berkas pembaruan pindah ke GitHub (keputusan Adnan 23:47–23:54)
- **Sebab:** rantai unggah ke server sendiri gagal dua kali diam-diam (build 0.10.8: grup variable AVOERA belum diimpor workflow saat build Adnan jalan; build 0.10.9 via API: build dari API tidak membawa grup yang tertulis di codemagic.yaml — grup harus dikirim di body permintaan). version.json server berhenti di 0.10.6, aplikasi 0.10.8 menjawab jujur "sudah terbaru". Adnan lalu memutuskan: berkas pembaruan TIDAK BOLEH di servernya — sering kena suspend.
- **Rumah baru:** repo GitHub publik `avoera-releases` — version.json + avoera.apk sebagai berkas biasa di branch main, diterbitkan Muse sesudah tiap build Codemagic selesai (ambil artefak → commit → push via deploy key khusus repo itu). `urlInfoUpdate` kini menunjuk raw.githubusercontent.com. Unduhan APK lewat raw GitHub (mengikuti pengalihan bila ada).
- **Ditolak dengan alasan terukur:** Cloudflare Pages (batas 25 MB/berkas; APK rilis 61 MB) dan Supabase Storage gratis (batas 50 MB) — keduanya gugur oleh ukuran APK. Cloudflare R2 mungkin tapi perlu token baru + pintu unggah Worker; token Cloudflare yang tersambung hanya berizin DNS.
- **codemagic.yaml dibersihkan:** langkah "Unggah APK untuk pembaruan dalam aplikasi" + impor grup AVOERA dicabut — build sekarang murni membangun; penerbitan urusan Muse dari luar. Token AVOERA_UPLOAD_TOKEN di Codemagic tidak dipakai lagi.
- **Harga yang jujur:** repo publik = APK bisa diunduh siapa pun yang tahu alamatnya (aplikasi tetap buta tanpa Kode Usaha untuk sinkron penuh; bawaan terbungkus memang kode usaha Avorea — risiko diterima Adnan demi jalur pembaruan yang tidak bisa kena suspend). Riwayat git repo bertambah ±61 MB per rilis; cukup untuk puluhan rilis.
- v0.10.10 sendiri tetap dipasang manual SEKALI (aplikasi lama masih mengecek alamat server lama); sesudahnya semua rilis tiba lewat banner dari GitHub.

## v0.10.11 (2026-11-16) — Perbaikan Riwayat #1 (7 poin Adnan 00:22, sekalian uji perdana pembaruan dalam aplikasi dari GitHub)
- **App bar:** tombol kembali eksplisit (maybePop) + ikon kalender PINDAH ke app bar di sebelah ikon bagikan (bertinta aksen saat rentang aktif); tombol kalender di baris saringan dicabut, pil rentang aktif tetap di baris periode.
- **Saringan metode DIPISAH** jadi baris chip sendiri di bawah baris periode (pilihan pertama Adnan; opsi tombol "Filter" berbadge tidak diambil — semua saringan tetap terlihat, ramah kasir).
- **Kolom pencarian** di bawah chip: cocokkan nomor transaksi (tak peka huruf) ATAU nominal (angka dicocokkan polos — '52.900' = '52900'). Helper murni txCocokCari. Keadaan kosong saat mencari aktif berpesan khusus.
- **Label total DINAMIS** (labelTotalRiwayat): 'Total semua transaksi', 'Total transaksi Tunai minggu ini', 'Total semua transaksi · 10 – 15 Nov 2026', dst.
- **Badge status:** TxRecord kini punya kolom `status` (bawaan 'Lunas', JSON pulang-pergi aman, data lama terbaca Lunas). Baris biasa TANPA badge; badgeStatusTx hanya memberi lencana untuk Batal (merah), Refund (kuning), Belum bayar (abu). Belum ada alur penulis status — kolom disiapkan untuk fitur batal/refund kelak. Pil 'Lunas' di halaman Detail TIDAK berubah.
- **Baris:** subjudul = 'A-1045 · 12:10' saja (metode dari ikon); '+N' (jumlahTambahanTx, menggantikan labelTambahanTx '+N lainnya') menempel di kanan nama produk sebagai teks redup terpisah.
- **Lebih lembut:** AppCard/cardDecoration dapat parameter shadowAlpha opsional (bawaan tak berubah untuk layar lain); Riwayat memakai 0.03 terang/0.18 gelap + divider berwarna border alpha 0.55.
- Tes: patch_0111 baru (5) + patch_0109/0106 disesuaikan. Bingkai 0111-riwayat.png diperiksa visual: ketujuh poin terbaca jelas.

## v0.10.12 (2026-11-16) — Pemasang diperbaiki + tawaran update muncul sendiri (perintah Adnan 00:43, dari uji langsung di HP-nya)
- **AKAR MASALAH pemasang gagal (uji Adnan 00:43):** unduhan 0.10.11 sukses, tapi dialog bilang "pemasang tidak bisa dibuka". Sisi Android lama langsung startActivity tanpa memeriksa izin "pasang aplikasi tidak dikenal" (wajib sejak Android 8, per-aplikasi) → di Xiaomi izin belum ada dan startActivity melempar pengecualian. Jalan pintas "Coba lagi dari Pengaturan" di pesan lama tidak menolong — yang dikeluhkan Adnan persis itu.
- **MainActivity:** periksa canRequestPackageInstalls() dulu. Belum diizinkan → buka Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES untuk paket ini, jawab 'perlu-izin'. Sudah → buka pemasang, jawab 'dibuka'. pasangApk (Dart) kini mengembalikan 'dibuka' | 'perlu-izin' | 'gagal' (jawaban bool warisan tetap dimengerti).
- **DialogUnduhUpdate berfase:** unduh → pasang; 'perlu-izin' → penjelasan sekali-izin + tombol 'Pasang' mencoba lagi dari berkas yang sama (TANPA unduh ulang); 'gagal' → 'Coba Lagi' juga tanpa unduh ulang; 'unduh-gagal' pesannya sendiri. Jahitan uji unduhFn/pasangFn.
- **Tawaran OTOMATIS (perluTawaranUpdate + meta persisten avoera.updatemeta.v1):** versi baru terdeteksi → dialog 'Ada versi baru' muncul SENDIRI sekali per versi. Syarat ketat: splash lewat, data siap, pengguna di Beranda, wizard selesai, tak ada dialog tawaran lain. 'Nanti' = tidak ditawari lagi untuk versi itu; banner + pemberitahuan tetap ada. Pemicu: akhir muat, akhir splash, penjaga berkala 20 dtk, dan cek ulang saat aplikasi kembali ke depan (dijatah 5 menit).
- **Banner Beranda pindah** ke bawah sapaan + baris cabang (posisi lamanya di paling atas dipertanyakan Adnan) — kini pengingat tenang di bawah kepala halaman, di atas kartu Penjualan.
- Konsekuensi jujur: aplikasi Adnan yang terpasang (0.10.10) memuat pemasang LAMA yang rusak → 0.10.12 tetap harus dipasang manual sekali dari tautan; perilaku baru terasa mulai pembaruan sesudahnya.
- Tes: patch_0112 baru (6: helper tawaran, 3 fase dialog, posisi banner) + patch_0107 disesuaikan ke kontrak baru. Bingkai 0112-beranda.png diperiksa: banner di bawah sapaan ✓.

## v0.10.13 (2026-11-16) — Unduhan pembaruan ringan: split per ABI (perintah Adnan 01:11, "lambat ya kalo download via github")
- **Sebab lambat:** APK universal 61 MB membawa TIGA mesin (arm64 19 MB + arm32 17 MB + x86_64 21 MB, ukuran tak-terkompresi) — tiap HP hanya butuh satu. GitHub bukan biang utama; ukuran berkasnya.
- **Build:** codemagic.yaml android-release kini `flutter build apk --release --split-per-abi` → 3 artefak ±25 MB. Kode versi per ABI dari Flutter (1000×build + penanda) tidak mengganggu: perbandingan versi memakai konstanta appBuild.
- **Terbit:** avoera.apk = arm64 (berkas utama di version.json urlApk — aplikasi LAMA 0.10.12 di HP arm64 Adnan langsung ikut ringan), avoera-32.apk = arm32 (urlApk32 baru). x86_64 tidak diterbitkan (bukan HP).
- **Aplikasi:** InfoUpdate.urlApk32 (JSON lama aman) + urlApkUntukPerangkat(info, Abi) — unduhApk memilih lewat Abi.current(): androidArm → urlApk32 bila ada; selain itu urlApk.
- **Cadangan izin:** intent halaman izin per-paket gagal di suatu ROM → coba intent umum ACTION_MANAGE_UNKNOWN_APP_SOURCES sebelum menyerah (di MainActivity).
- Rilis ini sekaligus panggung uji penuh alur baru: dialog tawaran otomatis di aplikasi 0.10.12 Adnan → unduh arm64 → halaman izin sekali → Pasang.
- Tes: patch_0113 baru (2).

## v0.10.14 (2026-11-16) — Gerbang PIN "Bersih Tengah" (pilihan Adnan dari 3 varian)
- "Padat Bawah" (v0.10.5) ditolak Adnan 03:15 ("perbarui tampilannya aku ga suka"). Tiga varian dirender sebagai golden (A Hijau Berani / B Bersih Tengah / C Kartu Padat); Adnan memilih **B** pukul 05:45.
- PinGateScreen: semua isi di tengah — ubin logo 54, nama usaha, 'Kasir Terkunci', titik 14 polos TANPA pil abu (jarak 16), keterangan/kesalahan di bawah titik, papan angka LINGKARAN 72 tanpa kotak (angka 28 w500; ditekan = lingkaran accentSoft), petunjuk di bawah. Medali gembok + panel putih bawah HILANG. Perilaku utuh: titik memantul, goyang+merah saat salah, getar, tekan lama hapus = kosongkan, cek PIN 4–6 sama.
- Catatan alat: render frame kini lewat golden (matchesGoldenFile + --update-goldens); jalur toImage manual macet di VM sesudah restart (lihat AGENTS.md).

## v0.10.15 (2026-11-16) — Pemasang: sebab gagal DIBUKA + unduhan diverifikasi utuh
- Uji Adnan 07:10 atas alur baru (aplikasinya kini ≥0.10.12 — dialog fase baru terbukti): tawaran otomatis ✓, unduhan ✓, tapi pasangApk tetap 'gagal'. Sebab tak terbaca: Dart menelan pesan PlatformException dan Kotlin tidak menandai langkah yang gagal.
- **Kotlin:** kesalahan kini berkode tahap — IZIN (dua intent izin gagal), PROVIDER (FileProvider menolak), BUKA (intent pemasang gagal) — pesan membawa nama pengecualian. Intent VIEW dapat CATEGORY_DEFAULT; ActivityNotFoundException → cadangan ACTION_INSTALL_PACKAGE.
- **Dart:** pasangApk meneruskan 'gagal|<kode>: <pesan>'; DialogUnduhUpdate fase gagal MENAMPILKAN alasan itu (teks kecil) supaya terbaca di tangkapan layar.
- **unduhApk memverifikasi keutuhan:** ukuran diterima wajib sama dengan contentLength + kepala berkas wajib 'PK'; terpotong/bukan APK → berkas dihapus, hasil null (fase unduh-gagal, bisa diulang) — menutup lubang aliran putus diam-diam (pola terpotong yang sama terlihat di unduhan artefak VM malam ini).
- Tes: patch_0115 baru (4); patch_0107 bytes uji kini diawali 'PK'.

## v0.10.16 (2026-11-16) — Laporan Laba Rugi (diminta Adnan)
- Baris 'Laporan Laba Rugi' di hub Laporan yang dulu 'Segera' kini hidup: layar LabaRugiScreen (periode Bulan Ini/Bulan Lalu/Hari Ini/Pilih Tanggal; per cabang aktif; ekspor pratinjau seperti laporan lain).
- Hitungan murni `hitungLabaRugi` (data.dart): pendapatan = transaksi LUNAS dalam rentang; HPP = Σ resep menu (dicocokkan per NAMA dari TxLine) × qty dengan harga beli bahan SAAT INI; laba kotor; biaya operasional; laba bersih. Kejujuran: baris yang menunya terhapus/tanpa resep + transaksi lama tanpa rincian TIDAK ditebak modalnya — dihitung & diperingatkan di layar ('laba sebenarnya bisa lebih kecil').
- Model Pengeluaran baru (kategori bawaan 8, keterangan, jumlah, tanggal, cabang) tersimpan LOKAL (avoera.expenses.v1; belum sinkron — seperti mutasi/notifikasi). CRUD lewat sheet pola Gudang dari layar laporan: tombol Tambah Pengeluaran + ketuk catatan untuk edit/hapus.
- rupiah() kini aman untuk nilai negatif (-Rp...) — dipakai label rugi.
- Tes: patch_0116 baru (8).

## v0.10.17 (2026-11-16) — AKAR SAGA PEMASANG KETEMU: code-cache-path hilang
- Tangkapan layar Adnan 08:00 (aplikasinya sudah 0.10.15 — dialog mencetak alasannya): "PROVIDER: IllegalArgumentException: Failed to find configured root that contains /data/data/id.avoera.avoera_pos/code_cache/avoera-42.apk".
- Sebab: Directory.systemTemp di Android menunjuk folder CODE cache, sedangkan file_paths.xml hanya mendaftarkan cache-path + files-path. FileProvider menolak membuat URI → pemasang tak pernah terbuka. Ini menjelaskan SEMUA kegagalan sejak v0.10.7.
- Obat: tambah `<code-cache-path name="code_cache" path="." />`. Tanpa perubahan kode lain.
- Konsekuensi jujur: perbaikan tinggal di APK baru → Adnan pasang manual SEKALI lagi (0.10.17 dari tautan); rilis sesudahnya adalah uji pemasang yang sesungguhnya.

## v0.10.18 (2026-11-16) — Splash baru "Fill + Hijau" (pilihan Adnan)
- Adnan mengirim karya logo transparan baru (avorea-segar.png, 1774×887, berisi slogan + lencana Halal) dan mengusulkan efek fill; dari kandidat Krim/Hijau Stiker/Hijau Panel/Putih + 3 varian fill, Adnan memilih **Fill + Hijau**.
- SplashScreen ditulis ulang visualnya: latar #1E3A2A POLOS (gradasi + painter aksen lama dibuang), karya logo di tengah, efek isi dua lapis (abu-abu pudar 45% + warna penuh terpotong _KlipIsi bergelombang) digerakkan controller 1500ms (Interval 0.05–0.95 easeInOut) seirama timer splash shell; label bawah 'AVOERA POS · BY WEBTALES STUDIO' dipertahankan. Garis muat & teks slogan terpisah hilang (sudah di dalam karya).
- Aset lama avorea-logo-gelap.png tidak lagi dirujuk splash (masih di bundle; tidak dihapus).

## v0.10.19 (2026-11-16) — Pemasang: pindah folder unduhan + cadangan salin native
- BUKTI BARU dari HP Adnan (uji v0.10.18, 11:12 WITA): error PROVIDER yang sama untuk …/code_cache/avoera-44.apk, padahal pemeriksaan ulang APK 0.10.17 TERBIT membuktikan <code-cache-path> BENAR ada di resource yang dirujuk provider aplikasi (@0x7f100000 = xml/file_paths = res/8K.xml berisi cache-path+code-cache-path+files-path; dua provider lain milik image_picker & share_plus). Kesimpulan: penolakan khas ROM HyperOS terhadap folder code_cache (dugaan beda bentuk alamat kanonis /data/data vs /data/user/0) — menambah slip izin untuk folder itu TIDAK cukup.
- Obat dua lapis: (1) unduhApk kini menulis ke folder CACHE aplikasi via path_provider getTemporaryDirectory (jahitan AmbilFolderUnduh untuk tes; tes lama diarahkan ke systemTemp host, +1 tes baru membuktikan berkas mendarat di folder jahitan); (2) MainActivity: bila getUriForFile menolak jalur berkas, berkas disalin ke cacheDir lalu dicoba lagi; error PROVIDER kini membawa juga sebab gagal-salinnya. <code-cache-path> dipertahankan (benar & tak berbahaya).
- Bukti akhir tetap di HP Adnan: pasang manual 0.10.19 sekali lagi, lalu rilis berikutnya adalah uji sesungguhnya.

## v0.10.20 (2026-11-16) — Splash diganti PUTIH + spinner (keputusan Adnan, jalur cepat tanpa suite atas perintahnya)
- Adnan mengganti pilihannya 11:35 WITA: latar splash PUTIH (bukan hijau), efek isi dipertahankan, DITAMBAH spinner hijau 26px di bawah logo; label bawah jadi abu kehijauan. Frame emas tengah+penuh diperiksa visual. Rilis ini sekaligus UJI PEMASANG untuk 0.10.19 (folder cache).

## v0.11.0 (2026-11-16) — UPDATE BESAR: semua laporan 'Segera' dibangun + logo PIN + bar bawah (perintah Adnan "jadikan update besar, harus detail")
- SEMUA baris Laporan kini hidup (tes membuktikan tidak ada chip 'Segera' lagi): Neraca (aktiva: kas perkiraan/QRIS/persediaan/piutang; pasiva: utang + modal penyeimbang + laba ditahan kumulatif; rincian persediaan maks 12 + sisa; pilih tanggal posisi; selalu seimbang), Arus Kas (masuk tunai/QRIS/hutang baru; keluar pembelian bahan/biaya per kategori/lunasi hutang; saldo awal dihitung aturan sama dari catatan sebelum periode → saldo akhir konsisten), Arus Stok (rekap per bahan dari mutasi: masuk/terpakai/opname/edit/bersih), Persediaan (nilai stok × harga pokok + status Aman/Kritis/Habis + saring), Pembelian (barang masuk per periode, nilai harga pokok kini, rekap per bahan + daftar entri).
- Laporan Hutang = fitur CRUD baru: model Hutang (kreditur, jumlah, jatuh tempo opsional, lunas + tanggal lunas, per cabang) tersimpan LOKAL avoera.hutang.v1; layar: hero total belum lunas, kelompok Belum Lunas (terlambat dulu, chip Terlambat) & Sudah Lunas, tombol Lunasi + dialog konfirmasi, formulir sheet (validasi kreditur & jumlah), ekspor. Angkanya mengalir ke Neraca (utang) & Arus Kas (hutang baru masuk, pelunasan keluar).
- Promo & Diskon = fitur kasir baru: model Promo (persen/nominal, min belanja, aktif) LOKAL avoera.promos.v1; layar kelola + pemakaian per promo; kasir memilih promo dari panel keranjang (sheet pemilih, diskon dihitung hitungDiskonPromo — SATU sumber kebenaran untuk tampilan & pencatatan), total pembayaran berkurang, TxRecord.diskon + promoNama tercatat (JSON lama aman), baris diskon tampil di Pembayaran & Detail Transaksi; pilihan promo reset sesudah bayar & promo yang dihapus/dinonaktifkan berhenti berlaku (_promoBerlaku).
- Gerbang PIN: ubin ikon toko 54px diganti LOGO Avorea (avorea-segar.png) lebar 205 (permintaan Adnan dari tangkapan layar: "harusnya logo aplikasi, besarin skalanya").
- Bar bawah: NavigationBar kembali ke permukaan KARTU (membalik keputusan 2026-11-15 atas keluhan Adnan 2026-11-16 "semua halaman ketutupan navbar" + "berjarak banget" — di HP tombol 3, area sistem ±48dp yang sewarna latar terbaca sebagai ruang kosong raksasa; terbukti lewat frame berinset 48dp sebelum & sesudah).
- Hitungan murni baru di data.dart: hitungNeraca, hitungArusKas, nilaiPersediaan, ringkasArusStok, ringkasPembelian, totalHutangBelumLunas, hitungDiskonPromo. Potongan bersama layar laporan di screens/laporan_bersama.dart (PemilihPeriode, BarisNilai, KartuHero, JudulSeksi, GarisTipis).
- Tes: 137/137 (27 baru di patch_0110_test.dart: hitungan murni semua fitur, JSON, layar Neraca/Arus Kas/Persediaan/Arus Stok/Pembelian, alur Hutang lunasi + catat + validasi, PromoScreen, kasir promo ujung ke ujung, Laporan tanpa 'Segera', PIN berlogo). Frame emas PIN + Neraca + Beranda berinset diperiksa visual.

## v0.12.0 (2026-11-16) — UPDATE IDENTITAS VISUAL (prinsip Adnan: "komponennya jangan kayak buatan AI")
- Huruf khas: Plus Jakarta Sans DIBUNDEL (assets/fonts, 5 bobot, ±150KB) untuk judul & angka (AppText subtitle/title/pageTitle/number/hero/display + judul AppBar + label bar bawah + chip); isi teks tetap Roboto. Tes wajib memuat Jakarta lewat FontLoader — tanpa itu judul jatuh ke font uji raksasa dan lebar teks mengecoh (58 tes gagal semu sebelum akar ini ketemu).
- BarNavigasiBawah JAHITAN SENDIRI (widgets.dart) menggantikan NavigationBar Material: permukaan kartu + garis tepi atas, aktif = garis aksen 22×3 di atas ikon + ikon/label aksen, TANPA kapsul pastel; lencana Dapur dipertahankan; label maxLines 1 (tidak boleh membungkus). Tema navigationBarTheme dihapus.
- AppChip JAHITAN SENDIRI menggantikan ChoiceChip (satu-satunya pemakai): terpilih = isi aksen PEKAT + teks putih; nonaktif = teks pudar; tetap pil & tetap TANPA centang. chipTheme Material dihapus.
- Kartu tombol Pembayaran SATU sistem (_kartuPilih): metode & ubin nominal tinggi tetap 76, radius sama, terpilih = garis aksen 2px + isi aksen di permukaan kartu (bukan isian pastel) — menjawab keluhan Adnan "button card nya tidak konsisten" (ubin Uang pas dua baris dulu lebih tinggi dari ubin sebaris; kartu metode jauh lebih tinggi dari ubin).
- Pita ringkasan laporan (KartuHero) berubah: permukaan kartu + garis aksen 4px di kiri + angka tinta. Blok emerald pekat DICADANGKAN hanya untuk dua angka utama (penjualan Beranda & laba bersih Laba Rugi yang mempertahankan heronya sendiri) — semua laporan memakai blok sama = rasa templat.
- Daftar Laporan dikelompokkan berbobot: 'Penjualan & Keuangan' ubin aksen pekat ikon putih; 'Stok & Operasional' ubin bergaris aksen; 'Segera' ubin pudar. Judul baris kini AppText.subtitle.
- Keadaan terpilih tegas di tempat lain: SegmentedButton terpilih = aksen pekat + teks putih (tema); item laci HP & sidebar lebar terpilih = aksen pekat + ikon/teks putih (dulu accentSoft); pemilih ikon menu terpilih = garis aksen 2px.
- Kolom isian BERTEPI: tema input kini permukaan kartu + garis 1px selalu terlihat, fokus aksen 1.5px, error danger; fieldFill tak lagi dipakai tema (dua baris tanggal di sheet Laba Rugi & Hutang ikut permukaan kartu bergaris).
- Motif khas berulang: GARIS AKSEN PENDEK — di PageHeader (26×4 di atas judul, 6 layar shell), indikator bar bawah, garis tepi KartuHero. Satu motif kecil yang sama = identitas.
- EmptyState: ikon di dalam cincin bergaris 64px + pesan tinta tegas (bukan ikon lepas abu).
- Splash & gerbang PIN: logo SUSUNAN HURUF (LogoAvorea di widgets.dart: 'AVOREA' Jakarta ExtraBold hijau alpukat #1E3A2A + garis kuning brand #F5B921 + 'MAESTRO ALPUKAT KOCOK'); poster promosi avorea-segar & efek isi warna DIBUANG dari splash (Adnan: "ga cocok pakai splash begitu"); splash tetap putih + spinner hijau brand; PIN memakai lockup yang sama (terang mengikuti tema gelap).
- Perbaikan: _KepalaTetapDelegate (kepala lengket pill kategori Produk) kini memaksa anak setinggi extent yang diumumkan — chip baru 1px lebih pendek membuat geometri sliver tidak sah dan 58 tes gagal serentak.
- Tes: 137/137. Frame emas 8 layar (splash, PIN, Beranda+bar, Kasir, Pembayaran, Laporan, Neraca, Hutang) diperiksa visual satu-satu.

## v0.12.1 (2026-11-16) — isi bawah layar terdorong tidak lagi tertutup bar navigasi sistem
- Keluhan Adnan (tangkapan layar Neraca 17:52): catatan kaki halaman tertutup area tombol navigasi Android — "masih banyak ternyata halaman yang ketutupan navbar, ga full screen". Akar: SEMUA layar terdorong memakai padding bawah daftar rata 16, sementara area tombol sistem ±48dp & tembus pandang (Android edge-to-edge). Perbaikan sejenis pada 2026-11-15 hanya menyembuhkan Status Sinkronisasi sendirian.
- Obat sistemik: fungsi bersama `paddingBawahAman(context, [dasar])` di widgets.dart = dasar + MediaQuery.viewPaddingOf(context).bottom. Dipakai 24 titik: Neraca, Arus Kas, Arus Stok, Persediaan, Pembelian, Hutang, Promo, Laba Rugi, Detail Transaksi, Laporan Bulanan/Pajak/Piutang, Riwayat, Notifikasi, Riwayat Mutasi, Profil Usaha, Resep (2 layar), Kelola Menu/Meja/Stok, Tambah Cabang, wizard onboarding; Status Sinkronisasi diselaraskan ke viewPadding. Halaman shell TIDAK diubah (bar bawah shell sudah menyisakan ruang); lembar popup aman (showAppSheet membungkus SafeArea); bar tombol bawah Kelola* sudah SafeArea sejak lama.
- Bukti: frame Neraca digulir mentok dengan inset bawah tiruan 48dp — catatan kaki tampil utuh + ruang lega di bawahnya. Tes 137/137.

## v0.13.0 (2026-11-16) — SEMUA ikon diganti ke set Phosphor (pilihan Adnan dari frame perbandingan)
- Adnan: "icon2 nya bisa lebih fresh ga svg nya?" — dibuatkan frame perbandingan Material vs Lucide vs Phosphor dari berkas SVG asli kedua set; Adnan memilih PHOSPHOR (garis bersih agak bulat). Paket ikon pub (lucide_icons/phosphor_flutter) TIDAK bisa dipakai: keduanya mewarisi IconData yang kini final di Flutter 3.47 — tidak kompilasi. Jalan yang dipakai: huruf ikon RESMI Phosphor (Phosphor.ttf + Phosphor-Fill.ttf dari @phosphor-icons/web 2.1.1) dibundel di assets/fonts, sama seperti huruf Jakarta.
- Lapisan penerjemah lib/ikon.dart: kelas `Ikon` dengan 134 field bernama PERSIS ikon Material lama (arrow_back, home_outlined, dst) berisi IconData Phosphor — seluruh tempat pemakaian cukup berganti awalan Icons. → Ikon. (52 berkas). Varian terpilih/aktif memakai huruf PhosphorFill berkode sama (house, cash-register, gear, cooking-pot, table, chart-bar, dst).
- Data menu AMAN: MenuItem menyimpan iconIndex ke menuIconChoices — urutan daftar TIDAK digeser, hanya glyph-nya diganti (local_cafe→coffee, coffee→coffee-bean, coffee_maker→tea-bag, emoji_food_beverage→orange-slice, local_drink→wine, rice_bowl→bowl-food, dinner_dining→fork-knife, ramen_dining→bowl-steam, set_meal→fish, fastfood→hamburger, bakery_dining→bread, breakfast_dining→egg, tapas→cookie, card_giftcard→gift, group→users, cake→cake, groups→users-three). Jalur data sangat lama (≤0.3.2, hanya codePoint Material) dipetakan lewat daftar kode lama yang DIBEKUKAN di data.dart (_kodeIkonMenuLama).
- Ikon bawaan kerangka Flutter (tombol kembali AppBar otomatis, dsb) tetap Material — itu milik framework, bukan kode aplikasi; dua finder tes disesuaikan ke fakta itu.
- Tes: 137/137 (3 perbaikan tes: store_test kini memasukkan codePoint Material asli 58094 sebagai data lama; audit_kelola & laporan mencari tombol kembali framework). Frame Beranda/Kasir/Laporan/PIN dengan huruf Phosphor dimuat — semua glyph tampil segar & terbaca.

## v0.14.0 (2026-11-16) — Set ikon diganti lagi: Phosphor → LUCIDE (keputusan akhir Adnan)
- Sesudah melihat contoh halaman Riwayat Transaksi versi Lucide (frame contoh dibuat dari SVG resmi Lucide), Adnan memutuskan "lucide aja deh" — menggantikan pilihan Phosphor sehari sebelumnya (v0.13.0). Alasan rasa: garis Lucide lebih tipis, tegas, formal seperti aplikasi keuangan.
- Cara pasang sama seperti Phosphor: paket pub lucide_icons tidak kompilasi di Flutter 3.47 (IconData final), jadi huruf resmi Lucide (lucide.ttf dari paket lucide_icons 0.257.0) dibundel di assets/fonts sebagai keluarga 'Lucide'; lib/ikon.dart ditulis ulang berisi 134 IconData Lucide dengan nama field yang sama persis — tidak ada tempat pemakaian yang berubah.
- Pemetaan rasa Lucide: dapur = chefHat (topi koki, paling terbaca), kasir = shoppingCart, tunai = banknote, QRIS = qrCode, neraca = scale, pajak = landmark, stok = package/archive, meja = table2, arus = arrowLeftRight, tema = contrast, sinkron = uploadCloud/refreshCcw. Menu (urutan TIDAK digeser): coffee, bean, cupSoda, citrus, wine, salad, utensils, soup, fish, sandwich, croissant, eggFried, cookie, gift, users, cake, users2.
- Lucide hanya punya SATU gaya garis (tidak ada varian isi) — field yang dulu memakai PhosphorFill kini menunjuk glyph garis yang sama; keadaan terpilih tetap jelas dari warna + garis penanda (aturan identitas v0.12.0). Huruf Phosphor dicabut dari aplikasi.
- Tes: 137/137. Frame Beranda/Laporan/Riwayat asli dengan huruf Lucide dimuat — semua glyph tampil; Riwayat asli cocok dengan frame contoh yang membuat Adnan memutuskan.

## v0.14.1 (2026-11-17) — Paket poles UI dari 4 tangkapan layar Adnan
- **Dropdown Produk dirombak** (keluhan: panel bawaan raksasa memenuhi layar, huruf besar-besar): tema popup global baru (popupMenuTheme) — permukaan kartu putih, garis tepi, sudut md, angkat 6, huruf body; menu Produk kini lebar terbatas 256–292, baris ringkas 46px berikon Lucide, berkelompok dengan garis pemisah (utama / data / katalog), keadaan aktif tetap ditandai teks 'Aktif' (aturan tanpa centang). Menu lain (pilih meja Kasir, ganti cabang Beranda) ikut naik tampilannya dari tema yang sama. Ikon baru: bike (Harga Ojol), upload (Impor).
- **Bar pilihan Produk disamakan ukurannya** (keluhan: "ga sama ukurannya"): tombol Batal dan Hapus Terpilih kini sepasang setara — tinggi 48, huruf dan bantalan sama; beda hanya warna peran (garis tepi vs merah penuh). Jarak bawah daftar mode pilih 64 → 88 agar bar tidak menutupi produk terakhir.
- **Profil Usaha diperbarui**: kolom Nama/Alamat/Telepon berikon depan Lucide redup (toko, pin, telepon — ikon phone baru), foto usaha diberi bingkai garis halus.
- **Sheet Pilih Bahan bisa diseret** (permintaan: "kalau ditarik ke bawah maka dia kegeser ke bawah popupnya"): DraggableScrollableSheet — menarik daftar di puncak atau gagang/kepala sheet menggeser sheet mengikuti jari, tarikan jauh menutup; ada gagang tarik 40×4 di atas; tinggi awal 88% layar sehingga judul tidak lagi menempel status bar. Teruji angka: tarikan 320px menggeser judul turun 300px.
- Ikon kini 137 field. Tes: 137/137 lulus.

## v0.14.2 (2026-11-17) — Statistik Beranda jadi satu kartu lebar
- Tiga kartu statistik terpisah (Transaksi / Rata-rata / Menu Dijual atau Di Dapur) digabung jadi SATU kartu lebar berisi 3 kolom berpisah garis tipis menjorok — pilihan Adnan dari 3 usul sesudah mengeluh kartu lama "kurang lebar kalau di HP". Ruang antar kartu yang terbuang (2×12) kini jadi ruang angka; tinggi tetap dikunci 88; tiap kolom tetap bisa diketuk ke tujuan lama (Riwayat / Dapur / Produk) dengan InkWell di atas Material transparan; angka tetap FitNumber.
- Tes: 137/137 lulus. Frame Beranda terverifikasi: satu kartu, 3 kolom, garis pemisah menjorok.

## v0.14.3 (2026-11-17) — Pemberitahuan terbaca tidak lahir lagi
- Keluhan Adnan (mengambang sejak 2026-11-16 05:49, jelas 2026-11-17 04:46): "notifikasi walaupun sudah dibaca kalau direfresh terbaca belum dibaca". Akar terbukti di kode: penjaga duplikat `_tambahNotifikasi` hanya menolak bila salinan BELUM dibaca masih ada — salinan terbaca tidak menghalangi, jadi setiap pemeriksaan ulang (sinkron sesudah tarik-refresh memanggil `_periksaStokNotifikasi`; cek update saat aplikasi dibuka lagi) melahirkan salinan baru belum-dibaca.
- Obat: satu kunci = satu pemberitahuan per EPISODE keadaan. Kunci aktif tersimpan persisten (LocalStore `avoera.notifkunci.v1`); episode berakhir eksplisit hanya bila keadaan pulih: stok bahan normal lagi (di `_periksaStokNotifikasi`), sinkron tuntas (kunci sinkron-gagal), versi pembaruan berganti/terpasang (kunci update-*). Migrasi: pemberitahuan stok & pembaruan yang sudah ada di daftar dianggap episode berjalan.
- Tes regresi baru patch_0143: tandai semua terbaca → buka ulang aplikasi → tombol 'Tandai semua terbaca' tetap tidak muncul. Suite 138/138 lulus.

## v0.15.0 (2026-11-17) — Splash artwork Adnan, Margin Tipis, Pengunjung, Tutup Kasir, Struk & printer thermal
- **Splash baru dari artwork Adnan sendiri** (13:12): berkas `assets/branding/avorea-splash.png` (lockup "Avorea — Bikin Harimu Lebih Segar", latar TRANSPARAN) digambar di atas hitam pekat persis pratinjau yang ia kirim; spinner kuning #F5B921 + label kaki krem. Ini menggantikan splash tipografi LogoAvorea v0.12.0 atas instruksi eksplisit pemilik karya; PIN tetap memakai LogoAvorea.
- **Margin Tipis** (baris 'Segera' terakhir dari sisi hitungan): `hitungMarginMenu` di data.dart memakai `hppMenu` yang sama dengan kasir/Laba Rugi — status jujur tiga macam (terhitung / tanpa resep / harga bahan kosong), urut persen paling tipis dulu, hero = menu paling tipis, keterangan menyertakan jumlah terjual periode terpilih (PemilihPeriode bersama). Menu tanpa resep TIDAK diberi angka rekaan.
- **Laporan Pengunjung**: prasyaratnya catatan tamu per transaksi — `TxRecord.tamu` (bawaan 0, JSON lama aman) dicatat kasir lewat stepper "Jumlah tamu" di Pembayaran (tidak wajib). Laporan menghitung hanya transaksi Lunas bertamu > 0 sebagai "tercatat", menampilkan total, rata-rata, terbanyak, dan rincian per hari; catatan kaki jujur bahwa rata-rata hanya dari yang tercatat.
- **Dine-in/Bungkus sinkron dua arah**: pilihan jenis kini juga tampil di Pembayaran memakai rangka kartu pilih yang sama (tinggi 76, tepi aksen 2px saat terpilih, TANPA isian pastel, TANPA centang). Pembayaran mengembalikan `HasilBayar` (metode + tamu + jenis); perubahan jenis di Pembayaran ditulis balik ke tombol Kasir. Pesanan meja: jenis terkunci Dine-in dan tampil sebagai satu kartu statis "Dine-in · Meja N". Pemetaan label lama dipertahankan (Bungkus → label tiket 'Bungkus', jenis tersimpan 'Takeaway').
- **Tutup Kasir (Sesi Kasir)**: model `SesiKasir` tersimpan LOKAL (`avoera.sesi.v1`) — buka dengan modal awal + nama kasir bebas, tutup dengan hitung fisik; selisih dihitung langsung di lembar tutup (seharusnya = modal + tunai − pengeluaran laci; isian pengeluaran laci terisi awal dari pengeluaran tercatat dan boleh dibetulkan). Riwayat sesi + layar detail rekonsiliasi. Aturan lama ditegakkan: penjualan TIDAK PERNAH diblokir sesi — Kasir hanya menampilkan pita peringatan kuning + tombol Buka bila sesi belum dibuka. Pintu masuk: Pengaturan → bagian Kasir.
- **Struk & printer thermal**: Detail Transaksi punya tombol "Lihat Struk" → Pratinjau Struk digambar dari SATU sumber susunan (`susunStruk` di lib/struk.dart) yang sama untuk teks bagikan (SharePlus) dan byte ESC/POS printer — tidak ada tiga versi isi. Pratinjau: kertas putih bertepi garis di atas latar halaman, huruf monospace, lebar kertas mengikuti desain (58mm = 32 karakter, 80mm = 48). Layar "Desain Struk & Printer" (Pengaturan → Kasir): saklar tampil alamat/telepon/tamu, teks pembuka/penutup/tambahan bebas, pilihan lebar kertas, pilih/lupakan printer, Tes Cetak dengan struk contoh. Desain tersimpan lokal `avoera.struk.v1`.
- **Pustaka BLE = universal_ble (MIT)**, BUKAN flutter_blue_plus: versi 2.x-nya mewajibkan deklarasi `License` dan lisensi komersialnya BERBAYAR — tidak dipakai untuk aplikasi klien tanpa persetujuan. universal_ble dipatok ^3.3.0. Cetak: sambung → cari karakteristik penulis (prioritas UUID lazim printer POS FFE1/FFF1/FF02/AE01/ISSC, lalu bisa-tulis pertama) → kirim potongan 100 byte → putus. Izin BLUETOOTH_SCAN/CONNECT + lokasi (Android lama) ditambah ke manifest. **Cetak asli hanya bisa dibuktikan di HP Adnan dengan printernya — kode & byte teruji, perangkat keras tidak.**
- Ikon baru di Ikon: lock_outlined (lock), lock_open_outlined (unlock), bluetooth — codepoint divalidasi dari tabel lucide_icons 0.257.0.
- Tes baru patch_0150 (hitungan margin/pengunjung/sesi, layar Margin/Pengunjung/Laporan/Sesi, alur Pembayaran tamu+jenis+meja-terkunci, struk teks & ESC/POS, persistensi sesi+desain). Typedef onCheckout Kasir bertambah parameter bernama opsional `{int tamu}` — satu-satunya penyesuaian tes lama: closure di patch_0110.

## v0.16.0 (2026-11-17) — Keranjang & pesanan dapur TERSIMPAN (tidak hilang saat aplikasi tertutup paksa)
- **Masalah yang ditutup**: sampai 0.15.0 keranjang dan antrean dapur hanya hidup di ingatan — aplikasi tertutup paksa / HP mati = pesanan belum dibayar dan tiket dapur lenyap. Ini celah produksi nomor satu yang dicatat sejak penilaian pilot 2026-11-15.
- **Yang disimpan** (lokal saja, tidak ikut sinkron — sama seperti meja/sesi/struk): seluruh antrean dapur di `avoera.dapur.v1` (`KitchenOrder.toJson/fromJson`, status ikut tersimpan), dan draf kasir di `avoera.keranjang.v1` (`DraftKasir`): baris keranjang dirujuk lewat **id menu** (`BarisKeranjang`) + varian/catatan/jumlah/harga satuan saat itu, nomor meja terpilih, nomor urut pesanan (id tiket tidak boleh mengulang sesudah buka ulang), jenis pesanan, dan id promo terpilih.
- **Aturan pemulihan jujur**: baris yang menunya sudah dihapus pemilik DIBUANG saat pemulihan (tidak disambung ke menu lain); promo yang sudah dihapus/dinonaktifkan gugur sendiri lewat pemeriksa `promoBerlaku` yang sudah ada; meja yang sudah dihapus → pilihan meja kosong. Jalan pertama tanpa berkas draf: dapur tetap berisi data contoh seperti sebelumnya.
- **Titik simpan**: satu fungsi induk `_simpanDraft()` dipanggil sesudah SETIAP perubahan — tambah/kurang/hapus baris, pilih meja, hapus menu, checkout (keranjang kosong + tiket baru + nomor urut naik), majukan status dapur, dan laporan balik pilihan jenis/promo dari layar Kasir (callback opsional baru `onJenisBerubah`/`onPromoBerubah`; reset promo sesudah bayar ikut dilaporkan supaya promo tidak terbawa ke pelanggan berikutnya lewat draf).
- **Penerapan draf di layar Kasir**: parameter opsional `jenisAwal`/`promoIdAwal` hanya dikirim induk sesudah data termuat (`_ready`); layar menerapkannya SEKALI — dari initState bila layar lahir sesudah data siap, atau didUpdateWidget bila data selesai belakangan. Sesudah itu pilihan kasir di sesi berjalan yang berkuasa.
- Tes baru patch_0160: pulang-pergi JSON KitchenOrder & DraftKasir, persistensi LocalStore, dan dua tes aplikasi penuh — (1) bayar 1 pesanan jadi tiket, sisakan 1 item di keranjang, buka ulang aplikasi dua kali: keranjang selamat, tiket selamat, status Dimasak ikut selamat; (2) draf berisi menu hantu: baris hantu dibuang dan jenis Bungkus pulih. Pelajaran tes: `scrollUntilVisible` hanya mencari KE BAWAH — menu yang tertinggal di atas posisi gulir melempar StateError; tarik grid ke puncak dulu.

## v0.17.0 (2026-11-17) — CRUD kategori menu + splash latar putih
- **Splash latar putih** (permintaan Adnan sore ini, mengganti hitam v0.15.0): karya Avorea yang sama di atas putih; spinner & label studio diganti hijau alpukat tua #1E3A2A (warna huruf karya itu sendiri) karena kuning/krem lama tidak terbaca di atas putih. Diverifikasi dari bingkai render sebelum rilis — catatan harness: gambar aset butuh waktu nyata (runAsync) untuk selesai dibaca, satu pump pendek menghasilkan bingkai kosong palsu.
- **Kategori bukan lagi daftar mati**: sebelumnya `const categories` di data.dart — tidak bisa ditambah/diubah/dihapus. Kini daftar kategori tersimpan di `AppSettings.menuCategories` (ikut tersinkron lewat pengaturan) dan daftar EFEKTIF selalu lewat `kategoriEfektif(settings, menus)`: daftar tersimpan (atau `kategoriBawaan` bila belum pernah diatur) + kategori apa pun yang sedang dipakai menu — data lama tidak pernah kehilangan kategorinya.
- **Layar Kelola Kategori** (Produk → menu ⋯ → Kelola Kategori): baris per kategori dengan jumlah menu, tombol ubah nama & hapus berikon, tombol Tambah Kategori. Ubah nama menulis ulang kategori di SEMUA menu yang memakainya. Hapus TIDAK menghapus menu — menunya dipindah ke 'Lainnya' (dibuat bila belum ada), dan dialog konfirmasi menyatakannya terus terang. Nama dobel (tak peka huruf) dan nama 'Semua' ditolak dengan pesan galat di lembar.
- **Editor menu**: chip kategori kini dari daftar efektif, plus chip 'Kategori Baru' — mengetik nama di dialog kecil langsung memakainya untuk menu itu; induk mendaftarkannya ke daftar tersimpan otomatis saat menu disimpan (`_daftarkanKategoriMenu` di jalur tambah/ubah/impor). Chip saring Kasir & Produk dan validasi impor CSV memakai daftar yang sama.
- Tes baru patch_0170 (10): kategoriEfektif 2 kasus, pulang-pergi JSON pengaturan, layar Kelola Kategori (tampil+jumlah, tambah, dobel ditolak, ubah nama, hapus+dialog), splash putih, dan alur aplikasi penuh ubah nama 'Kopi' → 'Kopi Robusta' terbukti di penyimpanan + chip Kasir.

## v0.18.0 (2026-11-17) — Ganti nama: Avoera → Avorea
- Permintaan Adnan malam ini: "Ganti semua nama jadi Avorea, bukan Avoera" — menyamakan nama aplikasi dengan merek usaha klien (Avorea, Maestro Alpukat Kocok) yang memang sudah jadi isi karya splash & lockup LogoAvorea.
- **Yang diganti (semua yang terlihat pengguna)**: `appName` → 'Avorea POS' (mengalir ke Pengaturan, sidebar, kaki halaman), label peluncur Android, judul MaterialApp, label kaki splash 'AVOREA POS · BY WEBTALES STUDIO', bawaan nama usaha 'Avorea Cafe & Resto', teks pemberitahuan & dialog pembaruan, cap 'Dibuat oleh Avorea POS' di ekspor PDF/teks & label harga, dan nama cadangan di kepala struk.
- **Migrasi nama tersimpan**: nama usaha yang MASIH persis bawaan lama ('Avoera Cafe & Resto') diganti otomatis saat data dimuat; nama yang sudah diubah pemilik sendiri tidak disentuh (diuji dua arah di patch_0180).
- **Yang SENGAJA tidak diganti (mesin, tak terlihat)**: applicationId `id.avoera.avoera_pos`, kunci penyimpanan `avoera.*`, nama paket Dart, nama tabel Supabase `avoera_*`, nama repo & kelas internal — menggantinya akan memutus jalur pembaruan dan menghapus data di HP yang sudah terpasang. Nama dagang dan nama mesin memang lazim berbeda.
- Tes baru patch_0180 (4): konstanta nama, label splash, migrasi nama bawaan, nama kustom kebal.

## v0.19.0 (2026-11-17) — Perbaikan cabang hilang + ubah nama cabang
- Kejadian malam ini: sesudah install ulang, baris "Cabang 2" hilang dari awan — pembersih hantu ikut membersihkan cabang (padahal cabang tidak bisa dihapus dari aplikasi), dan nama cabang pertama tertimpa jadi "Cabang Ketiga" oleh isian sambutan awal. Baris Cabang 2 dipulihkan manual ke awan oleh Muse malam itu juga.
- **Pembersih hantu khusus cabang DIMATIKAN** (sync.dart): cabang yang "dikenal tapi tidak lokal" selalu sisa gabungan/pemulihan, bukan penghapusan sungguhan. Menu & bahan tetap dibersihkan seperti biasa.
- **Pemulihan cabang yatim** (`pulihkanCabangYatim` di data.dart, dipakai pada hasil gabungan sinkron): transaksi yang branchId-nya tidak ada di daftar cabang → cabangnya dibuatkan lagi dengan id yang sama, nama 'Cabang (dipulihkan)', supaya transaksi nyambung dan cabang bisa dipakai & diganti namanya.
- **Ubah Cabang di Pengaturan**: setiap baris cabang kini punya tombol pensil (tooltip 'Ubah cabang') → sheet `showUbahCabangSheet` (branch_wizard_screen.dart; pola FormSheet yang sama dengan sheet kategori): nama wajib, alamat & telepon boleh kosong; id tidak berubah jadi transaksi lama aman. Inilah jalan membetulkan "Cabang Ketiga" → "Cabang Utama" dari HP.
- Tes baru patch_0190 (6): pemulihan yatim (3), sheet ubah cabang (2), alur penuh ubah nama dari Pengaturan sampai tersimpan (1).

## v0.20.0 (2026-11-17) — Reset Total: semua data dihapus, balik seperti baru dipasang
- Permintaan Adnan malam ini (ia memilih "reset total" dari dua pilihan): fitur menghapus SEMUA data supaya aplikasi mulai dari nol — pas sesudah kejadian cabang, sebelum pilot, karena isi awan kebanyakan data tes.
- **Pengaturan → Zona Berbahaya → Reset Semua Data** (baris merah datar: ikon tong sampah di kotak danger 10%, tanpa bayangan/gradasi): membuka `showResetTotalDialog` — penjelasan akibat dengan kata biasa (awan + HP ini, permanen, perangkat lain harus ikut direset/diinstall ulang), lalu pengguna WAJIB mengetik RESET (tidak peka huruf besar/kecil) sebelum tombol 'Hapus Semua Data' (PrimaryButton danger) menyala.
- **Urutan kerja shell `_resetTotal`** (mengembalikan null = berhasil / pesan galat = batal): (1) bekukan sinkron (`_resetBerlangsung` — _syncNow menolak jalan & hasil sinkron yang sedang terbang tidak diterapkan/disimpan), tunggu sinkron terbang selesai supaya unggahannya tuntas sebelum penghapusan; (2) hapus semua baris usaha di 5 tabel awan (`hapusSemuaDataCloud` di sync.dart, DELETE per business_key) — GAGAL di sini = reset batal total, data HP tidak diubah sama sekali; (3) buang berkas foto usaha, `LocalStore.hapusSemuaData()` membuang semua kunci avoera.*; (4) kosongkan ingatan kotor/dikenal/laporan, muat ulang `_loadData()` (data contoh + sambutan awal, backend bawaan ditanam ulang), lalu satu sinkron awal seperti pemasangan baru.
- Jahitan tes `jahitanHapusCloud` (sync.dart, selalu null di produksi) menggantikan penghapusan awan di tes. Tes baru patch_0200 (5): hapus lokal tuntas, dialog (tombol mati→menyala + galat tampil), alur penuh berhasil→OnboardingFlow, alur penuh gagal→data utuh.

## v0.21.0 (2026-11-18) — Wizard pintar: pilih cabang lama, bukan menimpa
- Permintaan Adnan: wizard sesudah onboarding membingungkan bila cabang SUDAH ada — dan memang di situlah akar kejadian nama cabang tertimpa ("Cabang Ketiga"): `_finish` wizard selalu mengganti daftar cabang jadi satu cabang bernama hasil ketikan.
- **Dua mode dari daftar cabang hidup** (`OnboardingFlow._modePilih` = `initial.branches.length > 1`; daftarnya objek pengaturan yang sama dengan milik shell, jadi hasil sinkron awan terbaca langsung): (1) **Mode buat** (usaha baru / sesudah Reset Total — daftar satu): persis seperti dulu, kolom 'Nama Cabang Pertama'. (2) **Mode pilih** (install ulang / HP baru, cabang lama ketemu dari awan): judul jadi 'Cabang Lamamu Ketemu', kolom nama cabang HILANG, diganti daftar baris pilih cabang (gaya kartu pilih Pembayaran: tepi aksen 2px saat terpilih, tanpa isian pastel, tanpa centang; keterangan 'Dipakai di perangkat ini'); selesai hanya mengubah `activeBranchId`. Tombol halaman perkenalan terakhir ikut berubah: 'Pilih Cabangmu'.
- **Pengaman anti-timpa di `_finish`**: keputusan diambil dari daftar TERKINI saat tombol ditekan — bila isinya > 1, daftar tidak pernah diganti; sinkron yang mendarat di tengah wizard (didUpdateWidget membuang pilihan yang sudah tidak sah) ikut aman.
- Nama usaha tetap terisi dari awan dan boleh diubah; PIN tetap dibuat baru per perangkat (PIN tidak pernah sinkron). Tes baru patch_0210 (4): mode pilih tampil, mode pilih selesai (cabang utuh, aktif berpindah), sinkron mendarat di tengah wizard, mode buat tidak berubah.
