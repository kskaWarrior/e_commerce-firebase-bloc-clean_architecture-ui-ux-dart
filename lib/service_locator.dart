import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/categories/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/repository/auth_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/repository/category_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/source/category_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/is_logged_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/send_password_reset_email.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/repository/category_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {

  //services
  sl.registerSingleton<FirebaseService>(FirebaseServiceImpl()
  );
  
  sl.registerSingleton<CategoryFirebaseService>(CategoryFirebaseServiceImpl()
  );

  //repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl());
  
  //usecases
  sl.registerLazySingleton<SignupUseCase>(() => SignupUseCase());
  sl.registerLazySingleton<SigninUseCase>(() => SigninUseCase());
  sl.registerLazySingleton<SendPasswordEmailResetUseCase>(() => SendPasswordEmailResetUseCase());
  sl.registerLazySingleton<IsLoggedInUseCase>(() => IsLoggedInUseCase());
  sl.registerLazySingleton<GetUserUseCase>(() => GetUserUseCase());
  sl.registerLazySingleton<GetCategoriesUseCase>(() => GetCategoriesUseCase());

  //cubits
  sl.registerLazySingleton<UserCubit>(() => UserCubit());
  sl.registerLazySingleton<SplashCubit>(() => SplashCubit()); 
  sl.registerLazySingleton<CategoriesCubit>(() => CategoriesCubit()); 
}
