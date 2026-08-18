import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/page/favorites_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_product_by_id_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/shipping_config_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/get_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/pages/web_cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/entities/payment_preference_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/usecases/create_payment_preference.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class CartPage extends StatefulWidget {
  final String? userIdOverride;

  const CartPage({super.key, this.userIdOverride});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isConfirmingPurchase = false;
  late final UserCubit _userCubit;

  @override
  void initState() {
    super.initState();
    _userCubit = sl<UserCubit>();
    if (_userCubit.state is! UserLoaded) {
      _userCubit.getUser();
    }
  }

  void _showPaymentError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.brand.danger,
        ),
      );
  }

  Future<void> _openProductDetails(SalesEntity draft) async {
    final firstItem =
        draft.productsList.isNotEmpty ? draft.productsList.first : null;
    if (firstItem == null) {
      return;
    }

    final productId =
        ((firstItem['id'] ?? firstItem['productId']) ?? '').toString().trim();
    if (productId.isEmpty) {
      _showPaymentError(S.of(context).productDetailsUnavailable);
      return;
    }

    try {
      final result = await sl<GetProductByIdUseCase>().call(productId);

      if (!mounted) {
        return;
      }

      result.fold(
        (_) => _showPaymentError(S.of(context).productDetailsUnavailable),
        (product) => AppNavigator.push(
          context,
          ProductPage(product: product as ProductEntity),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showPaymentError(S.of(context).unableToOpenProduct);
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
      _showPaymentError(storeError);
      return null;
    }

    final fee = config.feeFor(cep, subtotal: subtotal);
    if (fee == null && !config.pickupEnabled) {
      _showPaymentError(S.of(context).deliveryUnavailableForCep);
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
              child: Text(
                  '${s.deliveryOption} — ${_formatCurrency(fee)}'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('pickup'),
            child: Text('${s.pickupOption} — ${_formatCurrency(0)}'),
          ),
        ],
      ),
    );
    if (choice == null) return null;
    return choice == 'pickup'
        ? _DeliveryChoice(freight: 0, method: 'pickup')
        : _DeliveryChoice(freight: fee!, method: 'delivery');
  }

  Future<void> _confirmPurchase() async {
    final userId =
        widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(S.of(context).signInToConfirmPurchase),
            backgroundColor: context.brand.danger,
          ),
        );
      return;
    }

    final drafts = CartDraftStore.instance.drafts;
    if (drafts.isEmpty) {
      return;
    }

    setState(() {
      _isConfirmingPurchase = true;
    });

    if (_userCubit.state is! UserLoaded) {
      await _userCubit.getUser();
    }

    if (!mounted) {
      return;
    }

    final userState = _userCubit.state;
    if (userState is! UserLoaded) {
      final message = userState is UserError
          ? userState.error
          : S.of(context).unableToLoadProfile;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: context.brand.danger,
          ),
        );
      setState(() {
        _isConfirmingPurchase = false;
      });
      return;
    }

    final userAddress = userState.user.addressData;
    if (userAddress == null || !userAddress.isComplete) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(S.of(context).pleaseCompleteAddress),
            backgroundColor: context.brand.danger,
          ),
        );
      setState(() {
        _isConfirmingPurchase = false;
      });
      return;
    }

    final userName = userState.user.name.trim();
    final userBirthDate = Timestamp.fromDate(userState.user.birthDate);
    final userGender = userState.user.gender.trim();

    final mergedProducts = <Map<String, dynamic>>[];
    for (final draft in drafts) {
      mergedProducts.addAll(draft.productsList);
    }

    final totalDiscountedPrice = drafts.fold<double>(
      0,
      (runningTotal, draft) => runningTotal + draft.discountedPrice,
    );
    final totalPriceWithoutDiscount = drafts.fold<double>(
      0,
      (runningTotal, draft) => runningTotal + draft.price,
    );
    final totalDiscount = drafts.fold<double>(
      0,
      (runningTotal, draft) =>
          runningTotal + (draft.price - draft.discountedPrice),
    );

    final delivery = await _resolveDelivery(
      cep: userAddress.cep,
      subtotal: totalPriceWithoutDiscount - totalDiscount,
    );
    if (delivery == null) {
      if (mounted) {
        setState(() {
          _isConfirmingPurchase = false;
        });
      }
      return;
    }
    final freight = delivery.freight;

    final firstItem =
        mergedProducts.isNotEmpty ? mergedProducts.first : <String, dynamic>{};
    final productId = (firstItem['id'] ?? '').toString();

    final finalSale = SalesEntity(
      createdDate: Timestamp.now(),
      discountedPrice: totalDiscountedPrice,
      freight: freight,
      id: productId,
      installmentsNumber: 1,
      paymentMethod: 'Mercado Pago',
      price: totalPriceWithoutDiscount,
      productsList: mergedProducts,
      totalPrice: totalPriceWithoutDiscount + freight - totalDiscount,
      userBirthDate: userBirthDate,
      userGender: userGender,
      userId: userId,
      userName: userName,
      deliveryMethod: delivery.method,
      address: delivery.method == 'pickup'
          ? null
          : AddressModel.fromEntity(userAddress).toMap(),
    );

    final result = await sl<RegisterSaleUseCase>().call(finalSale);

    if (!mounted) {
      return;
    }

    final saleId = result.fold<String?>(
      (error) {
        _showPaymentError(error.toString());
        return null;
      },
      (id) => id as String,
    );
    if (saleId == null) {
      setState(() {
        _isConfirmingPurchase = false;
      });
      return;
    }

    final preferenceResult = await sl<CreatePaymentPreferenceUseCase>().call(
      CreatePaymentPreferenceParams(
        storeId: sl<StoreContext>().storeId,
        saleId: saleId,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isConfirmingPurchase = false;
    });

    final preference = preferenceResult.fold<PaymentPreferenceEntity?>(
      (error) {
        _showPaymentError(error.toString());
        return null;
      },
      (pref) => pref as PaymentPreferenceEntity,
    );
    if (preference == null) {
      return;
    }

    final checkoutUrl = preference.checkoutUrl;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      _showPaymentError(S.of(context).paymentStartFailed);
      return;
    }

    CartDraftStore.instance.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(S.of(context).redirectingToPayment),
          backgroundColor: context.brand.success,
        ),
      );

    await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MyPurchasesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Web gets the storefront experience; the mobile layout stays as-is.
    if (kIsWeb) {
      return WebCartPage(userIdOverride: widget.userIdOverride);
    }

    final userId =
        widget.userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;

    return BlocProvider<UserCubit>.value(
      value: _userCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            S.of(context).myCart,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  Theme.of(context).colorScheme.primary.withOpacity(0.06),
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.surface.withOpacity(0.45),
                ],
              ),
            ),
            child: userId == null || userId.isEmpty
                ? const _AuthRequiredView()
                : _CartView(
                    isConfirmingPurchase: _isConfirmingPurchase,
                    onConfirmPurchase: _confirmPurchase,
                    onOpenProduct: _openProductDetails,
                    onGoToFavorites: () {
                      AppNavigator.push(context, const FavoritesPage());
                    },
                    onReturnHome: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  final bool isConfirmingPurchase;
  final VoidCallback onConfirmPurchase;
  final ValueChanged<SalesEntity> onOpenProduct;
  final VoidCallback onGoToFavorites;
  final VoidCallback onReturnHome;

  const _CartView({
    required this.isConfirmingPurchase,
    required this.onConfirmPurchase,
    required this.onOpenProduct,
    required this.onGoToFavorites,
    required this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartDraftStore.instance,
      builder: (context, _) {
        final drafts = CartDraftStore.instance.drafts;

        if (drafts.isEmpty) {
          return SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CenteredInfoCard(
                    title: S.of(context).cartEmptyTitle,
                    body: S.of(context).cartEmptyBody,
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onGoToFavorites,
                              icon: const Icon(Icons.favorite_border),
                              label: Text(
                                S.of(context).goToFavorites,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onReturnHome,
                              icon: const Icon(Icons.home_outlined),
                              label: Text(
                                S.of(context).returnToHome,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                  width: 3,
                                ),
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalOriginal = CartDraftStore.instance.totalOriginalPrice;
        final totalDiscounted = CartDraftStore.instance.totalDiscountedPrice;
        final totalSavings = totalOriginal - totalDiscounted;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagPill(label: S.of(context).itemsCount(drafts.length)),
                  _TagPill(
                      label: S
                          .of(context)
                          .savedAmount(_formatCurrency(totalSavings))),
                  _TagPill(
                      label: S
                          .of(context)
                          .totalAmount(_formatCurrency(totalDiscounted))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).draftItems,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
              ),
              const SizedBox(height: 10),
              ...List.generate(
                drafts.length,
                (index) => _CartItemCard(
                  saleDraft: drafts[index],
                  onOpenProduct: () => onOpenProduct(drafts[index]),
                  onRemove: () => CartDraftStore.instance.removeAt(index),
                ),
              ),
              const SizedBox(height: 4),
              const _SectionSeparator(),
              const SizedBox(height: 14),
              _StatsCard(
                totalOriginal: totalOriginal,
                totalDiscounted: totalDiscounted,
                totalSavings: totalSavings,
              ),
              const SizedBox(height: 14),
              const _SectionSeparator(),
              const SizedBox(height: 14),
              Text(
                S.of(context).paymentMethod,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
              ),
              const SizedBox(height: 10),
              const _MercadoPagoInfoCard(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isConfirmingPurchase ? null : onConfirmPurchase,
                  icon: isConfirmingPurchase
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isConfirmingPurchase
                        ? S.of(context).confirmingPurchase
                        : S.of(context).confirmPurchase,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MercadoPagoInfoCard extends StatelessWidget {
  const _MercadoPagoInfoCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '',
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).paidViaMercadoPago,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final SalesEntity saleDraft;
  final VoidCallback onOpenProduct;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.saleDraft,
    required this.onOpenProduct,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final productData = saleDraft.productsList.isNotEmpty
        ? saleDraft.productsList.first
        : <String, dynamic>{};

    final productTitle = (productData['title'] ?? '').toString();
    final productCode = (productData['productId'] ?? '').toString();
    final size = (productData['size'] ?? 'N/A').toString();
    final color = (productData['color'] ?? 'N/A').toString();
    final colorHex = (productData['colorHex'] ?? '').toString();
    final unitPrice = _toDouble(productData['unitPrice']);
    final unitDiscounted = _toDouble(productData['unitDiscounted']);
    final quantityValue = _toDouble(productData['quantity']);
    final quantity = quantityValue % 1 == 0
        ? quantityValue.toInt().toString()
        : quantityValue.toStringAsFixed(2);

    final resolvedTitle = productTitle.isEmpty
        ? S
            .of(context)
            .productFallback(productCode.isEmpty ? '-' : productCode)
        : productTitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenProduct,
        child: _InfoCard(
          title: '',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      resolvedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(S.of(context).remove),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _LineItem(label: S.of(context).quantity, value: quantity),
              const SizedBox(height: 6),
              _LineItem(label: S.of(context).size, value: size),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).color,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _parseHexColor(colorHex) ?? _parseColorName(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.brand.textPrimary.withOpacity(0.26),
                        width: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    color,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _LineItem(
                  label: S.of(context).unitPrice,
                  value: _formatCurrency(unitPrice)),
              const SizedBox(height: 6),
              _LineItem(
                label: S.of(context).unitDiscounted,
                value: _formatCurrency(unitDiscounted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).total,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    _formatCurrency(saleDraft.totalPrice),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.brand.successStrong,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final double totalOriginal;
  final double totalDiscounted;
  final double totalSavings;

  const _StatsCard({
    required this.totalOriginal,
    required this.totalDiscounted,
    required this.totalSavings,
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
          width: 5,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).cartSummary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20),
          ),
          const SizedBox(height: 10),
          _LineItem(
              label: S.of(context).originalTotal,
              value: _formatCurrency(totalOriginal)),
          const SizedBox(height: 6),
          _LineItem(
              label: S.of(context).discountedTotal,
              value: _formatCurrency(totalDiscounted)),
          const SizedBox(height: 6),
          _LineItem(
              label: S.of(context).totalSaved,
              value: _formatCurrency(totalSavings)),
        ],
      ),
    );
  }
}

class _AuthRequiredView extends StatelessWidget {
  const _AuthRequiredView();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: _CenteredInfoCard(
        title: S.of(context).pleaseSignIn,
        body: S.of(context).signInToViewCart,
        icon: Icons.lock_outline,
      ),
    );
  }
}

class _CenteredInfoCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _CenteredInfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: _InfoCard(
            title: title,
            margin: EdgeInsets.zero,
            centerContent: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
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
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  final EdgeInsetsGeometry margin;
  final bool centerContent;

  const _InfoCard({
    required this.title,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.brand.surfaceBright.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: centerContent
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (hasTitle)
            Text(
              title,
              textAlign: centerContent ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          if (hasTitle) const SizedBox(height: 8),
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
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              baseColor.withOpacity(0.0),
              baseColor.withOpacity(0.22),
              baseColor.withOpacity(0.9),
              baseColor.withOpacity(0.22),
              baseColor.withOpacity(0.0),
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

class _DeliveryChoice {
  const _DeliveryChoice({required this.freight, required this.method});

  final double freight;
  final String method;
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

Color _parseColorName(String colorName) {
  switch (colorName.trim().toLowerCase()) {
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    case 'red':
      return Colors.red; // tripwire-allow: product swatch data
    case 'blue':
      return Colors.blue; // tripwire-allow: product swatch data
    case 'green':
      return Colors.green; // tripwire-allow: product swatch data
    case 'yellow':
      return Colors.yellow; // tripwire-allow: product swatch data
    case 'orange':
      return Colors.orange; // tripwire-allow: product swatch data
    case 'purple':
      return Colors.purple; // tripwire-allow: product swatch data
    case 'pink':
      return Colors.pink; // tripwire-allow: product swatch data
    case 'brown':
      return Colors.brown; // tripwire-allow: product swatch data
    case 'grey':
    case 'gray':
      return Colors.grey; // tripwire-allow: product swatch data
    default:
      return Colors.grey; // tripwire-allow: product swatch data
  }
}

Color? _parseHexColor(String hexCode) {
  final normalized = hexCode.replaceAll('#', '').trim();

  if (normalized.length == 6) {
    final intColor = int.tryParse('FF$normalized', radix: 16);
    if (intColor != null) {
      return Color(intColor);
    }
  }

  if (normalized.length == 8) {
    final intColor = int.tryParse(normalized, radix: 16);
    if (intColor != null) {
      return Color(intColor);
    }
  }

  return null;
}
