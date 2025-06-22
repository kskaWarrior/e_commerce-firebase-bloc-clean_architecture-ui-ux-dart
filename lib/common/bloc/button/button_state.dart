abstract class ButtonState {}

class Initial extends ButtonState {}

class Loading extends ButtonState {}

class Success extends ButtonState {
  final String message;

  Success(this.message);
}

class Failure extends ButtonState {
  final String error;

  Failure(this.error);
}

