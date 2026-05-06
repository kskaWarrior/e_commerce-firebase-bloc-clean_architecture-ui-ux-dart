import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/repository/favorite_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class RegisterFavoriteUseCase implements UseCase<Either, FavoriteEntity> {
  @override
  Future<Either> call(FavoriteEntity params) async {
    return await sl<FavoriteRepository>().registerFavorite(params);
  }
}