import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';
import 'package:http/http.dart' as http;

abstract class ViaCepService {
  Future<Either> lookupCep(String cep);
}

class ViaCepServiceImpl implements ViaCepService {
  ViaCepServiceImpl({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Either> lookupCep(String cep) async {
    final normalized = AddressEntity.normalizeCep(cep);
    if (normalized.length != 8) {
      return const Left('Invalid CEP.');
    }
    try {
      final response = await _client
          .get(Uri.parse('https://viacep.com.br/ws/$normalized/json/'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const Left('CEP lookup failed.');
      }
      final body = json.decode(response.body);
      if (body is! Map<String, dynamic> || body['erro'] == true) {
        return const Left('CEP not found.');
      }
      return Right(AddressModel.fromViaCep(body));
    } catch (_) {
      return const Left('CEP lookup failed.');
    }
  }
}
