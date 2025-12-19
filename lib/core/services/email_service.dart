import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // TODO: Replace with your actual SMTP credentials
  // For Gmail: Use App Password (https://support.google.com/accounts/answer/185833)
  static const String _username = 'your_email@gmail.com';
  static const String _password = 'your_app_password'; 

  Future<void> sendPasswordChangedNotification(String recipientEmail) async {
    // Configure the SMTP server
    // For Gmail, use gmail(_username, _password)
    // For other providers, use SmtpServer(host, username: _username, password: _password)
    final smtpServer = gmail(_username, _password);

    final message = Message()
      ..from = const Address(_username, 'Foodie App Support')
      ..recipients.add(recipientEmail)
      ..subject = 'Security Notification: Password Changed'
      ..text = 'Your password for Foodie App has been successfully changed. If this was not you, please contact support immediately.'
      ..html = '''
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2 style="color: #333;">Password Changed</h2>
          <p>Hello,</p>
          <p>Your password for your <strong>Foodie App</strong> account has been successfully changed.</p>
          <p>If you initiated this change, you can safely ignore this email.</p>
          <p style="color: red;">If you did not make this change, please contact our support team immediately.</p>
          <br>
          <p>Best regards,</p>
          <p>The Foodie App Team</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Email sent: $sendReport');
    } on MailerException catch (e) {
      debugPrint('Message not sent.');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
    }
  }
}
