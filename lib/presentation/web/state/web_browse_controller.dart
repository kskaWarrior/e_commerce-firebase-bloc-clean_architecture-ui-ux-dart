import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:flutter/foundation.dart';

/// Shared, app-wide browse state for the web storefront.
///
/// The site-wide header (search box + category strip) writes to this
/// singleton and returns the user to the home page; the home page listens and
/// renders the results in place — search results replace the hero banner, and
/// a selected category renders an inline gallery below the category cards.
///
/// Search and category are mutually exclusive: setting one clears the other.
/// Modeled on [CartDraftStore] (a ChangeNotifier singleton).
class WebBrowseController extends ChangeNotifier {
  WebBrowseController._();

  static final WebBrowseController instance = WebBrowseController._();

  String _query = '';
  CategoriesEntity? _category;

  String get query => _query;
  CategoriesEntity? get category => _category;

  bool get hasQuery => _query.trim().isNotEmpty;
  bool get hasCategory => _category != null;

  /// Sets the active search query (and clears any selected category).
  void search(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _query = trimmed;
    _category = null;
    notifyListeners();
  }

  /// Selects a category to browse inline (and clears any search query).
  void selectCategory(CategoriesEntity category) {
    _category = category;
    _query = '';
    notifyListeners();
  }

  void clearSearch() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  void clearCategory() {
    if (_category == null) return;
    _category = null;
    notifyListeners();
  }

  /// Clears both — used when the home page mounts fresh (e.g. after sign-in).
  void reset() {
    if (_query.isEmpty && _category == null) return;
    _query = '';
    _category = null;
    notifyListeners();
  }
}
