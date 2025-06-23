// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String address;
  final String phone;
  final String name;
  final DateTime birthDate;
  final String gender;

  UserModel(
    this.id,
    this.email,
    this.address,
    this.phone,
    this.name,
    this.birthDate,
    this.gender
  );
  

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
      map['id'] as String? ?? '',
      map['email'] as String? ?? '',
      map['address'] as String? ?? '',
      map['phone'] as String? ?? '',
      map['name'] as String? ?? '',
      (map['birthDate'] as Timestamp).toDate(),
      map['gender'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
