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
  final String productId;
  final double totalPrice;
  final String userId;

  SalesModel({
    required this.createdDate,
    required this.discountedPrice,
    required this.freight,
    required this.id,
    required this.installmentsNumber,
    required this.paymentMethod,
    required this.price,
    required this.productId,
    required this.totalPrice,
    required this.userId,
  });

  factory SalesModel.fromMap(Map<String, dynamic> map) {
    return SalesModel(
      createdDate: map['createdDate'] as Timestamp,
      discountedPrice: (map['discountedPrice'] as num).toDouble(),
      freight: (map['freight'] as num).toDouble(),
      id: map['id'] as String,
      installmentsNumber: map['installmentsNumber'] as int,
      paymentMethod: map['paymentMethod'] as String,
      price: (map['price'] as num).toDouble(),
      productId: map['productId'] as String,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      userId: map['userId'] as String,
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
      productId: entity.productId,
      totalPrice: entity.totalPrice,
      userId: entity.userId,
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
      'productId': productId,
      'totalPrice': totalPrice,
      'userId': userId,
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
      productId: productId,
      totalPrice: totalPrice,
      userId: userId,
    );
  }
}
