import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_user_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetSalesByUserIdCubit extends Cubit<GetSalesByUserIdState> {
  final GetSalesByUserIdUseCase getSalesByUserIdUseCase;

  GetSalesByUserIdCubit({required this.getSalesByUserIdUseCase})
      : super(GetSalesByUserIdInitial());

  Future<void> getSalesByUserId(String userId) async {
    emit(GetSalesByUserIdLoading());
    final data = await getSalesByUserIdUseCase.call(userId);

    if (isClosed) return;

    data.fold(
      (error) {
        if (isClosed) return;
        emit(GetSalesByUserIdError(error.toString()));
      },
      (sales) {
        if (isClosed) return;
        emit(GetSalesByUserIdLoaded(List<SalesEntity>.from(sales)));
      },
    );
  }
}
