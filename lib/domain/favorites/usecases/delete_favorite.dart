import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/repository/favorite_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class DeleteFavoriteParams {
  final String userId;
  final String productId;

  DeleteFavoriteParams({required this.userId, required this.productId});
}

class DeleteFavoriteUseCase
    implements UseCase<Either, DeleteFavoriteParams> {
  @override
  Future<Either> call(DeleteFavoriteParams params) async {
    return await sl<FavoriteRepository>()
        .deleteFavorite(params.userId, params.productId);
  }
}