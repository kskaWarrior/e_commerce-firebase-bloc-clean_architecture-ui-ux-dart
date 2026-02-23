import 'package:dartz/dartz.dart';

abstract class ProductsRepository {
  Future<Either> getTopSelling();
  Future<Either> getNewIn();
}