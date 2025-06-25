import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/is_logged_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashCubit extends Cubit<SplashState>{
  SplashCubit() : super(DisplaySplash());

  void appStarted() async {
    try {
      final result = await sl<IsLoggedInUseCase>().call(null);
      result.fold(
        (failure) {
            emit(UnAuthenticated());
        },
        (isLoggedIn) {
          if (isLoggedIn) {
            emit(Authenticated());
          } else {
            emit(UnAuthenticated());
          }
        },
      );
    } on Exception {
      emit(UnAuthenticated());
    }
  }
}