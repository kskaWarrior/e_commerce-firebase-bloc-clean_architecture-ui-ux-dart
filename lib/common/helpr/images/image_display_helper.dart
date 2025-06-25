import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/constants/app_urls.dart';

class ImageDisplayHelper {

  static String generateCategoryImagePath(String title) {
    return AppUrls.categoryImage + 
           //Uri.encodeComponent(title) + 
           title +
           AppUrls.alt;
  }
}