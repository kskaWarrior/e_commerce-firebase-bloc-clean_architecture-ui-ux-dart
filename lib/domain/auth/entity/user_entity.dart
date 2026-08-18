import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';

class UserEntity {
  final String id;
  final String email;
  final String address;
  final AddressEntity? addressData;
  final String phone;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String profileImageUrl;

  UserEntity({
    required this.id,
    required this.email,
    required this.address,
    this.addressData,
    required this.phone,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.profileImageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'address': address,
      'addressData': addressData == null
          ? null
          : AddressModel.fromEntity(addressData!).toMap(),
      'phone': phone,
      'name': name,
      'birthDate': birthDate.millisecondsSinceEpoch,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      addressData: map['addressData'] is Map
          ? AddressModel.fromMap(
              Map<String, dynamic>.from(map['addressData'] as Map))
          : null,
      phone: map['phone'] as String? ?? '',
      name: map['name'] as String? ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      gender: map['gender'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserEntity.fromJson(String source) =>
      UserEntity.fromMap(json.decode(source) as Map<String, dynamic>);
}
