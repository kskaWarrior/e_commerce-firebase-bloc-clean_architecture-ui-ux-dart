import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:flutter/foundation.dart';

class CartDraftStore extends ChangeNotifier {
  CartDraftStore._();

  static final CartDraftStore instance = CartDraftStore._();

  final List<SalesEntity> _drafts = <SalesEntity>[];

  List<SalesEntity> get drafts => List<SalesEntity>.unmodifiable(_drafts);

  bool get isEmpty => _drafts.isEmpty;

  int get itemsCount => _drafts.length;

  double get totalPrice =>
      _drafts.fold<double>(0, (sum, draft) => sum + draft.totalPrice);

  double get totalOriginalPrice =>
      _drafts.fold<double>(0, (sum, draft) => sum + draft.price);

  double get totalDiscountedPrice =>
      _drafts.fold<double>(0, (sum, draft) => sum + draft.discountedPrice);

  void addDraft(SalesEntity draft) {
    _drafts.add(draft);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _drafts.length) {
      return;
    }
    _drafts.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _drafts.clear();
    notifyListeners();
  }
}
