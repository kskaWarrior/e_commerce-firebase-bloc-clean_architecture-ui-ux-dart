import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/button/button_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ButtonCubit extends Cubit<ButtonState>{
  ButtonCubit() : super(InitialState());

  Future<void> execute ({dynamic params, required UseCase useCase}) async {
    try {
      emit(LoadingState());
      Either result = await useCase.call(params);
      result.fold(
        (failure) => emit(
            FailureState(failure is String ? failure : failure.toString())),
        (data) => emit(SuccessState(data)),
      );
    } catch (e) {
      emit(FailureState(e.toString()));
    }
  }
}