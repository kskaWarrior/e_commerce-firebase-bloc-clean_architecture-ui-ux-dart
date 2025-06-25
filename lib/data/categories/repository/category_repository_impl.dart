import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/models/categories_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/source/category_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/repository/category_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class CategoryRepositoryImpl extends CategoryRepository{

  @override
  Future<Either> getCategories() async {
    var categories = await sl<CategoryFirebaseService>().getCategories();
    return categories.fold(
      (error) {
        return Left(error);
      },
      (categories) {
        return Right(
          List.from(categories).map(
            (category) => CategoriesModel.fromMap(category as Map<String, dynamic>).toEntity(),
          ).toList(),
          
          //List.from(
          //  categories.map((category) => CategoriesModel.fromMap(category).toEntity()).toList(),
          //),
          
          //CategoriesModel.fromMap(categories as Map<String, dynamic>).toEntity(),
        );
      },
    );
  }
}