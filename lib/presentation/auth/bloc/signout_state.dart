abstract class SignOutState {}

class SignOutInitial extends SignOutState {}

class SignOutLoading extends SignOutState {}

class SignOutSuccess extends SignOutState {
  final String message;

  SignOutSuccess({required this.message});
}

class SignOutFailure extends SignOutState {
  final String error;

  SignOutFailure({required this.error});
}