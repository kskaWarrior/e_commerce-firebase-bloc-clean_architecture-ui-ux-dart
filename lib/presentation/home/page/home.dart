import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_route_observer.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/my_profile_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/page/favorites_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/category_carousel.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/header.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in_title.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/search_carousel.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/search_box.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling_title.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/language_menu.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/pages/web_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ModalRoute<dynamic>? _currentRoute;
  BuildContext? _providerContext;
  String? _selectedCategoryId;
  String? _selectedCategoryTitle;
  String _searchQuery = '';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadDrawerProfileImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (_currentRoute == route || route is! PageRoute) {
      return;
    }

    if (_currentRoute != null) {
      appRouteObserver.unsubscribe(this);
    }

    _currentRoute = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFavorites();
      _loadDrawerProfileImage();
    });
  }

  @override
  void didPush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFavorites();
      _loadDrawerProfileImage();
    });
  }

  Future<void> _loadDrawerProfileImage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileImageUrl = '';
      });
      return;
    }

    try {
      final result = await sl<GetUserUseCase>().call(null);
      final String fetchedImageUrl = result.fold(
        (_) => '',
        (user) => user.profileImageUrl.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profileImageUrl = fetchedImageUrl;
      });
    } catch (_) {
      // Ignore profile image fetch failures and keep a safe fallback avatar.
    }
  }

  void _refreshFavorites() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final providerContext = _providerContext;
    if (providerContext == null) {
      return;
    }

    try {
      providerContext.read<FavoritesCubit>().loadFavoritesByUserId(userId);
    } catch (_) {
      // Favorites provider may not be mounted yet on the first frame.
    }
  }

  Future<void> _toggleFavorite({
    required BuildContext context,
    required ProductEntity product,
    required Set<String> favoriteProductIds,
    required String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseSignInAddFavorites),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }

    final favoritesCubit = context.read<FavoritesCubit>();
    if (favoriteProductIds.contains(product.id)) {
      await favoritesCubit.deleteFavorite(userId, product.id);
      if (!context.mounted) return;
      await favoritesCubit.loadFavoritesByUserId(userId);
      return;
    }

    final favorite = FavoriteEntity(
      createdDate: Timestamp.now(),
      id: '',
      productId: product.id,
      userId: userId,
    );

    await favoritesCubit.registerFavorite(favorite);
    if (!context.mounted) return;
    await favoritesCubit.loadFavoritesByUserId(userId);
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: colorScheme.surface,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout,
                  size: 20,
                  color: colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  S.of(dialogContext).confirmLogoutTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            S.of(dialogContext).confirmLogoutBody,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(S.of(dialogContext).cancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(S.of(dialogContext).logout),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.inversePrimary,
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    Navigator.pop(context);
    context.read<SignOutCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Web gets the storefront experience; the mobile layout stays as-is.
    if (kIsWeb) {
      return const WebHomePage();
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<CategoriesCubit>()..loadCategories(),
        ),
        BlocProvider(
          create: (context) => sl<NewInDisplayCubit>()..displayProducts(),
        ),
        BlocProvider(
          create: (context) => sl<ProductsDisplayCubit>()..displayProducts(),
        ),
        BlocProvider(
          create: (context) => sl<SignOutCubit>(),
        ),
        BlocProvider(
          create: (context) {
            final cubit = sl<FavoritesCubit>();
            if (userId != null && userId.isNotEmpty) {
              cubit.loadFavoritesByUserId(userId);
            }
            return cubit;
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CategoriesCubit, CategoriesState>(
            listener: (context, state) {
              if (state is CategoriesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: context.brand.danger,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductsDisplayCubit, ProductsDisplayState>(
            listener: (context, state) {
              if (state is ProductsDisplayError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: context.brand.danger,
                  ),
                );
              }
            },
          ),
          BlocListener<NewInDisplayCubit, ProductsDisplayState>(
            listener: (context, state) {
              if (state is ProductsDisplayError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: context.brand.danger,
                  ),
                );
              }
            },
          ),
          BlocListener<SignOutCubit, SignOutState>(
            listener: (context, state) {
              if (state is SignOutFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: context.brand.danger,
                  ),
                );
              } else if (state is SignOutSuccess) {
                AppNavigator.pushAndRemoveUntil(context, const SigninPage());
              }
            },
          ),
          BlocListener<FavoritesCubit, FavoritesState>(
            listener: (context, state) {
              if (state is FavoritesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: context.brand.danger,
                  ),
                );
              } else if (state is FavoritesRegisterSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: context.brand.success,
                    ),
                  );
              } else if (state is FavoritesDeleteSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: context.brand.success,
                    ),
                  );
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            _providerContext = context;
            final isLoggingOut = context
                .select((SignOutCubit cubit) => cubit.state is SignOutLoading);
            final currentUser = FirebaseAuth.instance.currentUser;
            final userDisplayName = (currentUser?.displayName ?? '').trim();
            final userEmail =
                (currentUser?.email ?? S.of(context).signedInUser).trim();

            return Scaffold(
              key: _scaffoldKey,
              appBar: HomeHeader(
                isLoggingOut: isLoggingOut,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onCartTap: () => AppNavigator.push(context, const CartPage()),
              ),
              drawer: Drawer(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                backgroundImage: _profileImageUrl.isNotEmpty
                                    ? NetworkImage(_profileImageUrl)
                                    : null,
                                child: _profileImageUrl.isEmpty
                                    ? Icon(
                                        Icons.person_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  userEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (userDisplayName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                userDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ListTileTheme(
                          iconColor:
                              Theme.of(context).colorScheme.inversePrimary,
                          textColor:
                              Theme.of(context).colorScheme.inversePrimary,
                          child: Column(
                            children: [
                              _DrawerNavTile(
                                icon: Icons.account_circle_outlined,
                                label: S.of(context).myProfile,
                                onTap: () {
                                  Navigator.pop(context);
                                  AppNavigator.push(
                                      context, const MyProfilePage());
                                },
                              ),
                              _DrawerNavTile(
                                icon: Icons.favorite_border,
                                label: S.of(context).favorites,
                                onTap: () {
                                  Navigator.pop(context);
                                  AppNavigator.push(
                                      context, const FavoritesPage());
                                },
                              ),
                              _DrawerNavTile(
                                icon: Icons.shopping_bag_outlined,
                                label: S.of(context).myPurchases,
                                onTap: () {
                                  Navigator.pop(context);
                                  AppNavigator.push(
                                      context, const MyPurchasesPage());
                                },
                              ),
                              _DrawerNavTile(
                                icon: Icons.language,
                                label: S.of(context).language,
                                onTap: () {
                                  Navigator.pop(context);
                                  showLanguagePicker(context);
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Divider(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(1),
                            height: 5,
                          ),
                        ),
                        _DrawerNavTile(
                          icon: Icons.logout,
                          label: S.of(context).logout,
                          enabled: !isLoggingOut,
                          trailing: isLoggingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onTap: isLoggingOut
                              ? null
                              : () => _confirmAndSignOut(context),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = (constraints.maxWidth - 24)
                        .clamp(320.0, 860.0)
                        .toDouble();

                    return SingleChildScrollView(
                      child: Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SearchBox(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                              if (_searchQuery.trim().isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: Text(
                                    S.of(context).searchResults,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withOpacity(0.4),
                                          offset: const Offset(1, 3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<FavoritesCubit, FavoritesState>(
                                  builder: (context, favoritesState) {
                                    final favoriteProductIds =
                                        favoritesState is FavoritesLoaded
                                            ? favoritesState.favorites
                                                .map((e) => e.productId)
                                                .toSet()
                                            : <String>{};

                                    return BlocBuilder<ProductsDisplayCubit,
                                        ProductsDisplayState>(
                                      builder: (context, state) {
                                        if (state is ProductsDisplayLoading) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (state
                                            is ProductsDisplayError) {
                                          return Center(
                                            child: Text(
                                              state.message,
                                              style: TextStyle(
                                                  color: context.brand.danger),
                                            ),
                                          );
                                        } else if (state
                                            is ProductsDisplayLoaded) {
                                          return SearchCarousel(
                                            query: _searchQuery,
                                            products: state.products,
                                            favoriteProductIds:
                                                favoriteProductIds,
                                            onTap: (product) {
                                              AppNavigator.push(
                                                context,
                                                ProductPage(
                                                  product: product,
                                                  topSellingProducts:
                                                      state.products,
                                                ),
                                              );
                                            },
                                            onFavoritePressed: (product) async {
                                              await _toggleFavorite(
                                                context: context,
                                                product: product,
                                                favoriteProductIds:
                                                    favoriteProductIds,
                                                userId: userId,
                                              );
                                            },
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                const _SectionSeparator(),
                              ],
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 5, left: 6.0, bottom: 10),
                                child: Text(
                                  S.of(context).categories,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withOpacity(0.4),
                                        offset: const Offset(1, 3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              BlocBuilder<CategoriesCubit, CategoriesState>(
                                builder: (context, state) {
                                  if (state is CategoriesLoading) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (state is CategoriesError) {
                                    return Center(
                                      child: Text(
                                        state.message,
                                        style:
                                            TextStyle(
                                                color: context.brand.danger),
                                      ),
                                    );
                                  } else if (state is CategoriesLoaded) {
                                    if (state.categories.isEmpty) {
                                      return Center(
                                          child: Text(S
                                              .of(context)
                                              .noCategoriesFound));
                                    }
                                    return CategoriesWidget(
                                      categories: state.categories,
                                      onTap: (category) {
                                        setState(() {
                                          _selectedCategoryId = category.id;
                                          _selectedCategoryTitle =
                                              category.title;
                                        });
                                      },
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                              if (_selectedCategoryId != null) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedCategoryTitle ??
                                              S.of(context).categoryFallback,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inversePrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black
                                                    .withOpacity(0.4),
                                                offset: const Offset(1, 3),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.keyboard_arrow_up,
                                          size: 28,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                        tooltip: S.of(context).hideCategory,
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategoryId = null;
                                            _selectedCategoryTitle = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<FavoritesCubit, FavoritesState>(
                                  builder: (context, favoritesState) {
                                    final favoriteProductIds =
                                        favoritesState is FavoritesLoaded
                                            ? favoritesState.favorites
                                                .map((e) => e.productId)
                                                .toSet()
                                            : <String>{};

                                    return BlocBuilder<ProductsDisplayCubit,
                                        ProductsDisplayState>(
                                      builder: (context, state) {
                                        if (state is ProductsDisplayLoading) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (state
                                            is ProductsDisplayError) {
                                          return Center(
                                            child: Text(
                                              state.message,
                                              style: TextStyle(
                                                  color: context.brand.danger),
                                            ),
                                          );
                                        } else if (state
                                            is ProductsDisplayLoaded) {
                                          return CategoryCarousel(
                                            categoryId: _selectedCategoryId!,
                                            products: state.products,
                                            favoriteProductIds:
                                                favoriteProductIds,
                                            onTap: (product) {
                                              AppNavigator.push(
                                                context,
                                                ProductPage(
                                                  product: product,
                                                  topSellingProducts:
                                                      state.products,
                                                ),
                                              );
                                            },
                                            onFavoritePressed: (product) async {
                                              await _toggleFavorite(
                                                context: context,
                                                product: product,
                                                favoriteProductIds:
                                                    favoriteProductIds,
                                                userId: userId,
                                              );
                                            },
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: 7),
                              const _SectionSeparator(),
                              const SizedBox(height: 7),
                              const TopSellingTitle(),
                              BlocBuilder<FavoritesCubit, FavoritesState>(
                                builder: (context, favoritesState) {
                                  final favoriteProductIds =
                                      favoritesState is FavoritesLoaded
                                          ? favoritesState.favorites
                                              .map((e) => e.productId)
                                              .toSet()
                                          : <String>{};

                                  return BlocBuilder<ProductsDisplayCubit,
                                      ProductsDisplayState>(
                                    builder: (context, state) {
                                      if (state is ProductsDisplayLoading) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (state
                                          is ProductsDisplayError) {
                                        return Center(
                                          child: Text(
                                            state.message,
                                            style: TextStyle(
                                                color: context.brand.danger),
                                          ),
                                        );
                                      } else if (state
                                          is ProductsDisplayLoaded) {
                                        if (state.products.isEmpty) {
                                          return Center(
                                              child: Text(S
                                                  .of(context)
                                                  .noProductsFound));
                                        }
                                        return TopSellingCarousel(
                                          products: state.products,
                                          favoriteProductIds:
                                              favoriteProductIds,
                                          onTap: (product) {
                                            AppNavigator.push(
                                              context,
                                              ProductPage(
                                                product: product,
                                                topSellingProducts:
                                                    state.products,
                                              ),
                                            );
                                          },
                                          onFavoritePressed: (product) async {
                                            await _toggleFavorite(
                                              context: context,
                                              product: product,
                                              favoriteProductIds:
                                                  favoriteProductIds,
                                              userId: userId,
                                            );
                                          },
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              const _SectionSeparator(),
                              const SizedBox(height: 7),
                              const NewInTitle(),
                              BlocBuilder<FavoritesCubit, FavoritesState>(
                                builder: (context, favoritesState) {
                                  final favoriteProductIds =
                                      favoritesState is FavoritesLoaded
                                          ? favoritesState.favorites
                                              .map((e) => e.productId)
                                              .toSet()
                                          : <String>{};

                                  return BlocBuilder<NewInDisplayCubit,
                                      ProductsDisplayState>(
                                    builder: (context, state) {
                                      if (state is ProductsDisplayLoading) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (state
                                          is ProductsDisplayError) {
                                        return Center(
                                          child: Text(
                                            state.message,
                                            style: TextStyle(
                                                color: context.brand.danger),
                                          ),
                                        );
                                      } else if (state
                                          is ProductsDisplayLoaded) {
                                        if (state.products.isEmpty) {
                                          return Center(
                                              child: Text(S
                                                  .of(context)
                                                  .noNewProductsFound));
                                        }
                                        return NewInCarousel(
                                          products: state.products,
                                          favoriteProductIds:
                                              favoriteProductIds,
                                          onTap: (product) {
                                            AppNavigator.push(
                                              context,
                                              ProductPage(
                                                product: product,
                                                topSellingProducts:
                                                    state.products,
                                              ),
                                            );
                                          },
                                          onFavoritePressed: (product) async {
                                            await _toggleFavorite(
                                              context: context,
                                              product: product,
                                              favoriteProductIds:
                                                  favoriteProductIds,
                                              userId: userId,
                                            );
                                          },
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              const _SectionSeparator(),
                              const SizedBox(height: 22),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  bottom: 10,
                                ),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        AppNavigator.push(
                                          context,
                                          const FavoritesPage(),
                                        );
                                      },
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
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
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
      padding:
          const EdgeInsets.only(top: 7.0, bottom: 3.0, left: 6.0, right: 6.0),
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

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        trailing: trailing,
        enabled: enabled,
        onTap: onTap,
      ),
    );
  }
}

//USAR STATE HomeError.toString() ?
