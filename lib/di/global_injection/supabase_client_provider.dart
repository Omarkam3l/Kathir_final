import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_locator.dart';

void registerSupabaseClient() {
  AppLocator.I.registerSingleton<SupabaseClient>(Supabase.instance.client);
}
