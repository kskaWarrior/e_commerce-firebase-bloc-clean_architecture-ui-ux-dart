import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories.state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesCubit extends Cubit<CategoriesState>{
  CategoriesCubit() : super(CategoriesInitial());

  void loadCategories() async {
    var data = await sl<GetCategoriesUseCase>().call(null);
    data.fold(
      (error) {
        emit(CategoriesError(error.toString()));
      },
      (categories) {
        emit(CategoriesLoaded(categories));
      },
    );
  }
}