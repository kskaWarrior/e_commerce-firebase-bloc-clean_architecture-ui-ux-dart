import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/repository/store_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class UpdateStoreBrandingParams {
  final Map<String, dynamic> branding;
  final String name;

  UpdateStoreBrandingParams({required this.branding, required this.name});
}

class UpdateStoreBrandingUseCase
    implements UseCase<Either, UpdateStoreBrandingParams> {
  @override
  Future<Either> call(UpdateStoreBrandingParams params) async {
    return await sl<StoreRepository>()
        .updateStoreBranding(params.branding, params.name);
  }
}
