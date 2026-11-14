import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kelola_menu_screen.dart';

/// Layar Produk (menu jualan) — menu utama di navbar atas permintaan
/// Adnan (meniru Bisakasir yang punya tombol Produk sendiri).
/// Isinya daftar kelola menu yang sama dengan Pengaturan > Kelola
/// Menu: tambah, ubah, hapus — langsung tersimpan & tampil di kasir.
class ProdukScreen extends StatelessWidget {
  const ProdukScreen({super.key, required this.menus, required this.onAdd, required this.onChanged, required this.onDelete});

  final List<MenuItem> menus;
  final ValueChanged<MenuItem> onAdd;
  final VoidCallback onChanged;
  final ValueChanged<MenuItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: PageHeader(
            title: 'Produk',
            subtitle: '${menus.length} menu jualan. Tambah, ubah, hapus — langsung tampil di kasir.',
          ),
        ),
        Expanded(
          child: KelolaMenuScreen(
            menus: menus,
            onAdd: onAdd,
            onChanged: onChanged,
            onDelete: onDelete,
            embedded: true,
          ),
        ),
      ],
    );
  }
}
