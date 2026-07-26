import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';

/// Single gateway for tenant-scoped Firestore access.
///
/// Every collection lives under `stores/{storeId}/...` so security rules can
/// isolate tenants by path. Data sources must use these refs instead of
/// `FirebaseFirestore.instance.collection(...)`.
class TenantCollections {
  TenantCollections(this._db, this._context);

  final FirebaseFirestore _db;
  final StoreContext _context;

  String get storeId => _context.storeId;

  DocumentReference<Map<String, dynamic>> get storeDoc =>
      _db.collection('stores').doc(_context.storeId);

  CollectionReference<Map<String, dynamic>> get products =>
      storeDoc.collection('products');

  CollectionReference<Map<String, dynamic>> get categories =>
      storeDoc.collection('categories');

  CollectionReference<Map<String, dynamic>> get favorites =>
      storeDoc.collection('favorites');

  CollectionReference<Map<String, dynamic>> get sales =>
      storeDoc.collection('sales');

  CollectionReference<Map<String, dynamic>> get salesProducts =>
      storeDoc.collection('sales_products');

  CollectionReference<Map<String, dynamic>> get users =>
      storeDoc.collection('users');

  WriteBatch batch() => _db.batch();
}
