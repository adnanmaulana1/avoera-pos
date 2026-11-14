import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class DapurScreen extends StatefulWidget {
  const DapurScreen({super.key, required this.orders, required this.onAdvance});

  final List<KitchenOrder> orders;
  final ValueChanged<KitchenOrder> onAdvance;

  @override
  State<DapurScreen> createState() => _DapurScreenState();
}

class _DapurScreenState extends State<DapurScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final orders = widget.orders;
    final onAdvance = widget.onAdvance;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final columns = <(KitchenStatus, List<KitchenOrder>)>[
      for (final s in KitchenStatus.values) (s, orders.where((o) => o.status == s).toList()),
    ];
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Dapur',
            subtitle: 'Tekan tombol di tiap pesanan untuk memajukan statusnya.',
          ),
          if (!wide) ...[
            const SizedBox(height: AppSpacing.md),
            FilterChipRow(
              children: [
                for (final f in ['Semua', 'Baru', 'Dimasak', 'Selesai'])
                  AppChip(label: f, selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
              ],
            ),
          ],
        ],
      ),
    );
    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (status, list) in columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: _Column(status: status, orders: list, onAdvance: onAdvance),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    final tampil = _filter == 'Semua'
        ? columns
        : columns.where((c) => c.$1.label == _filter).toList();
    return ListView(
      children: [
        header,
        for (final (status, list) in tampil) _Column(status: status, orders: list, onAdvance: onAdvance, shrinkWrap: true),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.status, required this.orders, required this.onAdvance, this.shrinkWrap = false});
  final KitchenStatus status;
  final List<KitchenOrder> orders;
  final ValueChanged<KitchenOrder> onAdvance;
  final bool shrinkWrap;

  Color get _color => switch (status) {
        KitchenStatus.baru => AppColors.danger,
        KitchenStatus.dimasak => AppColors.warning,
        KitchenStatus.selesai => AppColors.accentDark,
      };

  @override
  Widget build(BuildContext context) {
    final empty = EmptyState(message: 'Tidak ada pesanan.', icon: Icons.receipt_long_outlined);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.sm),
              Text(status.label, style: AppText.body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: '${orders.length}', color: _color),
            ],
          ),
        ),
        if (shrinkWrap)
          if (orders.isEmpty)
            empty
          else
            for (final o in orders) _OrderCard(order: o, onAdvance: onAdvance)
        else
          Expanded(
            child: orders.isEmpty
                ? empty
                : ListView(children: [for (final o in orders) _OrderCard(order: o, onAdvance: onAdvance)]),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onAdvance});
  final KitchenOrder order;
  final ValueChanged<KitchenOrder> onAdvance;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.id, style: AppText.subtitle.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: order.tableLabel, color: AppColors.accentDark),
              const Spacer(),
              Text(order.time, style: AppText.small.copyWith(color: AppColors.muted)),
            ],
          ),
          if (order.orderType != 'Dine-in')
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(order.orderType, style: AppText.small.copyWith(color: AppColors.muted)),
            ),
          const Divider(),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, child: Text('${line.qty}×', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.name),
                        if (line.note.isNotEmpty) Text(line.note, style: AppText.small.copyWith(color: AppColors.muted, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: order.status.nextLabel,
              backgroundColor: order.status == KitchenStatus.selesai ? AppColors.ink : null,
              onPressed: () => onAdvance(order),
            ),
          ),
        ],
      ),
    );
  }
}
