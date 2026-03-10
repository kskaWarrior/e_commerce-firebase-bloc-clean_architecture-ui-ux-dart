import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories.state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/header.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const HomeHeader(),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => sl<CategoriesCubit>()..loadCategories(),
          ),
          BlocProvider(
            create: (context) => sl<NewInDisplayCubit>()..displayProducts(),
          ),
          BlocProvider(
            create: (context) =>
                sl<ProductsDisplayCubit>()..displayProducts(),
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
          ],
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // --- Modern Search Box ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(24),
                    color: Color.fromARGB(255, 10, 32, 53),
                    child: TextField(
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for your next buy buy here ;)',
                        hintStyle: TextStyle(
                          color: colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: colorScheme.primary),
                        filled: true,
                        fillColor: Color.fromARGB(255, 10, 32, 53),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // --- End Search Box ---
                const SizedBox(height: 5),
                BlocBuilder<CategoriesCubit, CategoriesState>(
                  builder: (context, state) {
                    if (state is CategoriesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is CategoriesError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is CategoriesLoaded) {
                      // Assuming state.categories is List<CategoriesEntity>
                      if (state.categories.isEmpty) {
                        return const Center(child: Text('No categories found'));
                      }
                      return CategoriesWidget(
                        categories: state.categories, // List<CategoriesEntity>
                        onTap: (category) {
                          //TODO Handle category tap
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New In',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(1, 3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'New In',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(1, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'New In',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(1, 3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<NewInDisplayCubit, ProductsDisplayState>(
                  builder: (context, state) {
                    if (state is ProductsDisplayLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProductsDisplayError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is ProductsDisplayLoaded) {
                      if (state.products.isEmpty) {
                        return const Center(
                            child: Text('No new products found'));
                      }
                      return NewInCarousel(
                        products: state.products,
                        onTap: (product) {
                          //TODO Handle product tap
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Top Selling',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.inversePrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(1, 3),
                          blurRadius: 4,
                          ),
                        ],
                              ),
                      ),
                      Text(
                        'Top Selling',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(1, 2),
                          blurRadius: 4,
                          ),
                        ],
                              ),
                      ),
                      Text(
                        'Top Selling',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.inversePrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(1, 3),
                          blurRadius: 4,
                          ),
                        ],
                              ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
                  builder: (context, state) {
                    if (state is ProductsDisplayLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProductsDisplayError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is ProductsDisplayLoaded) {
                      if (state.products.isEmpty) {
                        return const Center(child: Text('No products found'));
                      }
                      return TopSellingCarousel(
                        products: state.products,
                        onTap: (product) {
                          //TODO Handle product tap
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//USAR STATE HomeError.toString()