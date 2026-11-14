-- ============================================================
-- Avoera POS — Skema backend Supabase (gratis)
-- Jalankan SEKALI di Supabase: menu SQL Editor → New query →
-- tempel seluruh berkas ini → Run.
--
-- Cara kerja keamanan (sederhana, tanpa akun login):
-- setiap baris data ditandai business_key (Kode Usaha yang dibuat
-- pemilik sendiri di aplikasi). Aplikasi mengirim kode itu sebagai
-- header 'x-business-key'; aturan RLS di bawah hanya mengizinkan
-- baca/tulis baris yang kodenya cocok dengan header. Perangkat
-- dengan Kode Usaha yang sama = melihat data yang sama.
-- Kode Usaha bersifat seperti kata sandi bersama: jangan dibagikan
-- ke orang luar. Kunci "anon" Supabase memang boleh tersebar
-- (perlindungannya dari RLS ini), kunci "service_role" JANGAN
-- pernah dimasukkan ke aplikasi.
-- ============================================================

-- ---------- Tabel generik: satu baris = satu data JSON ----------
-- Pola ini membuat aplikasi bebas berkembang (kolom baru cukup di
-- JSON) tanpa migrasi SQL berulang.

create table if not exists public.avoera_menus (
  business_key text not null,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (business_key, id)
);

create table if not exists public.avoera_ingredients (
  business_key text not null,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (business_key, id)
);

create table if not exists public.avoera_branches (
  business_key text not null,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (business_key, id)
);

create table if not exists public.avoera_transactions (
  business_key text not null,
  uuid text not null,
  at timestamptz not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (business_key, uuid)
);
create index if not exists avoera_tx_at on public.avoera_transactions (business_key, at desc);

create table if not exists public.avoera_settings (
  business_key text not null,
  id text not null default 'main',
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (business_key, id)
);

-- ---------- RLS: hanya baris dengan Kode Usaha yang cocok ----------
-- Berlaku sama untuk kelima tabel.

do $$
declare
  t text;
  tables text[] := array['avoera_menus', 'avoera_ingredients', 'avoera_branches', 'avoera_transactions', 'avoera_settings'];
begin
  foreach t in array tables loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists avoera_akses_kode on public.%I', t);
    execute format($p$
      create policy avoera_akses_kode on public.%I
      for all to anon, authenticated
      using (business_key = (current_setting('request.headers', true)::json ->> 'x-business-key'))
      with check (business_key = (current_setting('request.headers', true)::json ->> 'x-business-key'))
    $p$, t);
  end loop;
end $$;
