import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/delete_product_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_all_products_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AdminProductsState {}

class AdminProductsLoading extends AdminProductsState {}

class AdminProductsLoaded extends AdminProductsState {
  AdminProductsLoaded(this.products);
  final List<ProductEntity> products;
}

class AdminProductsError extends AdminProductsState {
  AdminProductsError(this.message);
  final String message;
}

class AdminProductsCubit extends Cubit<AdminProductsState> {
  AdminProductsCubit({
    required this.getAllProductsUseCase,
    required this.deleteProductUseCase,
  }) : super(AdminProductsLoading());

  final GetAllProductsUseCase getAllProductsUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  Future<void> load() async {
    emit(AdminProductsLoading());
    final result = await getAllProductsUseCase.call(null);
    if (isClosed) return;
    result.fold(
      (error) => emit(AdminProductsError(error.toString())),
      (products) =>
          emit(AdminProductsLoaded(List<ProductEntity>.from(products))),
    );
  }

  Future<String?> delete(String productId) async {
    final result = await deleteProductUseCase.call(productId);
    return result.fold(
      (error) => error.toString(),
      (_) {
        load();
        return null;
      },
    );
  }
}
