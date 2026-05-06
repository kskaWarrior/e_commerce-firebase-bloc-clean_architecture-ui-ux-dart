import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories.state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/favorites/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/favorites/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/header.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in_title.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/search_box.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling_title.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

            return Scaffold(
              appBar: HomeHeader(
                isLoggingOut: isLoggingOut,
                onLogoutTap: () => context.read<SignOutCubit>().signOut(),
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
                              const SearchBox(),
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
                                        // TODO Handle category tap
                                      },
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
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
                                            // TODO Handle product tap
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
                                                .contains(product.productId)) {
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .deleteFavorite(
                                                    userId,
                                                    product.productId,
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
                                              productId: product.productId,
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
                                            // TODO Handle product tap
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
                                                .contains(product.productId)) {
                                              await context
                                                  .read<FavoritesCubit>()
                                                  .deleteFavorite(
                                                    userId,
                                                    product.productId,
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
                                              productId: product.productId,
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

//USAR STATE HomeError.toString() ?