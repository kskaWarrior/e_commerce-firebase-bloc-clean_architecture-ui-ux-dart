import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';

class NewInDisplayCubit extends ProductsDisplayCubit {
  NewInDisplayCubit(GetNewInProductsUseCase super.useCase);
}