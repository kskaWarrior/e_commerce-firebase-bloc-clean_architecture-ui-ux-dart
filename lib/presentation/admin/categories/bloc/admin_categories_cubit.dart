import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/delete_category_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AdminCategoriesState {}

class AdminCategoriesLoading extends AdminCategoriesState {}

class AdminCategoriesLoaded extends AdminCategoriesState {
  AdminCategoriesLoaded(this.categories);
  final List<CategoriesEntity> categories;
}

class AdminCategoriesError extends AdminCategoriesState {
  AdminCategoriesError(this.message);
  final String message;
}

class AdminCategoriesCubit extends Cubit<AdminCategoriesState> {
  AdminCategoriesCubit({
    required this.getCategoriesUseCase,
    required this.deleteCategoryUseCase,
  }) : super(AdminCategoriesLoading());

  final GetCategoriesUseCase getCategoriesUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;

  Future<void> load() async {
    emit(AdminCategoriesLoading());
    final result = await getCategoriesUseCase.call(null);
    if (isClosed) return;
    result.fold(
      (error) => emit(AdminCategoriesError(error.toString())),
      (categories) =>
          emit(AdminCategoriesLoaded(List<CategoriesEntity>.from(categories))),
    );
  }

  Future<String?> delete(String categoryId) async {
    final result = await deleteCategoryUseCase.call(categoryId);
    return result.fold(
      (error) => error.toString(),
      (_) {
        load();
        return null;
      },
    );
  }
}
