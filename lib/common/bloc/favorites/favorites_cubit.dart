import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/favorites/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/register_favorite.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavoritesByUserIdUseCase getFavoritesByUserIdUseCase;
  final RegisterFavoriteUseCase registerFavoriteUseCase;
  final DeleteFavoriteUseCase deleteFavoriteUseCase;

  FavoritesCubit({
    required this.getFavoritesByUserIdUseCase,
    required this.registerFavoriteUseCase,
    required this.deleteFavoriteUseCase,
  }) : super(FavoritesInitial());

  Future<void> loadFavoritesByUserId(String userId) async {
    emit(FavoritesLoading());
    final data = await getFavoritesByUserIdUseCase.call(userId);

    if (isClosed) return;

    data.fold(
      (error) {
        if (isClosed) return;
        emit(FavoritesError(error.toString()));
      },
      (favorites) {
        if (isClosed) return;
        emit(FavoritesLoaded(List<FavoriteEntity>.from(favorites)));
      },
    );
  }

  Future<void> registerFavorite(FavoriteEntity favorite) async {
    emit(FavoritesRegisterLoading());
    final data = await registerFavoriteUseCase.call(favorite);

    if (isClosed) return;

    data.fold(
      (error) {
        if (isClosed) return;
        emit(FavoritesError(error.toString()));
      },
      (message) {
        if (isClosed) return;
        emit(FavoritesRegisterSuccess(message.toString()));
      },
    );
  }

  Future<void> deleteFavorite(String userId, String productId) async {
    emit(FavoritesDeleteLoading());
    final data = await deleteFavoriteUseCase.call(
      DeleteFavoriteParams(userId: userId, productId: productId),
    );

    if (isClosed) return;

    data.fold(
      (error) {
        if (isClosed) return;
        emit(FavoritesError(error.toString()));
      },
      (message) {
        if (isClosed) return;
        emit(FavoritesDeleteSuccess(message.toString()));
      },
    );
  }
}