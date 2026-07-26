import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/repository/sales_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class UpdateSaleStatusParams {
  final String saleId;
  final String status;

  UpdateSaleStatusParams({required this.saleId, required this.status});
}

class UpdateSaleStatusUseCase implements UseCase<Either, UpdateSaleStatusParams> {
  @override
  Future<Either> call(UpdateSaleStatusParams params) async {
    return await sl<SalesRepository>()
        .updateSaleStatus(params.saleId, params.status);
  }
}
