# Avoera POS — UI Flutter

UI aplikasi kasir untuk resto, cafe, dan kedai kopi.
**Ini UI saja**: data contoh statis, state lokal di dalam aplikasi, **tanpa backend**.
Interaksi yang sudah bekerja: keranjang (tambah/kurang/hapus), pilih varian menu
(ukuran & level gula) lewat bottom sheet, pilih meja aktif, pembayaran Tunai/QRIS
dengan dialog sukses, pesanan hasil bayar masuk ke Dapur, dan status dapur bisa
dimajukan (Baru Masuk → Dimasak → Selesai → Sudah Diantar).

## Layar

| Layar | Isi |
|---|---|
| Kasir | Kategori menu, cari, grid menu, pilih meja, keranjang, subtotal + layanan 5% + pajak 10%, bayar Tunai/QRIS |
| Meja | Peta 12 meja: Kosong / Terisi / Belum Bayar, ketuk untuk jadi meja aktif |
| Dapur | 3 kolom status pesanan dengan tombol maju status |
| Laporan | Omzet hari ini, transaksi, rata-rata, grafik batang 7 hari, menu terlaris, stok kritis |
| Stok Bahan | Daftar bahan baku dengan sisa stok dan status Aman / Kritis / Habis |

Responsif: lebar ≥ 900 pakai sidebar kiri + kasir dua kolom;
di HP pakai bottom navigation + bar keranjang di bawah.

## Sistem desain

Semua tampilan mengikuti satu sistem desain yang tertulis di
[DESIGN.md](DESIGN.md): palet warna (satu aksen emerald), skala jarak
kelipatan 4, skala radius, dan skala teks. Tokennya ada di
`lib/theme.dart` (`AppColors`, `AppSpacing`, `AppRadius`, `AppText`) dan
komponen bersama (PageHeader, AppCard, AppChip, QtyButton, PrimaryButton,
EmptyState, sheet) ada di `lib/widgets.dart`. File layar tidak menulis
warna/ukuran mentah sendiri.

## Jalan lokal

Butuh Flutter 3.47.9 (Dart 3.13).

```bash
flutter pub get
flutter run            # ke HP/emulator yang terhubung
flutter analyze        # cek kode
flutter test           # tes dasar
```

## Compile di Codemagic

File `codemagic.yaml` sudah ada di root project dengan 2 workflow **manual**:

- `android-release` — `flutter pub get` + `flutter build apk --release`
- `android-debug` — `flutter pub get` + `flutter build apk --debug`

Cara pakai:

1. Push project ini ke repo GitHub.
2. Di Codemagic: **Add application** → hubungkan repo GitHub tersebut →
   pilih **Flutter App** / yaml. Codemagic akan membaca `codemagic.yaml`.
3. Pilih workflow **Android Release** (atau Android Debug) → **Start new build**.
4. Sesudah selesai, unduh APK dari bagian **Artifacts**
   (`build/app/outputs/flutter-apk/*.apk`).
5. Pasang APK di HP untuk uji.

### Catatan keystore

Belum ada keystore rilis sendiri. APK dari Codemagic saat ini ditandatangani
dengan **keystore debug bawaan**. Akibatnya:

- Cukup untuk uji internal di HP sendiri.
- Pasang pertama mungkin harus menghapus aplikasi versi lain dulu bila
  tanda tangannya berbeda.
- Untuk rilis resmi ke pelanggan nanti, buat keystore rilis sendiri dan
  daftarkan di Codemagic sebelum build dibagikan.

## Struktur

```
lib/
  main.dart            # shell navigasi + state bersama (keranjang, meja, dapur)
  data.dart            # model + data contoh (menu, meja, dapur, bahan, laporan)
  theme.dart           # token desain (warna, jarak, radius, teks) + tema
  widgets.dart         # komponen bersama (PageHeader, AppCard, AppChip, dll)
  screens/
    kasir_screen.dart
    meja_screen.dart
    dapur_screen.dart
    laporan_screen.dart
    stok_screen.dart
codemagic.yaml
```
