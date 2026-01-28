import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/user_role.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../data/models/user_model.dart';

class AuthUserView {
  final String id;
  final String name;
  final String fullName; // alias for name, for compatibility
  final String email;
  final String? phone;
  final List<String> addresses;
  final List<Map<String, dynamic>> cards;
  final String role;
  final String? defaultLocation;
  final String approvalStatus;
  // TODO: Add organizationName from NGO/restaurant table if needed
  const AuthUserView({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.addresses = const [],
    this.cards = const [],
    this.role = 'user',
    this.defaultLocation,
    this.approvalStatus = 'pending',
  }) : fullName = name;

  /// Check if user needs approval (restaurant or NGO)
  bool get needsApproval => role == 'rest' || role == 'ngo';

  /// Check if user is approved
  bool get isApproved => approvalStatus == 'approved';
}


class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = AppLocator.I.get<SupabaseClient>();
  bool _loggedIn = false;
  bool _passwordRecovery = false;
  Map<String, dynamic>? _userProfile;
  AuthProvider() {
    _loggedIn = _client.auth.currentSession != null;
    if (_loggedIn) {
      _syncUserProfile();
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
        _syncUserProfile();
      }
      notifyListeners();
    });
  }
  bool get isLoggedIn => _loggedIn;
  bool get isPasswordRecovery => _passwordRecovery;

  void endPasswordRecovery() {
    _passwordRecovery = false;
    notifyListeners();
  }

  AuthUserView? get user {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    final meta = u.userMetadata ?? const <String, dynamic>{};
    final addresses =
        (meta['addresses'] as List?)?.map((e) => e.toString()).toList() ??
            const [];
    final cards = (meta['cards'] as List?)
            ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
            .toList()
            .cast<Map<String, dynamic>>() ??
        const [];
    final model = UserModelFactory.fromAuthUser(u);

    final role = (_userProfile?['role'] as String?) ??
        (meta['role'] as String?) ??
        'user';

    return AuthUserView(
      id: model.id,
      name: model.fullName,
      email: model.email,
      phone: model.phoneNumber,
      addresses: addresses,
      cards: cards,
      role: role,
      defaultLocation: _userProfile?['default_location'] as String?,
      approvalStatus: (_userProfile?['approval_status'] as String?) ?? 'pending',
      // TODO: Fetch organizationName from NGO/restaurant table if needed
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
        // TODO: Add organizationName to NGO/restaurant table after profile creation
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
      await _syncUserProfile();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
    final ok = _client.auth.currentSession != null;
    _loggedIn = ok;
    if (ok) {
      await _syncUserProfile();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithFacebook() async {
    await _client.auth.signInWithOAuth(OAuthProvider.facebook);
    final ok = _client.auth.currentSession != null;
    _loggedIn = ok;
    if (ok) {
      await _syncUserProfile();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> loginWithApple() async {
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
    final ok = _client.auth.currentSession != null;
    _loggedIn = ok;
    if (ok) {
      await _syncUserProfile();
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

  Future<void> _syncUserProfile() async {
    final current = _client.auth.currentUser;
    if (current == null) {
      _userProfile = null;
      return;
    }
    try {
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', current.id)
          .maybeSingle();

      if (existing == null) {
        final newProfile = {
          'id': current.id,
          'email': current.email ?? '',
          'full_name': (current.userMetadata?['full_name'] as String?) ?? '',
          'role': (current.userMetadata?['role'] as String?) ?? 'user',
          'phone_number': (current.userMetadata?['phone_number'] as String?),
          'is_verified': current.emailConfirmedAt != null,
        };
        await _client.from('profiles').upsert(newProfile);
        _userProfile = newProfile;
      } else {
        _userProfile = existing;
      }
      notifyListeners();
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

  void logout() {
    // alias for existing signOut
    signOut();
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
    final List<dynamic> list =
        List<dynamic>.from(meta['addresses'] as List? ?? const []);
    list.add(address);
    meta['addresses'] = list;
    await _client.auth.updateUser(UserAttributes(data: meta));
  }

  Future<void> addCard(Map<String, dynamic> card) async {
    final current = _client.auth.currentUser;
    if (current == null) return;
    final meta = Map<String, dynamic>.from(current.userMetadata ?? {});
    final List<dynamic> list =
        List<dynamic>.from(meta['cards'] as List? ?? const []);
    list.add(card);
    meta['cards'] = list;
    await _client.auth.updateUser(UserAttributes(data: meta));
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    // Supabase updates password for the current session user
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    return true;
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
