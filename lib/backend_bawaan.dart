// Backend bawaan yang DITANAM di aplikasi (permintaan Adnan
// 2026-11-14 malam: "hardcode aja") — proyek Supabase usaha ini,
// supaya aplikasi langsung tersambung tanpa mengisi kolom
// Pengaturan satu-satu (kunci anon panjang gampang meleset saat
// disalin manual, itu biang sinkron gagal berhari-hari).
//
// Cara pakai: saat aplikasi pertama kali jalan dengan build ini,
// ketiga nilai ini ditulis ke pengaturan (migrasi sekali jalan,
// penanda AppSettings.backendBawaanDitanam). Sesudah itu kolom
// Pengaturan yang MENANG — usaha lain / proyek lain tinggal
// menimpa dari Pengaturan seperti biasa.
//
// KEAMANAN: yang tertanam HANYA kunci anon. Kunci anon memang
// dirancang boleh tersebar (yang menjaga data adalah RLS +
// Kode Usaha di server). JANGAN PERNAH menaruh kunci
// service_role di aplikasi — itu kunci bebas hambatan.
const kSupabaseUrlBawaan = 'https://ejevcxqxasiaprorkank.supabase.co';
const kSupabaseAnonKeyBawaan = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqZXZjeHF4YXNpYXByb3JrYW5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ2NTA2NzUsImV4cCI6MjExMDIyNjY3NX0.I4HDoaHUtzzBgUsKMr34gZiVYMg0tjHs6Stj1M1XSBo';
const kKodeUsahaBawaan = 'avorea-2026';
