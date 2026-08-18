import 'package:dartz/dartz.dart';

abstract class AddressRepository {
  Future<Either> lookupCep(String cep);
}
