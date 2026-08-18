import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/shipping_config_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/repository/store_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class UpdateStoreShippingUseCase implements UseCase<Either, ShippingConfig> {
  @override
  Future<Either> call(ShippingConfig params) async {
    return await sl<StoreRepository>().updateStoreShipping(params.toMap());
  }
}
