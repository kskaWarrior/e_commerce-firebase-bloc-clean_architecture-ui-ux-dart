import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class ProductsFirebaseService {
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

class ProductsFirebaseServiceImpl implements ProductsFirebaseService {
  ProductsFirebaseServiceImpl(this._tenant);

  final TenantCollections _tenant;

  @override
  Future<Either> getTopSelling() async {
    try {
      var data = await _tenant.products
      .where('salesNumber', isGreaterThanOrEqualTo: 20)
      .get();
      return Right(data.docs.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      return Left(
          'Top selling query failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('Top selling query failed: $e');
    }
  }

  @override
  Future<Either> getNewIn() async {
    try {
      var data = await _tenant.products
          .where('createdDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 1000))))
          .orderBy('createdDate', descending: true)
      .get();
      return Right(data.docs.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      return Left(
          'New in query failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('New in query failed: $e');
    }
  }

  @override
  Future<Either> getAllProducts() async {
    try {
      final data = await _tenant.products.orderBy('title').get();
      return Right(data.docs.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      return Left(
          'Products query failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('Products query failed: $e');
    }
  }

  @override
  Future<Either> upsertProduct(Map<String, dynamic> product) async {
    try {
      final providedId = (product['id'] as String?)?.trim();
      final docRef = providedId == null || providedId.isEmpty
          ? _tenant.products.doc()
          : _tenant.products.doc(providedId);

      await docRef.set(
        <String, dynamic>{
          ...product,
          'id': docRef.id,
          'productId': (product['productId'] ?? docRef.id).toString(),
          'createdDate': product['createdDate'] ?? Timestamp.now(),
          'salesNumber': product['salesNumber'] ?? 0,
        },
        SetOptions(merge: true),
      );
      return Right(docRef.id);
    } on FirebaseException catch (e) {
      return Left(
          'Save product failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('Save product failed: $e');
    }
  }

  @override
  Future<Either> deleteProduct(String productId) async {
    try {
      await _tenant.products.doc(productId).delete();
      return const Right('Product deleted.');
    } on FirebaseException catch (e) {
      return Left(
          'Delete product failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('Delete product failed: $e');
    }
  }

  @override
  Future<Either> uploadProductImage(
      Uint8List bytes, String contentType, String fileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('stores/${_tenant.storeId}/products/images/$fileName');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final downloadUrl = await ref.getDownloadURL();
      return Right(downloadUrl);
    } on FirebaseException catch (e) {
      return Left(
          'Image upload failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('Image upload failed: $e');
    }
  }

  @override
  Future<Either> getProductById(String productId) async {
    try {
      final snapshot = await _tenant.products
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return Right(snapshot.docs.first.data());
      }

      final byDocId = await _tenant.products.doc(productId).get();
      final data = byDocId.data();
      if (data != null) {
        return Right(data);
      }
      return const Left('Product not found.');
    } on FirebaseException catch (e) {
      return Left(
          'Product lookup failed [${e.code}]: ${e.message ?? 'unknown error'}');
    } catch (e) {
      return Left('Product lookup failed: $e');
    }
  }
}
