import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../printer.dart';
import '../theme.dart';
import '../ikon.dart';

/// Hasil memilih printer: nama tampilan + id perangkat.
typedef PrinterDipilih = ({String nama, String id});

/// Cari Printer (v0.15.0): memindai perangkat Bluetooth di
/// sekitar; mengetuk satu perangkat memilihnya sebagai
/// printer struk (tersimpan, dipakai tombol Cetak &
/// Tes Cetak). Printer thermal biasanya bernama seperti
/// MTP-58, RPP02N, atau Bluetooth Printer.
class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final _perangkat = <String, BleDevice>{};
  String? _pesan;
  bool _memindai = false;
  Timer? _timerScan;

  @override
  void initState() {
    super.initState();
    UniversalBle.onScanResult = (d) {
      if (!mounted) return;
      setState(() => _perangkat[d.deviceId] = d);
    };
    _mulai();
  }

  @override
  void dispose() {
    _timerScan?.cancel();
    UniversalBle.onScanResult = null;
    UniversalBle.stopScan().catchError((_) {});
    super.dispose();
  }

  Future<void> _mulai() async {
    setState(() {
      _pesan = null;
      _perangkat.clear();
    });
    final izin = await PrinterTermal.mintaIzin();
    if (!mounted) return;
    if (izin != null) {
      setState(() => _pesan = izin);
      return;
    }
    final bt = await PrinterTermal.periksaBluetooth();
    if (!mounted) return;
    if (bt != null) {
      setState(() => _pesan = bt);
      return;
    }
    try {
      await UniversalBle.startScan();
      if (!mounted) return;
      setState(() => _memindai = true);
      _timerScan?.cancel();
      _timerScan = Timer(const Duration(seconds: 12), () {
        UniversalBle.stopScan().catchError((_) {});
        if (mounted) setState(() => _memindai = false);
      });
    } catch (e) {
      if (mounted) setState(() => _pesan = 'Tidak bisa memindai: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _perangkat.values.toList()
      ..sort((a, b) {
        final an = (a.name ?? '').isNotEmpty ? 0 : 1;
        final bn = (b.name ?? '').isNotEmpty ? 0 : 1;
        if (an != bn) return an.compareTo(bn);
        return (b.rssi ?? -999).compareTo(a.rssi ?? -999);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Printer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (_memindai) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                if (_memindai) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _memindai ? 'Memindai perangkat di sekitar…' : 'Pindai selesai. Nyalakan printer lalu pindai lagi bila belum muncul.',
                    style: AppText.body.copyWith(color: AppColors.muted),
                  ),
                ),
                TextButton(onPressed: _mulai, child: const Text('Pindai Lagi')),
              ],
            ),
          ),
          if (_pesan != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warningBorder)),
                child: Text(_pesan!, style: AppText.body.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(
            child: hasil.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        _memindai ? 'Belum ada perangkat ditemukan…' : 'Tidak ada perangkat. Pastikan printer menyala & dekat.',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: AppColors.muted),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: hasil.length,
                    separatorBuilder: (c, i) => const Divider(height: 1, indent: 68),
                    itemBuilder: (context, i) {
                      final d = hasil[i];
                      final nama = (d.name ?? '').isEmpty ? '(tanpa nama)' : d.name!;
                      return ListTile(
                        leading: Icon(Ikon.print_outlined, color: AppColors.accentDark),
                        title: Text(nama, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(d.deviceId, style: AppText.caption.copyWith(color: AppColors.muted)),
                        trailing: Icon(Ikon.chevron_right, color: AppColors.muted),
                        onTap: () async {
                          _timerScan?.cancel();
                          await UniversalBle.stopScan().catchError((_) {});
                          if (!context.mounted) return;
                          Navigator.of(context).pop((nama: d.name ?? '', id: d.deviceId));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
