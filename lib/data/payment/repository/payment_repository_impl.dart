import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/payment/source/payment_functions_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/repository/payment_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  @override
  Future<Either> createPaymentPreference(String storeId, String saleId) async {
    return await sl<PaymentFunctionsService>()
        .createPaymentPreference(storeId, saleId);
  }

  @override
  Future<Either> setStorePaymentConfig({
    required String storeId,
    required String mpAccessToken,
    String? mpWebhookSecret,
  }) async {
    return await sl<PaymentFunctionsService>().setStorePaymentConfig(
      storeId: storeId,
      mpAccessToken: mpAccessToken,
      mpWebhookSecret: mpWebhookSecret,
    );
  }
}
