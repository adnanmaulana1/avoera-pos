import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:universal_ble/universal_ble.dart';

/// Layanan printer thermal Bluetooth (BLE) — v0.15.0.
///
/// Memakai universal_ble (lisensi MIT). Catatan: pustaka BLE
/// populer lain (flutter_blue_plus 2.x) kini berbayar untuk
/// aplikasi komersial, jadi tidak dipakai di aplikasi klien.
///
/// Printer thermal 58/80mm umumnya menerima perintah ESC/POS
/// lewat satu karakteristik BLE yang bisa ditulis. Layanan
/// ini: minta izin → pindai → sambung → cari karakteristik
/// penulis (mengutamakan UUID yang lazim dipakai printer
/// POS, lalu karakteristik bisa-tulis pertama) → kirim byte
/// berpotong kecil → putus. Semua kegagalan dikembalikan
/// sebagai pesan teks yang bisa ditampilkan ke pengguna,
/// bukan lemparan.
class PrinterTermal {
  /// Minta izin Bluetooth (dan lokasi untuk Android lama).
  /// Mengembalikan pesan kesalahan, atau null bila siap.
  static Future<String?> mintaIzin() async {
    final hasil = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final ditolak = hasil.entries.where((e) => e.value.isDenied || e.value.isPermanentlyDenied).toList();
    if (ditolak.isEmpty) return null;
    return 'Izin Bluetooth belum diberikan. Aktifkan lewat Pengaturan aplikasi.';
  }

  /// Bluetooth menyala & didukung?
  static Future<String?> periksaBluetooth() async {
    final state = await UniversalBle.getBluetoothAvailabilityState();
    if (state == AvailabilityState.unsupported) return 'Perangkat ini tidak mendukung Bluetooth LE.';
    if (state != AvailabilityState.poweredOn) return 'Bluetooth belum menyala. Nyalakan dulu, lalu coba lagi.';
    return null;
  }

  /// UUID karakteristik yang lazim pada printer thermal POS
  /// (urutan = prioritas pilihan).
  static const _uuidKarakteristikKandidat = [
    '0000ffe1-0000-1000-8000-00805f9b34fb', // seri HM-10 & banyak printer 58mm
    '0000fff1-0000-1000-8000-00805f9b34fb', // ISSC / printer generik
    '0000ff02-0000-1000-8000-00805f9b34fb',
    '0000ae01-0000-1000-8000-00805f9b34fb',
    '49535343-1e4d-4bd9-ba61-23c647249616', // Microchip ISSC transparan
    '000018f0-0000-1000-8000-00805f9b34fb',
  ];

  /// Sambung ke printer [deviceId] dan kirim [bytes] ESC/POS.
  /// Mengembalikan pesan kesalahan, atau null bila terkirim.
  static Future<String?> cetak(String deviceId, List<int> bytes) async {
    final izin = await mintaIzin();
    if (izin != null) return izin;
    final bt = await periksaBluetooth();
    if (bt != null) return bt;

    try {
      await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 15));
    } catch (_) {
      return 'Tidak bisa menyambung ke printer. Pastikan printer menyala dan dekat.';
    }
    try {
      final layanan = await UniversalBle.discoverServices(deviceId);
      ({String layanan, String karakter, bool tanpaBalasan})? target;
      bool bisaTulis(BleCharacteristic c) => c.properties.contains(CharacteristicProperty.write) || c.properties.contains(CharacteristicProperty.writeWithoutResponse);
      for (final uuid in _uuidKarakteristikKandidat) {
        for (final s in layanan) {
          for (final c in s.characteristics) {
            if (c.uuid.toLowerCase() == uuid && bisaTulis(c)) {
              target = (layanan: s.uuid, karakter: c.uuid, tanpaBalasan: c.properties.contains(CharacteristicProperty.writeWithoutResponse));
              break;
            }
          }
          if (target != null) break;
        }
        if (target != null) break;
      }
      if (target == null) {
        for (final s in layanan) {
          for (final c in s.characteristics) {
            if (bisaTulis(c)) {
              target = (layanan: s.uuid, karakter: c.uuid, tanpaBalasan: c.properties.contains(CharacteristicProperty.writeWithoutResponse));
              break;
            }
          }
          if (target != null) break;
        }
      }
      final t = target;
      if (t == null) return 'Printer tersambung, tapi saluran cetaknya tidak ditemukan.';

      // Kirim berpotong kecil — buffer printer thermal kecil;
      // potongan besar sekaligus sering hilang di tengah.
      const potong = 100;
      for (var i = 0; i < bytes.length; i += potong) {
        final bagian = Uint8List.fromList(bytes.sublist(i, i + potong > bytes.length ? bytes.length : i + potong));
        await UniversalBle.write(deviceId, t.layanan, t.karakter, bagian, withoutResponse: t.tanpaBalasan);
        if (t.tanpaBalasan) await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      // Beri waktu printer menyelesaikan cetakan sebelum putus.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return null;
    } catch (e) {
      return 'Gagal mengirim ke printer: $e';
    } finally {
      try {
        await UniversalBle.disconnect(deviceId);
      } catch (_) {
        // Abaikan kegagalan memutus.
      }
    }
  }
}
