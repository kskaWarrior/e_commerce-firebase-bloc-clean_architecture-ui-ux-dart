import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';

abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<Either<Failure, String>> signUp(
      UserCreationReq userCreationReq);
  Future<void> signOut();
}