import 'package:dartz/dartz.dart';

import 'dart:typed_data';

abstract class CategoryRepository {
  Future<Either> getCategories();

  // Admin operations
  Future<Either> upsertCategory(Map<String, dynamic> category);
  Future<Either> deleteCategory(String categoryId);
  Future<Either> uploadCategoryImage(
      Uint8List bytes, String contentType, String fileName);
}