import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserEntity buildEntity() {
    return UserEntity(
      id: 'u1',
      email: 'john@doe.com',
      address: 'Street 1',
      phone: '999999',
      name: 'John',
      birthDate: DateTime(1995, 1, 10),
      gender: 'Male',
      profileImageUrl: 'https://img',
    );
  }

  test('toMap returns expected scalar values', () {
    final user = buildEntity();

    final map = user.toMap();

    expect(map['id'], 'u1');
    expect(map['email'], 'john@doe.com');
    expect(map['address'], 'Street 1');
    expect(map['phone'], '999999');
    expect(map['name'], 'John');
    expect(map['gender'], 'Male');
    expect(map['profileImageUrl'], 'https://img');
    expect(map['birthDate'], user.birthDate.millisecondsSinceEpoch);
  });

  test('fromMap maps timestamp birthDate and defaults missing strings', () {
    final user = UserEntity.fromMap({
      'id': 'u1',
      'email': 'john@doe.com',
      'address': 'Street 1',
      'phone': '999999',
      'name': 'John',
      'birthDate': Timestamp.fromDate(DateTime(1995, 1, 10)),
      'gender': 'Male',
    });

    expect(user.id, 'u1');
    expect(user.profileImageUrl, '');
    expect(user.birthDate, DateTime(1995, 1, 10));
  });

  test('toJson serializes map content', () {
    final user = buildEntity();

    final jsonString = user.toJson();
    final decoded = json.decode(jsonString) as Map<String, dynamic>;

    expect(decoded['id'], 'u1');
    expect(decoded['email'], 'john@doe.com');
    expect(decoded['birthDate'], user.birthDate.millisecondsSinceEpoch);
  });
}
