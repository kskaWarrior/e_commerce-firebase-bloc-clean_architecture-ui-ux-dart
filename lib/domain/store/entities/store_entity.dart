import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/shipping_config_entity.dart';

class StoreEntity {
  final String id;
  final String name;
  final String status;
  final String plan;
  final String ownerUid;
  final Map<String, dynamic> branding;
  final ShippingConfig shipping;

  StoreEntity({
    required this.id,
    required this.name,
    this.status = 'active',
    this.plan = 'free',
    this.ownerUid = '',
    this.branding = const {},
    this.shipping = ShippingConfig.empty,
  });
}
