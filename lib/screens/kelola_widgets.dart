import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

/// Label kecil tebal di atas kolom isian formulir kelola.
class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

/// Kerangka isi sheet formulir kelola: gagang, judul, isi, tombol simpan,
/// dan (bila mengubah data lama) tombol hapus di bawahnya.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.saveLabel = 'Simpan',
    this.onDelete,
    this.errorText,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final String saveLabel;
  final VoidCallback? onDelete;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    // WAJIB dibatasi tingginya: tanpa ini, formulir yang lebih
    // tinggi dari layar (mis. editor menu + foto) membuat tombol
    // bawah jatuh DI LUAR layar dan tidak bisa diketuk — isi harus
    // bergulir di dalam sheet.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.lg),
            ...children,
            if (errorText != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(errorText!, style: AppText.small.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: saveLabel, onPressed: onSave),
            ),
            if (onDelete != null)
              Center(
                child: TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Hapus'),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Konfirmasi hapus yang sama di semua layar kelola.
/// Mengembalikan true bila pengguna benar-benar memilih Hapus.
Future<bool> showConfirmDelete(BuildContext context, {required String title, required String message}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        PrimaryButton(
          label: 'Hapus',
          backgroundColor: AppColors.danger,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}
