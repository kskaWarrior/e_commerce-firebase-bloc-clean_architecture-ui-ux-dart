import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// A [TenantCollections] whose Firestore throws a [FirebaseException] on any
/// access, mirroring the old "Firebase unavailable in unit tests" behavior
/// the data-source error-path tests rely on.
TenantCollections unavailableTenantCollections() {
  final db = _MockFirebaseFirestore();
  when(() => db.collection(any())).thenThrow(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'Firestore unavailable in unit tests',
    ),
  );
  when(db.batch).thenThrow(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'Firestore unavailable in unit tests',
    ),
  );
  return TenantCollections(db, StoreContext()..set('test-store'));
}
