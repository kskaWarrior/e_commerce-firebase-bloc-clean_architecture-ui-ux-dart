import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';

class ProductEntity {
  final String categoryId;
  final List<ProductColorEntity> colors;
  final Timestamp createdDate;
  final num discountedPrice;
  final String gender;
  final List<dynamic> images;
  final num price;
  final List<dynamic> sizes;
  final String title;
  final String productId;
  final int salesNumber;
  final String description;

  ProductEntity({required this.categoryId, required this.colors, required this.createdDate, required this.discountedPrice, required this.gender, required this.images, required this.price, required this.sizes, required this.title, required this.productId, required this.salesNumber, required this.description});

}
