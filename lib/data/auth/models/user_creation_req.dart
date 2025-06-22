import 'package:cloud_firestore/cloud_firestore.dart';

class UserCreationReq {
  final String email;
  final String? password;
  final String? name;
  final String? phone;
  String? gender;
  DateTime? birthDate;
  String? address;

  UserCreationReq({
    required this.email,
    this.password,
    this.name,
    this.phone,
    this.address,
    this.birthDate,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
    };
  }

  factory UserCreationReq.fromJson(Map<String, dynamic> json) {
    return UserCreationReq(
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      birthDate: json['birthDate'] != null ? (json['birthDate'] as Timestamp).toDate() : null,
      gender: json['gender'],
    );
  }
}