import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/models/color_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

class ProductModel {
  final String categoryId;
  final List<ProductColorModel> colors;
  final Timestamp createdDate;
  final num discountedPrice;
  final String gender;
  final List<dynamic> images;
  final num price;
  final List<String> sizes;
  final String title;
  final String productId;
  final int salesNumber;
  final String description;

  ProductModel({required this.categoryId, required this.colors, required this.createdDate, required this.discountedPrice, required this.gender, required this.images, required this.price, required this.sizes, required this.title, required this.productId, required this.salesNumber, required this.description});


  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      categoryId: map['categoryId'] as String,
      colors: List<ProductColorModel>.from((map['colors'] as List)
          .map<ProductColorModel>((x) => ProductColorModel.fromMap(x as Map<String,dynamic>))
          .toList()),
      createdDate:map['createdDate'] as Timestamp,
      discountedPrice: map['discountedPrice'] as num,
      gender: map['gender'] as String,
      images: List<dynamic>.from(map['images'] as List<dynamic>).cast<String>(),
      price: map['price'] as num,
      sizes: List<dynamic>.from(map['sizes'] as List<dynamic>).cast<String>(),
      title: map['title'] as String,
      productId: map['productId'] as String,
      salesNumber: map['salesNumber'] as int,
      description: map['description'] as String,
    );
  }
}

extension ProductXModel on ProductModel {
  ProductEntity toEntity() {
    return ProductEntity(
      categoryId: categoryId,
      colors: colors.map((e) => e.toEntity()).toList(),
      createdDate: createdDate,
      discountedPrice: discountedPrice,
      gender: gender,
      images: images,
      price: price,
      sizes: sizes,
      title: title,
      productId: productId,
      salesNumber: salesNumber,
      description: description
    );
  }
}
