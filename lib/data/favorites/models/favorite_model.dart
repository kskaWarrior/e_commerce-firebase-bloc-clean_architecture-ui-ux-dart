import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final Timestamp createdDate;
  final String id;
  final String productId;
  final String userId;

  FavoriteModel({
    required this.createdDate,
    required this.id,
    required this.productId,
    required this.userId,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      createdDate: map['createdDate'] as Timestamp,
      id: map['id'] as String,
      productId: map['productId'] as String,
      userId: map['userId'] as String,
    );
  }
}
