import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/admin_session.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/pages/admin_login_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/pages/select_store_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/categories/pages/admin_categories_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/dashboard/pages/admin_dashboard_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/categories/pages/admin_category_form_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/orders/pages/admin_orders_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/products/pages/admin_product_form_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/products/pages/admin_products_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/settings/pages/store_settings_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/shell/admin_shell.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:go_router/go_router.dart';

GoRouter buildAdminRouter() {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = sl<AdminSession>();
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isSelectStore = location == '/select-store';

      if (!session.isAuthorized) {
        return isLogin ? null : '/login';
      }
      if (!session.hasStore) {
        return isSelectStore ? null : '/select-store';
      }
      if (isLogin || isSelectStore) {
        return '/orders';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const AdminLoginPage()),
      GoRoute(
          path: '/select-store', builder: (_, __) => const SelectStorePage()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const AdminDashboardPage()),
          GoRoute(
              path: '/orders', builder: (_, __) => const AdminOrdersPage()),
          GoRoute(
            path: '/products',
            builder: (_, __) => const AdminProductsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const AdminProductFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    AdminProductFormPage(productId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            builder: (_, __) => const AdminCategoriesPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const AdminCategoryFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => AdminCategoryFormPage(
                    categoryId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
              path: '/settings',
              builder: (_, __) => const StoreSettingsPage()),
        ],
      ),
    ],
  );
}
