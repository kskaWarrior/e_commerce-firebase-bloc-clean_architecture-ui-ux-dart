import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/category_carousel.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/header.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/new_in_title.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/search_box.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/search_carousel.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/top_selling_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductEntity buildProduct({required String id, required String title, required String categoryId}) {
    return ProductEntity(
      categoryName: 'Category',
      id: id,
      currentDiscount: 0,
      categoryId: categoryId,
      colors: [
        ProductColorEntity(title: 'Red', hexCode: '#FF0000'),
      ],
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      discountedPrice: 10,
      gender: 'unisex',
      images: const ['image.jpg'],
      price: 20,
      sizes: const ['M'],
      title: title,
      productId: id,
      salesNumber: 10,
      description: 'desc',
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('SearchBox calls onChanged', (tester) async {
    String? captured;

    await tester.pumpWidget(wrap(SearchBox(onChanged: (value) => captured = value)));
    await tester.enterText(find.byType(TextField), 'shoe');

    expect(captured, 'shoe');
  });

  testWidgets('titles render expected text', (tester) async {
    await tester.pumpWidget(wrap(const Column(children: [NewInTitle(), TopSellingTitle()])));

    expect(find.text('New In'), findsNWidgets(3));
    expect(find.text('Top Selling'), findsNWidgets(3));
  });

  testWidgets('ProductCard shows title and prices', (tester) async {
    final product = buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1');

    await tester.pumpWidget(wrap(ProductCard(product: product)));

    expect(find.text('Sneaker'), findsOneWidget);
    expect(find.text('Price: '), findsOneWidget);
    expect(find.text('Discounted: '), findsOneWidget);
  });

  testWidgets('TopSellingCarousel shows empty message when no products', (tester) async {
    await tester.pumpWidget(wrap(const TopSellingCarousel(products: [])));

    expect(find.text('No top selling products found'), findsOneWidget);
  });

  testWidgets('TopSellingCarousel renders products when list is not empty',
      (tester) async {
    final products = [
      buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1')
    ];

    await tester.pumpWidget(wrap(TopSellingCarousel(products: products)));
    await tester.pump();

    expect(find.text('Sneaker'), findsOneWidget);
  });

  testWidgets('NewInCarousel shows empty message when no products', (tester) async {
    await tester.pumpWidget(wrap(const NewInCarousel(products: [])));

    expect(find.text('No new products found'), findsOneWidget);
  });

  testWidgets('NewInCarousel renders products when list is not empty',
      (tester) async {
    final products = [
      buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1')
    ];

    await tester.pumpWidget(wrap(NewInCarousel(products: products)));
    await tester.pump();

    expect(find.text('Sneaker'), findsOneWidget);
  });

  testWidgets('SearchCarousel filters by query', (tester) async {
    final products = [
      buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1'),
      buildProduct(id: 'p2', title: 'Hat', categoryId: 'c2'),
    ];

    await tester.pumpWidget(wrap(SearchCarousel(query: 'sne', products: products)));

    expect(find.text('Sneaker'), findsOneWidget);
    expect(find.text('Hat'), findsNothing);
  });

  testWidgets('SearchCarousel shows empty message when no products match query',
      (tester) async {
    final products = [
      buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1'),
    ];

    await tester
        .pumpWidget(wrap(SearchCarousel(query: 'zzz', products: products)));
    await tester.pump();

    expect(find.text('No products match your search'), findsOneWidget);
  });

  testWidgets('CategoryCarousel shows empty message when category has no products', (tester) async {
    final products = [buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1')];

    await tester.pumpWidget(wrap(CategoryCarousel(categoryId: 'c2', products: products)));

    expect(find.text('No products found for this category'), findsOneWidget);
  });

  testWidgets('CategoryCarousel renders products for selected category',
      (tester) async {
    final products = [
      buildProduct(id: 'p1', title: 'Sneaker', categoryId: 'c1')
    ];

    await tester.pumpWidget(
        wrap(CategoryCarousel(categoryId: 'c1', products: products)));
    await tester.pump();

    expect(find.text('Sneaker'), findsOneWidget);
  });

  testWidgets('CategoriesWidget displays titles and handles taps', (tester) async {
    CategoriesEntity? tapped;
    final categories = [
      CategoriesEntity(id: 'c1', title: 'Shoes', image: 'shoes.png'),
      CategoriesEntity(id: 'c2', title: 'Hats', image: 'hats.png'),
    ];

    await tester.pumpWidget(
      wrap(
        CategoriesWidget(
          categories: categories,
          onTap: (category) => tapped = category,
        ),
      ),
    );

    expect(find.text('Shoes'), findsOneWidget);
    expect(find.text('Hats'), findsOneWidget);

    await tester.tap(find.text('Shoes'));
    await tester.pump();

    expect(tapped?.id, 'c1');
  });

  testWidgets('HomeHeader triggers menu and cart callbacks', (tester) async {
    var menuTapped = false;
    var cartTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: HomeHeader(
            onMenuTap: () => menuTapped = true,
            onCartTap: () => cartTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pump();

    expect(menuTapped, isTrue);
    expect(cartTapped, isTrue);
  });
}
