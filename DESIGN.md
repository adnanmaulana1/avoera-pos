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
| lg | 20 | Sheet bawah (sudut atas), dialog |
| pill | 999 | Chip status, chip pilihan, bar stok |

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
