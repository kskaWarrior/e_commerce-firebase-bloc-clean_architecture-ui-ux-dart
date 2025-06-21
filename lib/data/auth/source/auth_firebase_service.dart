import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';

abstract class AuthFirebaseService {
  Future<void> signIn(String email, String password);
  Future<Either<Failure, UserCreationReq>> signUp(UserCreationReq userCreationReq);
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<String?> getCurrentUserId();
  Future<String?> getCurrentUserEmail();
}

class AuthFirebaseServiceImpl implements AuthFirebaseService {
  @override
  Future<void> signIn(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, UserCreationReq>> signUp(UserCreationReq userCreationReq) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isSignedIn() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getCurrentUserId() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getCurrentUserEmail() {
    throw UnimplementedError();
  }
}