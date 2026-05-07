import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';

abstract class FavoritesState {}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteEntity> favorites;

  FavoritesLoaded(this.favorites);
}

class FavoritesRegisterLoading extends FavoritesState {}

class FavoritesRegisterSuccess extends FavoritesState {
  final String message;

  FavoritesRegisterSuccess(this.message);
}

class FavoritesDeleteLoading extends FavoritesState {}

class FavoritesDeleteSuccess extends FavoritesState {
  final String message;

  FavoritesDeleteSuccess(this.message);
}

class FavoritesError extends FavoritesState {
  final String message;

  FavoritesError(this.message);
}