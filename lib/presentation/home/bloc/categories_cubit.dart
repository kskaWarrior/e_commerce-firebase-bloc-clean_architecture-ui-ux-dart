import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesCubit extends Cubit<CategoriesState>{
  CategoriesCubit() : super(CategoriesInitial());

  void loadCategories() async {
    emit(CategoriesLoading());
    var data = await sl<GetCategoriesUseCase>().call(null);
    if (isClosed) return;

    data.fold(
      (error) {
        if (isClosed) return;
        emit(CategoriesError(error.toString()));
      },
      (categories) {
        if (isClosed) return;
        emit(CategoriesLoaded(categories));
      },
    );
  }
}