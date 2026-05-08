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

  UserModel(
      {required this.id,
      required this.email,
      required this.address,
      required this.phone,
      required this.name,
      required this.birthDate,
      required this.gender});

  static DateTime _dateOnlyFromDateTime(DateTime input) {
    final DateTime utcDate = input.toUtc();
    return DateTime(utcDate.year, utcDate.month, utcDate.day);
  }

  static DateTime _dateOnlyFromEpochMs(int epochMs) {
    final DateTime utcDate =
        DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
    return DateTime(utcDate.year, utcDate.month, utcDate.day);
  }

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
    final dynamic birthDateRaw = map['birthDate'];
    DateTime parsedBirthDate = DateTime(2000, 1, 1);
    if (birthDateRaw is Timestamp) {
      parsedBirthDate = _dateOnlyFromDateTime(birthDateRaw.toDate());
    } else if (birthDateRaw is int) {
      parsedBirthDate = _dateOnlyFromEpochMs(birthDateRaw);
    } else if (birthDateRaw is String) {
      final DateTime? parsed = DateTime.tryParse(birthDateRaw);
      if (parsed != null) {
        parsedBirthDate = _dateOnlyFromDateTime(parsed);
      }
    }

    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      name: map['name'] as String? ?? '',
      birthDate: parsedBirthDate,
      gender: map['gender'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
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
