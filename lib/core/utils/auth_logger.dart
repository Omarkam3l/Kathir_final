import 'package:flutter/foundation.dart';

/// Lightweight, structured logger for auth-related flows.
/// - Debug-only by default (won't spam production)
/// - Consistent format: [TIME] LEVEL AUTH: message | key=value,...
/// - Supports error + stackTrace
class AuthLogger {
  AuthLogger._();

  // Toggle (debug-only by default)
  static bool enabled = kDebugMode;

  // --- Public helpers (high-level events) ---

  static void signupAttempt({
    required String role,
    required String email,
  }) {
    info('signup.attempt', ctx: {'role': role, 'email': email});
  }

  static void signupResult({
    required String role,
    required String email,
    String? userId,
    bool? hasSession,
    bool? emailConfirmed,
  }) {
    info('signup.result', ctx: {
      'role': role,
      'email': email,
      if (userId != null) 'userId': userId,
      if (hasSession != null) 'hasSession': hasSession,
      if (emailConfirmed != null) 'emailConfirmed': emailConfirmed,
    });
  }

  static void otpRequested({
    required String email,
    required String type, // e.g. "signup" / "email" / "magiclink"
  }) {
    info('otp.requested', ctx: {'email': email, 'type': type});
  }

  static void otpRequestFailed({
    required String email,
    required String type,
    Object? error,
    StackTrace? stackTrace,
  }) {
    errorLog('otp.request.failed',
        ctx: {'email': email, 'type': type}, error: error, stackTrace: stackTrace);
  }

  static void otpVerifyAttempt({
    required String email,
    required String type,
  }) {
    info('otp.verify.attempt', ctx: {'email': email, 'type': type});
  }

  static void otpVerifyResult({
    required String email,
    required String type,
    required bool success,
    String? userId,
  }) {
    info('otp.verify.result', ctx: {
      'email': email,
      'type': type,
      'success': success,
      if (userId != null) 'userId': userId,
    });
  }

  static void profileCheck({
    required String userId,
    required String role,
    required bool exists,
  }) {
    info('db.profile.check', ctx: {'userId': userId, 'role': role, 'exists': exists});
  }

  static void docUploadAttempt({
    required String userId,
    required String fileName,
  }) {
    info('storage.upload.attempt', ctx: {'userId': userId, 'file': fileName});
  }

  static void docUploadSuccess({
    required String userId,
    required String fileName,
    String? url,
  }) {
    info('storage.upload.success', ctx: {
      'userId': userId,
      'file': fileName,
      if (url != null) 'url': _short(url),
    });
  }

  static void docUploadFailed({
    required String userId,
    required String fileName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    errorLog('storage.upload.failed',
        ctx: {'userId': userId, 'file': fileName}, error: error, stackTrace: stackTrace);
  }

  static void dbOp({
    required String operation, // insert/update/select/rpc/etc.
    required String table,
    String? userId,
    Map<String, Object?>? extra,
  }) {
    info('db.$operation', ctx: {
      'table': table,
      if (userId != null) 'userId': userId,
      ...?extra,
    });
  }

  static void dbOpFailed({
    required String operation,
    required String table,
    String? userId,
    Map<String, Object?>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    errorLog('db.$operation.failed',
        ctx: {'table': table, if (userId != null) 'userId': userId, ...?extra},
        error: error,
        stackTrace: stackTrace);
  }

  // --- Generic log methods (useful anywhere) ---

  static void info(String message, {Map<String, Object?>? ctx}) {
    _log('INFO', message, ctx: ctx);
  }

  static void warn(String message, {Map<String, Object?>? ctx, Object? error, StackTrace? stackTrace}) {
    _log('WARN', message, ctx: ctx, error: error, stackTrace: stackTrace);
  }

  static void errorLog(String message,
      {Map<String, Object?>? ctx, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, ctx: ctx, error: error, stackTrace: stackTrace);
  }

  // --- Internals ---

  static void _log(
    String level,
    String message, {
    Map<String, Object?>? ctx,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    final ts = DateTime.now().toIso8601String();
    final contextStr = _formatCtx(ctx);

    final base = '[$ts] $level AUTH: $message${contextStr.isEmpty ? '' : ' | $contextStr'}';

    if (error != null || stackTrace != null) {
      debugPrint('$base\n  error: ${_formatError(error)}'
          '${stackTrace != null ? '\n  stack: $stackTrace' : ''}');
    } else {
      debugPrint(base);
    }
  }

  static String _formatCtx(Map<String, Object?>? ctx) {
    if (ctx == null || ctx.isEmpty) return '';
    // Keep it deterministic & readable
    final entries = ctx.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .toList();
    return entries.join(', ');
  }

  static String _formatError(Object? error) {
    if (error == null) return 'unknown';
    return error.toString();
  }

  static String _short(String url, {int max = 80}) {
    if (url.length <= max) return url;
    return '${url.substring(0, max)}...';
  }
}
