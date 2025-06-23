import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either<Failure, String>> signIn(UserSigninReq userSigninReq) async {
    return await sl<FirebaseService>().signIn(userSigninReq);
  }

  @override
  Future<Either<Failure, String>> signUp(UserCreationReq userCreationReq) async {
    return await sl<FirebaseService>().signUp(userCreationReq);
  }

  @override
  Future<Either<Failure, String>> signOut() {
    throw UnimplementedError();
  }
  
  @override
  Future<Either<Failure, String>> sendPasswordEmailResetUseCase(String email) async {
    return await sl<FirebaseService>().sendPasswordEmailResetUseCase(email);
  }

  @override
  Future<Either<Failure, UserModel>> getUser() async {
    return await sl<FirebaseService>().getUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await sl<FirebaseService>().isLoggedIn();
  }
}