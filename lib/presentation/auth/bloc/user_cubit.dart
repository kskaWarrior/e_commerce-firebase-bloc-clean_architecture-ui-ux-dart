import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCubit extends Cubit<UserState>{
  UserCubit() : super(UserInitial());

  Future<void> getUser() async {
    emit(UserLoading());
    try {
      final result = await sl<GetUserUseCase>().call(null);
      result.fold(
        (failure) => emit(UserError(message: failure.error)),
        (user) => emit(UserLoaded(user: user)), 
      ); 
    } catch (error) {
      emit(UserError(message: error.toString()));
    }
  }
}