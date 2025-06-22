import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/auth_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<void> signIn(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, UserCreationReq>> signUp(UserCreationReq userCreationReq) {
    return sl<AuthFirebaseService>().signUp(userCreationReq);
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}