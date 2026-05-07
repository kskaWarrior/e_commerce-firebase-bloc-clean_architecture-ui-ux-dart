abstract class ButtonState {}

class InitialState extends ButtonState {}

class LoadingState extends ButtonState {}

class SuccessState extends ButtonState {
  final String message;

  SuccessState(this.message);
}

class FailureState extends ButtonState {
  final String error;

  FailureState(this.error);
}

