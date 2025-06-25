import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class SigninUseCase implements UseCase<Either, UserSigninReq> {
  @override
  Future<Either<Failure, String>> call(UserSigninReq userSigninReq) async {
    return await sl<AuthRepository>().signIn(userSigninReq);
  }
}