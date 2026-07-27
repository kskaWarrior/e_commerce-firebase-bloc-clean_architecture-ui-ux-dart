import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';

abstract class StoreFirebaseService {
  Future<Either> getStore();
  Future<Either> updateStoreBranding(
      Map<String, dynamic> branding, String name);
}

class StoreFirebaseServiceImpl implements StoreFirebaseService {
  StoreFirebaseServiceImpl(this._tenant);

  final TenantCollections _tenant;

  @override
  Future<Either> getStore() async {
    try {
      final doc = await _tenant.storeDoc.get();
      final data = doc.data();
      if (data == null) {
        return const Left('Store not found.');
      }
      return Right(<String, dynamic>{...data, 'id': doc.id});
    } catch (e) {
      return Left('Failed to load store: $e');
    }
  }

  @override
  Future<Either> updateStoreBranding(
      Map<String, dynamic> branding, String name) async {
    try {
      // Security rules only allow owners to change branding/name.
      // set+merge (not update) so the store doc is created on first save
      // when it hasn't been provisioned yet, rather than throwing not-found.
      await _tenant.storeDoc
          .set({'branding': branding, 'name': name}, SetOptions(merge: true));
      return const Right('Store updated successfully!');
    } catch (e) {
      return Left('Failed to update store: $e');
    }
  }
}
