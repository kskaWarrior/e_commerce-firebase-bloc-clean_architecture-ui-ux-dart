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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

enum _PaymentMethod { creditCard, debitCard }

class CartPage extends StatefulWidget {
  final String? userIdOverride;

  const CartPage({super.key, this.userIdOverride});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isConfirmingPurchase = false;
  _PaymentMethod _selectedPaymentMethod = _PaymentMethod.debitCard;
  int _creditInstallments = 1;
  late final UserCubit _userCubit;

  final TextEditingController _cardholderNameController =
      TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

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

  bool _hasValidPaymentData() {
    final cardholderName = _cardholderNameController.text.trim();
    final cardDigits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final expiry = _cardExpiryController.text.trim();
    final cvvDigits = _cardCvvController.text.replaceAll(RegExp(r'\D'), '');

    if (cardholderName.isEmpty) {
      _showPaymentError(S.of(context).enterCardholderName);
      return false;
    }

    if (cardDigits.length < 13 || cardDigits.length > 19) {
      _showPaymentError(S.of(context).enterValidCardNumber);
      return false;
    }

    final expiryPattern = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$');
    if (!expiryPattern.hasMatch(expiry)) {
      _showPaymentError(S.of(context).enterExpiryAsMmYy);
      return false;
    }

    final expiryMatch = expiryPattern.firstMatch(expiry);
    if (expiryMatch == null) {
      _showPaymentError(S.of(context).enterExpiryAsMmYy);
      return false;
    }
    final expiryMonth = int.parse(expiryMatch.group(1)!);
    final expiryYear = 2000 + int.parse(expiryMatch.group(2)!);
    final now = DateTime.now();
    final isExpired = expiryYear < now.year ||
        (expiryYear == now.year && expiryMonth < now.month);
    if (isExpired) {
      _showPaymentError(S.of(context).cardExpired);
      return false;
    }

    if (cvvDigits.length < 3 || cvvDigits.length > 4) {
      _showPaymentError(S.of(context).enterValidCvv);
      return false;
    }

    return true;
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

    if (!_hasValidPaymentData()) {
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

    setState(() {
      _isConfirmingPurchase = false;
    });

    result.fold(
      (error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: context.brand.danger,
            ),
          );
      },
      (_) {
        CartDraftStore.instance.clear();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(S.of(context).purchaseConfirmed),
              backgroundColor: context.brand.success,
            ),
          );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MyPurchasesPage(),
          ),
        );
      },
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
                    selectedPaymentMethod: _selectedPaymentMethod,
                    onPaymentMethodChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                        if (value == _PaymentMethod.debitCard) {
                          _creditInstallments = 1;
                        }
                      });
                    },
                    creditInstallments: _creditInstallments,
                    onCreditInstallmentsChanged: (value) {
                      setState(() {
                        _creditInstallments = value;
                      });
                    },
                    cardholderNameController: _cardholderNameController,
                    cardNumberController: _cardNumberController,
                    cardExpiryController: _cardExpiryController,
                    cardCvvController: _cardCvvController,
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
  final _PaymentMethod selectedPaymentMethod;
  final ValueChanged<_PaymentMethod> onPaymentMethodChanged;
  final int creditInstallments;
  final ValueChanged<int> onCreditInstallmentsChanged;
  final TextEditingController cardholderNameController;
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvvController;
  final bool isConfirmingPurchase;
  final VoidCallback onConfirmPurchase;
  final ValueChanged<SalesEntity> onOpenProduct;
  final VoidCallback onGoToFavorites;
  final VoidCallback onReturnHome;

  const _CartView({
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.creditInstallments,
    required this.onCreditInstallmentsChanged,
    required this.cardholderNameController,
    required this.cardNumberController,
    required this.cardExpiryController,
    required this.cardCvvController,
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
              _PaymentSection(
                selectedPaymentMethod: selectedPaymentMethod,
                onPaymentMethodChanged: onPaymentMethodChanged,
                creditInstallments: creditInstallments,
                onCreditInstallmentsChanged: onCreditInstallmentsChanged,
                cardholderNameController: cardholderNameController,
                cardNumberController: cardNumberController,
                cardExpiryController: cardExpiryController,
                cardCvvController: cardCvvController,
              ),
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

class _PaymentSection extends StatelessWidget {
  final _PaymentMethod selectedPaymentMethod;
  final ValueChanged<_PaymentMethod> onPaymentMethodChanged;
  final int creditInstallments;
  final ValueChanged<int> onCreditInstallmentsChanged;
  final TextEditingController cardholderNameController;
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvvController;

  const _PaymentSection({
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.creditInstallments,
    required this.onCreditInstallmentsChanged,
    required this.cardholderNameController,
    required this.cardNumberController,
    required this.cardExpiryController,
    required this.cardCvvController,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<_PaymentMethod>(
            segments: [
              ButtonSegment<_PaymentMethod>(
                value: _PaymentMethod.creditCard,
                icon: const Icon(Icons.credit_card),
                label: Text(S.of(context).creditCard),
              ),
              ButtonSegment<_PaymentMethod>(
                value: _PaymentMethod.debitCard,
                icon: const Icon(Icons.payments_outlined),
                label: Text(S.of(context).debitCard),
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
                  return Theme.of(context).colorScheme.primary;
                }
                return context.brand.surfaceBright.withOpacity(0.85);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.onPrimary;
                }
                return Theme.of(context).colorScheme.onSurface;
              }),
              side: WidgetStateProperty.resolveWith((states) {
                return BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.35),
                );
              }),
            ),
          ),
          const SizedBox(height: 25),
          if (selectedPaymentMethod == _PaymentMethod.creditCard)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: DropdownButtonFormField<int>(
                value: creditInstallments,
                decoration: _paymentInputDecoration(
                  context,
                  S.of(context).installmentsNumber,
                  Icons.calendar_view_week_outlined,
                ).copyWith(
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                  floatingLabelStyle:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                ),
                items: List.generate(
                  12,
                  (index) {
                    final value = index + 1;
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  },
                ),
                onChanged: (value) {
                  if (value != null) {
                    onCreditInstallmentsChanged(value);
                  }
                },
              ),
            ),
          TextField(
            controller: cardholderNameController,
            textInputAction: TextInputAction.next,
            decoration: _paymentInputDecoration(
              context,
              S.of(context).cardholderName,
              Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: 17),
          TextField(
            controller: cardNumberController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _paymentInputDecoration(
              context,
              S.of(context).cardNumber,
              Icons.credit_card,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cardExpiryController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    _ExpiryDateInputFormatter(),
                  ],
                  decoration: _paymentInputDecoration(
                    context,
                    S.of(context).expiryMmYy,
                    Icons.date_range_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: cardCvvController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _paymentInputDecoration(
                    context,
                    S.of(context).cvv,
                    Icons.lock_outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _paymentInputDecoration(
  BuildContext context,
  String label,
  IconData icon,
) {
  final labelTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      );

  return InputDecoration(
    labelText: label,
    labelStyle: labelTextStyle,
    floatingLabelStyle: labelTextStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    prefixIcon: Icon(icon, size: 18),
    filled: true,
    fillColor: context.brand.surfaceBright.withOpacity(0.8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
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
