import 'dart:typed_data';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_tenant.dart';

void main() {
  late FirebaseServiceImpl service;

  setUp(() {
    service = FirebaseServiceImpl(unavailableTenantCollections());
  });

  test('signIn returns Left when Firebase is unavailable in tests', () async {
    final result = await service.signIn(
      UserSigninReq(email: 'john@doe.com', password: '123456'),
    );

    expect(result.isLeft(), isTrue);
  });

  test('signUp returns Left when Firebase is unavailable in tests', () async {
    final result = await service.signUp(
      UserCreationReq(
        email: 'john@doe.com',
        password: '123456',
        name: 'John',
        phone: '999999',
        address: 'Street 1',
        gender: 'Male',
        birthDate: DateTime(1995, 1, 1),
      ),
    );

    expect(result.isLeft(), isTrue);
  });

  test('updateUser returns Left when Firebase is unavailable in tests', () async {
    final result = await service.updateUser(
      UserCreationReq(
        email: 'john@doe.com',
        name: 'John',
        phone: '999999',
        address: 'Street 1',
        gender: 'Male',
        birthDate: DateTime(1995, 1, 1),
      ),
    );

    expect(result.isLeft(), isTrue);
  });

  test('sendPasswordEmailResetUseCase returns Left without Firebase', () async {
    final result = await service.sendPasswordEmailResetUseCase('john@doe.com');

    expect(result.isLeft(), isTrue);
  });

  test('uploadProfileImage returns Left without signed user/Firebase', () async {
    final result = await service.uploadProfileImage(
      UploadProfileImageParams(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
      ),
    );

    expect(result.isLeft(), isTrue);
  });

  test('signOut returns Left without Firebase', () async {
    final result = await service.signOut();

    expect(result.isLeft(), isTrue);
  });

  test('isLoggedIn returns false without Firebase app', () async {
    final result = await service.isLoggedIn();

    expect(result, isFalse);
  });

  test('getUser returns Left without Firebase app/user', () async {
    final result = await service.getUser();

    expect(result.isLeft(), isTrue);
  });
}
