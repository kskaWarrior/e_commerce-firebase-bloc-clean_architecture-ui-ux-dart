import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/source/viacep_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/repository/address_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class AddressRepositoryImpl implements AddressRepository {
  @override
  Future<Either> lookupCep(String cep) async {
    return await sl<ViaCepService>().lookupCep(cep);
  }
}
