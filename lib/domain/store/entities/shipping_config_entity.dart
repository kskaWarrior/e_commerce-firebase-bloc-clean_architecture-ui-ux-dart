import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';

class ShippingZone {
  final String label;

  /// 8-digit CEP range bounds, inclusive; fixed-length string compare.
  final String cepStart;
  final String cepEnd;
  final double fee;

  const ShippingZone({
    required this.label,
    required this.cepStart,
    required this.cepEnd,
    required this.fee,
  });

  bool contains(String cep) {
    final normalized = AddressEntity.normalizeCep(cep);
    if (normalized.length != 8 ||
        cepStart.length != 8 ||
        cepEnd.length != 8) {
      return false;
    }
    return cepStart.compareTo(normalized) <= 0 &&
        normalized.compareTo(cepEnd) <= 0;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'cepStart': cepStart,
      'cepEnd': cepEnd,
      'fee': fee,
    };
  }

  factory ShippingZone.fromMap(Map<String, dynamic> map) {
    final feeRaw = map['fee'];
    return ShippingZone(
      label: (map['label'] ?? '').toString(),
      cepStart: AddressEntity.normalizeCep((map['cepStart'] ?? '').toString()),
      cepEnd: AddressEntity.normalizeCep((map['cepEnd'] ?? '').toString()),
      fee: feeRaw is num ? feeRaw.toDouble() : 0.0,
    );
  }
}

class ShippingConfig {
  final bool pickupEnabled;

  /// Subtotal at or above which delivery is free; null disables.
  final double? freeShippingThreshold;

  /// Ordered; first matching zone wins.
  final List<ShippingZone> zones;

  const ShippingConfig({
    this.pickupEnabled = false,
    this.freeShippingThreshold,
    this.zones = const [],
  });

  static const empty = ShippingConfig();

  /// Fee for delivering to [cep] with the given cart [subtotal], or null when
  /// no zone covers the CEP (delivery unavailable).
  double? feeFor(String cep, {required double subtotal}) {
    for (final zone in zones) {
      if (zone.contains(cep)) {
        final threshold = freeShippingThreshold;
        if (threshold != null && subtotal >= threshold) return 0;
        return zone.fee;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pickupEnabled': pickupEnabled,
      'freeShippingThreshold': freeShippingThreshold,
      'zones': zones.map((zone) => zone.toMap()).toList(),
    };
  }

  factory ShippingConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    final thresholdRaw = map['freeShippingThreshold'];
    final zonesRaw = map['zones'];
    return ShippingConfig(
      pickupEnabled: map['pickupEnabled'] == true,
      freeShippingThreshold:
          thresholdRaw is num ? thresholdRaw.toDouble() : null,
      zones: zonesRaw is List
          ? zonesRaw
              .whereType<Map>()
              .map((zone) =>
                  ShippingZone.fromMap(Map<String, dynamic>.from(zone)))
              .toList()
          : const [],
    );
  }
}
