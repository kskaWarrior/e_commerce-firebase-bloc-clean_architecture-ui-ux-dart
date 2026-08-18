import 'package:cloud_firestore/cloud_firestore.dart';

class SalesEntity {
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
  final String userGender;
  final String userId;
  final String userName;

  /// Order lifecycle: pending | paid | shipped | delivered | cancelled.
  final String status;

  /// 'delivery' | 'pickup'.
  final String deliveryMethod;

  /// Structured delivery address map (null for pickup).
  final Map<String, dynamic>? address;

  SalesEntity({
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
    required this.userGender,
    required this.userId,
    required this.userName,
    this.status = 'pending',
    this.deliveryMethod = 'delivery',
    this.address,
  });
}
