import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/sales/register_sale_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterSaleCubit extends Cubit<RegisterSaleState> {
  final RegisterSaleUseCase registerSaleUseCase;

  RegisterSaleCubit({required this.registerSaleUseCase})
      : super(RegisterSaleInitial());

  Future<void> registerSale(SalesEntity sale) async {
    emit(RegisterSaleLoading());

    final data = await registerSaleUseCase.call(sale);

    if (isClosed) return;

    data.fold(
      (error) {
        if (isClosed) return;
        emit(RegisterSaleFailure(error.toString()));
      },
      (message) {
        if (isClosed) return;
        emit(RegisterSaleSuccess(message.toString()));
      },
    );
  }
}
