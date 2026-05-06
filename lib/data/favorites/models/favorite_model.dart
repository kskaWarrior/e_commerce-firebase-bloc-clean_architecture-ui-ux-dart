import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';

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

  factory FavoriteModel.fromEntity(FavoriteEntity entity) {
    return FavoriteModel(
      createdDate: entity.createdDate,
      id: entity.id,
      productId: entity.productId,
      userId: entity.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'createdDate': createdDate,
      'id': id,
      'productId': productId,
      'userId': userId,
    };
  }
}

extension FavoriteXModel on FavoriteModel {
  FavoriteEntity toEntity() {
    return FavoriteEntity(
      createdDate: createdDate,
      id: id,
      productId: productId,
      userId: userId,
    );
  }
}
