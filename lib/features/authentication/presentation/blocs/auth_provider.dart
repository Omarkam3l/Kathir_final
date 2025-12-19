import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/user_role.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../data/models/user_model.dart';
import '../../../../core/services/email_service.dart';

class AuthUserView {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> addresses;
  final List<Map<String, dynamic>> cards;
  final String role;
  const AuthUserView({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.addresses = const [],
    this.cards = const [],
    this.role = 'user',
  });
}

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = AppLocator.I.get<SupabaseClient>();
  bool _loggedIn = false;
  bool _passwordRecovery = false;
  AuthProvider() {
    _loggedIn = _client.auth.currentSession != null;
    if (_loggedIn) {
      _ensureProfileExists();
    }
    _client.auth.onAuthStateChange.listen((data) {
      final ev = data.event;
      if (ev == AuthChangeEvent.passwordRecovery) {
        _passwordRecovery = true;
        notifyListeners();
        return;
      }
      _loggedIn = _client.auth.currentSession != null;
      if (_loggedIn) {
        _ensureProfileExists();
      }
      notifyListeners();
    });
  }
  bool get isLoggedIn => _loggedIn;
  bool get isPasswordRecovery => _passwordRecovery;

  AuthUserView? get user {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    final meta = u.userMetadata ?? const <String, dynamic>{};
    final addresses = (meta['addresses'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final cards = (meta['cards'] as List?)?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v))).toList().cast<Map<String, dynamic>>() ?? const [];
    final model = UserModelFactory.fromAuthUser(u);
    return AuthUserView(
      id: model.id,
      name: model.fullName,
      email: model.email,
      phone: model.phoneNumber,
      addresses: addresses,
      cards: cards,
      role: (meta['role'] as String?) ?? 'user',
    );
  }

  Future<void> signup(
    String fullName,
    String email,
    String? phoneNumber,
    UserRole role,
    String password, {
    String? organizationName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        'role': role.wireValue,
        if (organizationName != null) 'organization_name': organizationName,
      },
    );

    final userId = res.user?.id;
    if (userId == null) {
      throw StateError('Signup failed: missing user id');
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'role': role.wireValue,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (organizationName != null) 'organization_name': organizationName,
      'is_verified': role == UserRole.user,
    });
  }

  Future<bool> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final ok = res.session != null;
    _loggedIn = ok;
    if (ok) {
      await _ensureProfileExists();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
    final ok = _client.auth.currentSession != null;
    _loggedIn = ok;
    if (ok) {
      await _ensureProfileExists();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithFacebook() async {
    await _client.auth.signInWithOAuth(OAuthProvider.facebook);
    final ok = _client.auth.currentSession != null;
    _loggedIn = ok;
    if (ok) {
      await _ensureProfileExists();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithApple() async {
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
    final ok = _client.auth.currentSession != null;
    _loggedIn = ok;
    if (ok) {
      await _ensureProfileExists();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithOtp(String email, {String? redirectTo}) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo ?? 'io.supabase.flutter://login-callback/',
    );
    // Email sent; user must complete flow. Session will be set on deep-link return.
    return true;
  }

  Future<void> _ensureProfileExists() async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', current.id)
          .maybeSingle();
      if (existing == null) {
        await _client.from('profiles').upsert({
          'id': current.id,
          'email': current.email ?? '',
          'full_name': (current.userMetadata?['full_name'] as String?) ?? '',
          'role': (current.userMetadata?['role'] as String?) ?? 'user',
          'phone_number': (current.userMetadata?['phone_number'] as String?),
          'is_verified': current.emailConfirmedAt != null,
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _loggedIn = false;
    _passwordRecovery = false;
    notifyListeners();
  }

  Future<void> logout() async {
    // alias for existing signOut
    await signOut();
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    // Update auth user metadata
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          if (name != null) 'full_name': name,
          if (phone != null) 'phone_number': phone,
        },
      ),
    );
    // Upsert into profiles table
    await _client.from('profiles').upsert({
      'id': current.id,
      if (name != null) 'full_name': name,
      if (phone != null) 'phone_number': phone,
      'email': current.email ?? '',
      'role': (current.userMetadata?['role'] as String?) ?? 'user',
      'is_verified': current.emailConfirmedAt != null,
    });
  }

  Future<void> setRole(UserRole role) async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    await _client.auth.updateUser(UserAttributes(data: {
      ...(current.userMetadata ?? const <String, dynamic>{}),
      'role': role.wireValue,
    }));
    await _client.from('profiles').upsert({
      'id': current.id,
      'role': role.wireValue,
    });
    notifyListeners();
  }

  Future<void> addAddress(String address) async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    final meta = Map<String, dynamic>.from(current.userMetadata ?? {});
    final List<dynamic> list = List<dynamic>.from(meta['addresses'] as List? ?? const []);
    list.add(address);
    meta['addresses'] = list;
    await _client.auth.updateUser(UserAttributes(data: meta));
  }

  Future<void> addCard(Map<String, dynamic> card) async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    final meta = Map<String, dynamic>.from(current.userMetadata ?? {});
    final List<dynamic> list = List<dynamic>.from(meta['cards'] as List? ?? const []);
    list.add(card);
    meta['cards'] = list;
    await _client.auth.updateUser(UserAttributes(data: meta));
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return false;

    // 1. Verify current password by re-authenticating
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      
      if (res.session == null) {
        debugPrint('changePassword: Re-authentication failed (no session)');
        return false;
      }
    } catch (e) {
      debugPrint('changePassword: Re-authentication error: $e');
      // Assume wrong password if re-auth fails
      return false;
    }

    // 2. Update password
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      
      // 3. Send notification email
      try {
        final emailService = AppLocator.I.get<EmailService>();
        await emailService.sendPasswordChangedNotification(email);
      } catch (e) {
        debugPrint('Failed to send password changed email: $e');
        // Continue even if email fails, as password was changed
      }

      return true;
    } catch (e) {
      debugPrint('changePassword: Update user error: $e');
      // Rethrow to let UI handle "Update failed" instead of "Wrong password"
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    try {
      await _client.from('profiles').delete().eq('id', current.id);
    } catch (_) {}
    await _client.auth.signOut();
    _loggedIn = false;
    notifyListeners();
  }
}
