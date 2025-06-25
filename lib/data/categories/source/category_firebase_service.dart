import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class CategoryFirebaseService {

  Future<Either<String, List<Map<String, dynamic>>>> getCategories();
}

class CategoryFirebaseServiceImpl implements CategoryFirebaseService {
  @override
  Future<Either<String, List<Map<String, dynamic>>>> getCategories() async {
    try {
      var categories = await FirebaseFirestore.instance.collection('categories').get();
      return Right(categories.docs.map((doc) => doc.data()).toList());
    } on Exception catch (e) {
      return Left('Error fetching categories: $e');
    }
  }
}