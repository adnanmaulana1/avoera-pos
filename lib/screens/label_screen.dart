import 'package:flutter/material.dart';

import '../data.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';

/// Layar Cetak Label Harga (permintaan Adnan 2026-11-15 — fitur
/// yang dulu 'Segera'): pratinjau label persis seperti hasil
/// PDF-nya — kartu putih berisi nama usaha, nama menu, kategori,
/// harga. Tombol di bawah membagikan PDF untuk dicetak.
class LabelHargaScreen extends StatelessWidget {
  const LabelHargaScreen({super.key, required this.menus, required this.businessName});
  final List<MenuItem> menus;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cetak Label Harga')),
      body: Column(
        children: [
          Expanded(
            child: menus.isEmpty
                ? const EmptyState(message: 'Belum ada menu untuk dibuatkan label.', icon: Icons.sell_outlined)
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: menus.length,
                    itemBuilder: (_, i) {
                      final m = menus[i];
                      // Kertas label selalu putih (seperti hasil cetak).
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName.toUpperCase(),
                              style: AppText.caption.copyWith(color: const Color(0xFF6B7280), fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              m.name,
                              style: AppText.body.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(m.category, style: AppText.caption.copyWith(color: const Color(0xFF6B7280))),
                            const Spacer(),
                            Text(rupiah(m.price), style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800, color: AppColors.accentDark)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Bagikan / Cetak PDF',
                    icon: Icons.print_outlined,
                    onPressed: menus.isEmpty
                        ? null
                        : () => bagikanPdfLabel(menus: menus, businessName: businessName),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
