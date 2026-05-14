import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class SalesFirebaseService {
  Future<Either> getSalesByUserId(String userId);
  Future<Either> registerSale(Map<String, dynamic> sale);
}

class SalesFirebaseServiceImpl implements SalesFirebaseService {
  @override
  Future<Either> getSalesByUserId(String userId) async {
    try {
      final data = await FirebaseFirestore.instance
          .collection('sales')
          .where('userId', isEqualTo: userId)
          .get();

      return Right(data.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Failed to load sales. Please try again.');
    }
  }

  @override
  Future<Either> registerSale(Map<String, dynamic> sale) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final salesCollection = firestore.collection('sales');
      final salesProductsCollection = firestore.collection('sales_products');

      final saleRef = salesCollection.doc();
      final saleId = saleRef.id;
      final saleData = <String, dynamic>{...sale, 'id': saleId};

      final rawProducts = sale['productsList'];
      final products = rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final batch = firestore.batch();
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
          'sourceCollection': 'sales',
          'payload': product,
        });
      }

      await batch.commit();

      return const Right('Sale registered successfully!');
    } catch (e) {
      return Left('Failed to register sale. Please try again.');
    }
  }
}