import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/favorites/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/product/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/repository/auth_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/repository/category_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/source/category_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/repository/favorite_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/source/favorites_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/repository_impl/products_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/source/products_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/repository/sales_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/source/sales_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/is_logged_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/send_password_reset_email.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/repository/category_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/repository/favorite_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/register_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_top_selling_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/repository/sales_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {

  //services
  sl.registerSingleton<FirebaseService>(
     FirebaseServiceImpl()
  );
  
  sl.registerSingleton<CategoryFirebaseService>(
    CategoryFirebaseServiceImpl()
  );

  sl.registerSingleton<ProductsFirebaseService>(
    ProductsFirebaseServiceImpl()
  );

  sl.registerSingleton<FavoritesFirebaseService>(
      FavoritesFirebaseServiceImpl());

  sl.registerSingleton<SalesFirebaseService>(SalesFirebaseServiceImpl());

  //repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl());
  
  sl.registerLazySingleton<ProductsRepository>(() => ProductsRepositoryImpl());

  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl());

  sl.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl());
  
  //usecases
  sl.registerLazySingleton<SignupUseCase>(() => SignupUseCase());
  sl.registerLazySingleton<SigninUseCase>(() => SigninUseCase());
  sl.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase());
  sl.registerLazySingleton<SendPasswordEmailResetUseCase>(() => SendPasswordEmailResetUseCase());
  sl.registerLazySingleton<IsLoggedInUseCase>(() => IsLoggedInUseCase());
  sl.registerLazySingleton<GetUserUseCase>(() => GetUserUseCase());
  sl.registerLazySingleton<GetCategoriesUseCase>(() => GetCategoriesUseCase());
  sl.registerLazySingleton<GetTopSellingProductsUseCase>(() => GetTopSellingProductsUseCase());
  sl.registerLazySingleton<GetNewInProductsUseCase>(
      () => GetNewInProductsUseCase());
  sl.registerLazySingleton<GetFavoritesByUserIdUseCase>(
      () => GetFavoritesByUserIdUseCase());
  sl.registerLazySingleton<RegisterFavoriteUseCase>(
      () => RegisterFavoriteUseCase());
  sl.registerLazySingleton<DeleteFavoriteUseCase>(
      () => DeleteFavoriteUseCase());
  sl.registerLazySingleton<RegisterSaleUseCase>(() => RegisterSaleUseCase());

  //cubits
  sl.registerLazySingleton<UserCubit>(() => UserCubit());
  sl.registerFactory<SignOutCubit>(() => SignOutCubit());
  sl.registerLazySingleton<SplashCubit>(() => SplashCubit()); 
  sl.registerFactory<CategoriesCubit>(() => CategoriesCubit()); 
  sl.registerFactory<NewInDisplayCubit>(
      () => NewInDisplayCubit(sl<GetNewInProductsUseCase>()));
  sl.registerFactory<ProductsDisplayCubit>(
      () => ProductsDisplayCubit(sl<GetTopSellingProductsUseCase>()));
  sl.registerFactory<FavoritesCubit>(
    () => FavoritesCubit(
      getFavoritesByUserIdUseCase: sl<GetFavoritesByUserIdUseCase>(),
      registerFavoriteUseCase: sl<RegisterFavoriteUseCase>(),
      deleteFavoriteUseCase: sl<DeleteFavoriteUseCase>(),
    ),
  );
}
