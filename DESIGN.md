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
