import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

abstract class ProductsDisplayState {}

class ProductsDisplayInitial extends ProductsDisplayState {}

class ProductsDisplayLoading extends ProductsDisplayState {}

class ProductsDisplayLoaded extends ProductsDisplayState {
  final List<ProductEntity> products;

  ProductsDisplayLoaded(this.products);
}

class ProductsDisplayError extends ProductsDisplayState {
  final String message;

  ProductsDisplayError(this.message);
}
