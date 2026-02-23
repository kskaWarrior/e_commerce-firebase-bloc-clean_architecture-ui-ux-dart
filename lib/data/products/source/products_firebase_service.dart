import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class ProductsFirebaseService {
  Future<Either> getTopSelling();
  Future<Either> getNewIn();
}

class ProductsFirebaseServiceImpl implements ProductsFirebaseService {

  @override
  Future<Either> getTopSelling() async {
    try {
      var data = await FirebaseFirestore.instance.collection('products')
      .where('salesNumber', isGreaterThanOrEqualTo: 20)
      .get();
      return Right(data.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Please try again');
    }
  }
  
  @override
  Future<Either> getNewIn() async {
    try {
      var data = await FirebaseFirestore.instance.collection('products')
      .where('createdDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
      .get();
      return Right(data.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Please try again');
    }
  }
}