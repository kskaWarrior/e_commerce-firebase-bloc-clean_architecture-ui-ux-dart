import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class FavoritesFirebaseService {
  Future<Either> getFavoritesByUserId(String userId);
  Future<Either> registerFavorite(Map<String, dynamic> favorite);
  Future<Either> deleteFavorite(String userId, String productId);
}

class FavoritesFirebaseServiceImpl implements FavoritesFirebaseService {
  @override
  Future<Either> getFavoritesByUserId(String userId) async {
    try {
      final data = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      return Right(data.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Failed to load favorites. Please try again.');
    }
  }

  @override
  Future<Either> registerFavorite(Map<String, dynamic> favorite) async {
    try {
      final collection = FirebaseFirestore.instance.collection('favorites');
      final favoriteId = (favorite['id'] as String?)?.trim();

      if (favoriteId == null || favoriteId.isEmpty) {
        final docRef = collection.doc();
        await docRef.set(<String, dynamic>{...favorite, 'id': docRef.id});
      } else {
        await collection.doc(favoriteId).set(favorite);
      }

      return const Right('Favorite registered successfully!');
    } catch (e) {
      return Left('Failed to register favorite. Please try again.');
    }
  }

  @override
  Future<Either> deleteFavorite(String userId, String productId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (query.docs.isEmpty) {
        return const Right('Favorite not found.');
      }

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      return const Right('Favorite removed successfully!');
    } catch (e) {
      return Left('Failed to remove favorite. Please try again.');
    }
  }
}