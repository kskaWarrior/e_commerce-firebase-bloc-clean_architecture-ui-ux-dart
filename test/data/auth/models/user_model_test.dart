import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap normalizes Timestamp birthDate into date-only value', () {
    final map = <String, dynamic>{
      'id': '1',
      'email': 'john@doe.com',
      'address': 'A',
      'phone': '999',
      'name': 'John',
      'birthDate': Timestamp.fromDate(DateTime.utc(2000, 1, 15, 23, 10)),
      'gender': 'male',
      'profileImageUrl': 'img',
    };

    final model = UserModel.fromMap(map);

    expect(model.birthDate.year, 2000);
    expect(model.birthDate.month, 1);
    expect(model.birthDate.day, 15);
    expect(model.birthDate.hour, 0);
    expect(model.birthDate.minute, 0);
  });

  test('toEntity preserves key fields', () {
    final model = UserModel(
      id: '1',
      email: 'john@doe.com',
      address: 'A',
      phone: '999',
      name: 'John',
      birthDate: DateTime(2000, 1, 15),
      gender: 'male',
      profileImageUrl: 'img',
    );

    final entity = model.toEntity();

    expect(entity.id, model.id);
    expect(entity.email, model.email);
    expect(entity.birthDate, model.birthDate);
    expect(entity.profileImageUrl, model.profileImageUrl);
  });

  test('fromMap parses int birthDate as date-only UTC', () {
    final map = <String, dynamic>{
      'id': '2',
      'email': 'int@date.com',
      'birthDate': DateTime.utc(2001, 2, 3, 22, 10).millisecondsSinceEpoch,
    };

    final model = UserModel.fromMap(map);

    expect(model.birthDate.year, 2001);
    expect(model.birthDate.month, 2);
    expect(model.birthDate.day, 3);
    expect(model.birthDate.hour, 0);
  });

  test('fromMap parses string birthDate as date-only UTC', () {
    final map = <String, dynamic>{
      'id': '3',
      'email': 'string@date.com',
      'birthDate': '2002-03-04T19:30:00.000Z',
    };

    final model = UserModel.fromMap(map);

    expect(model.birthDate.year, 2002);
    expect(model.birthDate.month, 3);
    expect(model.birthDate.day, 4);
    expect(model.birthDate.hour, 0);
  });

  test('fromMap falls back when birthDate is invalid', () {
    final map = <String, dynamic>{
      'id': '4',
      'email': 'fallback@date.com',
      'birthDate': 'not-a-date',
    };

    final model = UserModel.fromMap(map);

    expect(model.birthDate.year, 2000);
    expect(model.birthDate.month, 1);
    expect(model.birthDate.day, 1);
  });

  test('toMap and json roundtrip keep values', () {
    final model = UserModel(
      id: '10',
      email: 'json@user.com',
      address: 'Street',
      phone: '321',
      name: 'Json User',
      birthDate: DateTime(2010, 5, 6),
      gender: 'female',
      profileImageUrl: 'img',
    );

    final mapped = model.toMap();
    final decoded = UserModel.fromJson(model.toJson());

    expect(mapped['id'], '10');
    expect(mapped['birthDate'], isA<int>());
    expect(decoded.email, 'json@user.com');
    expect(decoded.name, 'Json User');
    expect(decoded.profileImageUrl, 'img');
  });
}
