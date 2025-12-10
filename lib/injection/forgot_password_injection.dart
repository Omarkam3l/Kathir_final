import '../di/global_injection/app_locator.dart';
import '../data/datasource/auth_remote_datasource.dart';
import '../data/repo/forgot_password_repository_impl.dart';
import '../domain/repo/forgot_password_repository.dart';
import '../domain/usecase/send_otp_usecase.dart';
import '../domain/usecase/verify_otp_usecase.dart';
import '../domain/usecase/update_password_usecase.dart';
import '../data/repo/auth_repository_impl.dart';
import '../domain/repo/auth_repository.dart';
import '../features/authentication/presentation/viewmodels/forgot_password_viewmodel.dart';
import '../features/authentication/presentation/viewmodels/verification_viewmodel.dart';
import '../features/authentication/presentation/viewmodels/new_password_viewmodel.dart';

void registerForgotPasswordDependencies() {
  // DataSource
  final ds = AuthRemoteDataSource();
  AppLocator.I.registerSingleton<AuthRemoteDataSource>(ds);
  // Repository
  final repo = ForgotPasswordRepositoryImpl(ds);
  AppLocator.I.registerSingleton<ForgotPasswordRepository>(repo);
  // Also register AuthRepository for existing usecases
  final authRepo = AuthRepositoryImpl(dataSource: ds);
  AppLocator.I.registerSingleton<AuthRepository>(authRepo);
  // Usecases
  AppLocator.I.registerFactory<SendOtpUseCase>(() => SendOtpUseCase(repo));
  AppLocator.I.registerFactory<VerifyOtpUseCase>(() => VerifyOtpUseCase(authRepo));
  AppLocator.I.registerFactory<UpdatePasswordUseCase>(() => UpdatePasswordUseCase(authRepo));
  // ViewModels
  AppLocator.I.registerFactory<ForgotPasswordViewModel>(() => ForgotPasswordViewModel());
  AppLocator.I.registerFactory<VerificationViewModel>(() => VerificationViewModel());
  AppLocator.I.registerFactory<NewPasswordViewModel>(() => NewPasswordViewModel());
}
