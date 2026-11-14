import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Layar Pengaturan: profil usaha, biaya transaksi (langsung berlaku
/// di kasir), dan Tentang aplikasi. Semua nilai tinggal di HomeShell —
/// layar ini hanya menampilkan & mengubah lewat callback.
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({
    super.key,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.servicePercent,
    required this.taxPercent,
    required this.onBusinessNameChanged,
    required this.onBusinessAddressChanged,
    required this.onBusinessPhoneChanged,
    required this.onServicePercentChanged,
    required this.onTaxPercentChanged,
    required this.menuCount,
    required this.tableCount,
    required this.ingredientCount,
    required this.onManageMenus,
    required this.onManageTables,
    required this.onManageIngredients,
  });

  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final int servicePercent;
  final int taxPercent;
  final ValueChanged<String> onBusinessNameChanged;
  final ValueChanged<String> onBusinessAddressChanged;
  final ValueChanged<String> onBusinessPhoneChanged;
  final ValueChanged<int> onServicePercentChanged;
  final ValueChanged<int> onTaxPercentChanged;

  /// Jumlah data saat ini + pintu ke layar kelola (CRUD).
  final int menuCount;
  final int tableCount;
  final int ingredientCount;
  final VoidCallback onManageMenus;
  final VoidCallback onManageTables;
  final VoidCallback onManageIngredients;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'Pengaturan',
          subtitle: 'Profil usaha, biaya transaksi, dan info aplikasi.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionTitle('Usaha'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.storefront_outlined,
                label: 'Nama Usaha',
                value: businessName,
                onTap: () => _editText(
                  context,
                  title: 'Nama Usaha',
                  initial: businessName,
                  onSave: onBusinessNameChanged,
                ),
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Icons.location_on_outlined,
                label: 'Alamat',
                value: businessAddress,
                onTap: () => _editText(
                  context,
                  title: 'Alamat Usaha',
                  initial: businessAddress,
                  onSave: onBusinessAddressChanged,
                ),
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Icons.call_outlined,
                label: 'Telepon / WhatsApp',
                value: businessPhone,
                onTap: () => _editText(
                  context,
                  title: 'Telepon / WhatsApp',
                  initial: businessPhone,
                  keyboard: TextInputType.phone,
                  onSave: onBusinessPhoneChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Biaya Transaksi'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.room_service_outlined,
                label: 'Biaya Layanan',
                value: '$servicePercent%',
                onTap: () => _editPercent(
                  context,
                  title: 'Biaya Layanan',
                  initial: servicePercent,
                  onSave: onServicePercentChanged,
                ),
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Icons.receipt_long_outlined,
                label: 'Pajak',
                value: '$taxPercent%',
                onTap: () => _editPercent(
                  context,
                  title: 'Pajak',
                  initial: taxPercent,
                  onSave: onTaxPercentChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Perubahan biaya langsung berlaku di kasir.',
          style: AppText.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Kelola Data'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.restaurant_menu_outlined,
                label: 'Kelola Menu',
                value: '$menuCount menu',
                onTap: onManageMenus,
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Icons.table_restaurant_outlined,
                label: 'Kelola Meja',
                value: '$tableCount meja',
                onTap: onManageTables,
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Icons.inventory_2_outlined,
                label: 'Kelola Stok Bahan',
                value: '$ingredientCount bahan',
                onTap: onManageIngredients,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tambah, ubah, dan hapus data. Semua tersimpan permanen di perangkat ini.',
          style: AppText.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Tentang'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SettingRow(
            icon: Icons.info_outlined,
            label: 'Info Aplikasi',
            value: 'Versi $appVersion',
            onTap: () => showAppInfoDialog(context),
          ),
        ),
      ],
    );
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initial,
    required ValueChanged<String> onSave,
    TextInputType keyboard = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initial);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: title),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Simpan')),
        ],
      ),
    );
    if (saved == true) {
      final value = controller.text.trim();
      if (value.isNotEmpty) onSave(value);
    }
    disposeControllersLater([controller]);
  }

  Future<void> _editPercent(
    BuildContext context, {
    required String title,
    required int initial,
    required ValueChanged<int> onSave,
  }) async {
    final controller = TextEditingController(text: '$initial');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: '%', hintText: '0'),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Simpan')),
        ],
      ),
    );
    if (saved == true) {
      final value = int.tryParse(controller.text.trim());
      if (value != null) onSave(value.clamp(0, 100));
    }
    disposeControllersLater([controller]);
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(icon, size: 20, color: AppColors.accentDark),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.sm),
            // fit tight: kotak teks nilai melebar sampai tepi kanan,
            // jadi teksnya benar-benar rata kanan (tanpa ini teks nilai
            // menggantung di tengah pada layar lebar).
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppText.small.copyWith(color: AppColors.muted),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Popup Info Aplikasi: nama aplikasi + pembuatnya.
void showAppInfoDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Icon(Icons.local_cafe, color: AppColors.card, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(appName, style: AppText.pageTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'by $appStudio',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.accentDark),
            ),
            const SizedBox(height: AppSpacing.md),
            StatusChip(label: 'Versi $appVersion', color: AppColors.accentDark),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aplikasi kasir untuk resto, cafe, dan kedai kopi.\nKelola pesanan, meja, dapur, stok, dan laporan dalam satu tempat.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: 'Tutup', onPressed: () => Navigator.of(ctx).pop()),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('© 2026 $appStudio', style: AppText.caption.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    ),
  );
}
