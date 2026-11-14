# Backend Supabase Avoera POS — Panduan Pasang (Gratis)

Backend ini membuat data Avoera POS (menu, stok bahan, cabang,
pengaturan usaha, transaksi) tersimpan di awan dan sama di semua
perangkat dengan **Kode Usaha** yang sama. Aplikasi tetap bisa
jualan tanpa internet — sinkron ditekan manual dari Pengaturan.

Biaya: Rp0 (paket gratis Supabase cukup untuk pemakaian cafe).

## Langkah pasang (±10 menit, sekali saja)

1. Buka https://supabase.com → **Start your project** → masuk
   dengan akun Google/GitHub.
2. **New project**: beri nama bebas (mis. `avoera-pos`), buat
   kata sandi database (simpan baik-baik), region pilih
   **Singapore**. Tunggu proyek selesai dibuat (±2 menit).
3. Di proyek itu buka menu **SQL Editor** → **New query** →
   tempel SELURUH isi berkas `schema.sql` di folder ini → **Run**.
   Harus muncul "Success".
4. Buka **Project Settings → API**. Salin dua hal:
   - **Project URL** (bentuknya `https://xxxx.supabase.co`)
   - **anon public key** (diawali `eyJ...`)
   JANGAN pakai kunci `service_role` — kunci itu rahasia penuh.
5. Di aplikasi Avoera POS: **Pengaturan → Sinkronisasi Online**:
   - isi **URL Proyek Supabase** dan **Kunci Anon Supabase** dari langkah 4,
   - buat **Kode Usaha** sendiri (bebas, mis. `kopisenja-2026`) —
     anggap seperti kata sandi bersama; perangkat lain yang ingin
     datanya menyatu harus memakai kode yang PERSIS sama,
   - tekan **Sinkronkan Sekarang**.
6. Di perangkat kedua: pasang Avoera POS, lewati wizard, lalu isi
   URL + kunci anon + Kode Usaha yang sama → Sinkronkan Sekarang →
   menu, bahan, cabang, dan riwayat transaksi ikut turun.

## Catatan jujur

- Sinkron saat ini **manual** (tombol) dan menimpa per data dengan
  aturan "yang dari server menang untuk data yang sama id-nya";
  transaksi digabung, tidak dobel.
- **Meja (status & tagihan berjalan) tidak disinkronkan** — itu
  keadaan langsung di satu perangkat kasir.
- Foto menu masih tersimpan lokal di perangkat (belum naik awan).
- PIN kasir tidak pernah dikirim ke server.
- Tahap berikutnya bila dibutuhkan: login akun Supabase Auth,
  sinkron otomatis, dan foto naik ke Supabase Storage.
