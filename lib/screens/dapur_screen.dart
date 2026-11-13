import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class DapurScreen extends StatelessWidget {
  const DapurScreen({super.key, required this.orders, required this.onAdvance});

  final List<KitchenOrder> orders;
  final ValueChanged<KitchenOrder> onAdvance;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final columns = <(KitchenStatus, List<KitchenOrder>)>[
      for (final s in KitchenStatus.values) (s, orders.where((o) => o.status == s).toList()),
    ];
    final header = const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dapur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Tekan tombol di tiap pesanan untuk memajukan statusnya.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
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
                      padding: const EdgeInsets.all(8),
                      child: _Column(status: status, orders: list, onAdvance: onAdvance),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView(
      children: [
        header,
        for (final (status, list) in columns) _Column(status: status, orders: list, onAdvance: onAdvance, shrinkWrap: true),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(status.label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              StatusChip(label: '${orders.length}', color: _color),
            ],
          ),
        ),
        if (shrinkWrap)
          if (orders.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('Tidak ada pesanan.', style: TextStyle(color: AppColors.muted)))
          else
            for (final o in orders) _OrderCard(order: o, onAdvance: onAdvance)
        else
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('Tidak ada pesanan.', style: TextStyle(color: AppColors.muted)))
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
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: 8),
              StatusChip(label: order.tableLabel, color: AppColors.accentDark),
              const Spacer(),
              Text(order.time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          if (order.orderType != 'Dine-in')
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(order.orderType, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          const Divider(),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, child: Text('${line.qty}×', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.name),
                        if (line.note.isNotEmpty) Text(line.note, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => onAdvance(order),
              style: FilledButton.styleFrom(
                backgroundColor: order.status == KitchenStatus.selesai ? AppColors.ink : AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: Text(order.status.nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}
