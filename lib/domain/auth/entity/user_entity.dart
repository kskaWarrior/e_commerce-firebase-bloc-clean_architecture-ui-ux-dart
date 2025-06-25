import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserEntity {
  final String id;
  final String email;
  final String address;
  final String phone;
  final String name;
  final DateTime birthDate;
  final String gender;

  UserEntity({
    required this.id,
    required this.email,
    required this.address,
    required this.phone,
    required this.name,
    required this.birthDate,
    required this.gender
});
  

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'address': address,
      'phone': phone,
      'name': name,
      'birthDate': birthDate.millisecondsSinceEpoch,
      'gender': gender,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      name: map['name'] as String? ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      gender: map['gender'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserEntity.fromJson(String source) => UserEntity.fromMap(json.decode(source) as Map<String, dynamic>);

}