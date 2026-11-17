import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../ikon.dart';

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
    required this.onServicePercentChanged,
    required this.onTaxPercentChanged,
    required this.tablesEnabled,
    required this.onTablesEnabledChanged,
    required this.kitchenEnabled,
    required this.onKitchenEnabledChanged,
    required this.menuCount,
    required this.tableCount,
    required this.ingredientCount,
    required this.onManageMenus,
    required this.onManageTables,
    required this.onManageIngredients,
    required this.branches,
    required this.activeBranchId,
    required this.pinSet,
    required this.onSwitchBranch,
    required this.onOpenProfile,
    required this.onOpenPinSettings,
    required this.onOpenBranchWizard,
    required this.businessPhotoPath,
    required this.cloudSyncEnabled,
    required this.onCloudSyncChanged,
    required this.statusSinkronRingkasan,
    required this.onOpenSyncStatus,
    required this.modeTema,
    required this.onModeTemaChanged,
    this.onCekUpdate,
    this.statusSesiKasir = 'Belum dibuka',
    this.onOpenSesiKasir,
    this.statusPrinter = 'Belum diatur',
    this.onOpenStruk,
  });

  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final int servicePercent;
  final int taxPercent;
  final ValueChanged<int> onServicePercentChanged;
  final ValueChanged<int> onTaxPercentChanged;

  /// Saklar fitur meja (tidak wajib — bisa dimatikan total).
  final bool tablesEnabled;
  final ValueChanged<bool> onTablesEnabledChanged;

  /// Saklar fitur dapur (tidak wajib — bisa dimatikan total).
  final bool kitchenEnabled;
  final ValueChanged<bool> onKitchenEnabledChanged;

  /// Jumlah data saat ini + pintu ke layar kelola (CRUD).
  final int menuCount;
  final int tableCount;
  final int ingredientCount;
  final VoidCallback onManageMenus;
  final VoidCallback onManageTables;
  final VoidCallback onManageIngredients;

  /// Multi-cabang & PIN kasir (v0.7.0). Profil usaha, PIN, dan
  /// tambah cabang kini punya halaman/wizard sendiri (v0.8.0).
  final List<Branch> branches;
  final String activeBranchId;
  final bool pinSet;
  final ValueChanged<Branch> onSwitchBranch;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenPinSettings;
  final VoidCallback onOpenBranchWizard;

  /// Foto usaha (berkas lokal) untuk kartu profil; null = ikon.
  final String? businessPhotoPath;

  /// Sinkronisasi Online versi ringkas (permintaan Adnan
  /// 2026-11-15): di Pengaturan hanya DUA baris — saklar Cloud
  /// Sync + pintu Status Sinkronisasi. Rincian (menunggu, gagal,
  /// tombol sinkron, pengaturan Supabase) pindah ke halaman
  /// Status Sinkronisasi sendiri.
  final bool cloudSyncEnabled;
  final ValueChanged<bool> onCloudSyncChanged;
  final String statusSinkronRingkasan;
  final VoidCallback onOpenSyncStatus;

  /// Pilihan tema tampilan: 'terang' | 'gelap' | 'sistem'.
  final String modeTema;
  final ValueChanged<String> onModeTemaChanged;

  /// Cek pembaruan aplikasi ke server (baris "Pembaruan
  /// Aplikasi" di bagian Tentang). Null = baris tidak tampil.
  final VoidCallback? onCekUpdate;

  /// Sesi Kasir & Struk (v0.15.0): teks status singkat untuk
  /// baris di bagian Kasir + pintunya. Opsional supaya
  /// konstruksi lama (tes) tetap sah.
  final String statusSesiKasir;
  final VoidCallback? onOpenSesiKasir;
  final String statusPrinter;
  final VoidCallback? onOpenStruk;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onOpenProfile,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _FotoProfilMini(path: businessPhotoPath),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(businessName, style: AppText.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if ([businessAddress, businessPhone].any((s) => s.isNotEmpty)) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            [businessAddress, businessPhone].where((s) => s.isNotEmpty).join(' · '),
                            style: AppText.caption.copyWith(color: AppColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Ikon.chevron_right, color: AppColors.muted, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Cabang'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
            children: [
              for (final b in branches)
                ListTile(
                  leading: const Icon(Ikon.storefront_outlined, color: AppColors.accentDark),
                  title: Text(b.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(b.id == activeBranchId ? 'Cabang aktif — penjualan tercatat di sini' : 'Ketuk untuk pindah ke cabang ini', style: AppText.small.copyWith(color: AppColors.muted)),
                  trailing: b.id == activeBranchId ? const StatusChip(label: 'Aktif', color: AppColors.accent) : null,
                  onTap: b.id == activeBranchId ? null : () => onSwitchBranch(b),
                ),
              const Divider(height: 1),
              _SettingRow(
                icon: Ikon.add_business_outlined,
                label: 'Tambah Cabang',
                value: 'Wizard',
                onTap: onOpenBranchWizard,
              ),
            ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Keamanan'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SettingRow(
            icon: Ikon.pin_outlined,
            label: 'PIN Kasir',
            value: pinSet ? 'Sudah diatur' : 'Belum diatur',
            onTap: onOpenPinSettings,
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
                icon: Ikon.room_service_outlined,
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
                icon: Ikon.receipt_long_outlined,
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
        const SectionTitle('Fitur'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingSwitchRow(
                icon: Ikon.table_restaurant_outlined,
                label: 'Manajemen Meja',
                subtitle: tablesEnabled
                    ? 'Aktif — ada menu Meja dan pilihan meja di kasir.'
                    : 'Mati — menu Meja disembunyikan, kasir tanpa meja.',
                value: tablesEnabled,
                onChanged: onTablesEnabledChanged,
              ),
              const Divider(height: 1, indent: 68),
              _SettingSwitchRow(
                icon: Ikon.soup_kitchen_outlined,
                label: 'Layar Dapur',
                subtitle: kitchenEnabled
                    ? 'Aktif — pembayaran membuat tiket antrean dapur.'
                    : 'Mati — menu Dapur disembunyikan, tanpa tiket dapur.',
                value: kitchenEnabled,
                onChanged: onKitchenEnabledChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Kelola Data'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Ikon.restaurant_menu_outlined,
                label: 'Kelola Menu',
                value: '$menuCount menu',
                onTap: onManageMenus,
              ),
              // Kelola Meja ikut sembunyi saat fitur meja mati.
              if (tablesEnabled) ...[
                const Divider(height: 1, indent: 68),
                _SettingRow(
                  icon: Ikon.table_restaurant_outlined,
                  label: 'Kelola Meja',
                  value: '$tableCount meja',
                  onTap: onManageTables,
                ),
              ],
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Ikon.inventory_2_outlined,
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
        const SectionTitle('Kasir'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Ikon.lock_outlined,
                label: 'Sesi Kasir',
                value: statusSesiKasir,
                onTap: onOpenSesiKasir ?? () {},
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Ikon.print_outlined,
                label: 'Struk & Printer',
                value: statusPrinter,
                onTap: onOpenStruk ?? () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Sinkronisasi Online'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingSwitchRow(
                icon: Ikon.cloud_outlined,
                label: 'Cloud Sync',
                subtitle: cloudSyncEnabled
                    ? 'Aktif — data tersinkron ke Supabase secara otomatis.'
                    : 'Mati — aplikasi berjalan murni lokal di perangkat ini.',
                value: cloudSyncEnabled,
                onChanged: onCloudSyncChanged,
              ),
              const Divider(height: 1, indent: 68),
              _SettingRow(
                icon: Ikon.cloud_sync_outlined,
                label: 'Status Sinkronisasi',
                value: statusSinkronRingkasan,
                onTap: onOpenSyncStatus,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Tampilan'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Ikon.brightness_6_outlined, color: AppColors.accentDark, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Mode Terang / Gelap', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Listener mencatat titik ketukan terakhir: dari titik
              // chip inilah lingkaran iris animasi ganti tema membesar.
              Listener(
                onPointerDown: (e) => AnimasiIrisTema.pusatDariKetukan = e.position,
                child: FilterChipRow(
                  children: [
                    AppChip(label: 'Terang', selected: modeTema == 'terang', onSelected: (_) => onModeTemaChanged('terang')),
                    AppChip(label: 'Gelap', selected: modeTema == 'gelap', onSelected: (_) => onModeTemaChanged('gelap')),
                    AppChip(label: 'Ikuti Sistem', selected: modeTema == 'sistem', onSelected: (_) => onModeTemaChanged('sistem')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ikuti Sistem = ikut pengaturan gelap/terang HP. Ganti mode membuka seperti iris dari tombol yang diketuk.',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Tentang'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SettingRow(
            icon: Ikon.info_outlined,
            label: 'Info Aplikasi',
            value: 'Versi $appVersion',
            onTap: () => showAppInfoDialog(context),
          ),
        ),
        if (onCekUpdate != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: _SettingRow(
              icon: Ikon.system_update_alt_outlined,
              label: 'Pembaruan Aplikasi',
              value: 'Periksa',
              onTap: () => onCekUpdate!(),
            ),
          ),
        ],
      ],
    );
  }

  /// Dialog persen DENGAN teks simulasi langsung (permintaan
  /// Adnan 2026-11-14): saat angka diubah, contoh hitungan di kasir
  /// ikut berubah di tempat — pemilik langsung paham dampaknya.
  Future<void> _editPercent(
    BuildContext context, {
    required String title,
    required int initial,
    required ValueChanged<int> onSave,
  }) async {
    final controller = TextEditingController(text: '$initial');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final typed = (int.tryParse(controller.text.trim()) ?? initial).clamp(0, 100);
          final isTax = title == 'Pajak';
          final svc = isTax ? servicePercent : typed;
          final tax = isTax ? typed : taxPercent;
          const contoh = 100000;
          final svcRp = (contoh * svc / 100).round();
          final taxRp = (contoh * tax / 100).round();
          Widget barisSim(String label, String nilai, {bool tebal = false}) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: AppText.small.copyWith(fontWeight: tebal ? FontWeight.w800 : FontWeight.w400))),
                    Text(nilai, style: AppText.small.copyWith(fontWeight: tebal ? FontWeight.w800 : FontWeight.w600)),
                  ],
                ),
              );
          return GuardBack(
            dirty: () => controller.text != '$initial',
            child: AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(suffixText: '%', hintText: '0'),
                    onChanged: (_) => setDialog(() {}),
                    onSubmitted: (_) => Navigator.of(ctx).pop(true),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Simulasi di kasir', style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  barisSim('Pesanan contoh', rupiah(contoh)),
                  barisSim('Biaya layanan ($svc%)', rupiah(svcRp)),
                  barisSim('Pajak ($tax%)', rupiah(taxRp)),
                  const Divider(height: AppSpacing.md),
                  barisSim('Pembeli membayar', rupiah(contoh + svcRp + taxRp), tebal: true),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                PrimaryButton(label: 'Simpan', onPressed: () => Navigator.of(ctx).pop(true)),
              ],
            ),
          );
        },
      ),
    );
    if (saved == true) {
      final value = int.tryParse(controller.text.trim());
      if (value != null) onSave(value.clamp(0, 100));
    }
    disposeControllersLater([controller]);
  }
}

/// Baris pengaturan dengan saklar on/off (untuk fitur opsional
/// seperti Manajemen Meja).
class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppText.caption.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
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
            Icon(Ikon.chevron_right, size: 20, color: AppColors.muted),
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
              child: Icon(Ikon.local_cafe, color: AppColors.card, size: 32),
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


/// Kotak foto profil usaha 52px: foto lokal bila ada & berkasnya
/// masih ada, selain itu kotak aksen + ikon toko seperti dulu.
class _FotoProfilMini extends StatelessWidget {
  const _FotoProfilMini({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Icon(Ikon.storefront, color: AppColors.card, size: 26),
    );
    if (path == null || path!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.file(
        File(path!),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
