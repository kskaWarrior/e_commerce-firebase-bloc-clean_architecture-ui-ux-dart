import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsDisplayCubit extends Cubit<ProductsDisplayState> {
  final UseCase useCase;
  ProductsDisplayCubit(this.useCase) : super(ProductsDisplayInitial());


  void displayProducts() async {
    emit(ProductsDisplayLoading());
    var data = await useCase.call(null);
    data.fold(
      (error) => emit(ProductsDisplayError(error)),
      (products) => emit(ProductsDisplayLoaded(products)),
    );
  }

}