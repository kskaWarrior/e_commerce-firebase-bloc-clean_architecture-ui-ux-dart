import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_top_selling_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/top_selling_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TopSellingDisplayCubit extends Cubit<TopSellingDisplayState> {
  TopSellingDisplayCubit() : super(TopSellingDisplayInitial());


  void displayProducts() async {
    var data = await sl<GetTopSellingProductsUseCase>().call(null);
    data.fold(
      (error) => emit(TopSellingDisplayError(error)),
      (products) => emit(TopSellingDisplayLoaded(products)),
    );
  }

}