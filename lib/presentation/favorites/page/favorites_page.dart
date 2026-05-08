import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in_title.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritesPage extends StatelessWidget {
	const FavoritesPage({super.key});

	@override
	Widget build(BuildContext context) {
		final userId = FirebaseAuth.instance.currentUser?.uid;

		return MultiBlocProvider(
			providers: [
				BlocProvider(
					create: (_) {
						final cubit = sl<FavoritesCubit>();
						if (userId != null && userId.isNotEmpty) {
							cubit.loadFavoritesByUserId(userId);
						}
						return cubit;
					},
				),
				BlocProvider(
					create: (_) => sl<ProductsDisplayCubit>()..displayProducts(),
				),
				BlocProvider(
					create: (_) => sl<NewInDisplayCubit>()..displayProducts(),
				),
			],
			child: Scaffold(
				appBar: AppBar(
					title: Text(
						'My favorites',
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
								? const _AuthRequiredView()
								: _FavoritesView(userId: userId),
					),
				),
			),
		);
	}
}

class _FavoritesView extends StatefulWidget {
	final String userId;

	const _FavoritesView({required this.userId});

	@override
	State<_FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<_FavoritesView> {
	List<FavoriteEntity> _cachedFavorites = const [];

	List<FavoriteEntity> _resolveFavorites(FavoritesState state) {
		if (state is FavoritesLoaded) {
			return state.favorites;
		}
		return _cachedFavorites;
	}

	@override
	Widget build(BuildContext context) {
		return MultiBlocListener(
			listeners: [
				BlocListener<FavoritesCubit, FavoritesState>(
					listener: (context, state) {
						if (state is FavoritesLoaded) {
							setState(() {
								_cachedFavorites = List<FavoriteEntity>.from(state.favorites);
							});
						}
					},
				),
				BlocListener<FavoritesCubit, FavoritesState>(
					listener: (context, state) {
						if (state is FavoritesError) {
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(
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
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(
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
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(
									SnackBar(
										content: Text(state.message),
										backgroundColor: Colors.red,
									),
								);
						}
					},
				),
			],
			child: BlocBuilder<FavoritesCubit, FavoritesState>(
				builder: (context, favoritesState) {
					if (favoritesState is FavoritesLoading && _cachedFavorites.isEmpty) {
						return const Center(child: CircularProgressIndicator());
					}

					if (favoritesState is FavoritesError && _cachedFavorites.isEmpty) {
						return _CenteredStateView(
							title: 'Could not load favorites',
							body: favoritesState.message,
							icon: Icons.error_outline,
						);
					}

					final favorites = _resolveFavorites(favoritesState);
					final favoritesSortedByRecent =
							List<FavoriteEntity>.from(favorites)
								..sort((a, b) => b.createdDate.compareTo(a.createdDate));
					return BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
						builder: (context, topSellingState) {
							return BlocBuilder<NewInDisplayCubit, ProductsDisplayState>(
								builder: (context, newInState) {
									final isCatalogLoading =
											topSellingState is ProductsDisplayLoading &&
													newInState is ProductsDisplayLoading;

									if (isCatalogLoading) {
										return const Center(child: CircularProgressIndicator());
									}

									final topSelling = topSellingState is ProductsDisplayLoaded
											? topSellingState.products
											: <ProductEntity>[];
									final newIn = newInState is ProductsDisplayLoaded
											? newInState.products
											: <ProductEntity>[];

									final catalogById = <String, ProductEntity>{};
									for (final product in [...topSelling, ...newIn]) {
										catalogById[product.id] = product;
									}

									final favoriteProducts = <ProductEntity>[];
									for (final favorite in favoritesSortedByRecent) {
										final product = catalogById[favorite.productId];
										if (product != null) {
											favoriteProducts.add(product);
										}
									}

									final missingCount = favorites.length - favoriteProducts.length;

									if (favoriteProducts.isEmpty && favorites.isNotEmpty) {
										return _CenteredStateView(
											title: 'Favorites unavailable',
											body: missingCount > 0
													? 'We found your favorites, but product details are unavailable right now.'
													: 'No favorite products available.',
											icon: Icons.hourglass_empty,
										);
									}

									return SingleChildScrollView(
										padding: EdgeInsets.fromLTRB(
											16,
											favorites.isEmpty ? 70 : 17,
											16,
											12,
										),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												if (favorites.isEmpty) ...[
													_InfoCard(
														title: 'No favorites yet',
														centerContent: true,
														child: Column(
															mainAxisSize: MainAxisSize.min,
															children: [
																Icon(
																	Icons.favorite_border,
																	size: 36,
																	color: Theme.of(context).colorScheme.primary,
																),
																const SizedBox(height: 8),
																const Text(
																	'Tap the heart icon in product lists to save favorites.',
																	textAlign: TextAlign.center,
																),
															],
														),
													),
													const SizedBox(height: 8),
												] else ...[
													Wrap(
														spacing: 8,
														runSpacing: 8,
														children: [
															_TagPill(label: 'Favorites count: ${favorites.length}'),
															if (missingCount > 0)
																_TagPill(label: 'Unavailable: $missingCount'),
														],
													),
													const SizedBox(height: 10),
													Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Favorites gallery',
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontFamily: 'CircularStd',
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                                    ),
                            ),
                          ),
													const SizedBox(height: 8),
													GridView.builder(
														shrinkWrap: true,
														physics: const NeverScrollableScrollPhysics(),
														itemCount: favoriteProducts.length,
														gridDelegate:
																const SliverGridDelegateWithFixedCrossAxisCount(
															crossAxisCount: 2,
															crossAxisSpacing: 2,
															childAspectRatio: 0.56,
														),
														itemBuilder: (context, index) {
															final product = favoriteProducts[index];

															return ProductCard(
																product: product,
																isFavorite: true,
																compactInfo: true,
																onTap: () {
																	AppNavigator.push(
																		context,
																		ProductPage(
																			product: product,
																			topSellingProducts: topSelling,
																		),
																	);
																},
																onFavoritePressed: () async {
																	await context
																			.read<FavoritesCubit>()
																				.deleteFavorite(widget.userId, product.id);
																	await context
																			.read<FavoritesCubit>()
																				.loadFavoritesByUserId(widget.userId);
																},
															);
														},
													),
												],
													SizedBox(height: favorites.isEmpty ? 55 : 14),
													const _SectionSeparator(),
													const SizedBox(height: 6),
													const NewInTitle(),
													NewInCarousel(
														products: newIn,
														favoriteProductIds:
																favorites.map((e) => e.productId).toSet(),
														onTap: (product) {
															AppNavigator.push(
																context,
																ProductPage(
																	product: product,
																	topSellingProducts: newIn,
																),
															);
														},
														onFavoritePressed: (product) async {
															if (favorites
																	.map((e) => e.productId)
																	.contains(product.id)) {
																await context
																		.read<FavoritesCubit>()
																		.deleteFavorite(widget.userId, product.id);
																await context
																		.read<FavoritesCubit>()
																		.loadFavoritesByUserId(widget.userId);
																return;
															}

															final favorite = FavoriteEntity(
																createdDate: Timestamp.now(),
																id: '',
																productId: product.id,
																userId: widget.userId,
															);

															await context
																	.read<FavoritesCubit>()
																	.registerFavorite(favorite);
															await context
																	.read<FavoritesCubit>()
																	.loadFavoritesByUserId(widget.userId);
														},
													),
															const SizedBox(height: 14),
															const _SectionSeparator(),
															const SizedBox(height: 22),
													Padding(
														padding: const EdgeInsets.only(left: 18, right: 18, bottom: 10),
														child: ConstrainedBox(
															constraints: const BoxConstraints(maxWidth: 460),
															child: SizedBox(
																width: double.infinity,
																child: OutlinedButton.icon(
																	onPressed: () {
																		Navigator.of(context).popUntil((route) => route.isFirst);
																	},
																	icon: const Icon(Icons.home_outlined),
																	label: Text(
																		'Return to home',
																		style: Theme.of(context)
																			.textTheme
																			.titleMedium
																			?.copyWith(
																				fontFamily: 'CircularStd',
																				fontWeight: FontWeight.w700,
																			),
																	),
																	style: OutlinedButton.styleFrom(
																		padding: const EdgeInsets.symmetric(vertical: 13),
																		backgroundColor: Theme.of(context).colorScheme.primary,
																		side: BorderSide(
																			color: Theme.of(context)
																				.colorScheme
																				.primary
																				.withValues(alpha: 0.8),
																			width: 3,
																		),
																		foregroundColor:
																			Theme.of(context).colorScheme.inversePrimary,
																	),
																),
															),
														),
													),
												if (missingCount > 0) ...[
													const SizedBox(height: 12),
													_InfoCard(
														title: 'Note',
														child: Text(
															'$missingCount favorite item(s) could not be shown because full product data is currently unavailable.',
															style: Theme.of(context).textTheme.bodyMedium,
														),
													),
												],
											],
										),
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

class _AuthRequiredView extends StatelessWidget {
	const _AuthRequiredView();

	@override
	Widget build(BuildContext context) {
		return const _CenteredStateView(
			title: 'Please sign in',
			body: 'Sign in to view your favorite products.',
			icon: Icons.lock_outline,
		);
	}
}

class _CenteredStateView extends StatelessWidget {
	final String title;
	final String body;
	final IconData icon;

	const _CenteredStateView({
		required this.title,
		required this.body,
		required this.icon,
	});

	@override
	Widget build(BuildContext context) {
		return SizedBox.expand(
			child: Padding(
				padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						_CenteredInfoCard(
							title: title,
							body: body,
							icon: icon,
						),
					],
				),
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
									style: Theme.of(context).textTheme.bodyLarge?.copyWith(
												fontFamily: 'CircularStd',
											),
								),
							],
						),
					),
				),
			),
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
				color: Colors.white.withValues(alpha: 0.6),
				borderRadius: BorderRadius.circular(18),
				border: Border.all(
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
							textAlign:
									centerContent ? TextAlign.center : TextAlign.start,
							style: Theme.of(context).textTheme.titleMedium?.copyWith(
										fontFamily: 'CircularStd',
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
