import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/repository/sales_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

/// Stream variant of GetSalesByUserId so purchase pages update live when the
/// payment webhook flips an order's status.
class WatchSalesByUserIdUseCase {
  Stream<Either> call(String userId) {
    return sl<SalesRepository>().watchSalesByUserId(userId);
  }
}
