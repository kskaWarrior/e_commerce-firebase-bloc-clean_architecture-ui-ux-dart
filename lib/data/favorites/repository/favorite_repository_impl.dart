import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/models/favorite_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/source/favorites_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/repository/favorite_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class FavoriteRepositoryImpl extends FavoriteRepository {
  @override
  Future<Either> getFavoritesByUserId(String userId) async {
    final data = await sl<FavoritesFirebaseService>().getFavoritesByUserId(userId);

    return data.fold(
      (error) => Left(error),
      (favorites) => Right(
        List.from(favorites)
            .map((e) => FavoriteModel.fromMap(e as Map<String, dynamic>).toEntity())
            .toList(),
      ),
    );
  }

  @override
  Future<Either> registerFavorite(FavoriteEntity favorite) async {
    final model = FavoriteModel.fromEntity(favorite);
    return await sl<FavoritesFirebaseService>().registerFavorite(model.toMap());
  }
}