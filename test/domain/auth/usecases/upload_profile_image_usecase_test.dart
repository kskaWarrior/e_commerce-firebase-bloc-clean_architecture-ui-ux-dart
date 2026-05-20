import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late UploadProfileImageUseCase useCase;

  setUp(() {
    sl.reset();
    mockAuthRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockAuthRepository);
    useCase = UploadProfileImageUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('uploads profile image with given params', () async {
    final params = UploadProfileImageParams(
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/png',
    );

    when(() => mockAuthRepository.uploadProfileImage(params))
        .thenAnswer((_) async => const Right('https://img'));

    final result = await useCase.call(params);

    expect(result, const Right('https://img'));
    verify(() => mockAuthRepository.uploadProfileImage(params)).called(1);
  });

  test('returns failure when upload fails', () async {
    final params = UploadProfileImageParams(
      bytes: Uint8List.fromList([1]),
      contentType: 'image/jpeg',
    );

    when(() => mockAuthRepository.uploadProfileImage(params))
        .thenAnswer((_) async => Left(Failure(error: 'upload failed')));

    final result = await useCase.call(params);

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f.toString(), (_) => ''), 'error: upload failed');
  });
}
