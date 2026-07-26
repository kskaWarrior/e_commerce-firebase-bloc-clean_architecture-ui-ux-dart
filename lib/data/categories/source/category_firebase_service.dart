import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class CategoryFirebaseService {

  Future<Either<String, List<Map<String, dynamic>>>> getCategories();

  // Admin operations
  Future<Either> upsertCategory(Map<String, dynamic> category);
  Future<Either> deleteCategory(String categoryId);
  Future<Either> uploadCategoryImage(
      Uint8List bytes, String contentType, String fileName);
}

class CategoryFirebaseServiceImpl implements CategoryFirebaseService {
  CategoryFirebaseServiceImpl(this._tenant);

  final TenantCollections _tenant;

  @override
  Future<Either<String, List<Map<String, dynamic>>>> getCategories() async {
    try {
      var categories = await _tenant.categories.get();
      return Right(categories.docs.map((doc) => doc.data()).toList());
    } on Exception catch (e) {
      return Left('Error fetching categories: $e');
    }
  }

  @override
  Future<Either> upsertCategory(Map<String, dynamic> category) async {
    try {
      final providedId = (category['id'] as String?)?.trim();
      final docRef = providedId == null || providedId.isEmpty
          ? _tenant.categories.doc()
          : _tenant.categories.doc(providedId);

      await docRef.set(<String, dynamic>{...category, 'id': docRef.id});
      return Right(docRef.id);
    } catch (e) {
      return Left('Save category failed: $e');
    }
  }

  @override
  Future<Either> deleteCategory(String categoryId) async {
    try {
      await _tenant.categories.doc(categoryId).delete();
      return const Right('Category deleted.');
    } catch (e) {
      return Left('Delete category failed: $e');
    }
  }

  @override
  Future<Either> uploadCategoryImage(
      Uint8List bytes, String contentType, String fileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('stores/${_tenant.storeId}/categories/images/$fileName');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final downloadUrl = await ref.getDownloadURL();
      return Right(downloadUrl);
    } catch (e) {
      return Left('Image upload failed: $e');
    }
  }
}
