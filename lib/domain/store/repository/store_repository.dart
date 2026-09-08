import 'package:dartz/dartz.dart';

abstract class StoreRepository {
  Future<Either> getStore();
  Future<Either> listStores();
  Future<Either> updateStoreBranding(Map<String, dynamic> branding, String name);
  Future<Either> updateStoreShipping(Map<String, dynamic> shipping);
}
