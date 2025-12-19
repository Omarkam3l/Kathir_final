import '../../di/global_injection/supabase_client_provider.dart';
import '../../di/global_injection/supabase_helper_provider.dart';
import '../../features/user_home/injection/home_injection.dart';
import '../../features/authentication/injection/auth_injection.dart';
import '../../injection/forgot_password_injection.dart';
import '../../core/services/email_injection.dart';

Future<void> bootstrapDI() async {
  registerSupabaseClient();
  registerSupabaseHelper();
  registerUserHomeDependencies();
  registerAuthDependencies();
  registerForgotPasswordDependencies();
  registerEmailService();
}
