import '../../di/global_injection/app_locator.dart';
import 'email_service.dart';

void registerEmailService() {
  AppLocator.I.registerSingleton<EmailService>(EmailService());
}
