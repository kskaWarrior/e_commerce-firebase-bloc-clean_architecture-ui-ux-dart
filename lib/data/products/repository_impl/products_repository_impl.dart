import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/models/product_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/source/products_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class ProductsRepositoryImpl extends ProductsRepository {
  @override
  Future<Either> getTopSelling() async {
    try {
      final data = await sl<ProductsFirebaseService>().getTopSelling();
      return data.fold(
        (error) => Left(error),
        (products) => Right(
          List.from(products)
              .map((e) => ProductModel.fromMap(e).toEntity())
              .toList(),
        ),
      );
    } catch (e) {
      return Left('Failed to parse top selling products: $e');
    }
  }
  
  @override
  Future<Either> getNewIn() async {
    try {
      final data = await sl<ProductsFirebaseService>().getNewIn();
      return data.fold(
        (error) => Left(error),
        (products) => Right(
          List.from(products)
              .map((e) => ProductModel.fromMap(e).toEntity())
              .toList(),
        ),
      );
    } catch (e) {
      return Left('Failed to parse new in products: $e');
    }
  }

  @override
  Future<Either> getProductById(String productId) async {
    try {
      final data = await sl<ProductsFirebaseService>().getProductById(productId);
      return data.fold(
        (error) => Left(error),
        (product) => Right(ProductModel.fromMap(product).toEntity()),
      );
    } catch (e) {
      return Left('Failed to parse product: $e');
    }
  }

  @override
  Future<Either> getAllProducts() async {
    try {
      final data = await sl<ProductsFirebaseService>().getAllProducts();
      return data.fold(
        (error) => Left(error),
        (products) => Right(
          List.from(products)
              .map((e) => ProductModel.fromMap(e).toEntity())
              .toList(),
        ),
      );
    } catch (e) {
      return Left('Failed to parse products: $e');
    }
  }

  @override
  Future<Either> upsertProduct(Map<String, dynamic> product) async {
    return await sl<ProductsFirebaseService>().upsertProduct(product);
  }

  @override
  Future<Either> deleteProduct(String productId) async {
    return await sl<ProductsFirebaseService>().deleteProduct(productId);
  }

  @override
  Future<Either> uploadProductImage(
      Uint8List bytes, String contentType, String fileName) async {
    return await sl<ProductsFirebaseService>()
        .uploadProductImage(bytes, contentType, fileName);
  }
}
