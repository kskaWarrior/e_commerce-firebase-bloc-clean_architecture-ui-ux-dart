import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/sales/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/sales/get_sales_by_user_id_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyPurchasesPage extends StatelessWidget {
  const MyPurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return BlocProvider(
      create: (_) {
        final cubit = sl<GetSalesByUserIdCubit>();
        if (userId != null && userId.isNotEmpty) {
          cubit.getSalesByUserId(userId);
        }
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My purchases',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'CircularStd',
                  fontWeight: FontWeight.w700,
                ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                ],
              ),
            ),
            child: userId == null || userId.isEmpty
                ? const _CenteredInfoCard(
                    title: 'Please sign in',
                    body: 'Sign in to view your purchases.',
                    icon: Icons.lock_outline,
                  )
                : const _PurchasesView(),
          ),
        ),
      ),
    );
  }
}

class _PurchasesView extends StatelessWidget {
  const _PurchasesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetSalesByUserIdCubit, GetSalesByUserIdState>(
      builder: (context, state) {
        if (state is GetSalesByUserIdLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GetSalesByUserIdError) {
          return _CenteredInfoCard(
            title: 'Could not load purchases',
            body: state.message,
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        }

        if (state is! GetSalesByUserIdLoaded) {
          return const SizedBox.shrink();
        }

        final sales = List<SalesEntity>.from(state.sales)
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

        if (sales.isEmpty) {
          return const _CenteredInfoCard(
            title: 'No purchases yet',
            body: 'Confirmed purchases will appear here.',
            icon: Icons.shopping_bag_outlined,
          );
        }

        final totalSpent = sales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalPrice,
        );
        final totalSavings = sales.fold<double>(
          0,
          (sum, sale) => sum + (sale.price - sale.discountedPrice),
        );
        final averageTicket = totalSpent / sales.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagPill(label: 'Orders: ${sales.length}'),
                  _TagPill(label: 'Saved: ${_formatCurrency(totalSavings)}'),
                  _TagPill(
                      label: 'Avg ticket: ${_formatCurrency(averageTicket)}'),
                ],
              ),
              const SizedBox(height: 14),
              _StatsCard(
                totalSpent: totalSpent,
                totalSavings: totalSavings,
                averageTicket: averageTicket,
              ),
              const SizedBox(height: 18),
              const _SectionSeparator(),
              const SizedBox(height: 8),
              Text(
                'Recent purchases',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'CircularStd',
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
              ),
              const SizedBox(height: 10),
              ...sales.map((sale) => _PurchaseCard(sale: sale)),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseCard extends StatefulWidget {
  final SalesEntity sale;

  const _PurchaseCard({required this.sale});

  @override
  State<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<_PurchaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final savings =
        sale.price > sale.discountedPrice ? sale.price - sale.discountedPrice : 0.0;
    final installmentValue = sale.installmentsNumber > 0
        ? sale.totalPrice / sale.installmentsNumber
        : sale.totalPrice;
    final products = sale.productsList;

    return _InfoCard(
      title: 'Order #${sale.id.isEmpty ? 'N/A' : sale.id}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LineItem(
            label: 'Created',
            value: _formatDate(sale.createdDate.toDate()),
          ),
          const SizedBox(height: 6),
          _LineItem(label: 'Payment', value: sale.paymentMethod),
          const SizedBox(height: 6),
          _LineItem(
            label: 'Products',
            value: '${products.length} item(s)',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'CircularStd',
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                _formatCurrency(sale.totalPrice),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'CircularStd',
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'CircularStd',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
              ),
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 28,
              ),
              label: Text(_expanded ? 'Show less' : 'Show more'),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 2),
            _LineItem(
              label: 'Subtotal',
              value: _formatCurrency(sale.price),
            ),
            const SizedBox(height: 6),
            _LineItem(
              label: 'Subtotal after discount',
              value: _formatCurrency(sale.discountedPrice),
            ),
            const SizedBox(height: 6),
            _LineItem(
              label: 'Freight',
              value: _formatCurrency(sale.freight),
            ),
            const SizedBox(height: 6),
            _LineItem(
              label: 'Savings',
              value: _formatCurrency(savings),
            ),
            const SizedBox(height: 6),
            _LineItem(
              label: 'Installments',
              value: sale.installmentsNumber.toString(),
            ),
            const SizedBox(height: 6),
            _LineItem(
              label: 'Installment value',
              value: _formatCurrency(installmentValue),
            ),
            const SizedBox(height: 10),
            Text(
              'Products details:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFamily: 'CircularStd',
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (products.isEmpty)
              Text(
                'No product details available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'CircularStd',
                    ),
              )
            else
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _LineItem(
                    label:
                        '${_productName(product)} x${_productQuantity(product)}',
                    value: _productPriceLabel(product),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final double totalSpent;
  final double totalSavings;
  final double averageTicket;

  const _StatsCard({
    required this.totalSpent,
    required this.totalSavings,
    required this.averageTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'CircularStd',
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          _LineItem(label: 'Total spent', value: _formatCurrency(totalSpent)),
          const SizedBox(height: 6),
          _LineItem(label: 'Total saved', value: _formatCurrency(totalSavings)),
          const SizedBox(height: 6),
          _LineItem(
            label: 'Average ticket',
            value: _formatCurrency(averageTicket),
          ),
        ],
      ),
    );
  }
}

class _CenteredInfoCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color? iconColor;

  const _CenteredInfoCard({
    required this.title,
    required this.body,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _InfoCard(
          title: title,
          child: Column(
            children: [
              Icon(icon,
                  size: 48,
                  color: iconColor ?? Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'CircularStd',
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final String value;

  const _LineItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'CircularStd',
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'CircularStd',
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'CircularStd',
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'CircularStd',
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionSeparator extends StatelessWidget {
  const _SectionSeparator();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 2, right: 2),
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              baseColor.withValues(alpha: 0.0),
              baseColor.withValues(alpha: 0.22),
              baseColor.withValues(alpha: 0.9),
              baseColor.withValues(alpha: 0.22),
              baseColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

String _formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year  $hour:$minute';
}

String _productName(Map<String, dynamic> product) {
  final value = product['title'] ??
      product['name'] ??
      product['productName'] ??
      product['productId'] ??
      product['id'];
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? 'Product' : text;
}

int _productQuantity(Map<String, dynamic> product) {
  final raw = product['quantity'] ?? product['qty'];
  if (raw is int && raw > 0) {
    return raw;
  }
  if (raw is num && raw > 0) {
    return raw.toInt();
  }
  return 1;
}

String _productPriceLabel(Map<String, dynamic> product) {
  final discounted = product['discountedPrice'];
  final regular = product['price'];

  if (discounted is num) {
    return _formatCurrency(discounted.toDouble());
  }
  if (regular is num) {
    return _formatCurrency(regular.toDouble());
  }
  return '-';
}
