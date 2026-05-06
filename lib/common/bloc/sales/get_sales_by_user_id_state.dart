import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';

abstract class GetSalesByUserIdState {}

class GetSalesByUserIdInitial extends GetSalesByUserIdState {}

class GetSalesByUserIdLoading extends GetSalesByUserIdState {}

class GetSalesByUserIdLoaded extends GetSalesByUserIdState {
  final List<SalesEntity> sales;

  GetSalesByUserIdLoaded(this.sales);
}

class GetSalesByUserIdError extends GetSalesByUserIdState {
  final String message;

  GetSalesByUserIdError(this.message);
}
