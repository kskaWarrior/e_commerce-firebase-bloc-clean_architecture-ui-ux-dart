import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/repository/payment_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class CreatePaymentPreferenceParams {
  final String storeId;
  final String saleId;

  CreatePaymentPreferenceParams({required this.storeId, required this.saleId});
}

class CreatePaymentPreferenceUseCase
    implements UseCase<Either, CreatePaymentPreferenceParams> {
  @override
  Future<Either> call(CreatePaymentPreferenceParams params) async {
    return await sl<PaymentRepository>()
        .createPaymentPreference(params.storeId, params.saleId);
  }
}
