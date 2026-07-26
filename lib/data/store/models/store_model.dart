import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';

class StoreModel {
  final String id;
  final String name;
  final String status;
  final String plan;
  final String ownerUid;
  final Map<String, dynamic> branding;

  StoreModel({
    required this.id,
    required this.name,
    required this.status,
    required this.plan,
    required this.ownerUid,
    required this.branding,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    final brandingRaw = map['branding'];
    return StoreModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      plan: (map['plan'] ?? 'free').toString(),
      ownerUid: (map['ownerUid'] ?? '').toString(),
      branding: brandingRaw is Map
          ? Map<String, dynamic>.from(brandingRaw)
          : <String, dynamic>{},
    );
  }
}

extension StoreXModel on StoreModel {
  StoreEntity toEntity() {
    return StoreEntity(
      id: id,
      name: name,
      status: status,
      plan: plan,
      ownerUid: ownerUid,
      branding: branding,
    );
  }
}
