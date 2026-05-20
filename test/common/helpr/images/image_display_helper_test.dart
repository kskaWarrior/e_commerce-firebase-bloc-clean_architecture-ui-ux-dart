import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/constants/app_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generateCategoryImagePath builds expected url', () {
    const imageName = 'category.png';

    final result = ImageDisplayHelper.generateCategoryImagePath(imageName);

    expect(result, '${AppUrls.categoryImage}$imageName${AppUrls.alt}');
  });

  test('generateProductImagePath builds expected url', () {
    const imageName = 'product.png';

    final result = ImageDisplayHelper.generateProductImagePath(imageName);

    expect(result, '${AppUrls.productImage}$imageName${AppUrls.alt}');
  });
}
