import 'package:dartz/dartz.dart';

abstract class ProductsFirebaseService {
  Future<Either> getTopSelling();
}

class ProductsFirebaseServiceImpl implements ProductsFirebaseService {

  @override
  Future<Either> getTopSelling() async {
    throw UnimplementedError('getTopSelling() is not implemented');
  }
}