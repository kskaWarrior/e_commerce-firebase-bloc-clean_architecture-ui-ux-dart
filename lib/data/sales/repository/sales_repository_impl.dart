import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/models/sales_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/source/sales_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/repository/sales_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class SalesRepositoryImpl extends SalesRepository {
  @override
  Future<Either> registerSale(SalesEntity sale) async {
    final model = SalesModel.fromEntity(sale);
    return await sl<SalesFirebaseService>().registerSale(model.toMap());
  }
}