// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';

class UserModel {
  final String id;
  final String email;
  final String address;
  final String phone;
  final String name;
  final DateTime birthDate;
  final String gender;

  UserModel({
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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
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

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

}

extension UserXModel on UserModel {
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      address: address,
      phone: phone,
      name: name,
      birthDate: birthDate,
      gender: gender,
    );
  }
}
