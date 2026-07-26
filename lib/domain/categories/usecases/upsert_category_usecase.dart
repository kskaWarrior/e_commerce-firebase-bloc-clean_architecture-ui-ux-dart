import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/repository/category_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class UpsertCategoryUseCase implements UseCase<Either, Map<String, dynamic>> {
  @override
  Future<Either> call(Map<String, dynamic> params) async {
    return await sl<CategoryRepository>().upsertCategory(params);
  }
}
