import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_helper.dart';
import '../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../features/authentication/data/datasources/profile_remote_datasource.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/data/repositories/profile_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/repositories/profile_repository.dart';
import '../features/authentication/domain/usecases/sign_in_usecase.dart';
import '../features/authentication/domain/usecases/sign_up_usecase.dart';
import '../features/authentication/domain/usecases/upload_legal_documents_usecase.dart';
import '../features/authentication/domain/usecases/social_login_usecase.dart';
import '../features/authentication/domain/usecases/create_or_get_profile_usecase.dart';
import '../features/authentication/domain/usecases/send_password_reset_usecase.dart';
import '../features/authentication/domain/usecases/verify_signup_otp_usecase.dart';
import '../features/authentication/domain/usecases/verify_recovery_otp_usecase.dart';
import '../features/authentication/domain/usecases/update_password_usecase.dart';
import '../features/authentication/domain/usecases/update_profile_legal_docs_usecase.dart';
import '../features/meals/data/datasources/meal_remote_datasource.dart';
import '../features/meals/data/repositories/meal_repository_impl.dart';
import '../features/meals/domain/repositories/meal_repository.dart';
import '../features/meals/domain/usecases/get_available_meals_usecase.dart';
import '../features/restaurants/data/datasources/restaurant_remote_datasource.dart';
import '../features/restaurants/data/repositories/restaurant_repository_impl.dart';
import '../features/restaurants/domain/repositories/restaurant_repository.dart';
import '../features/restaurants/domain/usecases/get_top_restaurants_usecase.dart';
import '../features/authentication/presentation/viewmodels/auth_viewmodel.dart';

final sl = GetIt.instance;

Future<void> registerGetItDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<SupabaseHelper>(() => SupabaseHelper());

  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => SupabaseAuthRemoteDataSource(sl(), sl()));
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => SupabaseProfileRemoteDataSource(sl(), sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerFactory<SignInUseCase>(() => SignInUseCase(sl()));
  sl.registerFactory<SignUpUseCase>(() => SignUpUseCase(sl()));
  sl.registerFactory<UploadLegalDocumentsUseCase>(
      () => UploadLegalDocumentsUseCase(sl()));
  sl.registerFactory<SocialLoginUseCase>(() => SocialLoginUseCase(sl()));
  sl.registerFactory<CreateOrGetProfileUseCase>(() => CreateOrGetProfileUseCase(sl()));
  sl.registerFactory<SendPasswordResetUseCase>(() => SendPasswordResetUseCase(sl()));
  sl.registerFactory<VerifySignupOtpUseCase>(() => VerifySignupOtpUseCase(sl()));
  sl.registerFactory<VerifyRecoveryOtpUseCase>(() => VerifyRecoveryOtpUseCase(sl()));
  sl.registerFactory<UpdatePasswordUseCase>(() => UpdatePasswordUseCase(sl()));
  sl.registerFactory<UpdateProfileLegalDocsUseCase>(
      () => UpdateProfileLegalDocsUseCase(sl()));

  sl.registerLazySingleton<MealRemoteDataSource>(
      () => SupabaseMealRemoteDataSource(sl()));
  sl.registerLazySingleton<MealRepository>(() => MealRepositoryImpl(sl()));
  sl.registerFactory<GetAvailableMealsUseCase>(
      () => GetAvailableMealsUseCase(sl()));

  sl.registerLazySingleton<RestaurantRemoteDataSource>(
      () => SupabaseRestaurantRemoteDataSource(sl()));
  sl.registerLazySingleton<RestaurantRepository>(
      () => RestaurantRepositoryImpl(sl()));
  sl.registerFactory<GetTopRestaurantsUseCase>(
      () => GetTopRestaurantsUseCase(sl()));

  sl.registerFactory<AuthViewModel>(() => AuthViewModel(
        signIn: sl(),
        signUp: sl(),
        uploadDocs: sl(),
        socialLogin: sl(),
        createOrGetProfile: sl(),
        sendPasswordReset: sl(),
        verifySignupOtp: sl(),
        verifyRecoveryOtp: sl(),
        updatePassword: sl(),
        updateProfileLegalDocs: sl(),
      ));
}
