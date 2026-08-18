class PaymentPreferenceEntity {
  final String preferenceId;
  final String? initPoint;
  final String? sandboxInitPoint;
  final double total;
  final double freight;

  const PaymentPreferenceEntity({
    required this.preferenceId,
    this.initPoint,
    this.sandboxInitPoint,
    required this.total,
    required this.freight,
  });

  /// URL the shopper should be sent to for Checkout Pro.
  String? get checkoutUrl => initPoint ?? sandboxInitPoint;
}
