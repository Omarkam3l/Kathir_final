import 'package:supabase/supabase.dart';
import '../../../di/global_injection/app_locator.dart';
import '../../authentication/data/datasources/auth_remote_datasource.dart';
import '../../authentication/data/datasources/profile_remote_datasource.dart';
import '../../authentication/data/repositories/auth_repository_impl.dart';
import '../../authentication/data/repositories/profile_repository_impl.dart';
import '../../authentication/domain/repositories/auth_repository.dart';
import '../../authentication/domain/repositories/profile_repository.dart';
import '../../authentication/domain/usecases/sign_in_usecase.dart';
import '../../authentication/domain/usecases/sign_up_usecase.dart';
import '../../authentication/domain/usecases/upload_legal_documents_usecase.dart';
import '../../authentication/domain/usecases/social_login_usecase.dart';
import '../../authentication/domain/usecases/create_or_get_profile_usecase.dart';
import '../../authentication/domain/usecases/send_password_reset_usecase.dart';
import '../../authentication/domain/usecases/verify_signup_otp_usecase.dart';
import '../../authentication/domain/usecases/verify_recovery_otp_usecase.dart';
import '../../authentication/domain/usecases/update_password_usecase.dart';
import '../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../authentication/presentation/viewmodels/forgot_password_viewmodel.dart';
import '../../authentication/presentation/viewmodels/verification_viewmodel.dart';
import '../../authentication/presentation/viewmodels/new_password_viewmodel.dart';
import '../../../core/supabase/supabase_helper.dart';

void registerAuthDependencies() {
  final client = AppLocator.I.get<SupabaseClient>();
  final helper = AppLocator.I.get<SupabaseHelper>();

  final authDs = SupabaseAuthRemoteDataSource(client, helper);
  AppLocator.I.registerSingleton<AuthRemoteDataSource>(authDs);

  final profileDs = SupabaseProfileRemoteDataSource(client, helper);
  AppLocator.I.registerSingleton<ProfileRemoteDataSource>(profileDs);

  final authRepo = AuthRepositoryImpl(authDs);
  AppLocator.I.registerSingleton<AuthRepository>(authRepo);

  final profileRepo = ProfileRepositoryImpl(profileDs);
  AppLocator.I.registerSingleton<ProfileRepository>(profileRepo);

  AppLocator.I.registerFactory<SignInUseCase>(() => SignInUseCase(authRepo));
  AppLocator.I.registerFactory<SignUpUseCase>(() => SignUpUseCase(authRepo));
  AppLocator.I.registerFactory<UploadLegalDocumentsUseCase>(
      () => UploadLegalDocumentsUseCase(authRepo));
  AppLocator.I
      .registerFactory<SocialLoginUseCase>(() => SocialLoginUseCase(authRepo));
  AppLocator.I.registerFactory<CreateOrGetProfileUseCase>(
      () => CreateOrGetProfileUseCase(profileRepo));
  AppLocator.I.registerFactory<SendPasswordResetUseCase>(
      () => SendPasswordResetUseCase(authRepo));
  AppLocator.I.registerFactory<VerifySignupOtpUseCase>(
      () => VerifySignupOtpUseCase(authRepo));
  AppLocator.I.registerFactory<VerifyRecoveryOtpUseCase>(
      () => VerifyRecoveryOtpUseCase(authRepo));
  AppLocator.I.registerFactory<UpdatePasswordUseCase>(
      () => UpdatePasswordUseCase(authRepo));

  AppLocator.I.registerFactory<AuthViewModel>(() => AuthViewModel(
        signIn: AppLocator.I.get<SignInUseCase>(),
        signUp: AppLocator.I.get<SignUpUseCase>(),
        uploadDocs: AppLocator.I.get<UploadLegalDocumentsUseCase>(),
        socialLogin: AppLocator.I.get<SocialLoginUseCase>(),
        createOrGetProfile: AppLocator.I.get<CreateOrGetProfileUseCase>(),
        sendPasswordReset: AppLocator.I.get<SendPasswordResetUseCase>(),
        verifySignupOtp: AppLocator.I.get<VerifySignupOtpUseCase>(),
        verifyRecoveryOtp: AppLocator.I.get<VerifyRecoveryOtpUseCase>(),
        updatePassword: AppLocator.I.get<UpdatePasswordUseCase>(),
      ));

  AppLocator.I.registerFactory<ForgotPasswordViewModel>(
      () => ForgotPasswordViewModel());
  AppLocator.I
      .registerFactory<VerificationViewModel>(() => VerificationViewModel());
  AppLocator.I
      .registerFactory<NewPasswordViewModel>(() => NewPasswordViewModel());
}
