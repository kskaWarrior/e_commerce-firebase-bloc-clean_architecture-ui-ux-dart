import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/register_sale_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/repository/auth_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/repository/category_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/source/category_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/repository/favorite_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/source/favorites_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/repository_impl/products_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/source/products_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/repository/address_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/source/viacep_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/repository/address_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/usecases/lookup_cep.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/repository/sales_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/source/sales_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/is_logged_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/send_password_reset_email.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/update_user.dart';
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
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/tenant_collections.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_product_by_id_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/store/repository/store_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/store/source/store_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/repository/store_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/get_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/update_store_branding.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_all_products_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/upsert_product_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/delete_product_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/upload_product_image_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/upsert_category_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/delete_category_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/upload_category_image_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/update_sale_status.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //tenant context (shopper builds are pinned to one store at compile time;
  //the admin app calls StoreContext.set() after owner login instead)
  final storeContext = StoreContext();
  if (BrandConfig.isConfigured) {
    storeContext.set(BrandConfig.storeId);
  }
  sl.registerSingleton<StoreContext>(storeContext);
  sl.registerSingleton<TenantCollections>(
      TenantCollections(FirebaseFirestore.instance, storeContext));

  //services
  sl.registerSingleton<FirebaseService>(
      FirebaseServiceImpl(sl<TenantCollections>()));

  sl.registerSingleton<CategoryFirebaseService>(
      CategoryFirebaseServiceImpl(sl<TenantCollections>()));

  sl.registerSingleton<ProductsFirebaseService>(
      ProductsFirebaseServiceImpl(sl<TenantCollections>()));

  sl.registerSingleton<FavoritesFirebaseService>(
      FavoritesFirebaseServiceImpl(sl<TenantCollections>()));

  sl.registerSingleton<SalesFirebaseService>(
      SalesFirebaseServiceImpl(sl<TenantCollections>()));

  sl.registerSingleton<StoreFirebaseService>(
      StoreFirebaseServiceImpl(sl<TenantCollections>()));

  sl.registerSingleton<ViaCepService>(ViaCepServiceImpl());

  //repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl());

  sl.registerLazySingleton<ProductsRepository>(() => ProductsRepositoryImpl());

  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl());

  sl.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl());

  sl.registerLazySingleton<StoreRepository>(() => StoreRepositoryImpl());

  sl.registerLazySingleton<AddressRepository>(() => AddressRepositoryImpl());

  //usecases
  sl.registerLazySingleton<SignupUseCase>(() => SignupUseCase());
  sl.registerLazySingleton<UpdateUserUseCase>(() => UpdateUserUseCase());
  sl.registerLazySingleton<SigninUseCase>(() => SigninUseCase());
  sl.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase());
  sl.registerLazySingleton<SendPasswordEmailResetUseCase>(
      () => SendPasswordEmailResetUseCase());
  sl.registerLazySingleton<IsLoggedInUseCase>(() => IsLoggedInUseCase());
  sl.registerLazySingleton<GetUserUseCase>(() => GetUserUseCase());
  sl.registerLazySingleton<UploadProfileImageUseCase>(
      () => UploadProfileImageUseCase());
  sl.registerLazySingleton<GetCategoriesUseCase>(() => GetCategoriesUseCase());
  sl.registerLazySingleton<GetTopSellingProductsUseCase>(
      () => GetTopSellingProductsUseCase());
  sl.registerLazySingleton<GetNewInProductsUseCase>(
      () => GetNewInProductsUseCase());
  sl.registerLazySingleton<GetProductByIdUseCase>(
      () => GetProductByIdUseCase());
  sl.registerLazySingleton<GetFavoritesByUserIdUseCase>(
      () => GetFavoritesByUserIdUseCase());
  sl.registerLazySingleton<RegisterFavoriteUseCase>(
      () => RegisterFavoriteUseCase());
  sl.registerLazySingleton<DeleteFavoriteUseCase>(
      () => DeleteFavoriteUseCase());
  sl.registerLazySingleton<GetSalesByUserIdUseCase>(
      () => GetSalesByUserIdUseCase());
  sl.registerLazySingleton<RegisterSaleUseCase>(() => RegisterSaleUseCase());
  sl.registerLazySingleton<LookupCepUseCase>(() => LookupCepUseCase());

  //admin usecases
  sl.registerLazySingleton<GetStoreUseCase>(() => GetStoreUseCase());
  sl.registerLazySingleton<UpdateStoreBrandingUseCase>(
      () => UpdateStoreBrandingUseCase());
  sl.registerLazySingleton<GetAllProductsUseCase>(
      () => GetAllProductsUseCase());
  sl.registerLazySingleton<UpsertProductUseCase>(() => UpsertProductUseCase());
  sl.registerLazySingleton<DeleteProductUseCase>(() => DeleteProductUseCase());
  sl.registerLazySingleton<UploadProductImageUseCase>(
      () => UploadProductImageUseCase());
  sl.registerLazySingleton<UpsertCategoryUseCase>(
      () => UpsertCategoryUseCase());
  sl.registerLazySingleton<DeleteCategoryUseCase>(
      () => DeleteCategoryUseCase());
  sl.registerLazySingleton<UploadCategoryImageUseCase>(
      () => UploadCategoryImageUseCase());
  sl.registerLazySingleton<GetSalesByStoreUseCase>(
      () => GetSalesByStoreUseCase());
  sl.registerLazySingleton<UpdateSaleStatusUseCase>(
      () => UpdateSaleStatusUseCase());

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
  sl.registerFactory<RegisterSaleCubit>(
    () => RegisterSaleCubit(
      registerSaleUseCase: sl<RegisterSaleUseCase>(),
    ),
  );
  sl.registerFactory<GetSalesByUserIdCubit>(
    () => GetSalesByUserIdCubit(
      getSalesByUserIdUseCase: sl<GetSalesByUserIdUseCase>(),
    ),
  );
}
