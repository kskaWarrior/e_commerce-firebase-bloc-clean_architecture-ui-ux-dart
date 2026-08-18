import 'package:dartz/dartz.dart';

abstract class PaymentRepository {
  Future<Either> createPaymentPreference(String storeId, String saleId);
  Future<Either> setStorePaymentConfig({
    required String storeId,
    required String mpAccessToken,
    String? mpWebhookSecret,
  });
}
