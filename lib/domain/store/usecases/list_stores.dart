import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/repository/store_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

/// Lists every store on the platform. Only the platform owner (`super`
/// claim) can read this — rules deny it to owners and shoppers.
class ListStoresUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call(params) async {
    return await sl<StoreRepository>().listStores();
  }
}
