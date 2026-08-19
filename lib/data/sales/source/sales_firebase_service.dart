import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';

abstract class SalesFirebaseService {
  Future<Either> getSalesByUserId(String userId);
  Stream<Either> watchSalesByUserId(String userId);
  Future<Either> registerSale(Map<String, dynamic> sale);

  // Admin operations
  Future<Either> getSalesByStore();
  Future<Either> updateSaleStatus(String saleId, String status);
}

class SalesFirebaseServiceImpl implements SalesFirebaseService {
  SalesFirebaseServiceImpl(this._tenant);

  final TenantCollections _tenant;

  @override
  Future<Either> getSalesByUserId(String userId) async {
    try {
      final data = await _tenant.sales
          .where('userId', isEqualTo: userId)
          .get();

      return Right(data.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Failed to load sales. Please try again.');
    }
  }

  @override
  Stream<Either> watchSalesByUserId(String userId) async* {
    try {
      // Live view so the webhook's pending->paid flip shows without refresh.
      await for (final snapshot in _tenant.sales
          .where('userId', isEqualTo: userId)
          .snapshots()) {
        yield Right(snapshot.docs.map((doc) => doc.data()).toList());
      }
    } catch (_) {
      yield const Left('Failed to load sales. Please try again.');
    }
  }

  @override
  Future<Either> getSalesByStore() async {
    try {
      final data = await _tenant.sales
          .orderBy('createdDate', descending: true)
          .get();
      return Right(data.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Failed to load orders. Please try again.');
    }
  }

  @override
  Future<Either> updateSaleStatus(String saleId, String status) async {
    try {
      // Rules restrict this write to owners/super and to the status field.
      await _tenant.sales.doc(saleId).update({'status': status});
      return const Right('Order status updated.');
    } catch (e) {
      return Left('Failed to update order status: $e');
    }
  }

  @override
  Future<Either> registerSale(Map<String, dynamic> sale) async {
    try {
      final salesCollection = _tenant.sales;
      final salesProductsCollection = _tenant.salesProducts;

      final saleRef = salesCollection.doc();
      final saleId = saleRef.id;
      final saleData = <String, dynamic>{
        ...sale,
        'id': saleId,
        // Path already carries the tenant; denormalized for BigQuery and
        // cross-store queries.
        'storeId': _tenant.storeId,
        'status': sale['status'] ?? 'pending',
      };

      final rawProducts = sale['productsList'];
      final products = rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final batch = _tenant.batch();
      batch.set(saleRef, saleData);

      for (var index = 0; index < products.length; index++) {
        final product = products[index];
        final salesProductRef = salesProductsCollection.doc();

        batch.set(salesProductRef, <String, dynamic>{
          'id': salesProductRef.id,
          'salesId': saleId,
          'orderId': saleId,
          'saleDocumentId': saleId,
          'productIndex': index,
          'productId': (product['productId'] ?? '').toString(),
          'title': (product['title'] ?? '').toString(),
          'categoryName': (product['categoryName'] ?? '').toString(),
          'color': (product['color'] ?? '').toString(),
          'colorHex': (product['colorHex'] ?? '').toString(),
          'size': (product['size'] ?? '').toString(),
          'quantity': product['quantity'],
          'unitPrice': product['unitPrice'],
          'unitDiscounted': product['unitDiscounted'],
          'totalPrice': product['totalPrice'],
          'createdDate': sale['createdDate'] ?? FieldValue.serverTimestamp(),
          'userId': (sale['userId'] ?? '').toString(),
          'userName': (sale['userName'] ?? '').toString(),
          'storeId': _tenant.storeId,
          'sourceCollection': 'sales',
          'payload': product,
        });
      }

      await batch.commit();

      // The created sale id lets checkout hand the order to the payment
      // function (createPaymentPreference) right after registration.
      return Right(saleId);
    } catch (e) {
      return Left('Failed to register sale. Please try again.');
    }
  }
}
