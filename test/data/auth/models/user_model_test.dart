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
}
