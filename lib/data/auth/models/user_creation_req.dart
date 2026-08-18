import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';

class UserCreationReq {
  final String email;
  final String? password;
  final String? name;
  final String? phone;
  String? gender;
  DateTime? birthDate;
  String? address;
  AddressModel? addressData;
  String? id;

  UserCreationReq({
    this.id,
    required this.email,
    this.password,
    this.name,
    this.phone,
    this.address,
    this.addressData,
    this.birthDate,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'addressData': addressData?.toMap(),
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
    };
  }

  factory UserCreationReq.fromJson(Map<String, dynamic> json) {
    return UserCreationReq(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      addressData: json['addressData'] is Map
          ? AddressModel.fromMap(
              Map<String, dynamic>.from(json['addressData'] as Map))
          : null,
      birthDate: json['birthDate'] != null ? (json['birthDate'] as Timestamp).toDate() : null,
      gender: json['gender'],
    );
  }
}