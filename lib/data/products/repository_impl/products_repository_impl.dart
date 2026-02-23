import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/models/product_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/source/products_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class ProductsRepositoryImpl extends ProductsRepository {
  @override
  Future<Either> getTopSelling() async {
    final data = await sl<ProductsFirebaseService>().getTopSelling();
    return data.fold(
      (error) => Left(error),
      (products) => Right(
        List.from(products)
            .map((e) => ProductModel.fromMap(e).toEntity())
            .toList(),
      ),
    );
  }
  
  @override
  Future<Either> getNewIn() {
    // TODO: implement getNewIn
    throw UnimplementedError();
  }
}
