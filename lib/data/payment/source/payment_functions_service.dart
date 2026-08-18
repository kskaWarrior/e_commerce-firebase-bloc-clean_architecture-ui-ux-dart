import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/entities/payment_preference_entity.dart';

abstract class PaymentFunctionsService {
  Future<Either> createPaymentPreference(String storeId, String saleId);
  Future<Either> setStorePaymentConfig({
    required String storeId,
    required String mpAccessToken,
    String? mpWebhookSecret,
  });
}

class PaymentFunctionsServiceImpl implements PaymentFunctionsService {
  PaymentFunctionsServiceImpl({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  @override
  Future<Either> createPaymentPreference(String storeId, String saleId) async {
    try {
      final result = await _functions
          .httpsCallable('createPaymentPreference')
          .call<Map<String, dynamic>>({'storeId': storeId, 'saleId': saleId});
      final data = Map<String, dynamic>.from(result.data);
      return Right(PaymentPreferenceEntity(
        preferenceId: (data['preferenceId'] ?? '').toString(),
        initPoint: data['initPoint'] as String?,
        sandboxInitPoint: data['sandboxInitPoint'] as String?,
        total: (data['total'] as num?)?.toDouble() ?? 0,
        freight: (data['freight'] as num?)?.toDouble() ?? 0,
      ));
    } on FirebaseFunctionsException catch (e) {
      return Left(e.message ?? 'Could not start the payment.');
    } catch (_) {
      return const Left('Could not start the payment.');
    }
  }

  @override
  Future<Either> setStorePaymentConfig({
    required String storeId,
    required String mpAccessToken,
    String? mpWebhookSecret,
  }) async {
    try {
      await _functions.httpsCallable('setStorePaymentConfig').call({
        'storeId': storeId,
        'mpAccessToken': mpAccessToken,
        if (mpWebhookSecret != null && mpWebhookSecret.isNotEmpty)
          'mpWebhookSecret': mpWebhookSecret,
      });
      return const Right('Payment settings saved!');
    } on FirebaseFunctionsException catch (e) {
      return Left(e.message ?? 'Failed to save payment settings.');
    } catch (_) {
      return const Left('Failed to save payment settings.');
    }
  }
}
