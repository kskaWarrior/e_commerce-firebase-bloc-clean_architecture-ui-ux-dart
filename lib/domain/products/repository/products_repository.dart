import 'dart:typed_data';

import 'package:dartz/dartz.dart';

abstract class ProductsRepository {
  Future<Either> getTopSelling();
  Future<Either> getNewIn();
  Future<Either> getProductById(String productId);

  // Admin operations
  Future<Either> getAllProducts();
  Future<Either> upsertProduct(Map<String, dynamic> product);
  Future<Either> deleteProduct(String productId);
  Future<Either> uploadProductImage(
      Uint8List bytes, String contentType, String fileName);
}