import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/repository/payment_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class SetStorePaymentConfigParams {
  final String storeId;
  final String mpAccessToken;
  final String? mpWebhookSecret;

  SetStorePaymentConfigParams({
    required this.storeId,
    required this.mpAccessToken,
    this.mpWebhookSecret,
  });
}

class SetStorePaymentConfigUseCase
    implements UseCase<Either, SetStorePaymentConfigParams> {
  @override
  Future<Either> call(SetStorePaymentConfigParams params) async {
    return await sl<PaymentRepository>().setStorePaymentConfig(
      storeId: params.storeId,
      mpAccessToken: params.mpAccessToken,
      mpWebhookSecret: params.mpWebhookSecret,
    );
  }
}
