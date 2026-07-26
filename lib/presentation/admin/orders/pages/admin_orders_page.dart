import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/update_sale_status.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/orders/bloc/admin_orders_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _statuses = ['pending', 'paid', 'shipped', 'delivered', 'cancelled'];

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminOrdersCubit(
        getSalesByStoreUseCase: sl<GetSalesByStoreUseCase>(),
        updateSaleStatusUseCase: sl<UpdateSaleStatusUseCase>(),
      )..load(),
      child: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
        builder: (context, state) {
          final s = S.of(context);
          return AdminPageScaffold(
            title: s.orders,
            subtitle: switch (state) {
              AdminOrdersLoaded(:final orders) =>
                s.adminOrdersSubtitle(orders.length),
              _ => s.adminOrdersTagline,
            },
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.read<AdminOrdersCubit>().load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(s.refresh),
              ),
            ],
            scrollable: true,
            child: switch (state) {
              AdminOrdersLoading() => const _CenteredState(
                  child: CircularProgressIndicator()),
              AdminOrdersError(:final message) =>
                _CenteredState(child: Text(message)),
              AdminOrdersLoaded(:final orders) => orders.isEmpty
                  ? _CenteredState(
                      child: _EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: s.adminOrdersEmpty,
                        body: s.adminOrdersEmptyBody,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(s.colOrder)),
                          DataColumn(label: Text(s.colDate)),
                          DataColumn(label: Text(s.colCustomer)),
                          DataColumn(label: Text(s.colItems)),
                          DataColumn(label: Text(s.total.toUpperCase())),
                          DataColumn(label: Text(s.colStatus)),
                        ],
                        rows: [
                          for (final order in orders)
                            DataRow(cells: [
                              DataCell(Text(
                                '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              )),
                              DataCell(Text(
                                _formatDate(order.createdDate.toDate()),
                                style: const TextStyle(
                                    color: AdminColors.textSecondary),
                              )),
                              DataCell(Text(order.userName)),
                              DataCell(
                                  Text('${order.productsList.length}')),
                              DataCell(Text(
                                '\$${order.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              )),
                              DataCell(
                                Row(
                                  children: [
                                    AdminStatusChip(status: order.status),
                                    const SizedBox(width: 10),
                                    _StatusMenu(
                                      current: order.status,
                                      onChanged: (status) async {
                                        final error = await context
                                            .read<AdminOrdersCubit>()
                                            .updateStatus(order.id, status);
                                        if (error != null &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(error)));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                        ],
                      ),
                    ),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  static String _titleCase(String label) =>
      label.isEmpty ? label : label[0] + label.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: S.of(context).changeStatus,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminColors.border),
      ),
      color: AdminColors.surface,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final status in _statuses)
          PopupMenuItem(
            value: status,
            height: 42,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AdminColors.statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _titleCase(S.of(context).statusLabel(status)),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: status == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (status == current) ...[
                  const Spacer(),
                  const Icon(Icons.check,
                      size: 16, color: AdminColors.accent),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: AdminColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.expand_more,
            size: 16, color: AdminColors.textSecondary),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(child: child),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AdminColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: AdminColors.accent),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
              fontSize: 14, color: AdminColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
