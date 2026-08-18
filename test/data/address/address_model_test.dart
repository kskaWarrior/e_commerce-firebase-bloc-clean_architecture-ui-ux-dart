import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressEntity.normalizeCep', () {
    test('strips mask characters', () {
      expect(AddressEntity.normalizeCep('01310-100'), '01310100');
      expect(AddressEntity.normalizeCep('01.310-100'), '01310100');
      expect(AddressEntity.normalizeCep('01310100'), '01310100');
    });
  });

  group('AddressModel', () {
    test('fromViaCep maps ViaCEP field names', () {
      final model = AddressModel.fromViaCep({
        'cep': '01310-100',
        'logradouro': 'Avenida Paulista',
        'bairro': 'Bela Vista',
        'localidade': 'São Paulo',
        'uf': 'SP',
      });

      expect(model.cep, '01310100');
      expect(model.street, 'Avenida Paulista');
      expect(model.neighborhood, 'Bela Vista');
      expect(model.city, 'São Paulo');
      expect(model.state, 'SP');
    });

    test('toMap/fromMap round-trips', () {
      const model = AddressModel(
        cep: '01310100',
        street: 'Avenida Paulista',
        number: '1000',
        complement: 'ap 12',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
      );

      final restored = AddressModel.fromMap(model.toMap());
      expect(restored.cep, model.cep);
      expect(restored.street, model.street);
      expect(restored.number, model.number);
      expect(restored.complement, model.complement);
      expect(restored.neighborhood, model.neighborhood);
      expect(restored.city, model.city);
      expect(restored.state, model.state);
    });

    test('isComplete requires cep, street, city and state', () {
      const complete = AddressModel(
        cep: '01310100',
        street: 'Avenida Paulista',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
      );
      expect(complete.isComplete, isTrue);

      const missingStreet = AddressModel(
        cep: '01310100',
        street: '',
        neighborhood: '',
        city: 'São Paulo',
        state: 'SP',
      );
      expect(missingStreet.isComplete, isFalse);

      const shortCep = AddressModel(
        cep: '0131010',
        street: 'Avenida Paulista',
        neighborhood: '',
        city: 'São Paulo',
        state: 'SP',
      );
      expect(shortCep.isComplete, isFalse);
    });

    test('toDisplayString joins the filled parts', () {
      const model = AddressModel(
        cep: '01310100',
        street: 'Avenida Paulista',
        number: '1000',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
      );
      expect(
        model.toDisplayString(),
        'Avenida Paulista, 1000, Bela Vista, São Paulo, SP, CEP 01310100',
      );
    });
  });
}
