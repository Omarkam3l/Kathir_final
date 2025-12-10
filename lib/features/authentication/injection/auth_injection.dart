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
import '../../authentication/presentation/viewmodels/auth_viewmodel.dart';
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
  AppLocator.I.registerFactory<UploadLegalDocumentsUseCase>(() => UploadLegalDocumentsUseCase(authRepo));
  AppLocator.I.registerFactory<SocialLoginUseCase>(() => SocialLoginUseCase(authRepo));
  AppLocator.I.registerFactory<CreateOrGetProfileUseCase>(() => CreateOrGetProfileUseCase(profileRepo));

  AppLocator.I.registerFactory<AuthViewModel>(() => AuthViewModel(
        signIn: AppLocator.I.get<SignInUseCase>(),
        signUp: AppLocator.I.get<SignUpUseCase>(),
        uploadDocs: AppLocator.I.get<UploadLegalDocumentsUseCase>(),
        socialLogin: AppLocator.I.get<SocialLoginUseCase>(),
        createOrGetProfile: AppLocator.I.get<CreateOrGetProfileUseCase>(),
      ));
}
