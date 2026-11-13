import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  static const int omzetHariIni = 3420000;
  static const int transaksiHariIni = 128;
  int get rataRata => (omzetHariIni / transaksiHariIni).round();

  @override
  Widget build(BuildContext context) {
    final kritis = ingredients.where((i) => i.status != StockStatus.aman).toList();
    final maxWeekly = weeklySales.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Laporan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Ringkasan pemilik · Hari ini', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            StatusChip(label: 'Data contoh', color: AppColors.warning),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final cross = c.maxWidth >= 900 ? 4 : 2;
            final stats = <(String, String, IconData)>[
              ('Omzet Hari Ini', rupiah(omzetHariIni), Icons.payments_outlined),
              ('Transaksi', '$transaksiHariIni', Icons.receipt_long_outlined),
              ('Rata-rata / Transaksi', rupiah(rataRata), Icons.calculate_outlined),
              ('Meja Terisi Sekarang', '4 dari 12', Icons.table_restaurant_outlined),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 104,
              ),
              itemCount: stats.length,
              itemBuilder: (_, i) => Container(
                decoration: cardDecoration(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stats[i].$3, color: AppColors.accentDark, size: 20),
                    const Spacer(),
                    Text(stats[i].$2, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    Text(stats[i].$1, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          decoration: cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Omzet 7 Hari Terakhir'),
              const SizedBox(height: 18),
              SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in weeklySales)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${(d.amount / 1000000).toStringAsFixed(1).replaceAll('.', ',')}jt',
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                              const SizedBox(height: 4),
                              Container(
                                height: 120 * (d.amount / maxWeekly),
                                decoration: BoxDecoration(
                                  color: d.day == 'Sab' ? AppColors.accent : const Color(0xFFA7F3D0),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(d.day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final sideBySide = c.maxWidth >= 900;
            final topCard = Container(
              decoration: cardDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Menu Paling Laris'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < topMenus.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFECFDF5),
                            child: Text('${i + 1}', style: const TextStyle(color: AppColors.accentDark, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(topMenus[i].name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text('${topMenus[i].sold} terjual', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          const SizedBox(width: 10),
                          Text(rupiah(topMenus[i].revenue), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            );
            final stockCard = Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Stok Bahan Kritis'),
                  const SizedBox(height: 8),
                  if (kritis.isEmpty) const Text('Semua stok aman.'),
                  for (final ing in kritis)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(ing.status == StockStatus.habis ? Icons.error_outline : Icons.warning_amber_outlined,
                              color: ing.status == StockStatus.habis ? AppColors.danger : AppColors.warning, size: 19),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text('Sisa ${stockText(ing.stock)} ${ing.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            );
            if (sideBySide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: topCard), const SizedBox(width: 12), Expanded(child: stockCard)]);
            }
            return Column(children: [topCard, const SizedBox(height: 12), stockCard]);
          },
        ),
        const SizedBox(height: 12),
        Container(
          decoration: cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Pembayaran Hari Ini'),
              SizedBox(height: 10),
              _PayRow(label: 'QRIS', value: 'Rp1.940.000 · 57%'),
              _PayRow(label: 'Tunai', value: 'Rp1.025.000 · 30%'),
              _PayRow(label: 'E-wallet / Debit', value: 'Rp455.000 · 13%'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
