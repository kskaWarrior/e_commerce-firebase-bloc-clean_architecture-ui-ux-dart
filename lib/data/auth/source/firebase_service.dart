import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirebaseService {
  Future<Either<Failure, String>> signIn(UserSigninReq userSigninReq);
  Future<Either<Failure, String>> signUp(UserCreationReq userCreationReq);
  Future<Either<Failure, String>> sendPasswordEmailResetUseCase(String email);
  Future<Either<Failure, String>> signOut();
  Future<bool> isLoggedIn();
  Future<Either<Failure, UserModel>> getUser();
}

class FirebaseServiceImpl implements FirebaseService {
  @override
  Future<Either<Failure, String>> signIn(UserSigninReq userSigninReq) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userSigninReq.email,
        password: userSigninReq.password!,
      );

      return Future.value(const Right('Login with success!')); // Placeholder for success
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-credentials':
            return Future.value(Left(Failure(error: 'Invalid credentials')));
          case 'invalid-email':
            return Future.value(Left(Failure(error: 'Invalid email')));
          default:
            return Future.value(
                Left(Failure(error: e.message ?? 'Unknown error')));
        }
      }
      return Future.value(Left(Failure(error: e.toString())));
    }
  }

  @override
  Future<Either<Failure, String>> signUp(
      UserCreationReq userCreationReq) async {
    try {
      var returnedData =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userCreationReq.email,
        password: userCreationReq.password!,
      );
      userCreationReq.id = returnedData.user?.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(returnedData.user?.uid)
          .set(userCreationReq.toJson());

      return Future.value(const Right('Created user with success!')); // Placeholder for success
    } catch (e) {
      // Handle exceptions and return a Failure
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            return Future.value(Left(Failure(error: 'Weak password')));
          case 'email-already-in-use':
            return Future.value(Left(Failure(error: 'Email already in use')));
          case 'invalid-email':
            return Future.value(Left(Failure(error: 'Invalid email')));
          default:
            return Future.value(
                Left(Failure(error: e.message ?? 'Unknown error')));
        }
      }
      return Future.value(Left(Failure(error: e.toString())));
    }
  }

  @override
  Future<Either<Failure, String>> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isLoggedIn() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return Future.value(user != null);
    } catch (e) {
      return Future.value(false);
    }
  }

  @override
  Future<Either<Failure, UserModel>> getUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return Left(Failure(error: 'User not logged in'));
      }
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = userDoc.data();
      if (data != null) {
        return Right(UserModel.fromMap(data));
      } else {
        return Left(Failure(error: 'User not found'));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled') {
        return Left(Failure(error: 'user-disabled'));
      }
      return Left(Failure(error: e.message ?? 'Auth error'));
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return Left(Failure(error: 'permission-denied'));
      }
      return Left(Failure(error: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, String>> sendPasswordEmailResetUseCase(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return Future.value(const Right('Password reset email sent! Check it out ;)')); // Placeholder for success
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            return Future.value(Left(Failure(error: 'User not found')));
          case 'invalid-email':
            return Future.value(Left(Failure(error: 'Invalid email')));
          default:
            return Future.value(
                Left(Failure(error: e.message ?? 'Unknown error')));
        }
      }
      return Future.value(Left(Failure(error: e.toString())));
    }
  }
  
}
