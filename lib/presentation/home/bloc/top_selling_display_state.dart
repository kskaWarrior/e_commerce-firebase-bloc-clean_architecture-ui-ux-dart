import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

abstract class TopSellingDisplayState {}

class TopSellingDisplayInitial extends TopSellingDisplayState {}

class TopSellingDisplayLoading extends TopSellingDisplayState {}

class TopSellingDisplayLoaded extends TopSellingDisplayState {
  final List<ProductEntity> products;

  TopSellingDisplayLoaded(this.products);
}

class TopSellingDisplayError extends TopSellingDisplayState {
  final String message;

  TopSellingDisplayError(this.message);
}
