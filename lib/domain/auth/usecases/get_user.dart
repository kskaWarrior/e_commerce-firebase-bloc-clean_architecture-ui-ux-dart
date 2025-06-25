import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class GetUserUseCase implements UseCase<Either, void> {
  @override
  Future<Either<Failure, UserEntity>> call(params) async {
    return await sl<AuthRepository>().getUser();
  }
}