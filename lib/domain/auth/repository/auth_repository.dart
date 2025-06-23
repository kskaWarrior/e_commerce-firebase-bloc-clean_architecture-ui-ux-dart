import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> signIn(UserSigninReq userSigninReq);
  Future<Either<Failure, String>> signUp(
      UserCreationReq userCreationReq);
  Future<Either<Failure, String>> signOut();
  Future<Either<Failure, String>> sendPasswordEmailResetUseCase(String email);
  Future<bool> isLoggedIn();
  Future<Either<Failure, UserModel>> getUser();
}