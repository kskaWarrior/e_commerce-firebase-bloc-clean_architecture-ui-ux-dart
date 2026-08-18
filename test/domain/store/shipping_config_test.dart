import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/shipping_config_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const capital = ShippingZone(
    label: 'Capital',
    cepStart: '01000000',
    cepEnd: '05999999',
    fee: 15.9,
  );
  const interior = ShippingZone(
    label: 'Interior',
    cepStart: '06000000',
    cepEnd: '19999999',
    fee: 29.9,
  );

  group('ShippingZone.contains', () {
    test('inclusive at both range boundaries', () {
      expect(capital.contains('01000000'), isTrue);
      expect(capital.contains('05999999'), isTrue);
      expect(capital.contains('00999999'), isFalse);
      expect(capital.contains('06000000'), isFalse);
    });

    test('accepts masked CEP input', () {
      expect(capital.contains('01310-100'), isTrue);
    });

    test('rejects malformed CEP', () {
      expect(capital.contains('123'), isFalse);
      expect(capital.contains(''), isFalse);
    });
  });

  group('ShippingConfig.feeFor', () {
    const config = ShippingConfig(
      pickupEnabled: true,
      freeShippingThreshold: 200.0,
      zones: [capital, interior],
    );

    test('first matching zone wins', () {
      const overlapping = ShippingConfig(
        zones: [
          ShippingZone(
              label: 'A', cepStart: '01000000', cepEnd: '09999999', fee: 10),
          ShippingZone(
              label: 'B', cepStart: '01000000', cepEnd: '05999999', fee: 99),
        ],
      );
      expect(overlapping.feeFor('01310100', subtotal: 50), 10);
    });

    test('returns the zone fee below the threshold', () {
      expect(config.feeFor('01310100', subtotal: 199.99), 15.9);
      expect(config.feeFor('07000000', subtotal: 50), 29.9);
    });

    test('free shipping at or above the threshold', () {
      expect(config.feeFor('01310100', subtotal: 200.0), 0);
      expect(config.feeFor('07000000', subtotal: 350.0), 0);
    });

    test('null threshold never grants free shipping', () {
      const noThreshold = ShippingConfig(zones: [capital]);
      expect(noThreshold.feeFor('01310100', subtotal: 100000), 15.9);
    });

    test('unserviceable CEP returns null even above threshold', () {
      expect(config.feeFor('99999999', subtotal: 500), isNull);
    });

    test('round-trips through toMap/fromMap', () {
      final restored = ShippingConfig.fromMap(config.toMap());
      expect(restored.pickupEnabled, isTrue);
      expect(restored.freeShippingThreshold, 200.0);
      expect(restored.zones.length, 2);
      expect(restored.feeFor('01310100', subtotal: 10), 15.9);
    });

    test('fromMap(null) yields empty config with no delivery', () {
      final config = ShippingConfig.fromMap(null);
      expect(config.pickupEnabled, isFalse);
      expect(config.zones, isEmpty);
      expect(config.feeFor('01310100', subtotal: 10), isNull);
    });
  });
}
