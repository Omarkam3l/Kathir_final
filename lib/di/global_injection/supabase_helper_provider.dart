import '../../core/supabase/supabase_helper.dart';
import 'app_locator.dart';

void registerSupabaseHelper() {
  AppLocator.I.registerSingleton<SupabaseHelper>(SupabaseHelper());
}
