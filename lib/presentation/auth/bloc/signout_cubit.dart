import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignOutCubit extends Cubit<SignOutState> {
  SignOutCubit() : super(SignOutInitial());

  Future<void> signOut() async {
    emit(SignOutLoading());
    try {
      final result = await sl<SignOutUseCase>().call(null);
      result.fold(
        (failure) => emit(SignOutFailure(error: failure.toString())),
        (message) => emit(SignOutSuccess(message: message)),
      );
    } catch (e) {
      emit(SignOutFailure(error: e.toString()));
    }
  }
}