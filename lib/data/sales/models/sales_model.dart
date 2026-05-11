import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';

class SalesModel {
  final Timestamp createdDate;
  final double discountedPrice;
  final double freight;
  final String id;
  final int installmentsNumber;
  final String paymentMethod;
  final double price;
  final List<Map<String, dynamic>> productsList;
  final double totalPrice;
  final Timestamp userBirthDate;
  final String userId;
  final String userName;

  SalesModel({
    required this.createdDate,
    required this.discountedPrice,
    required this.freight,
    required this.id,
    required this.installmentsNumber,
    required this.paymentMethod,
    required this.price,
    required this.productsList,
    required this.totalPrice,
    required this.userBirthDate,
    required this.userId,
    required this.userName,
  });

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  static int _toInt(dynamic value, {int fallback = 1}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static Timestamp _toTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    }
    return Timestamp.now();
  }

  static List<Map<String, dynamic>> _toProductsList(Map<String, dynamic> map) {
    final rawItems = map['productsList'] ?? map['productsIds'];

    if (rawItems is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  factory SalesModel.fromMap(Map<String, dynamic> map) {
    return SalesModel(
      createdDate: _toTimestamp(map['createdDate']),
      discountedPrice: _toDouble(map['discountedPrice']),
      freight: _toDouble(map['freight']),
      id: (map['id'] ?? '').toString(),
      installmentsNumber: _toInt(map['installmentsNumber']),
      paymentMethod: (map['paymentMethod'] ?? 'Unknown').toString(),
      price: _toDouble(map['price']),
      productsList: _toProductsList(map),
      totalPrice: _toDouble(map['totalPrice']),
      userBirthDate: _toTimestamp(map['userBirthDate']),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
    );
  }

  factory SalesModel.fromEntity(SalesEntity entity) {
    return SalesModel(
      createdDate: entity.createdDate,
      discountedPrice: entity.discountedPrice,
      freight: entity.freight,
      id: entity.id,
      installmentsNumber: entity.installmentsNumber,
      paymentMethod: entity.paymentMethod,
      price: entity.price,
      productsList: entity.productsList,
      totalPrice: entity.totalPrice,
      userBirthDate: entity.userBirthDate,
      userId: entity.userId,
      userName: entity.userName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'createdDate': createdDate,
      'discountedPrice': discountedPrice,
      'freight': freight,
      'id': id,
      'installmentsNumber': installmentsNumber,
      'paymentMethod': paymentMethod,
      'price': price,
      'productsList': productsList,
      'totalPrice': totalPrice,
      'userBirthDate': userBirthDate,
      'userId': userId,
      'userName': userName,
    };
  }
}

extension SalesXModel on SalesModel {
  SalesEntity toEntity() {
    return SalesEntity(
      createdDate: createdDate,
      discountedPrice: discountedPrice,
      freight: freight,
      id: id,
      installmentsNumber: installmentsNumber,
      paymentMethod: paymentMethod,
      price: price,
      productsList: productsList,
      totalPrice: totalPrice,
      userBirthDate: userBirthDate,
      userId: userId,
      userName: userName,
    );
  }
}
