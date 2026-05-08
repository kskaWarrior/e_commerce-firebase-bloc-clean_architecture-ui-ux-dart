import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsDisplayCubit extends Cubit<ProductsDisplayState> {
  final UseCase useCase;
  ProductsDisplayCubit(this.useCase) : super(ProductsDisplayInitial());


  void displayProducts() async {
    emit(ProductsDisplayLoading());
    try {
      final data = await useCase.call(null);
      data.fold(
        (error) => emit(ProductsDisplayError(error.toString())),
        (products) => emit(ProductsDisplayLoaded(products)),
      );
    } catch (e) {
      emit(ProductsDisplayError('Failed to load products: $e'));
    }
  }

}