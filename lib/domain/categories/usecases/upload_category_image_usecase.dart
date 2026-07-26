import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/repository/category_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class UploadCategoryImageParams {
  final Uint8List bytes;
  final String contentType;
  final String fileName;

  UploadCategoryImageParams({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });
}

class UploadCategoryImageUseCase
    implements UseCase<Either, UploadCategoryImageParams> {
  @override
  Future<Either> call(UploadCategoryImageParams params) async {
    return await sl<CategoryRepository>()
        .uploadCategoryImage(params.bytes, params.contentType, params.fileName);
  }
}
