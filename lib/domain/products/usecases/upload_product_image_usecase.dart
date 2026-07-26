import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';

class UploadProductImageParams {
  final Uint8List bytes;
  final String contentType;
  final String fileName;

  UploadProductImageParams({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });
}

class UploadProductImageUseCase
    implements UseCase<Either, UploadProductImageParams> {
  @override
  Future<Either> call(UploadProductImageParams params) async {
    return await sl<ProductsRepository>()
        .uploadProductImage(params.bytes, params.contentType, params.fileName);
  }
}
