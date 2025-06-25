import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserEntity user;
  UserLoaded({required this.user});
}

class UserError extends UserState {
  final String error;
  UserError({required this.error});

  @override
  String toString() => 'UserError: $error';
}