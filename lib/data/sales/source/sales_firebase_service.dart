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
      final collection = FirebaseFirestore.instance.collection('sales');
      final saleId = (sale['id'] as String?)?.trim();

      if (saleId == null || saleId.isEmpty) {
        final docRef = collection.doc();
        await docRef.set(<String, dynamic>{...sale, 'id': docRef.id});
      } else {
        await collection.doc(saleId).set(sale);
      }

      return const Right('Sale registered successfully!');
    } catch (e) {
      return Left('Failed to register sale. Please try again.');
    }
  }
}