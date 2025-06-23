import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserModel user;
  UserLoaded({required this.user});
}

class UserError extends UserState {
  final String message;
  UserError({required this.message});

  @override
  String toString() => 'UserError: $message';
}