import 'package:go_router/go_router.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/role_selection_screen.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/verification_screen.dart';
import 'presentation/screens/new_password_screen.dart';

List<GoRoute> authRoutes() => [
  GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
  GoRoute(path: '/role', builder: (context, state) => const RoleSelectionScreen()),
  GoRoute(path: ForgotPasswordScreen.routeName, builder: (context, state) => const ForgotPasswordScreen()),
  GoRoute(path: VerificationScreen.routeName, builder: (context, state) {
    final email = (state.extra as String?) ?? '';
    final mode = state.uri.queryParameters['mode'];
    final forSignup = mode == 'signup';
    return VerificationScreen(email: email, forSignup: forSignup);
  }),
  GoRoute(path: '/verify', builder: (context, state) {
    final email = (state.extra as String?) ?? '';
    final mode = state.uri.queryParameters['mode'];
    final forSignup = mode == 'signup';
    return VerificationScreen(email: email, forSignup: forSignup);
  }),
  GoRoute(path: NewPasswordScreen.routeName, builder: (context, state) => NewPasswordScreen(email: (state.extra as String?) ?? '')),
  GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
];
