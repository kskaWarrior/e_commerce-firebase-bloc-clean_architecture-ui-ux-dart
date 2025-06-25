import 'dart:convert';

class CategoriesEntity {
  final String id;
  final String title;
  final String image;

  CategoriesEntity({
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

  factory CategoriesEntity.fromMap(Map<String, dynamic> map) {
    return CategoriesEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      image: map['image'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoriesEntity.fromJson(String source) => CategoriesEntity.fromMap(json.decode(source) as Map<String, dynamic>);
}