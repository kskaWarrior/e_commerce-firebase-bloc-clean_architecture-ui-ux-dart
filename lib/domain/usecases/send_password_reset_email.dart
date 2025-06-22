import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class SendPasswordEmailResetUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call(String ? params) async {
    return await sl<AuthRepository>().sendPasswordEmailResetUseCase(params!);
  }
}