import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
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
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedCategoryId;
  String? _selectedCategoryTitle;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                    backgroundColor: Colors.red,
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
                    backgroundColor: Colors.red,
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
                    backgroundColor: Colors.red,
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
                    backgroundColor: Colors.red,
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
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is FavoritesRegisterSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
              } else if (state is FavoritesDeleteSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            final isLoggingOut = context
                .select((SignOutCubit cubit) => cubit.state is SignOutLoading);
            final currentUser = FirebaseAuth.instance.currentUser;
            final userDisplayName = (currentUser?.displayName ?? '').trim();
            final userEmail = (currentUser?.email ?? 'Signed in user').trim();

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
                              .withValues(alpha: 0.12),
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
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
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
                                        fontFamily: 'CircularStd',
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
                                      fontFamily: 'CircularStd',
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
                                label: 'My Profile',
                                onTap: () {
                                  Navigator.pop(context);
                                  AppNavigator.push(
                                      context, const _MyProfilePage());
                                },
                              ),
                              _DrawerNavTile(
                                icon: Icons.favorite_border,
                                label: 'Favorites',
                                onTap: () {
                                  Navigator.pop(context);
                                  AppNavigator.push(
                                      context, const _FavoritesPage());
                                },
                              ),
                              _DrawerNavTile(
                                icon: Icons.shopping_bag_outlined,
                                label: 'My Purchases',
                                onTap: () {
                                  Navigator.pop(context);
                                  AppNavigator.push(
                                      context, const MyPurchasesPage());
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
                                .withValues(alpha: 1),
                            height: 5,
                          ),
                        ),
                        _DrawerNavTile(
                          icon: Icons.logout,
                          label: 'Logout',
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
                              : () {
                                  Navigator.pop(context);
                                  context.read<SignOutCubit>().signOut();
                                },
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
                                    'Search results',
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
                                              .withValues(alpha: 0.4),
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
                                              style: const TextStyle(
                                                  color: Colors.red),
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
                                              if (userId == null ||
                                                  userId.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Please sign in to add favorites.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                return;
                                              }

                                              if (favoriteProductIds
                                                  .contains(product.id)) {
                                                await context
                                                    .read<FavoritesCubit>()
                                                    .deleteFavorite(
                                                      userId,
                                                      product.id,
                                                    );
                                                await context
                                                    .read<FavoritesCubit>()
                                                    .loadFavoritesByUserId(
                                                        userId);
                                                return;
                                              }

                                              final favorite = FavoriteEntity(
                                                createdDate: Timestamp.now(),
                                                id: '',
                                                productId: product.id,
                                                userId: userId,
                                              );

                                              await context
                                                  .read<FavoritesCubit>()
                                                  .registerFavorite(favorite);
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .loadFavoritesByUserId(
                                                      userId);
                                            },
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    );
                                  },
                                ),
                                const _SectionSeparator(),
                              ],
                              Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Text(
                                  'Categories',
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
                                            Colors.black.withValues(alpha: 0.4),
                                        offset: const Offset(1, 3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
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
                                            const TextStyle(color: Colors.red),
                                      ),
                                    );
                                  } else if (state is CategoriesLoaded) {
                                    if (state.categories.isEmpty) {
                                      return const Center(
                                          child: Text('No categories found'));
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
                                          _selectedCategoryTitle ?? 'Category',
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
                                                    .withValues(alpha: 0.4),
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
                                        tooltip: 'Hide category',
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
                                              style: const TextStyle(
                                                  color: Colors.red),
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
                                              if (userId == null ||
                                                  userId.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Please sign in to add favorites.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                return;
                                              }

                                              if (favoriteProductIds
                                                  .contains(product.id)) {
                                                await context
                                                    .read<FavoritesCubit>()
                                                    .deleteFavorite(
                                                      userId,
                                                      product.id,
                                                    );
                                                await context
                                                    .read<FavoritesCubit>()
                                                    .loadFavoritesByUserId(
                                                        userId);
                                                return;
                                              }

                                              final favorite = FavoriteEntity(
                                                createdDate: Timestamp.now(),
                                                id: '',
                                                productId: product.id,
                                                userId: userId,
                                              );

                                              await context
                                                  .read<FavoritesCubit>()
                                                  .registerFavorite(favorite);
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .loadFavoritesByUserId(
                                                      userId);
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
                              const _SectionSeparator(),
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
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                        );
                                      } else if (state
                                          is ProductsDisplayLoaded) {
                                        if (state.products.isEmpty) {
                                          return const Center(
                                              child: Text('No products found'));
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
                                            if (userId == null ||
                                                userId.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Please sign in to add favorites.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            if (favoriteProductIds
                                                .contains(product.id)) {
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .deleteFavorite(
                                                    userId,
                                                    product.id,
                                                  );
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .loadFavoritesByUserId(
                                                      userId);
                                              return;
                                            }

                                            final favorite = FavoriteEntity(
                                              createdDate: Timestamp.now(),
                                              id: '',
                                              productId: product.id,
                                              userId: userId,
                                            );

                                            await context
                                                .read<FavoritesCubit>()
                                                .registerFavorite(favorite);
                                            await context
                                                .read<FavoritesCubit>()
                                                .loadFavoritesByUserId(userId);
                                          },
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
                              ),
                              const _SectionSeparator(),
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
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                        );
                                      } else if (state
                                          is ProductsDisplayLoaded) {
                                        if (state.products.isEmpty) {
                                          return const Center(
                                              child: Text(
                                                  'No new products found'));
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
                                            if (userId == null ||
                                                userId.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Please sign in to add favorites.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            if (favoriteProductIds
                                                .contains(product.id)) {
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .deleteFavorite(
                                                    userId,
                                                    product.id,
                                                  );
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .loadFavoritesByUserId(
                                                      userId);
                                              return;
                                            }

                                            final favorite = FavoriteEntity(
                                              createdDate: Timestamp.now(),
                                              id: '',
                                              productId: product.id,
                                              userId: userId,
                                            );

                                            await context
                                                .read<FavoritesCubit>()
                                                .registerFavorite(favorite);
                                            await context
                                                .read<FavoritesCubit>()
                                                .loadFavoritesByUserId(userId);
                                          },
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
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
                fontFamily: 'CircularStd',
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

class _MyProfilePage extends StatelessWidget {
  const _MyProfilePage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64),
              const SizedBox(height: 12),
              Text(user?.displayName ?? 'Name not available'),
              const SizedBox(height: 6),
              Text(user?.email ?? 'Email not available'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesPage extends StatelessWidget {
  const _FavoritesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Your favorites are managed directly from product lists.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

//USAR STATE HomeError.toString() ?
