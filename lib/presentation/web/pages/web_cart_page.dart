import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_product_by_id_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/shipping_config_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/get_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_rail.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scroll_view.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _PaymentMethod { creditCard, debitCard }

/// Desktop-web cart & checkout: line items on the left, order summary and
/// (mocked) payment on the right. Mirrors the mobile cart's purchase flow.
class WebCartPage extends StatefulWidget {
  const WebCartPage({super.key, this.userIdOverride});

  final String? userIdOverride;

  @override
  State<WebCartPage> createState() => _WebCartPageState();
}

class _WebCartPageState extends State<WebCartPage> {
  bool _isConfirmingPurchase = false;
  _PaymentMethod _selectedPaymentMethod = _PaymentMethod.debitCard;
  int _creditInstallments = 1;
  late final UserCubit _userCubit;

  final _cardholderNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userCubit = sl<UserCubit>();
    if (_userCubit.state is! UserLoaded) {
      _userCubit.getUser();
    }
  }

  @override
  void dispose() {
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
  }

  bool _hasValidPaymentData() {
    final s = S.of(context);
    final cardholderName = _cardholderNameController.text.trim();
    final cardDigits =
        _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final expiry = _cardExpiryController.text.trim();
    final cvvDigits = _cardCvvController.text.replaceAll(RegExp(r'\D'), '');

    if (cardholderName.isEmpty) {
      _snack(s.enterCardholderName, context.brand.danger);
      return false;
    }
    if (cardDigits.length < 13 || cardDigits.length > 19) {
      _snack(s.enterValidCardNumber, context.brand.danger);
      return false;
    }
    final expiryPattern = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$');
    final expiryMatch = expiryPattern.firstMatch(expiry);
    if (expiryMatch == null) {
      _snack(s.enterExpiryAsMmYy, context.brand.danger);
      return false;
    }
    final expiryMonth = int.parse(expiryMatch.group(1)!);
    final expiryYear = 2000 + int.parse(expiryMatch.group(2)!);
    final now = DateTime.now();
    final isExpired = expiryYear < now.year ||
        (expiryYear == now.year && expiryMonth < now.month);
    if (isExpired) {
      _snack(s.cardExpired, context.brand.danger);
      return false;
    }
    if (cvvDigits.length < 3 || cvvDigits.length > 4) {
      _snack(s.enterValidCvv, context.brand.danger);
      return false;
    }
    return true;
  }

  Future<void> _openProductDetails(SalesEntity draft) async {
    final firstItem =
        draft.productsList.isNotEmpty ? draft.productsList.first : null;
    if (firstItem == null) return;

    final productId =
        ((firstItem['id'] ?? firstItem['productId']) ?? '').toString().trim();
    if (productId.isEmpty) {
      _snack(S.of(context).productDetailsUnavailable, context.brand.danger);
      return;
    }

    try {
      final result = await sl<GetProductByIdUseCase>().call(productId);
      if (!mounted) return;
      result.fold(
        (_) => _snack(
            S.of(context).productDetailsUnavailable, context.brand.danger),
        (product) => AppNavigator.push(
          context,
          ProductPage(product: product as ProductEntity),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _snack(S.of(context).unableToOpenProduct, context.brand.danger);
    }
  }

  /// Resolves freight + delivery method from the store's shipping config.
  /// Returns null when the purchase should be aborted (config unavailable,
  /// CEP unserviceable, or the user dismissed the choice dialog).
  Future<_DeliveryChoice?> _resolveDelivery({
    required String cep,
    required double subtotal,
  }) async {
    final storeResult = await sl<GetStoreUseCase>().call(null);
    if (!mounted) return null;

    ShippingConfig config = ShippingConfig.empty;
    final storeError = storeResult.fold(
      (error) => error.toString(),
      (store) {
        config = (store as StoreEntity).shipping;
        return null;
      },
    );
    if (storeError != null) {
      _snack(storeError, context.brand.danger);
      return null;
    }

    final fee = config.feeFor(cep, subtotal: subtotal);
    if (fee == null && !config.pickupEnabled) {
      _snack(S.of(context).deliveryUnavailableForCep, context.brand.danger);
      return null;
    }
    if (!config.pickupEnabled) {
      return _DeliveryChoice(freight: fee!, method: 'delivery');
    }

    final s = S.of(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(s.deliveryOption),
        children: [
          if (fee != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop('delivery'),
              child:
                  Text('${s.deliveryOption} — \$${fee.toStringAsFixed(2)}'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('pickup'),
            child: Text('${s.pickupOption} — \$0.00'),
          ),
        ],
      ),
    );
    if (choice == null) return null;
    return choice == 'pickup'
        ? const _DeliveryChoice(freight: 0, method: 'pickup')
        : _DeliveryChoice(freight: fee!, method: 'delivery');
  }

  Future<void> _confirmPurchase() async {
    final userId =
        widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      _snack(S.of(context).signInToConfirmPurchase, context.brand.danger);
      return;
    }

    final drafts = CartDraftStore.instance.drafts;
    if (drafts.isEmpty) return;
    if (!_hasValidPaymentData()) return;

    setState(() => _isConfirmingPurchase = true);

    if (_userCubit.state is! UserLoaded) {
      await _userCubit.getUser();
    }
    if (!mounted) return;

    final userState = _userCubit.state;
    if (userState is! UserLoaded) {
      final message = userState is UserError
          ? userState.error
          : S.of(context).unableToLoadProfile;
      _snack(message, context.brand.danger);
      setState(() => _isConfirmingPurchase = false);
      return;
    }

    final userAddress = userState.user.addressData;
    if (userAddress == null || !userAddress.isComplete) {
      _snack(S.of(context).pleaseCompleteAddress, context.brand.danger);
      setState(() => _isConfirmingPurchase = false);
      return;
    }

    final mergedProducts = <Map<String, dynamic>>[];
    for (final draft in drafts) {
      mergedProducts.addAll(draft.productsList);
    }

    final totalDiscountedPrice = drafts.fold<double>(
        0, (runningTotal, draft) => runningTotal + draft.discountedPrice);
    final totalPriceWithoutDiscount = drafts.fold<double>(
        0, (runningTotal, draft) => runningTotal + draft.price);
    final totalDiscount = drafts.fold<double>(
        0,
        (runningTotal, draft) =>
            runningTotal + (draft.price - draft.discountedPrice));

    final delivery = await _resolveDelivery(
      cep: userAddress.cep,
      subtotal: totalPriceWithoutDiscount - totalDiscount,
    );
    if (delivery == null) {
      if (mounted) setState(() => _isConfirmingPurchase = false);
      return;
    }
    final freight = delivery.freight;

    final firstItem =
        mergedProducts.isNotEmpty ? mergedProducts.first : <String, dynamic>{};
    final productId = (firstItem['id'] ?? '').toString();
    final installments = _selectedPaymentMethod == _PaymentMethod.creditCard
        ? _creditInstallments
        : 1;
    final paymentMethod = _selectedPaymentMethod == _PaymentMethod.creditCard
        ? 'Credit card'
        : 'Debit card';

    final finalSale = SalesEntity(
      createdDate: Timestamp.now(),
      discountedPrice: totalDiscountedPrice,
      freight: freight,
      id: productId,
      installmentsNumber: installments,
      paymentMethod: paymentMethod,
      price: totalPriceWithoutDiscount,
      productsList: mergedProducts,
      totalPrice: totalPriceWithoutDiscount + freight - totalDiscount,
      userBirthDate: Timestamp.fromDate(userState.user.birthDate),
      userGender: userState.user.gender.trim(),
      userId: userId,
      userName: userState.user.name.trim(),
      deliveryMethod: delivery.method,
      address: delivery.method == 'pickup'
          ? null
          : AddressModel.fromEntity(userAddress).toMap(),
    );

    final result = await sl<RegisterSaleUseCase>().call(finalSale);
    if (!mounted) return;
    setState(() => _isConfirmingPurchase = false);

    result.fold(
      (error) => _snack(error.toString(), context.brand.danger),
      (_) {
        CartDraftStore.instance.clear();
        _snack(S.of(context).purchaseConfirmed, context.brand.success);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyPurchasesPage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final userId =
        widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;

    return WebScaffold(
      section: WebSection.cart,
      body: AnimatedBuilder(
        animation: CartDraftStore.instance,
        builder: (context, _) {
          final drafts = CartDraftStore.instance.drafts;

          return WebScrollView(
            children: [
                const SizedBox(height: WebScaffold.headerHeight + 28),
                WebMaxWidth(
                  child: userId == null || userId.isEmpty
                      ? _EmptyState(
                          icon: Icons.lock_outline,
                          title: s.pleaseSignIn,
                          body: s.signInToViewCart,
                        )
                      : drafts.isEmpty
                          ? Column(
                              children: [
                                _EmptyState(
                                  icon: Icons.shopping_bag_outlined,
                                  title: s.cartEmptyTitle,
                                  body: s.cartEmptyBody,
                                  action: FilledButton.icon(
                                    onPressed: () => Navigator.of(context)
                                        .popUntil((route) => route.isFirst),
                                    icon: const Icon(
                                        Icons.storefront_outlined, size: 19),
                                    label: Text(s.continueShopping),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: brand.primary,
                                      foregroundColor: brand.onPrimary,
                                      minimumSize: const Size(0, 48),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48),
                                _EmptyCartSuggestions(userId: userId),
                              ],
                            )
                          : _cartContent(brand, drafts),
                ),
                const SizedBox(height: 64),
            ],
          );
        },
      ),
    );
  }

  Widget _cartContent(BrandTokens brand, List<SalesEntity> drafts) {
    final s = S.of(context);
    final totalOriginal = CartDraftStore.instance.totalOriginalPrice;
    final totalDiscounted = CartDraftStore.instance.totalDiscountedPrice;
    final totalSavings = totalOriginal - totalDiscounted;

    final items = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebSectionTitle(
          title: s.myCart,
          subtitle: s.itemsReadyForCheckout(drafts.length),
        ),
        const SizedBox(height: 20),
        const _CartHeaderRow(),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: brand.surfaceBright,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brand.iconStrong.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < drafts.length; i++) ...[
                if (i > 0)
                  Divider(
                    color: brand.iconStrong.withOpacity(0.07),
                    height: 1,
                  ),
                _CartItemRow(
                  draft: drafts[i],
                  onOpen: () => _openProductDetails(drafts[i]),
                  onRemove: () => CartDraftStore.instance.removeAt(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final sidebar = Column(
      children: [
        _SummaryCard(
          totalOriginal: totalOriginal,
          totalDiscounted: totalDiscounted,
          totalSavings: totalSavings,
        ),
        const SizedBox(height: 18),
        _PaymentCard(
          selectedPaymentMethod: _selectedPaymentMethod,
          onPaymentMethodChanged: (value) => setState(() {
            _selectedPaymentMethod = value;
            if (value == _PaymentMethod.debitCard) {
              _creditInstallments = 1;
            }
          }),
          creditInstallments: _creditInstallments,
          onCreditInstallmentsChanged: (value) =>
              setState(() => _creditInstallments = value),
          cardholderNameController: _cardholderNameController,
          cardNumberController: _cardNumberController,
          cardExpiryController: _cardExpiryController,
          cardCvvController: _cardCvvController,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isConfirmingPurchase ? null : _confirmPurchase,
            icon: _isConfirmingPurchase
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(_isConfirmingPurchase
                ? s.confirmingPurchase
                : s.confirmPurchase),
            style: FilledButton.styleFrom(
              backgroundColor: brand.primary,
              foregroundColor: brand.onPrimary,
              minimumSize: const Size(0, 52),
              textStyle: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [items, const SizedBox(height: 28), sidebar],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: items),
            const SizedBox(width: 32),
            Expanded(flex: 4, child: sidebar),
          ],
        );
      },
    );
  }
}

// Shared column metrics so the header row and item rows stay aligned.
const double _kCartColUnitPrice = 92;
const double _kCartColQuantity = 76;
const double _kCartColTotal = 104;
const double _kCartColAction = 44;
const double _kCartRowHPadding = 18;

class _CartHeaderRow extends StatelessWidget {
  const _CartHeaderRow();

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: brand.muted,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCartRowHPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(s.productLabel.toUpperCase(), style: labelStyle),
          ),
          SizedBox(
            width: _kCartColUnitPrice,
            child: Text(
              s.unitPrice.toUpperCase(),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          SizedBox(
            width: _kCartColQuantity,
            child: Text(
              s.quantity.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          SizedBox(
            width: _kCartColTotal,
            child: Text(
              s.total.toUpperCase(),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: _kCartColAction),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.draft,
    required this.onOpen,
    required this.onRemove,
  });

  final SalesEntity draft;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final productData = draft.productsList.isNotEmpty
        ? draft.productsList.first
        : <String, dynamic>{};

    final title = (productData['title'] ?? '').toString();
    final code = (productData['productId'] ?? '').toString();
    final size = (productData['size'] ?? 'N/A').toString();
    final color = (productData['color'] ?? 'N/A').toString();
    final quantityValue = _toDouble(productData['quantity']);
    final quantity = quantityValue % 1 == 0
        ? quantityValue.toInt().toString()
        : quantityValue.toStringAsFixed(2);
    final unitDiscounted = _toDouble(productData['unitDiscounted']);
    final resolvedTitle = title.isEmpty
        ? s.productFallback(code.isEmpty ? '-' : code)
        : title;
    final metaParts = <String>[
      if (size.trim().isNotEmpty && size != 'N/A') '${s.size} $size',
      if (color.trim().isNotEmpty && color != 'N/A') color,
    ];
    final meta = metaParts.isEmpty
        ? s.codeLabel(code.isEmpty ? '-' : code)
        : metaParts.join(' · ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onOpen,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: _kCartRowHPadding, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: brand.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    color: brand.iconStrong, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: brand.muted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: _kCartColUnitPrice,
                child: Text(
                  '\$${unitDiscounted.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: brand.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: _kCartColQuantity,
                child: Text(
                  quantity,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: _kCartColTotal,
                child: Text(
                  '\$${draft.totalPrice.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: brand.iconStrong,
                  ),
                ),
              ),
              SizedBox(
                width: _kCartColAction,
                child: Center(
                  child: IconButton(
                    tooltip: s.remove,
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                    icon: Icon(Icons.delete_outline,
                        size: 21, color: brand.muted),
                    hoverColor: brand.danger.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalOriginal,
    required this.totalDiscounted,
    required this.totalSavings,
  });

  final double totalOriginal;
  final double totalDiscounted;
  final double totalSavings;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: brand.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.iconStrong.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.orderSummary,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _line(brand, s.subtotal, totalOriginal),
          const SizedBox(height: 8),
          _line(brand, s.savings, -totalSavings, accent: brand.successStrong),
          const SizedBox(height: 8),
          Text(
            s.freightNote,
            style: TextStyle(fontSize: 12, color: brand.muted),
          ),
          const SizedBox(height: 14),
          Divider(color: brand.iconStrong.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.total,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '\$${totalDiscounted.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: brand.iconStrong,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BrandTokens brand, String label, double value,
      {Color? accent}) {
    final sign = value < 0 ? '-' : '';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: brand.muted),
          ),
        ),
        Text(
          '$sign\$${value.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: accent ?? brand.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.creditInstallments,
    required this.onCreditInstallmentsChanged,
    required this.cardholderNameController,
    required this.cardNumberController,
    required this.cardExpiryController,
    required this.cardCvvController,
  });

  final _PaymentMethod selectedPaymentMethod;
  final ValueChanged<_PaymentMethod> onPaymentMethodChanged;
  final int creditInstallments;
  final ValueChanged<int> onCreditInstallmentsChanged;
  final TextEditingController cardholderNameController;
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvvController;

  InputDecoration _decoration(
      BuildContext context, String label, IconData icon) {
    final brand = context.brand;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13.5, color: brand.muted),
      floatingLabelStyle: TextStyle(color: brand.iconStrong),
      prefixIcon: Icon(icon, size: 18, color: brand.muted),
      filled: true,
      fillColor: brand.background.withOpacity(0.6),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: brand.iconStrong.withOpacity(0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: brand.iconStrong.withOpacity(0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: brand.iconStrong, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: brand.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.iconStrong.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.payment,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_PaymentMethod>(
            segments: [
              ButtonSegment<_PaymentMethod>(
                value: _PaymentMethod.creditCard,
                icon: const Icon(Icons.credit_card, size: 17),
                label: Text(s.credit),
              ),
              ButtonSegment<_PaymentMethod>(
                value: _PaymentMethod.debitCard,
                icon: const Icon(Icons.payments_outlined, size: 17),
                label: Text(s.debit),
              ),
            ],
            selected: <_PaymentMethod>{selectedPaymentMethod},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onPaymentMethodChanged(selection.first);
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return brand.iconStrong;
                }
                return brand.surfaceBright;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return brand.textInverse;
                }
                return brand.textPrimary;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: brand.iconStrong.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (selectedPaymentMethod == _PaymentMethod.creditCard) ...[
            DropdownButtonFormField<int>(
              value: creditInstallments,
              decoration: _decoration(
                  context, s.installments, Icons.calendar_view_week_outlined),
              items: List.generate(
                12,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('${index + 1}x'),
                ),
              ),
              onChanged: (value) {
                if (value != null) onCreditInstallmentsChanged(value);
              },
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: cardholderNameController,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
                context, s.cardholderName, Icons.badge_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: cardNumberController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration:
                _decoration(context, s.cardNumber, Icons.credit_card),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cardExpiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    _ExpiryDateInputFormatter(),
                  ],
                  decoration: _decoration(
                      context, s.expiryMmYy, Icons.date_range_outlined),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: cardCvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _decoration(context, s.cvv, Icons.lock_outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, size: 15, color: brand.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.demoCheckoutNote,
                  style: TextStyle(fontSize: 12, color: brand.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: brand.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: brand.iconStrong),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontSize: 14.5, color: brand.muted),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Below the empty cart: the shopper's own favorites plus a "New In" rail —
/// mirrors the Favorites page's Novidades section. Owns its own cubits scoped
/// to this subtree so they close automatically once the cart is filled.
class _EmptyCartSuggestions extends StatelessWidget {
  const _EmptyCartSuggestions({required this.userId});

  final String userId;

  Future<void> _toggle(
    BuildContext context,
    ProductEntity product,
    Set<String> favoriteProductIds,
  ) async {
    final cubit = context.read<FavoritesCubit>();
    if (favoriteProductIds.contains(product.id)) {
      await cubit.deleteFavorite(userId, product.id);
    } else {
      await cubit.registerFavorite(FavoriteEntity(
        createdDate: Timestamp.now(),
        id: '',
        productId: product.id,
        userId: userId,
      ));
    }
    if (!context.mounted) return;
    await cubit.loadFavoritesByUserId(userId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<FavoritesCubit>()..loadFavoritesByUserId(userId),
        ),
        BlocProvider(
          create: (_) => sl<ProductsDisplayCubit>()..displayProducts(),
        ),
        BlocProvider(
          create: (_) => sl<NewInDisplayCubit>()..displayProducts(),
        ),
      ],
      child: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, favoritesState) {
          final favoriteProductIds = favoritesState is FavoritesLoaded
              ? favoritesState.favorites.map((f) => f.productId).toSet()
              : <String>{};

          return BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
            builder: (context, topState) {
              return BlocBuilder<NewInDisplayCubit, ProductsDisplayState>(
                builder: (context, newState) {
                  final s = S.of(context);

                  final catalogById = <String, ProductEntity>{};
                  if (topState is ProductsDisplayLoaded) {
                    for (final product in topState.products) {
                      catalogById[product.id] = product;
                    }
                  }
                  final newIn = newState is ProductsDisplayLoaded
                      ? newState.products
                      : const <ProductEntity>[];
                  for (final product in newIn) {
                    catalogById[product.id] = product;
                  }

                  final favoriteProducts = favoriteProductIds
                      .map((id) => catalogById[id])
                      .whereType<ProductEntity>()
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (favoriteProducts.isNotEmpty) ...[
                        WebSectionTitle(
                          title: s.myFavorites,
                          subtitle: s.savedProducts(favoriteProducts.length),
                        ),
                        const SizedBox(height: 20),
                        WebProductGrid(
                          products: favoriteProducts,
                          favoriteProductIds: favoriteProductIds,
                          onTap: (product) => AppNavigator.push(
                            context,
                            ProductPage(
                              product: product,
                              topSellingProducts: favoriteProducts,
                            ),
                          ),
                          onFavoritePressed: (product) =>
                              _toggle(context, product, favoriteProductIds),
                        ),
                        const SizedBox(height: 48),
                      ],
                      if (newIn.isNotEmpty)
                        WebProductRail(
                          title: s.newIn,
                          subtitle: s.youMightAlsoLike,
                          products: newIn,
                          favoriteProductIds: favoriteProductIds,
                          onTap: (product) => AppNavigator.push(
                            context,
                            ProductPage(
                              product: product,
                              topSellingProducts: newIn,
                            ),
                          ),
                          onFavoritePressed: (product) =>
                              _toggle(context, product, favoriteProductIds),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed =
        digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;

    var formatted = trimmed;
    if (trimmed.length > 2) {
      formatted = '${trimmed.substring(0, 2)}/${trimmed.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _DeliveryChoice {
  const _DeliveryChoice({required this.freight, required this.method});

  final double freight;
  final String method;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
