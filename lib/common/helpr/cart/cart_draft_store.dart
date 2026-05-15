import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartDraftStore extends ChangeNotifier {
  CartDraftStore._();

  static final CartDraftStore instance = CartDraftStore._();
  static const String _storageKey = 'cart_drafts_v1';

  final List<SalesEntity> _drafts = <SalesEntity>[];
  bool _isRestored = false;

  List<SalesEntity> get drafts => List<SalesEntity>.unmodifiable(_drafts);

  bool get isEmpty => _drafts.isEmpty;

  int get itemsCount => _drafts.length;

  double get totalPrice =>
      _drafts.fold<double>(
      0, (runningTotal, draft) => runningTotal + draft.totalPrice);

  double get totalOriginalPrice =>
      _drafts.fold<double>(
      0, (runningTotal, draft) => runningTotal + draft.price);

  double get totalDiscountedPrice =>
      _drafts.fold<double>(
      0, (runningTotal, draft) => runningTotal + draft.discountedPrice);

  Future<void> restore() async {
    if (_isRestored) {
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final jsonString = preferences.getString(_storageKey);

      if (jsonString == null || jsonString.trim().isEmpty) {
        _isRestored = true;
        return;
      }

      final decoded = json.decode(jsonString);
      if (decoded is! List) {
        _isRestored = true;
        return;
      }

      final restoredDrafts = decoded
          .whereType<Map>()
          .map((item) => _fromPersistedMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      _drafts
        ..clear()
        ..addAll(restoredDrafts);

      _isRestored = true;
      notifyListeners();
    } catch (_) {
      _isRestored = true;
    }
  }

  void addDraft(SalesEntity draft) {
    _drafts.add(draft);
    notifyListeners();
    unawaited(_persist());
  }

  void removeAt(int index) {
    if (index < 0 || index >= _drafts.length) {
      return;
    }
    _drafts.removeAt(index);
    notifyListeners();
    unawaited(_persist());
  }

  void clear() {
    _drafts.clear();
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final payload = _drafts.map(_toPersistedMap).toList(growable: false);
      await preferences.setString(_storageKey, json.encode(payload));
    } catch (_) {
      // Keep cart operations resilient even if persistence fails.
    }
  }

  static Map<String, dynamic> _toPersistedMap(SalesEntity draft) {
    return <String, dynamic>{
      'createdDateMs': draft.createdDate.millisecondsSinceEpoch,
      'discountedPrice': draft.discountedPrice,
      'freight': draft.freight,
      'id': draft.id,
      'installmentsNumber': draft.installmentsNumber,
      'paymentMethod': draft.paymentMethod,
      'price': draft.price,
      'productsList': draft.productsList,
      'totalPrice': draft.totalPrice,
      'userBirthDateMs': draft.userBirthDate.millisecondsSinceEpoch,
      'userGender': draft.userGender,
      'userId': draft.userId,
      'userName': draft.userName,
    };
  }

  static SalesEntity _fromPersistedMap(Map<String, dynamic> map) {
    return SalesEntity(
      createdDate: Timestamp.fromMillisecondsSinceEpoch(
        _toInt(map['createdDateMs'],
            fallback: DateTime.now().millisecondsSinceEpoch),
      ),
      discountedPrice: _toDouble(map['discountedPrice']),
      freight: _toDouble(map['freight']),
      id: (map['id'] ?? '').toString(),
      installmentsNumber: _toInt(map['installmentsNumber'], fallback: 1),
      paymentMethod: (map['paymentMethod'] ?? '').toString(),
      price: _toDouble(map['price']),
      productsList: _toProductsList(map['productsList']),
      totalPrice: _toDouble(map['totalPrice']),
      userBirthDate: Timestamp.fromMillisecondsSinceEpoch(
        _toInt(map['userBirthDateMs'],
            fallback: DateTime(1970, 1, 1).millisecondsSinceEpoch),
      ),
      userGender: (map['userGender'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
    );
  }

  static List<Map<String, dynamic>> _toProductsList(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}
