import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';

class AddressModel extends AddressEntity {
  const AddressModel({
    required super.cep,
    required super.street,
    super.number,
    super.complement,
    required super.neighborhood,
    required super.city,
    required super.state,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cep': cep,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      cep: AddressEntity.normalizeCep((map['cep'] ?? '').toString()),
      street: (map['street'] ?? '').toString(),
      number: (map['number'] ?? '').toString(),
      complement: (map['complement'] ?? '').toString(),
      neighborhood: (map['neighborhood'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
    );
  }

  /// ViaCEP payload: logradouro/bairro/localidade/uf.
  factory AddressModel.fromViaCep(Map<String, dynamic> map) {
    return AddressModel(
      cep: AddressEntity.normalizeCep((map['cep'] ?? '').toString()),
      street: (map['logradouro'] ?? '').toString(),
      neighborhood: (map['bairro'] ?? '').toString(),
      city: (map['localidade'] ?? '').toString(),
      state: (map['uf'] ?? '').toString(),
    );
  }

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      cep: entity.cep,
      street: entity.street,
      number: entity.number,
      complement: entity.complement,
      neighborhood: entity.neighborhood,
      city: entity.city,
      state: entity.state,
    );
  }
}
