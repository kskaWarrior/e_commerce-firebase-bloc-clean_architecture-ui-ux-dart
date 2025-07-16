import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class GetTopSellingProductsUseCase implements UseCase<Either, void> {
  @override
  Future<Either> call(params) async {
    return await sl<ProductsRepository>().getTopSelling();
  }
}