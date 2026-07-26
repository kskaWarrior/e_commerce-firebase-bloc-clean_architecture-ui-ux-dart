import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/constants/app_urls.dart';

class ImageDisplayHelper {

  /// New docs (admin-managed) store full download URLs; legacy demo docs
  /// store bare filenames resolved against the old global Storage folders.
  static bool _isFullUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  static String generateCategoryImagePath(String title) {
    if (_isFullUrl(title)) {
      return title;
    }
    return AppUrls.categoryImage +
           title +
           AppUrls.alt;
  }

  static String generateProductImagePath(String title) {
    if (_isFullUrl(title)) {
      return title;
    }
    return AppUrls.productImage +
           title +
           AppUrls.alt;
  }
}
