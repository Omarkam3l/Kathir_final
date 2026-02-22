import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
<<<<<<< HEAD
=======
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/auth_logger.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
import 'package:kathir_final/core/utils/user_role.dart';
import 'package:kathir_final/features/authentication/presentation/screens/verification_screen.dart';
import 'package:kathir_final/features/authentication/presentation/viewmodels/auth_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import '../../domain/usecases/sign_up_usecase.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
<<<<<<< HEAD


=======
import 'package:google_fonts/google_fonts.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
import 'package:kathir_final/features/_shared/providers/theme_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  UserRole? _selectedRole = UserRole.user;
  bool _documentsUploaded = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  List<int>? _legalDocBytes;

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
      _documentsUploaded = false;
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
<<<<<<< HEAD
    final l10n = AppLocalizations.of(context)!;

=======
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a role',
                style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if ((_selectedRole == UserRole.ngo ||
            _selectedRole == UserRole.restaurant) &&
        !_documentsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload your legal documents'),
            backgroundColor: AppColors.warning),
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
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      
      // ✅ FIX: Don't upload documents here - wait until after OTP verification
      // Store document bytes for upload after verification
      if (_legalDocBytes != null && vm.user?.id != null) {
        // Store in viewmodel for later upload
        vm.pendingLegalDocBytes = _legalDocBytes;
        vm.pendingLegalDocFileName = 'legal.pdf';
      }
      
      if (ok) {
        if (mounted) GoRouter.of(context).go('/home');
      } else {
<<<<<<< HEAD
          if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to verify your account'),
              backgroundColor: Colors.teal,
            ),
          );
          GoRouter.of(context).go('${VerificationScreen.routeName}?mode=signup',
=======
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Check your email to verify your account',
                style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.primary,
          ));
          GoRouter.of(context).push(
              '${VerificationScreen.routeName}?mode=signup',
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
              extra: _emailController.text.trim());
          }
      }
    } catch (e) {
      if (mounted) {
<<<<<<< HEAD
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLabel(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
=======
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}',
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.error,
        ));
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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

  Future<void> _uploadDocuments() async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Opening file picker...', style: TextStyle(color: AppColors.white)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
    
    AuthLogger.info('documentPicker.opening', ctx: {
      'role': _selectedRole.toString(),
    });
    
    final res = await FilePicker.platform.pickFiles(
      withReadStream: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    
    if (!mounted) return;
    
    if (res != null && res.files.isNotEmpty) {
      final file = res.files.first;
      _legalDocBytes = file.bytes;
      final fileName = file.name;
      final fileSize = file.size;
      
      AuthLogger.info('documentPicker.selected', ctx: {
        'fileName': fileName,
        'fileSize': fileSize,
        'fileSizeKB': (fileSize / 1024).toStringAsFixed(2),
        'role': _selectedRole.toString(),
      });
      
      if (_legalDocBytes != null) {
        // Validate file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          AuthLogger.warn('documentPicker.fileTooLarge', ctx: {
            'fileName': fileName,
            'fileSize': fileSize,
            'maxSize': 10 * 1024 * 1024,
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'File too large! Maximum size is 10MB',
                  style: TextStyle(color: AppColors.white),
                ),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        
        setState(() => _documentsUploaded = true);
        
        AuthLogger.info('documentPicker.success', ctx: {
          'fileName': fileName,
          'documentsUploaded': true,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document selected successfully!',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$fileName (${(fileSize / 1024).toStringAsFixed(1)} KB)',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      AuthLogger.info('documentPicker.cancelled', ctx: {
        'role': _selectedRole.toString(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
<<<<<<< HEAD
            content: Text('Documents selected'),
            backgroundColor: Colors.teal,
=======
            content: Text(
              'No document selected',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
          ),
        );
      }
    }
  }

  Future<void> _handleSocialLogin(String platform) async {
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
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
<<<<<<< HEAD
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLabel(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
=======
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final isDark = themeProvider.isDarkMode;
<<<<<<< HEAD
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    // Colors
    const Color headerTealTop = Color(0xFF00695C);
    const Color headerTealBottom = Color(0xFF4DB6AC);
    const Color creamyInputFill = Color(0xFFF3F1EB);
    const Color tealBtnStart = Color(0xFF4DB6AC);
    const Color tealBtnEnd = Color(0xFF00BCD4);
    final Color textColorDark = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
=======
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.white : AppColors.darkText;
    const textMuted = AppColors.grey;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Scaffold(
      backgroundColor: bg,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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
<<<<<<< HEAD
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [headerTealTop, headerTealBottom],
                  ),
=======
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.5),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
<<<<<<< HEAD
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLogin
                                ? l10n.launchIdeas
                                : l10n.createAccount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              themeProvider.toggleTheme();
                            },
                          ),
                        ],
=======
                      Text(
                        isLogin ? 'Welcome Back' : 'Join Kathir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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
                              ? 'e.g. Green Leaf Bistro'
                              : 'e.g. Green Earth Foundation',
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
                          hint: '+1 (555) 000-0000',
                          controller: _phoneController,
                          prefixIcon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          surface: surface,
                          border: border,
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
                      if (!isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final email = _emailController.text.trim();
                              if (email.isEmpty) {
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Enter your email first',
                                        style:
                                            TextStyle(color: AppColors.white)),
                                    backgroundColor: AppColors.error));
                                return;
                              }
                              try {
                                await s.Supabase.instance.client.auth.resend(
                                  type: s.OtpType.signup,
                                  email: email,
                                  emailRedirectTo: kIsWeb
                                      ? Uri.base.toString()
                                      : 'io.supabase.flutter://login-callback/',
                                );
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Verification email sent',
                                        style:
                                            TextStyle(color: AppColors.white)),
                                    backgroundColor: AppColors.primary));
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        'Resend failed: ${e.toString()}',
                                        style: const TextStyle(
                                            color: AppColors.white)),
                                    backgroundColor: AppColors.error));
                              }
                            },
                            child: Text('Resend verification email',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                        ),
                      ],
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
                      if (!isLogin &&
                          (_selectedRole == UserRole.ngo ||
                              _selectedRole == UserRole.restaurant)) ...[
                        const SizedBox(height: 20),
                        _buildDocumentUploadSection(
                            isDark, textPrimary, textMuted, surface, border),
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
              color: AppColors.black.withOpacity(0.15),
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
                  color: AppColors.primary.withOpacity(0.2),
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
                    AppColors.black.withOpacity(0.6)
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
                        fontSize: 14, color: AppColors.white.withOpacity(0.9))),
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
            : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: segments.map((e) {
          final sel = _selectedRole == e.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRole = e.$1;
                _documentsUploaded = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 6)
                        ]
                      : null,
                ),
<<<<<<< HEAD
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            isLogin ? "Welcome Back" : "Welcome!",
                            style: TextStyle(
                              color: isDark ? Colors.white : textColorDark,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Role Selection (Sign Up Only)
                        if (!isLogin) ...[
                          Text(
                            l10n.selectYourRole,
                            style: TextStyle(
                              color: isDark ? Colors.white : textColorDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleButton(
                                  UserRole.user,
                                  l10n.roleUser,
                                  Icons.person,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleButton(
                                  UserRole.ngo,
                                  l10n.roleOrg,
                                  Icons.handshake,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleButton(
                                  UserRole.restaurant,
                                  l10n.roleRest,
                                  Icons.restaurant,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Organization Name (Organization/Restaurant Only)
                        if (!isLogin &&
                            (_selectedRole == UserRole.ngo ||
                                _selectedRole == UserRole.restaurant)) ...[
                          CustomInputField(
                            hintText: l10n.orgNameLabel,
                            fillColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : creamyInputFill,
                            controller: _orgNameController,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Name Field (Sign Up Only)
                        if (!isLogin) ...[
                          CustomInputField(
                            hintText: l10n.fullNameLabel,
                            fillColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : creamyInputFill,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        CustomInputField(
                          hintText: l10n.emailLabel,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : creamyInputFill,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Phone Field (Sign Up Only)
                        if (!isLogin) ...[
                          CustomInputField(
                            hintText: "Phone Number (Optional)",
                            fillColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : creamyInputFill,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Password Field
                        CustomInputField(
                          hintText: l10n.passwordLabel,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : creamyInputFill,
                          isPassword: true,
                          controller: _passwordController,
                        ),

                        // Forgot Password Link (Login Only)
                        if (isLogin) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                GoRouter.of(context).go('/forgot-password');
                              },
                              child: Text(
                                l10n.forgotPasswordLink,
                                style: const TextStyle(
                                  color: Color(0xFF0099A6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Resend Verification (Sign Up Only)
                        if (!isLogin) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final email = _emailController.text.trim();
                                final primaryColor = Theme.of(context).colorScheme.primary;
                                final errorColor = Theme.of(context).colorScheme.error;

                                if (email.isEmpty) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.enterEmailFirst),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await s.Supabase.instance.client.auth.resend(
                                    type: s.OtpType.signup,
                                    email: email,
                                    emailRedirectTo: kIsWeb
                                        ? Uri.base.toString()
                                        : 'io.supabase.flutter://login-callback/',
                                  );
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.verificationSent),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          l10n.resendFailed(e.toString())),
                                      backgroundColor: errorColor,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                l10n.resendVerificationLink,
                                style: const TextStyle(
                                  color: Color(0xFF0099A6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Document Upload (NGO/Restaurant Only)
                        if (!isLogin &&
                            (_selectedRole == UserRole.ngo ||
                                _selectedRole == UserRole.restaurant)) ...[
                          const SizedBox(height: 24),
                          _buildDocumentUploadSection(isDark),
                        ],

                        const SizedBox(height: 30),

                        // Action Button
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [tealBtnStart, tealBtnEnd],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tealBtnStart.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (isLogin ? _handleLogin : _handleSignUp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    isLogin ? "Log In" : "Sign Up",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Social Media Login Section (Login Only)
                        if (isLogin) ...[
                          const Center(
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: Color(0xFF607d8b),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialMediaButton(
                                icon: Icons.g_mobiledata,
                                label: 'Google',
                                onTap: () => _handleSocialLogin('Google'),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 16),
                              _buildSocialMediaButton(
                                icon: Icons.facebook,
                                label: 'Facebook',
                                onTap: () => _handleSocialLogin('Facebook'),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 16),
                              _buildSocialMediaButton(
                                icon: Icons.apple,
                                label: 'Apple',
                                onTap: () => _handleSocialLogin('Apple'),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Toggle Text
                        Center(
                          child: GestureDetector(
                            onTap: toggleState,
                            child: RichText(
                              text: TextSpan(
                                text: isLogin
                                    ? l10n.noAccount
                                    : l10n.hasAccount,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: isLogin ? l10n.signupBtn : l10n.loginBtn,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : textColorDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: bottomPadding),
                      ],
=======
                child: Center(
                  child: Text(
                    e.$2,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.white : textMuted,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                    ),
                  ),
                ),
              ),
<<<<<<< HEAD
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      UserRole role, String label, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColorDark = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _documentsUploaded = false;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.2)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white : textColorDark),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
=======
            ),
          );
        }).toList(),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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

<<<<<<< HEAD
  Widget _buildDocumentUploadSection(bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColorDark = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

=======
  Widget _buildDocumentUploadSection(bool isDark, Color textPrimary,
      Color textMuted, Color surface, Color border) {
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputFillDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
<<<<<<< HEAD
          color: _documentsUploaded
              ? primaryColor
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          width: 2,
        ),
=======
            color: _documentsUploaded ? AppColors.primary : border,
            width: _documentsUploaded ? 2 : 1),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
<<<<<<< HEAD
              Icon(
                Icons.description,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Legal Documents Required',
                  style: TextStyle(
                    color: isDark ? Colors.white : textColorDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
=======
              const Icon(Icons.description_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Legal Documents Required',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
              ),
              if (_documentsUploaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
<<<<<<< HEAD
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
=======
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('Uploaded',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
<<<<<<< HEAD
            AppLocalizations.of(context)!.legalDocsHint,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
=======
            'Please upload your legal documents (Business License, Registration Certificate, etc.)',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textMuted),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
          ),
          const SizedBox(height: 12),
          if (!_documentsUploaded)
<<<<<<< HEAD
            OutlinedButton.icon(
              onPressed: _uploadDocuments,
              icon: const Icon(Icons.upload_file),
              label: Text(AppLocalizations.of(context)!.uploadDocsBtn),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
=======
            GestureDetector(
              onTap: _uploadDocuments,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primary, style: BorderStyle.solid),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Upload Documents',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
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
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
