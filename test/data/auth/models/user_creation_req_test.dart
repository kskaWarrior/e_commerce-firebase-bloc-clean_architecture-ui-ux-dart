import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson maps fields including birthDate timestamp', () {
    final req = UserCreationReq(
      id: 'u1',
      email: 'john@doe.com',
      password: 'secret',
      name: 'John',
      phone: '123',
      address: 'Street',
      birthDate: DateTime(2000, 1, 1),
      gender: 'male',
    );

    final json = req.toJson();

    expect(json['id'], 'u1');
    expect(json['email'], 'john@doe.com');
    expect(json['name'], 'John');
    expect(json['birthDate'], isA<Timestamp>());
  });

  test('fromJson parses values including timestamp date', () {
    final json = {
      'id': 'u1',
      'email': 'john@doe.com',
      'name': 'John',
      'phone': '123',
      'address': 'Street',
      'birthDate': Timestamp.fromDate(DateTime(2000, 1, 1)),
      'gender': 'male',
    };

    final req = UserCreationReq.fromJson(json);

    expect(req.id, 'u1');
    expect(req.email, 'john@doe.com');
    expect(req.birthDate?.year, 2000);
    expect(req.gender, 'male');
  });
}
