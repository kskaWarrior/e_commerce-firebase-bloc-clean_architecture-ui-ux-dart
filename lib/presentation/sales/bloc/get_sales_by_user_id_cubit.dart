import 'dart:async';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/watch_sales_by_user_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetSalesByUserIdCubit extends Cubit<GetSalesByUserIdState> {
  final GetSalesByUserIdUseCase getSalesByUserIdUseCase;
  final WatchSalesByUserIdUseCase? watchSalesByUserIdUseCase;
  StreamSubscription? _subscription;

  GetSalesByUserIdCubit({
    required this.getSalesByUserIdUseCase,
    this.watchSalesByUserIdUseCase,
  }) : super(GetSalesByUserIdInitial());

  /// Live subscription; falls back to the one-shot fetch when the watch
  /// use case isn't injected (older tests).
  void watchSalesByUserId(String userId) {
    final watch = watchSalesByUserIdUseCase;
    if (watch == null) {
      getSalesByUserId(userId);
      return;
    }
    emit(GetSalesByUserIdLoading());
    _subscription?.cancel();
    _subscription = watch.call(userId).listen((data) {
      if (isClosed) return;
      data.fold(
        (error) => emit(GetSalesByUserIdError(error.toString())),
        (sales) => emit(GetSalesByUserIdLoaded(List<SalesEntity>.from(sales))),
      );
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

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
