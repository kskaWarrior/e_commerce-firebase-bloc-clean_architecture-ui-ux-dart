import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Desktop-web order history: one card per purchase with status, items
/// and totals.
class WebPurchasesPage extends StatelessWidget {
  const WebPurchasesPage({super.key, this.userIdOverride});

  final String? userIdOverride;

  @override
  Widget build(BuildContext context) {
    final userId = userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;

    return BlocProvider(
      create: (_) {
        final cubit = sl<GetSalesByUserIdCubit>();
        if (userId != null && userId.isNotEmpty) {
          cubit.getSalesByUserId(userId);
        }
        return cubit;
      },
      child: WebScaffold(
        section: WebSection.orders,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: WebScaffold.headerHeight + 28),
              WebMaxWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<GetSalesByUserIdCubit, GetSalesByUserIdState>(
                      builder: (context, state) {
                        final brand = context.brand;
                        final s = S.of(context);

                        if (userId == null || userId.isEmpty) {
                          return _message(
                            brand,
                            icon: Icons.lock_outline,
                            title: s.pleaseSignIn,
                            body: s.signInToViewPurchases,
                          );
                        }
                        if (state is GetSalesByUserIdLoading ||
                            state is GetSalesByUserIdInitial) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child:
                                Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (state is GetSalesByUserIdError) {
                          return _message(
                            brand,
                            icon: Icons.error_outline,
                            title: s.couldNotLoadPurchases,
                            body: state.message,
                          );
                        }

                        final sales = List<SalesEntity>.from(
                            (state as GetSalesByUserIdLoaded).sales)
                          ..sort((a, b) =>
                              b.createdDate.compareTo(a.createdDate));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            WebSectionTitle(
                              title: s.myPurchases,
                              subtitle: sales.isEmpty
                                  ? s.purchasesEmptySubtitle
                                  : s.ordersCount(sales.length),
                            ),
                            const SizedBox(height: 20),
                            if (sales.isEmpty)
                              _message(
                                brand,
                                icon: Icons.shopping_bag_outlined,
                                title: s.noPurchasesYet,
                                body: s.purchasesEmptyBody,
                              )
                            else
                              for (final sale in sales)
                                _OrderCard(sale: sale),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              const WebFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(
    BrandTokens brand, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 44, color: brand.muted),
            const SizedBox(height: 14),
            Text(
              title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: brand.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.sale});

  final SalesEntity sale;

  String _formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(date.day)}/${pad(date.month)}/${date.year} '
        '${pad(date.hour)}:${pad(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final date = _formatDate(sale.createdDate.toDate());
    final savings = sale.price - sale.discountedPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: brand.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.iconStrong.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.orderPlaced(date),
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${sale.paymentMethod}'
                        '${sale.installmentsNumber > 1 ? ' · ${sale.installmentsNumber}x' : ''}',
                        style:
                            TextStyle(fontSize: 12.5, color: brand.muted),
                      ),
                    ],
                  ),
                ),
                _WebStatusChip(status: sale.status),
              ],
            ),
          ),
          Divider(color: brand.iconStrong.withOpacity(0.07), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                for (final item in sale.productsList)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 17, color: brand.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _itemLabel(item, s),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                        Text(
                          '\$${_toDouble(item['totalPrice']).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: brand.iconStrong.withOpacity(0.07), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                if (savings > 0)
                  Text(
                    s.youSaved('\$${savings.toStringAsFixed(2)}'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: brand.successStrong,
                    ),
                  ),
                const Spacer(),
                Text(
                  s.freightLabel('\$${sale.freight.toStringAsFixed(2)}'),
                  style: TextStyle(fontSize: 13, color: brand.muted),
                ),
                const SizedBox(width: 18),
                Text(
                  s.totalLabel('\$${sale.totalPrice.toStringAsFixed(2)}'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: brand.iconStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _itemLabel(Map<String, dynamic> item, AppStrings s) {
    final title = (item['title'] ?? '').toString();
    final code = (item['productId'] ?? '').toString();
    final size = (item['size'] ?? '').toString();
    final color = (item['color'] ?? '').toString();
    final quantityValue = _toDouble(item['quantity']);
    final quantity = quantityValue % 1 == 0
        ? quantityValue.toInt().toString()
        : quantityValue.toStringAsFixed(2);

    final resolvedTitle = title.isEmpty
        ? s.productFallback(code.isEmpty ? '-' : code)
        : title;
    final details = [
      if (size.trim().isNotEmpty && size != 'N/A') '${s.size} $size',
      if (color.trim().isNotEmpty && color != 'N/A') color,
      'x$quantity',
    ].join(' · ');

    return '$resolvedTitle  ($details)';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class _WebStatusChip extends StatelessWidget {
  const _WebStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final color = switch (status) {
      'paid' => brand.info,
      'shipped' => brand.shipped,
      'delivered' => brand.successStrong,
      'cancelled' => brand.dangerStrong,
      _ => brand.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            S.of(context).statusLabel(status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
