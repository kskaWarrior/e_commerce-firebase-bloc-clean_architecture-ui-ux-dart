import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/update_sale_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AdminOrdersState {}

class AdminOrdersLoading extends AdminOrdersState {}

class AdminOrdersLoaded extends AdminOrdersState {
  AdminOrdersLoaded(this.orders);
  final List<SalesEntity> orders;
}

class AdminOrdersError extends AdminOrdersState {
  AdminOrdersError(this.message);
  final String message;
}

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit({
    required this.getSalesByStoreUseCase,
    required this.updateSaleStatusUseCase,
  }) : super(AdminOrdersLoading());

  final GetSalesByStoreUseCase getSalesByStoreUseCase;
  final UpdateSaleStatusUseCase updateSaleStatusUseCase;

  Future<void> load() async {
    emit(AdminOrdersLoading());
    final result = await getSalesByStoreUseCase.call(null);
    if (isClosed) return;
    result.fold(
      (error) => emit(AdminOrdersError(error.toString())),
      (orders) => emit(AdminOrdersLoaded(List<SalesEntity>.from(orders))),
    );
  }

  Future<String?> updateStatus(String saleId, String status) async {
    final result = await updateSaleStatusUseCase
        .call(UpdateSaleStatusParams(saleId: saleId, status: status));
    return result.fold(
      (error) => error.toString(),
      (_) {
        load();
        return null;
      },
    );
  }
}
