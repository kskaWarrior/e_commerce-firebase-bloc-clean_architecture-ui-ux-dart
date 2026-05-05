import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteEntity {
  final Timestamp createdDate;
  final String id;
  final String productId;
  final String userId;

  FavoriteEntity({
    required this.createdDate,
    required this.id,
    required this.productId,
    required this.userId,
  });
}
