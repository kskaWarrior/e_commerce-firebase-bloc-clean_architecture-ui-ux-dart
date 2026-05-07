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
  final String userId;

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
    required this.userId,
  });
}
