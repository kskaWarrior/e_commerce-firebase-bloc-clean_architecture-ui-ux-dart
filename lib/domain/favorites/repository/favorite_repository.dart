import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';

abstract class FavoriteRepository {
  Future<Either> getFavoritesByUserId(String userId);
  Future<Either> registerFavorite(FavoriteEntity favorite);
}