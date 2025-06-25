import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';

abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<CategoriesEntity> categories;

  CategoriesLoaded(this.categories);
}

class CategoriesError extends CategoriesState {
  final String message;

  CategoriesError(this.message);
}