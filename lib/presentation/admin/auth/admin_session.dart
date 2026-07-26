import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin login state: which role the signed-in user has and which store the
/// admin is operating on. The storeId comes from the owner's custom claim —
/// never from user input — so tenant isolation is enforced by rules even if
/// this client is tampered with.
class AdminSession {
  String? _role;

  bool get isAuthorized => _role == 'owner' || _role == 'super';
  bool get isSuper => _role == 'super';
  bool get hasStore => sl<StoreContext>().isSet;

  /// Signs in and validates admin claims. Returns null on success or a
  /// user-facing error message.
  Future<String?> signIn(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return await _loadClaims(credential.user, forceRefresh: true);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'user-not-found':
          return 'Invalid email or password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        default:
          return e.message ?? 'Sign in failed.';
      }
    } catch (e) {
      return 'Sign in failed: $e';
    }
  }

  /// Restores a persisted session (page refresh). Returns true when the
  /// current user holds an admin role.
  Future<bool> restore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    final error = await _loadClaims(user);
    return error == null;
  }

  Future<String?> _loadClaims(User? user, {bool forceRefresh = false}) async {
    if (user == null) {
      return 'Sign in failed.';
    }
    final token = await user.getIdTokenResult(forceRefresh);
    final role = token.claims?['role'] as String?;
    if (role != 'owner' && role != 'super') {
      await FirebaseAuth.instance.signOut();
      return 'This account has no admin access.';
    }
    _role = role;
    final storeId = token.claims?['storeId'] as String?;
    if (storeId != null && storeId.isNotEmpty) {
      sl<StoreContext>().set(storeId);
    }
    return null;
  }

  /// Super admins have no storeId claim; they pick the store to manage.
  void selectStore(String storeId) {
    if (!isSuper) {
      throw StateError('Only the platform owner can switch stores.');
    }
    sl<StoreContext>().set(storeId);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _role = null;
    sl<StoreContext>().clear();
  }
}
