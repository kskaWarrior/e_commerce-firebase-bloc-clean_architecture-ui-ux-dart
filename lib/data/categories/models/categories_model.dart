// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';

class CategoriesModel {
  final String id;
  final String title;
  final String image;

  CategoriesModel({
    required this.id,
    required this.title,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'image': image,
    };
  }

  factory CategoriesModel.fromMap(Map<String, dynamic> map) {
    return CategoriesModel(
      id: map['id'] as String,
      title: map['title'] as String,
      image: map['image'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoriesModel.fromJson(String source) => CategoriesModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

extension CategoriesXModel on CategoriesModel {
  CategoriesEntity toEntity() {
    return CategoriesEntity(
      id: id,
      image: image,
      title: title,
    );
  }
}