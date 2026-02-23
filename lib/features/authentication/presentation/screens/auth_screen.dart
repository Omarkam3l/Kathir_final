import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/user_role.dart';
import 'package:kathir_final/features/authentication/presentation/screens/verification_screen.dart';
import 'package:kathir_final/features/authentication/presentation/viewmodels/auth_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import '../../domain/usecases/sign_up_usecase.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathir_final/features/_shared/providers/theme_provider.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  UserRole? _selectedRole = UserRole.user;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _orgNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    isLogin = vm.isLogin;
    _selectedRole = vm.selectedRole ?? (isLogin ? null : UserRole.user);
  }

  void toggleState() {
    setState(() {
      isLogin = !isLogin;
      _selectedRole = isLogin ? null : UserRole.user;
      _formKey.currentState?.reset();
    });
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    vm.setMode(isLogin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a role',
                style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.error),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final vm = Provider.of<AuthViewModel>(context, listen: false);
      final role = _selectedRole == UserRole.user
          ? SignUpRole.user
          : _selectedRole == UserRole.ngo
              ? SignUpRole.ngo
              : SignUpRole.restaurant;
      final ok = await vm.signup(
        role,
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        organizationName: _orgNameController.text.trim().isEmpty
            ? null
            : _orgNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      
      if (ok) {
        if (mounted) GoRouter.of(context).go('/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Check your email to verify your account',
                style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.primary,
          ));
          GoRouter.of(context).push(
              '${VerificationScreen.routeName}?mode=signup',
              extra: _emailController.text.trim());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}',
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final vm = Provider.of<AuthViewModel>(context, listen: false);
      final success = await vm.login(
          _emailController.text.trim(), _passwordController.text);
      if (mounted) {
        if (success) {
          GoRouter.of(context).go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Invalid email or password',
                style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}',
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(String platform) async {
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    bool ok = false;
    try {
      switch (platform.toLowerCase()) {
        case 'google':
          ok = await vm.loginWithProvider(s.OAuthProvider.google);
          break;
        case 'facebook':
          ok = await vm.loginWithProvider(s.OAuthProvider.facebook);
          break;
        case 'apple':
          ok = await vm.loginWithProvider(s.OAuthProvider.apple);
          break;
        case 'otp':
          ok = true;
          break;
      }
      if (ok && mounted) GoRouter.of(context).go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.white : AppColors.darkText;
    const textMuted = AppColors.grey;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLogin)
                _buildLoginHeader(isDark, themeProvider)
              else
                _buildSignUpHeader(isDark, themeProvider),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.5),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isLogin ? 'Welcome Back' : 'Join Kathir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLogin
                            ? 'Log in to your account to start helping.'
                            : 'Connect, donate, and help end food waste.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      if (!isLogin) ...[
                        Text('Select your role',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary)),
                        const SizedBox(height: 10),
                        _buildRoleSegments(isDark, textPrimary, textMuted),
                        const SizedBox(height: 20),
                      ],
                      if (!isLogin &&
                          (_selectedRole == UserRole.ngo ||
                              _selectedRole == UserRole.restaurant)) ...[
                        _AuthInput(
                          label: _selectedRole == UserRole.restaurant
                              ? 'Restaurant Name'
                              : 'Organization Name',
                          hint: _selectedRole == UserRole.restaurant
                              ? 'e.g. Koshary Al-Tahrir'
                              : 'e.g. Egyptian Food Bank',
                          controller: _orgNameController,
                          prefixIcon: Icons.business,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          surface: surface,
                          border: border,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!isLogin)
                        _AuthInput(
                          label: 'Full Name',
                          hint: 'Enter your name',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          surface: surface,
                          border: border,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                      if (!isLogin) const SizedBox(height: 16),
                      _AuthInput(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        surface: surface,
                        border: border,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      if (!isLogin)
                        _AuthInput(
                          label: 'Phone Number',
                          hint: '+20 10 1234 5678',
                          controller: _phoneController,
                          prefixIcon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          surface: surface,
                          border: border,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Phone number is required' : null,
                        ),
                      if (!isLogin) const SizedBox(height: 16),
                      _AuthInput(
                        label: 'Password',
                        hint: isLogin
                            ? 'Enter your password'
                            : 'Create a password',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.primary,
                              size: 22),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        surface: surface,
                        border: border,
                        validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () =>
                                GoRouter.of(context).push('/forgot-password'),
                            child: Text('Forgot Password?',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _PrimaryButton(
                        label: isLogin ? 'Sign In' : 'Create Account',
                        loading: _isLoading,
                        onPressed: isLogin ? _handleLogin : _handleSignUp,
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 20),
                        _buildDivider(textMuted, bg),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(
                                icon: Icons.g_mobiledata,
                                label: 'Google',
                                onTap: () => _handleSocialLogin('Google'),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                surface: surface,
                                border: border),
                            const SizedBox(width: 12),
                            _SocialButton(
                                icon: Icons.facebook,
                                label: 'Facebook',
                                onTap: () => _handleSocialLogin('Facebook'),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                surface: surface,
                                border: border),
                            const SizedBox(width: 12),
                            _SocialButton(
                                icon: Icons.apple,
                                label: 'Apple',
                                onTap: () => _handleSocialLogin('Apple'),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                surface: surface,
                                border: border),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: toggleState,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: textMuted),
                            children: [
                              TextSpan(
                                  text: isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? '),
                              TextSpan(
                                  text: isLogin ? 'Sign Up' : 'Sign In',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginHeader(bool isDark, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      height: 220,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'lib/resources/assets/images/8040836.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.eco,
                      size: 64, color: AppColors.primary)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.transparent,
                    AppColors.black.withValues(alpha: 0.6)
                  ]),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kathir',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
                Text('Connecting food to people.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: AppColors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                  color: AppColors.white),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpHeader(bool isDark, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
              child: Center(
                  child: Text('Sign Up',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.white : AppColors.darkText)))),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? AppColors.white : AppColors.darkText),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSegments(bool isDark, Color textPrimary, Color textMuted) {
    final segments = [
      (UserRole.user, 'Individual', Icons.person_outline),
      (UserRole.restaurant, 'Restaurant', Icons.restaurant_outlined),
      (UserRole.ngo, 'NGO', Icons.handshake_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: segments.map((e) {
          final sel = _selectedRole == e.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRole = e.$1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6)
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    e.$2,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.white : textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDivider(Color textMuted, Color bg) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.dividerLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or continue with',
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted)),
        ),
        const Expanded(child: Divider(color: AppColors.dividerLight)),
      ],
    );
  }
}

class _AuthInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color surface;
  final Color border;
  final String? Function(String?)? validator;

  const _AuthInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.surface,
    required this.border,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.plusJakartaSans(fontSize: 15, color: textMuted),
            prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton(
      {required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white)))
            : Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color textPrimary;
  final Color surface;
  final Color border;

  const _SocialButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.isDark,
      required this.textPrimary,
      required this.surface,
      required this.border});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: textPrimary),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
