abstract class RegisterSaleState {}

class RegisterSaleInitial extends RegisterSaleState {}

class RegisterSaleLoading extends RegisterSaleState {}

class RegisterSaleSuccess extends RegisterSaleState {
  final String message;

  RegisterSaleSuccess(this.message);
}

class RegisterSaleFailure extends RegisterSaleState {
  final String message;

  RegisterSaleFailure(this.message);
}
