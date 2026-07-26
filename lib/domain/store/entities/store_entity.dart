class StoreEntity {
  final String id;
  final String name;
  final String status;
  final String plan;
  final String ownerUid;
  final Map<String, dynamic> branding;

  StoreEntity({
    required this.id,
    required this.name,
    this.status = 'active',
    this.plan = 'free',
    this.ownerUid = '',
    this.branding = const {},
  });
}
