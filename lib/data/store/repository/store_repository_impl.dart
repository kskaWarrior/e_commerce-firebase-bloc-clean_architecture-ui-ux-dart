import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/store/models/store_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/store/source/store_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/repository/store_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class StoreRepositoryImpl extends StoreRepository {
  @override
  Future<Either> getStore() async {
    try {
      final data = await sl<StoreFirebaseService>().getStore();
      return data.fold(
        (error) => Left(error),
        (store) => Right(StoreModel.fromMap(store).toEntity()),
      );
    } catch (e) {
      return Left('Failed to parse store: $e');
    }
  }

  @override
  Future<Either> updateStoreBranding(
      Map<String, dynamic> branding, String name) async {
    return await sl<StoreFirebaseService>().updateStoreBranding(branding, name);
  }
}
