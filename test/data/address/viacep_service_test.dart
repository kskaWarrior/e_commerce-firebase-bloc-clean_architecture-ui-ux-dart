import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/source/viacep_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ViaCepServiceImpl', () {
    test('returns AddressModel on success', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://viacep.com.br/ws/01310100/json/');
        return http.Response(
          '{"cep":"01310-100","logradouro":"Avenida Paulista",'
          '"bairro":"Bela Vista","localidade":"São Paulo","uf":"SP"}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = ViaCepServiceImpl(client: client);

      final result = await service.lookupCep('01310-100');

      expect(result.isRight(), isTrue);
      final address = result.getOrElse(() => null) as AddressEntity;
      expect(address.street, 'Avenida Paulista');
      expect(address.city, 'São Paulo');
    });

    test('returns Left when ViaCEP flags an unknown CEP', () async {
      final client =
          MockClient((request) async => http.Response('{"erro": true}', 200));
      final service = ViaCepServiceImpl(client: client);

      final result = await service.lookupCep('99999999');

      expect(result.isLeft(), isTrue);
    });

    test('returns Left for malformed CEP without calling the API', () async {
      final client = MockClient((request) async {
        fail('should not reach the network');
      });
      final service = ViaCepServiceImpl(client: client);

      final result = await service.lookupCep('123');

      expect(result.isLeft(), isTrue);
    });

    test('returns Left on non-200 response', () async {
      final client =
          MockClient((request) async => http.Response('oops', 500));
      final service = ViaCepServiceImpl(client: client);

      final result = await service.lookupCep('01310100');

      expect(result.isLeft(), isTrue);
    });
  });
}
