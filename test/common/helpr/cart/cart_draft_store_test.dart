import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SalesEntity buildDraft({required String id, required double price, required double discounted}) {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    return SalesEntity(
      createdDate: ts,
      discountedPrice: discounted,
      freight: 0,
      id: id,
      installmentsNumber: 1,
      paymentMethod: 'Debit card',
      price: price,
      productsList: const [
        {
          'id': 'p1',
          'productId': 'p1',
          'title': 'Sneaker',
          'quantity': 1,
          'unitPrice': 100,
          'unitDiscounted': 90,
          'totalPrice': 90,
        }
      ],
      totalPrice: discounted,
      userBirthDate: ts,
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CartDraftStore.instance.clear();
  });

  test('add/remove/clear update cart totals and items count', () {
    final store = CartDraftStore.instance;

    final d1 = buildDraft(id: 's1', price: 100, discounted: 80);
    final d2 = buildDraft(id: 's2', price: 50, discounted: 45);

    store.addDraft(d1);
    store.addDraft(d2);

    expect(store.itemsCount, 2);
    expect(store.isEmpty, isFalse);
    expect(store.totalOriginalPrice, 150);
    expect(store.totalDiscountedPrice, 125);
    expect(store.totalPrice, 125);

    store.removeAt(0);
    expect(store.itemsCount, 1);
    expect(store.drafts.first.id, 's2');

    store.clear();
    expect(store.itemsCount, 0);
    expect(store.isEmpty, isTrue);
  });

  test('removeAt with invalid index keeps state unchanged', () {
    final store = CartDraftStore.instance;
    final draft = buildDraft(id: 's1', price: 100, discounted: 90);

    store.addDraft(draft);
    store.removeAt(-1);
    store.removeAt(100);

    expect(store.itemsCount, 1);
    expect(store.drafts.first.id, 's1');
  });

  test('restore loads persisted drafts from shared preferences', () async {
    final ts = DateTime(2025, 1, 1).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'cart_drafts_v1':
          '[{"createdDateMs":$ts,"discountedPrice":80,"freight":0,"id":"s1","installmentsNumber":1,"paymentMethod":"Debit card","price":100,"productsList":[{"id":"p1","productId":"p1","title":"Sneaker","quantity":1,"unitPrice":100,"unitDiscounted":80,"totalPrice":80}],"totalPrice":80,"userBirthDateMs":$ts,"userGender":"male","userId":"u1","userName":"John"}]'
    });

    final store = CartDraftStore.instance;
    store.clear();

    await store.restore();

    expect(store.itemsCount, 1);
    expect(store.drafts.first.id, 's1');
    expect(store.totalDiscountedPrice, 80);
  });

  test('restore ignores invalid persisted payload gracefully', () async {
    SharedPreferences.setMockInitialValues({'cart_drafts_v1': '{invalid_json'});

    final store = CartDraftStore.instance;
    store.clear();

    await store.restore();

    expect(store.itemsCount, 0);
    expect(store.isEmpty, isTrue);
  });
}
