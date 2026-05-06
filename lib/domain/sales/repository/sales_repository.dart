import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';

abstract class SalesRepository {
  Future<Either> registerSale(SalesEntity sale);
}