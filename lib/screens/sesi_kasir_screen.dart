import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';
import 'kelola_widgets.dart';
import 'laporan_bersama.dart';

/// Sesi Kasir (v0.15.0): buka kasir dengan modal awal, tutup
/// kasir dengan hitung fisik + selisih, dan riwayat sesi yang
/// sudah ditutup. Penjualan TIDAK pernah diblokir sesi —
/// halaman ini murni pencatatan & rekonsiliasi laci.
class SesiKasirScreen extends StatelessWidget {
  const SesiKasirScreen({
    super.key,
    required this.sesi,
    required this.transactions,
    required this.expenses,
    required this.branchId,
    required this.branchName,
    required this.onBuka,
    required this.onTutup,
  });

  final List<SesiKasir> sesi;
  final List<TxRecord> transactions;
  final List<Pengeluaran> expenses;
  final String branchId;
  final String branchName;
  final void Function(String namaKasir, int modalAwal) onBuka;
  final void Function(int tunaiFisik, int pengeluaranLaci, String catatan) onTutup;

  static String teksJam(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final terbuka = sesi.where((s) => s.terbuka && s.branchId == branchId).firstOrNull;
    final riwayat = sesi.where((s) => !s.terbuka && s.branchId == branchId).toList()..sort((a, b) => b.ditutupPada!.compareTo(a.ditutupPada!));

    return Scaffold(
      appBar: AppBar(title: const Text('Sesi Kasir')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          if (terbuka != null) ...[
            KartuHero(
              label: 'Kasir Sedang Buka',
              nilai: 'Sejak ${teksJam(terbuka.dibukaPada)}',
              keterangan: '${labelTgl(terbuka.dibukaPada)} · ${terbuka.namaKasir.isEmpty ? 'Tanpa nama kasir' : 'Kasir ${terbuka.namaKasir}'} · Modal awal ${rupiah(terbuka.modalAwal)}',
            ),
            const SizedBox(height: AppSpacing.lg),
            _KartuRingkasanSesi(sesi: terbuka, ringkasan: ringkasSesi(sesi: terbuka, transactions: transactions, expenses: expenses)),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Tutup Kasir',
              icon: Ikon.lock_outlined,
              onPressed: () => showTutupKasirSheet(
                context,
                sesi: terbuka,
                ringkasan: ringkasSesi(sesi: terbuka, transactions: transactions, expenses: expenses),
                onTutup: onTutup,
              ),
            ),
          ] else ...[
            KartuHero(
              label: 'Kasir Belum Dibuka',
              nilai: '—',
              keterangan: 'Buka kasir untuk mulai mencatat sesi. Penjualan tetap bisa jalan tanpa sesi, tapi tidak masuk ringkasan sesi mana pun.',
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Buka Kasir',
              icon: Ikon.lock_open_outlined,
              onPressed: () => showBukaKasirSheet(context, onBuka: onBuka),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const JudulSeksi(ikon: Ikon.history, teks: 'Riwayat sesi ditutup'),
          const SizedBox(height: AppSpacing.md),
          if (riwayat.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('Belum ada sesi yang ditutup.', textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.muted)),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < riwayat.length; i++) ...[
                    if (i > 0) const GarisTipis(),
                    Builder(builder: (context) {
                      final s = riwayat[i];
                      final r = ringkasSesi(sesi: s, transactions: transactions, expenses: expenses);
                      final sel = s.selisih(r);
                      return InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DetailSesiScreen(sesi: s, transactions: transactions, expenses: expenses)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${labelTgl(s.ditutupPada!)} · ${teksJam(s.dibukaPada)}–${teksJam(s.ditutupPada!)}', style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                    Text(
                                      '${s.namaKasir.isEmpty ? 'Tanpa nama kasir' : 'Kasir ${s.namaKasir}'} · ${r.jumlahTransaksi} transaksi · penjualan ${rupiah(r.totalPenjualan)}',
                                      style: AppText.caption.copyWith(color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              StatusChip(
                                label: sel == 0 ? 'Pas' : (sel > 0 ? 'Lebih ${rupiah(sel)}' : 'Kurang ${rupiah(-sel)}'),
                                color: sel == 0 ? AppColors.accentDark : (sel > 0 ? AppColors.warning : AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Catatan: sesi kasir tersimpan di perangkat ini (belum ikut sinkron). Uang yang seharusnya di laci = modal awal + penjualan tunai − pengeluaran dari laci.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Kartu angka berjalan satu sesi (dipakai layar Sesi Kasir).
class _KartuRingkasanSesi extends StatelessWidget {
  const _KartuRingkasanSesi({required this.sesi, required this.ringkasan});
  final SesiKasir sesi;
  final RingkasanSesi ringkasan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Column(
        children: [
          BarisNilai(label: 'Transaksi lunas', nilai: '${ringkasan.jumlahTransaksi} transaksi'),
          const GarisTipis(),
          BarisNilai(label: 'Penjualan tunai', nilai: rupiah(ringkasan.totalTunai)),
          const GarisTipis(),
          BarisNilai(label: 'Penjualan QRIS', nilai: rupiah(ringkasan.totalQris)),
          const GarisTipis(),
          BarisNilai(label: 'Total penjualan', nilai: rupiah(ringkasan.totalPenjualan), tebal: true),
          const GarisTipis(),
          BarisNilai(label: 'Diskon diberikan', nilai: rupiah(ringkasan.totalDiskon)),
          const GarisTipis(),
          BarisNilai(label: 'Pengeluaran tercatat', nilai: rupiah(ringkasan.totalPengeluaran)),
        ],
      ),
    );
  }
}

/// Detail satu sesi yang sudah ditutup: ringkasan penuh +
/// rekonsiliasi laci (seharusnya vs fisik vs selisih).
class DetailSesiScreen extends StatelessWidget {
  const DetailSesiScreen({super.key, required this.sesi, required this.transactions, required this.expenses});

  final SesiKasir sesi;
  final List<TxRecord> transactions;
  final List<Pengeluaran> expenses;

  @override
  Widget build(BuildContext context) {
    final r = ringkasSesi(sesi: sesi, transactions: transactions, expenses: expenses);
    final seharusnya = sesi.tunaiSeharusnya(r);
    final sel = sesi.selisih(r);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Sesi')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, paddingBawahAman(context)),
        children: [
          KartuHero(
            label: 'Selisih Laci',
            nilai: sel == 0 ? 'Pas' : rupiah(sel),
            keterangan: sel == 0
                ? 'Hitung fisik sama persis dengan catatan.'
                : (sel > 0 ? 'Uang fisik LEBIH ${rupiah(sel)} dari catatan.' : 'Uang fisik KURANG ${rupiah(-sel)} dari catatan.'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Dibuka', nilai: '${labelTgl(sesi.dibukaPada)} ${SesiKasirScreen.teksJam(sesi.dibukaPada)}'),
                const GarisTipis(),
                BarisNilai(label: 'Ditutup', nilai: '${labelTgl(sesi.ditutupPada!)} ${SesiKasirScreen.teksJam(sesi.ditutupPada!)}'),
                const GarisTipis(),
                BarisNilai(label: 'Kasir', nilai: sesi.namaKasir.isEmpty ? '—' : sesi.namaKasir),
                const GarisTipis(),
                BarisNilai(label: 'Transaksi lunas', nilai: '${r.jumlahTransaksi} transaksi'),
                const GarisTipis(),
                BarisNilai(label: 'Penjualan tunai', nilai: rupiah(r.totalTunai)),
                const GarisTipis(),
                BarisNilai(label: 'Penjualan QRIS', nilai: rupiah(r.totalQris)),
                const GarisTipis(),
                BarisNilai(label: 'Total penjualan', nilai: rupiah(r.totalPenjualan), tebal: true),
                const GarisTipis(),
                BarisNilai(label: 'Diskon diberikan', nilai: rupiah(r.totalDiskon)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const JudulSeksi(ikon: Ikon.payments_outlined, teks: 'Rekonsiliasi laci'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                BarisNilai(label: 'Modal awal', nilai: rupiah(sesi.modalAwal)),
                const GarisTipis(),
                BarisNilai(label: 'Pengeluaran dari laci', nilai: rupiah(sesi.pengeluaranLaci ?? 0)),
                const GarisTipis(),
                BarisNilai(label: 'Seharusnya di laci', catatan: 'Modal + tunai − pengeluaran laci', nilai: rupiah(seharusnya), tebal: true),
                const GarisTipis(),
                BarisNilai(label: 'Hitung fisik kasir', nilai: rupiah(sesi.tunaiFisik ?? 0)),
                const GarisTipis(),
                BarisNilai(
                  label: 'Selisih',
                  nilai: sel == 0 ? 'Pas' : rupiah(sel),
                  tebal: true,
                  warnaNilai: sel == 0 ? AppColors.accentDark : (sel > 0 ? AppColors.warning : AppColors.danger),
                ),
              ],
            ),
          ),
          if (sesi.catatan.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const JudulSeksi(ikon: Ikon.edit_outlined, teks: 'Catatan kasir'),
            const SizedBox(height: AppSpacing.md),
            AppCard(child: Text(sesi.catatan, style: AppText.body.copyWith(color: AppColors.ink))),
          ],
        ],
      ),
    );
  }
}

/// Lembar Buka Kasir: nama kasir (bebas, boleh kosong) +
/// modal awal uang di laci.
Future<void> showBukaKasirSheet(
  BuildContext context, {
  required void Function(String namaKasir, int modalAwal) onBuka,
}) async {
  final namaCtrl = TextEditingController();
  final modalCtrl = TextEditingController();
  String? error;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return FormSheet(
          title: 'Buka Kasir',
          errorText: error,
          saveLabel: 'Buka Kasir',
          onSave: () {
            final modal = int.tryParse(modalCtrl.text.replaceAll('.', '')) ?? 0;
            if (modal < 0) {
              setSheet(() => error = 'Modal awal tidak boleh negatif.');
              return;
            }
            onBuka(namaCtrl.text.trim(), modal);
            Navigator.of(ctx).pop();
          },
          children: [
            const FormLabel('Nama kasir'),
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(hintText: 'Boleh kosong'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            const FormLabel('Modal awal di laci (Rp)'),
            TextField(
              controller: modalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: 'Uang kembalian yang disiapkan'),
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([namaCtrl, modalCtrl]);
}

/// Lembar Tutup Kasir: ringkasan sesi + hitung fisik.
/// Pengeluaran dari laci terisi awal dari pengeluaran
/// tercatat; kasir boleh membetulkan (mis. ada yang dibayar
/// lewat transfer). Selisih tampil langsung saat mengetik.
Future<void> showTutupKasirSheet(
  BuildContext context, {
  required SesiKasir sesi,
  required RingkasanSesi ringkasan,
  required void Function(int tunaiFisik, int pengeluaranLaci, String catatan) onTutup,
}) async {
  final fisikCtrl = TextEditingController();
  final keluarCtrl = TextEditingController(text: ThousandsFormatter.format(ringkasan.totalPengeluaran));
  final catatanCtrl = TextEditingController();
  String? error;
  int? bacaRp(TextEditingController c) => int.tryParse(c.text.replaceAll('.', ''));
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final fisik = bacaRp(fisikCtrl);
        final keluar = bacaRp(keluarCtrl) ?? 0;
        final seharusnya = sesi.modalAwal + ringkasan.totalTunai - keluar;
        final sel = fisik == null ? null : fisik - seharusnya;
        return FormSheet(
          title: 'Tutup Kasir',
          errorText: error,
          saveLabel: 'Tutup Kasir',
          onSave: () {
            if (fisik == null) {
              setSheet(() => error = 'Isi dulu uang tunai hasil hitung fisik di laci.');
              return;
            }
            onTutup(fisik, keluar, catatanCtrl.text.trim());
            Navigator.of(ctx).pop();
          },
          children: [
            _barisRingkasan('Penjualan tunai', rupiah(ringkasan.totalTunai)),
            _barisRingkasan('Penjualan QRIS', rupiah(ringkasan.totalQris)),
            _barisRingkasan('Transaksi lunas', '${ringkasan.jumlahTransaksi} transaksi'),
            const SizedBox(height: AppSpacing.lg),
            const FormLabel('Uang tunai di laci — hitung fisik (Rp)'),
            TextField(
              controller: fisikCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: 'Hitung semua uang tunai di laci'),
              onChanged: (_) => setSheet(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            const FormLabel('Pengeluaran dari laci (Rp)'),
            TextField(
              controller: keluarCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: 'Terisi dari catatan pengeluaran — betulkan bila perlu'),
              onChanged: (_) => setSheet(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seharusnya di laci: ${rupiah(seharusnya)}', style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sel == null
                        ? 'Selisih tampil setelah uang fisik diisi.'
                        : (sel == 0 ? 'Selisih: Pas — tidak ada selisih.' : (sel > 0 ? 'Selisih: Lebih ${rupiah(sel)}' : 'Selisih: Kurang ${rupiah(-sel)}')),
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: sel == null ? AppColors.muted : (sel == 0 ? AppColors.accentDark : (sel > 0 ? AppColors.warning : AppColors.danger)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const FormLabel('Catatan (boleh kosong)'),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(hintText: 'Mis. selisih karena uang jatuh, dsb.'),
              maxLines: 2,
            ),
          ],
        );
      },
    ),
  );
  disposeControllersLater([fisikCtrl, keluarCtrl, catatanCtrl]);
}

Widget _barisRingkasan(String label, String nilai) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body.copyWith(color: AppColors.muted))),
          Text(nilai, style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
