import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<Either<Failure, UserCreationReq>> signUp(
      UserCreationReq userCreationReq) async {
        print('authfirebase service sign up called');
        print(userCreationReq.toJson());
    try {
      var returnedData =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userCreationReq.email,
        password: userCreationReq.password!,
      );
      print(returnedData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(returnedData.user?.uid)
          .set(userCreationReq.toJson());

      return Future.value(Right(userCreationReq)); // Placeholder for success
    } catch (e) {
      print(e.toString());
      // Handle exceptions and return a Failure
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            return Future.value(Left(Failure(message: 'Weak password')));
          case 'email-already-in-use':
            return Future.value(Left(Failure(message: 'Email already in use')));
          case 'invalid-email':
            return Future.value(Left(Failure(message: 'Invalid email')));
          default:
            return Future.value(
                Left(Failure(message: e.message ?? 'Unknown error')));
        }
      }
      return Future.value(Left(Failure(message: e.toString())));
    }
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