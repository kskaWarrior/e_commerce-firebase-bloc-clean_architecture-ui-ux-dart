import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling_title.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
	final ProductEntity product;
	final List<ProductEntity> topSellingProducts;

	const ProductPage({
		super.key,
		required this.product,
		this.topSellingProducts = const <ProductEntity>[],
	});

	@override
	State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
	late final PageController _imagePageController;
	int _currentImageIndex = 0;
	String? _selectedSize;
	String? _selectedColorKey;
	int _quantity = 1;

	@override
	void initState() {
		super.initState();
		_imagePageController = PageController();
	}

	@override
	void dispose() {
		_imagePageController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final product = widget.product;
		final topSellingProducts = widget.topSellingProducts
				.where((item) => item.id != product.id)
				.toList(growable: false);
		final hasDiscount =
				product.discountedPrice > 0 && product.discountedPrice < product.price;
		final imagePaths = product.images
				.map((image) => image.toString())
				.where((image) => image.trim().isNotEmpty)
				.toList(growable: false);

		final textTheme = Theme.of(context).textTheme;
		final colorScheme = Theme.of(context).colorScheme;

		return Scaffold(
			appBar: AppBar(
				title: Text(
					'Product details',
					style: textTheme.titleLarge?.copyWith(
						fontFamily: 'CircularStd',
						fontWeight: FontWeight.w700,
					),
				),
				centerTitle: true,
				backgroundColor: colorScheme.primary,
			),
			body: SafeArea(
				child: Container(
					decoration: BoxDecoration(
						gradient: LinearGradient(
							begin: Alignment.topCenter,
							end: Alignment.bottomCenter,
							colors: [
								colorScheme.primary.withValues(alpha: 0.06),
								Theme.of(context).scaffoldBackgroundColor,
								colorScheme.surface.withValues(alpha: 0.45),
							],
						),
					),
					child: SingleChildScrollView(
						child: Padding(
							padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									_ProductGallery(
										imagePaths: imagePaths,
										pageController: _imagePageController,
										currentImageIndex: _currentImageIndex,
										onFullscreenTap: () => _openFullscreenGallery(imagePaths),
										onPageChanged: (index) {
											setState(() {
												_currentImageIndex = index;
											});
										},
									),
									const SizedBox(height: 14),
									Text(
										product.title,
										style: textTheme.headlineSmall?.copyWith(
											fontFamily: 'CircularStd',
											fontWeight: FontWeight.w700,
											color: colorScheme.inversePrimary,
										),
									),
									const SizedBox(height: 8),
									Wrap(
										spacing: 8,
										runSpacing: 8,
										children: [
											_TagPill(label: 'Sales: ${product.salesNumber}'),
											_TagPill(label: 'Code: ${product.productId}'),
										],
									),
									const SizedBox(height: 14),
									_PriceSection(product: product, hasDiscount: hasDiscount),
									const SizedBox(height: 16),
									_InfoCard(
										title: 'Description',
										child: Text(
											product.description,
											style: textTheme.bodyLarge?.copyWith(
												fontFamily: 'CircularStd',
												height: 1.45,
											),
										),
									),
									const SizedBox(height: 12),
									_InfoCard(
										title: 'Sizes',
										child: Wrap(
											spacing: 8,
											runSpacing: 8,
											children: _buildSizeChips(product.sizes, colorScheme),
										),
									),
									const SizedBox(height: 12),
									_InfoCard(
										title: 'Colors',
										child: Wrap(
											spacing: 10,
											runSpacing: 10,
											children: _buildColorItems(product.colors),
										),
									),
									const SizedBox(height: 12),
									_InfoCard(
										title: 'Quantity',
										child: Row(
											mainAxisAlignment: MainAxisAlignment.start,
											children: [
												_QuantityButton(
													icon: Icons.remove,
													onTap: _quantity > 1
															? () {
																setState(() {
																	_quantity--;
																});
															}
															: null,
												),
												Container(
													width: 64,
													height: 42,
													alignment: Alignment.center,
													margin: const EdgeInsets.symmetric(horizontal: 10),
													decoration: BoxDecoration(
														color: Theme.of(context).colorScheme.surface,
														borderRadius: BorderRadius.circular(12),
														border: Border.all(
															color: Theme.of(context)
																	.colorScheme
																	.primary
																	.withValues(alpha: 0.5),
														),
													),
													child: Text(
														'$_quantity',
														style: Theme.of(context).textTheme.titleMedium?.copyWith(
															fontFamily: 'CircularStd',
															fontWeight: FontWeight.w700,
														),
													),
												),
												_QuantityButton(
													icon: Icons.add,
													onTap: () {
														setState(() {
															_quantity++;
														});
													},
												),
											],
										),
									),
									const SizedBox(height: 18),
									const _SectionSeparator(),
									if (topSellingProducts.isNotEmpty) ...[
										const SizedBox(height: 8),
                              			const TopSellingTitle(),
										const SizedBox(height: 4),
										TopSellingCarousel(
											products: topSellingProducts,
											onTap: (selectedProduct) {
												Navigator.push(
													context,
													MaterialPageRoute(
														builder: (_) => ProductPage(
															product: selectedProduct,
															topSellingProducts: widget.topSellingProducts,
														),
													),
												);
											},
										),
									],
									const SizedBox(height: 12),
								],
							),
						),
					),
				),
			),
		);
	}

	List<Widget> _buildSizeChips(List<dynamic> sizes, ColorScheme colorScheme) {
		final normalized = sizes
				.map((size) => size.toString().trim())
				.where((size) => size.isNotEmpty)
				.toList(growable: false);

		if (normalized.isEmpty) {
			return [const Text('No sizes available')];
		}

		return normalized
				.map(
					(size) {
						final isSelected = _selectedSize == size;

						return Material(
							color: Colors.transparent,
							child: InkWell(
								onTap: () {
									setState(() {
										_selectedSize = isSelected ? null : size;
									});
								},
								borderRadius: BorderRadius.circular(999),
								child: AnimatedContainer(
									duration: const Duration(milliseconds: 180),
									padding: const EdgeInsets.symmetric(
										horizontal: 12,
										vertical: 8,
									),
									decoration: BoxDecoration(
										color: isSelected
												? colorScheme.primary.withValues(alpha: 0.24)
												: colorScheme.surface,
										borderRadius: BorderRadius.circular(999),
										border: Border.all(
											color: isSelected
													? colorScheme.primary
													: colorScheme.primary.withValues(alpha: 0.5),
											width: isSelected ? 1.5 : 1,
										),
									),
									child: Text(
										size,
										style: TextStyle(
											fontFamily: 'CircularStd',
											fontWeight:
													isSelected ? FontWeight.w700 : FontWeight.w600,
											color: colorScheme.inversePrimary,
										),
									),
								),
							),
						);
					},
				)
				.toList(growable: false);
	}

	List<Widget> _buildColorItems(List<ProductColorEntity> colors) {
		if (colors.isEmpty) {
			return [const Text('No colors available')];
		}

		return colors
				.map(
					(colorOption) {
						final colorKey = '${colorOption.title}_${colorOption.hexCode}';
						final isSelected = _selectedColorKey == colorKey;

						return Material(
							color: Colors.transparent,
							child: InkWell(
								onTap: () {
									setState(() {
										_selectedColorKey = isSelected ? null : colorKey;
									});
								},
								borderRadius: BorderRadius.circular(12),
								child: AnimatedContainer(
									duration: const Duration(milliseconds: 180),
									padding: const EdgeInsets.symmetric(
										horizontal: 10,
										vertical: 8,
									),
									decoration: BoxDecoration(
										color: const Color.fromARGB(255, 10, 32, 53),
										borderRadius: BorderRadius.circular(12),
										border: Border.all(
											color: isSelected
													? Theme.of(context).colorScheme.primary
													: Colors.white.withValues(alpha: 0.1),
											width: isSelected ? 1.6 : 1,
										),
									),
									child: Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Container(
												width: 18,
												height: 18,
												decoration: BoxDecoration(
													color: _parseColor(colorOption.hexCode),
													shape: BoxShape.circle,
													border: Border.all(color: Colors.white, width: 1.1),
												),
											),
											const SizedBox(width: 8),
											Text(
												colorOption.title,
												style: TextStyle(
													color: Colors.white,
													fontFamily: 'CircularStd',
													fontWeight:
															isSelected ? FontWeight.w700 : FontWeight.w500,
												),
											),
											if (isSelected) ...[
												const SizedBox(width: 6),
												Icon(
													Icons.check_circle,
													size: 16,
													color: Theme.of(context).colorScheme.primary,
												),
											],
										],
									),
								),
							),
						);
					},
				)
				.toList(growable: false);
	}

	Color _parseColor(String hexCode) {
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

		return Colors.grey;
	}

	Future<void> _openFullscreenGallery(List<String> imagePaths) async {
		if (imagePaths.isEmpty) {
			return;
		}

		final selectedIndex = await Navigator.push<int>(
			context,
			MaterialPageRoute(
				builder: (_) => _FullscreenProductGalleryPage(
					imagePaths: imagePaths,
					initialIndex: _currentImageIndex,
				),
			),
		);

		if (!mounted || selectedIndex == null) {
			return;
		}

		setState(() {
			_currentImageIndex = selectedIndex;
		});

		_imagePageController.jumpToPage(selectedIndex);
	}

}

class _ProductGallery extends StatelessWidget {
	final List<String> imagePaths;
	final PageController pageController;
	final int currentImageIndex;
	final VoidCallback onFullscreenTap;
	final ValueChanged<int> onPageChanged;

	const _ProductGallery({
		required this.imagePaths,
		required this.pageController,
		required this.currentImageIndex,
		required this.onFullscreenTap,
		required this.onPageChanged,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(10),
			decoration: BoxDecoration(
				color: const Color.fromARGB(255, 10, 32, 53),
				borderRadius: BorderRadius.circular(24),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.18),
						blurRadius: 22,
						offset: const Offset(0, 10),
					),
				],
			),
			child: Column(
				children: [
					SizedBox(
						height: 320,
						child: Stack(
							children: [
								ClipRRect(
									borderRadius: BorderRadius.circular(16),
									child: imagePaths.isEmpty
											? _placeholder()
											: PageView.builder(
													controller: pageController,
													onPageChanged: onPageChanged,
													itemCount: imagePaths.length,
													itemBuilder: (context, index) {
														return Image.network(
															ImageDisplayHelper.generateProductImagePath(
																imagePaths[index],
															),
															fit: BoxFit.cover,
															errorBuilder: (context, error, stackTrace) {
																return _placeholder();
															},
														);
													},
												),
								),
								Positioned(
									right: 10,
									bottom: 10,
									child: Material(
										color: Colors.transparent,
										child: InkWell(
											onTap: onFullscreenTap,
											borderRadius: BorderRadius.circular(999),
											child: Ink(
												padding: const EdgeInsets.all(8),
												decoration: BoxDecoration(
													color: Colors.black.withValues(alpha: 0.45),
													shape: BoxShape.circle,
												),
												child: const Icon(
													Icons.fullscreen,
													color: Colors.white,
													size: 30,
												),
											),
										),
									),
								),
							],
						),
					),
					const SizedBox(height: 10),
					if (imagePaths.length > 1)
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: List.generate(
								imagePaths.length,
								(index) => AnimatedContainer(
									duration: const Duration(milliseconds: 240),
									margin: const EdgeInsets.symmetric(horizontal: 3),
									width: currentImageIndex == index ? 20 : 8,
									height: 8,
									decoration: BoxDecoration(
										color: currentImageIndex == index
												? Theme.of(context).colorScheme.primary
												: Colors.white.withValues(alpha: 0.35),
										borderRadius: BorderRadius.circular(999),
									),
								),
							),
						),
				],
			),
		);
	}

	Widget _placeholder() {
		return Container(
			color: Colors.grey[300],
			alignment: Alignment.center,
			child: const Icon(Icons.broken_image_outlined, size: 52),
		);
	}
}

class _PriceSection extends StatelessWidget {
	final ProductEntity product;
	final bool hasDiscount;

	const _PriceSection({required this.product, required this.hasDiscount});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;

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
						'Price',
						style: textTheme.titleMedium?.copyWith(
							fontFamily: 'CircularStd',
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 8),
					Row(
						children: [
							Text(
								'\$${product.price.toStringAsFixed(2)}',
								style: textTheme.titleLarge?.copyWith(
									fontFamily: 'CircularStd',
									fontWeight: FontWeight.w700,
									decoration: hasDiscount ? TextDecoration.lineThrough : null,
									color: hasDiscount
											? const Color.fromARGB(255, 233, 75, 60)
											: Theme.of(context).colorScheme.inversePrimary,
								),
							),
							if (hasDiscount) ...[
								const SizedBox(width: 12),
								Text(
									'\$${product.discountedPrice.toStringAsFixed(2)}',
									style: textTheme.titleLarge?.copyWith(
										fontFamily: 'CircularStd',
										fontWeight: FontWeight.w800,
										color: Colors.green,
									),
								),
							],
						],
					),
					if (hasDiscount) ...[
						const SizedBox(height: 8),
						_TagPill(label: '${product.currentDiscount}% OFF'),
					],
				],
			),
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

class _QuantityButton extends StatelessWidget {
	final IconData icon;
	final VoidCallback? onTap;

	const _QuantityButton({required this.icon, required this.onTap});

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(12),
				child: Ink(
					width: 42,
					height: 42,
					decoration: BoxDecoration(
						color: onTap == null
								? Theme.of(context).colorScheme.surface.withValues(alpha: 0.45)
								: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
						borderRadius: BorderRadius.circular(12),
						border: Border.all(
							color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
						),
					),
					child: Icon(
						icon,
						color: onTap == null
								? Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.45)
								: Theme.of(context).colorScheme.inversePrimary,
					),
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

class _FullscreenProductGalleryPage extends StatefulWidget {
	final List<String> imagePaths;
	final int initialIndex;

	const _FullscreenProductGalleryPage({
		required this.imagePaths,
		required this.initialIndex,
	});

	@override
	State<_FullscreenProductGalleryPage> createState() =>
			_FullscreenProductGalleryPageState();
}

class _FullscreenProductGalleryPageState
		extends State<_FullscreenProductGalleryPage> {
	late final PageController _controller;
	late int _currentIndex;

	@override
	void initState() {
		super.initState();
		_currentIndex = widget.initialIndex;
		_controller = PageController(initialPage: widget.initialIndex);
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.black,
			body: SafeArea(
				child: Stack(
					children: [
						PageView.builder(
							controller: _controller,
							itemCount: widget.imagePaths.length,
							onPageChanged: (index) {
								setState(() {
									_currentIndex = index;
								});
							},
							itemBuilder: (context, index) {
								return InteractiveViewer(
									minScale: 1,
									maxScale: 4,
									child: Center(
										child: Image.network(
											ImageDisplayHelper.generateProductImagePath(
												widget.imagePaths[index],
											),
											fit: BoxFit.contain,
											errorBuilder: (context, error, stackTrace) {
												return const Icon(
													Icons.broken_image_outlined,
													color: Colors.white70,
													size: 56,
												);
											},
										),
									),
								);
							},
						),
						Positioned(
							top: 8,
							right: 8,
							child: IconButton(
								onPressed: () => Navigator.pop(context, _currentIndex),
								icon: const Icon(Icons.close, color: Colors.white, size: 30),
							),
						),
						if (widget.imagePaths.length > 1)
							Positioned(
								left: 0,
								right: 0,
								bottom: 20,
								child: Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: List.generate(
										widget.imagePaths.length,
										(index) => AnimatedContainer(
											duration: const Duration(milliseconds: 220),
											margin: const EdgeInsets.symmetric(horizontal: 3),
											width: _currentIndex == index ? 20 : 8,
											height: 8,
											decoration: BoxDecoration(
												color: _currentIndex == index
														? Colors.white
														: Colors.white.withValues(alpha: 0.35),
												borderRadius: BorderRadius.circular(999),
											),
										),
									),
								),
							),
					],
				),
			),
		);
	}
}

