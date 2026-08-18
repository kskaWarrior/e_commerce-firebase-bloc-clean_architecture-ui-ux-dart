class AddressEntity {
  final String cep;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;

  const AddressEntity({
    required this.cep,
    required this.street,
    this.number = '',
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  bool get isComplete =>
      cep.length == 8 && street.isNotEmpty && city.isNotEmpty && state.isNotEmpty;

  /// Legacy single-line form kept on the user doc's `address` string field.
  String toDisplayString() {
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (number.isNotEmpty) number,
      if (complement.isNotEmpty) complement,
      if (neighborhood.isNotEmpty) neighborhood,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (cep.isNotEmpty) 'CEP $cep',
    ];
    return parts.join(', ');
  }

  AddressEntity copyWith({
    String? cep,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
  }) {
    return AddressEntity(
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  /// Strips non-digits; a valid CEP normalizes to 8 digits.
  static String normalizeCep(String raw) =>
      raw.replaceAll(RegExp(r'\D'), '');
}
