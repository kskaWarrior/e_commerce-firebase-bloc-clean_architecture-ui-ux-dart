import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class FirebaseService {
  Future<Either<Failure, String>> signIn(UserSigninReq userSigninReq);
  Future<Either<Failure, String>> signUp(UserCreationReq userCreationReq);
  Future<Either<Failure, String>> updateUser(UserCreationReq userCreationReq);
  Future<Either<Failure, String>> sendPasswordEmailResetUseCase(String email);
  Future<Either<Failure, String>> uploadProfileImage(
      UploadProfileImageParams params);
  Future<Either<Failure, String>> signOut();
  Future<bool> isLoggedIn();
  Future<Either<Failure, UserModel>> getUser();
}

class FirebaseServiceImpl implements FirebaseService {
  FirebaseServiceImpl(this._tenant);

  final TenantCollections _tenant;

  DateTime _toUtcDateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  Future<void> _writeProfile(String uid, UserCreationReq userCreationReq) {
    final DateTime? normalizedBirthDate = userCreationReq.birthDate != null
        ? _toUtcDateOnly(userCreationReq.birthDate!)
        : null;
    return _tenant.users.doc(uid).set({
      ...userCreationReq.toJson(),
      'birthDate': normalizedBirthDate != null
          ? Timestamp.fromDate(normalizedBirthDate)
          : null,
    });
  }

  @override
  Future<Either<Failure, String>> signIn(UserSigninReq userSigninReq) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userSigninReq.email,
        password: userSigninReq.password!,
      );

      return Future.value(
          const Right('Login with success!')); // Placeholder for success
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
          case 'invalid-credential':
            return Future.value(Left(Failure(
                error:
                    'That password does not look right. Please try again or reset your password.')));
          case 'invalid-email':
            return Future.value(
                Left(Failure(error: 'Please enter a valid email address.')));
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
      await _writeProfile(returnedData.user!.uid, userCreationReq);

      return Future.value(
          const Right('Created user with success!')); // Placeholder for success
    } catch (e) {
      // Handle exceptions and return a Failure
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            return Future.value(Left(Failure(error: 'Weak password')));
          case 'email-already-in-use':
            // Shared Auth pool across stores: the account may belong to a
            // shopper of another store's app. If the credentials are theirs
            // and they have no profile in THIS store yet, sign them in and
            // create the per-store profile instead of failing.
            return _signUpExistingAccount(userCreationReq);
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

  Future<Either<Failure, String>> _signUpExistingAccount(
      UserCreationReq userCreationReq) async {
    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userCreationReq.email,
        password: userCreationReq.password!,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return Left(Failure(error: 'Email already in use'));
      }

      final existingProfile = await _tenant.users.doc(uid).get();
      if (existingProfile.exists) {
        return Left(Failure(error: 'Email already in use'));
      }

      userCreationReq.id = uid;
      await _writeProfile(uid, userCreationReq);
      return const Right('Created user with success!');
    } on FirebaseAuthException {
      // Credentials don't match the existing account: report the original
      // conflict rather than leaking that the email exists elsewhere.
      return Left(Failure(error: 'Email already in use'));
    } catch (e) {
      return Left(Failure(error: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updateUser(
      UserCreationReq userCreationReq) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;
      if (currentUser == null || userId == null) {
        return Left(Failure(error: 'User not logged in'));
      }

      if (userCreationReq.password != null &&
          userCreationReq.password!.isNotEmpty) {
        await currentUser.updatePassword(userCreationReq.password!);
      }

      final DateTime? normalizedBirthDate = userCreationReq.birthDate != null
          ? _toUtcDateOnly(userCreationReq.birthDate!)
          : null;

      // set+merge (not update) so a first-time profile in this store is
      // created rather than throwing not-found; the email is stamped from
      // the Auth account so a freshly created doc is self-consistent.
      await _tenant.users.doc(userId).set({
        'email': currentUser.email,
        'name': userCreationReq.name,
        'phone': userCreationReq.phone,
        'address': userCreationReq.address,
        if (userCreationReq.addressData != null)
          'addressData': userCreationReq.addressData!.toMap(),
        'birthDate': normalizedBirthDate != null
            ? Timestamp.fromDate(normalizedBirthDate)
            : null,
        'gender': userCreationReq.gender,
      }, SetOptions(merge: true));

      return const Right('Profile updated with success!');
    } on FirebaseException catch (e) {
      return Left(Failure(error: e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(Failure(error: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      return Future.value(const Right('Logout successful!'));
    } on FirebaseAuthException catch (e) {
      return Future.value(Left(Failure(error: e.message ?? 'Unknown error')));
    } catch (e) {
      return Future.value(Left(Failure(error: e.toString())));
    }
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
      final userDoc = await _tenant.users.doc(userId).get();
      final data = userDoc.data();
      if (data != null) {
        return Right(UserModel.fromMap(data));
      } else {
        // Auth account exists but has no profile in THIS store (signed up
        // through another store's app). Distinct code so the UI can offer
        // per-store registration.
        return Left(Failure(error: 'profile-not-found'));
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
  Future<Either<Failure, String>> sendPasswordEmailResetUseCase(
      String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return Future.value(const Right(
          'Password reset email sent! Check it out ;)')); // Placeholder for success
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

  @override
  Future<Either<Failure, String>> uploadProfileImage(
      UploadProfileImageParams params) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return Left(Failure(error: 'User not logged in'));
      }

      final Reference ref =
          FirebaseStorage.instance.ref().child('profile/images/$userId');

      await ref.putData(
        params.bytes,
        SettableMetadata(contentType: params.contentType),
      );

      final String downloadUrl = await ref.getDownloadURL();

      // Merge so uploading a photo works even before the rest of the
      // profile doc exists (first-time profile in this store).
      await _tenant.users.doc(userId).set({
        'profileImageUrl': downloadUrl,
      }, SetOptions(merge: true));

      return Right(downloadUrl);
    } on FirebaseException catch (e) {
      return Left(Failure(error: e.message ?? 'Failed to upload image'));
    } catch (e) {
      return Left(Failure(error: e.toString()));
    }
  }
}
