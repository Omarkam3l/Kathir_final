import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/user_role.dart';
import 'package:kathir_final/features/_shared/widgets/custom_input_field.dart';
import 'package:kathir_final/features/authentication/presentation/screens/verification_screen.dart';
import 'package:kathir_final/features/authentication/presentation/viewmodels/auth_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import '../../domain/usecases/sign_up_usecase.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'package:kathir_final/features/_shared/providers/theme_provider.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  UserRole? _selectedRole;
  bool _documentsUploaded = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  List<int>? _legalDocBytes;

  // Colors - Using teal palette
  final Color _headerTealTop = AppColors.deepTeal;
  final Color _headerTealBottom = AppColors.tealAqua;
  final Color _creamyInputFill = const Color(0xFFF3F1EB);
  final Color _tealBtnStart = AppColors.tealAqua;
  final Color _tealBtnEnd = AppColors.aquaCyan;
  final Color _textColorDark = AppColors.darkText;

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
    _selectedRole = vm.selectedRole;
  }

  void toggleState() {
    setState(() {
      isLogin = !isLogin;
      _selectedRole = null;
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

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if NGO or Restaurant needs documents
    if ((_selectedRole == UserRole.ngo ||
            _selectedRole == UserRole.restaurant) &&
        !_documentsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your legal documents'),
          backgroundColor: AppColors.warning,
        ),
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

      // Attempt upload if we have a user, regardless of verification status
      if (_legalDocBytes != null) {
        // Use vm.user?.id because client.auth.currentUser might be null if email verification is pending (no session)
        final uid =
            vm.user?.id ?? s.Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading legal document...')),
          );
          final url =
              await vm.uploadLegalDoc(uid, 'legal.pdf', _legalDocBytes!);
          if (mounted) {
            if (url != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document uploaded successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Document upload failed. Please try again later.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
      }

      if (ok) {
        if (mounted) {
          GoRouter.of(context).go('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to verify your account'),
              backgroundColor: AppColors.primaryAccent,
            ),
          );
          GoRouter.of(context).go('${VerificationScreen.routeName}?mode=signup',
              extra: _emailController.text.trim());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vm = Provider.of<AuthViewModel>(context, listen: false);
      final success = await vm.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          GoRouter.of(context).go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid email or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadDocuments() async {
    final res = await FilePicker.platform.pickFiles(withReadStream: false);
    if (!mounted) return;
    if (res != null && res.files.isNotEmpty) {
      _legalDocBytes = res.files.first.bytes;
      if (_legalDocBytes != null) {
        setState(() {
          _documentsUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents selected'),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
      }
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
      if (ok && mounted) {
        GoRouter.of(context).go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _headerTealBottom,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_headerTealTop, _headerTealBottom],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLogin
                                ? "Launch Your\nIdeas."
                                : "Create\nAccount.",
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
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            minHeight: 100,
                          ),
                          child: Image.asset(
                            'lib/resources/assets/images/kathir_edit.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form Section
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.offWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
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
                              color: isDark ? Colors.white : _textColorDark,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Role Selection (Sign Up Only)
                        if (!isLogin) ...[
                          Text(
                            'Select Your Role',
                            style: TextStyle(
                              color: isDark ? Colors.white : _textColorDark,
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
                                  'User',
                                  Icons.person,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleButton(
                                  UserRole.ngo,
                                  'Organization',
                                  Icons.handshake,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRoleButton(
                                  UserRole.restaurant,
                                  'Restaurant',
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
                            hintText: "Organization Name",
                            fillColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : _creamyInputFill,
                            controller: _orgNameController,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Name Field (Sign Up Only)
                        if (!isLogin) ...[
                          CustomInputField(
                            hintText: "Full Name",
                            fillColor: isDark
                                ? const Color(0xFF2C2C2C)
                                : _creamyInputFill,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        CustomInputField(
                          hintText: "Email",
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : _creamyInputFill,
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
                                : _creamyInputFill,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Password Field
                        CustomInputField(
                          hintText: "Password",
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : _creamyInputFill,
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
                                GoRouter.of(context).push('/forgot-password');
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
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
                                if (email.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Enter your email first'),
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
                                    const SnackBar(
                                      content: Text('Verification email sent'),
                                      backgroundColor: AppColors.primaryAccent,
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Resend failed: ${e.toString()}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Resend verification email',
                                style: TextStyle(
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
                            gradient: LinearGradient(
                              colors: [_tealBtnStart, _tealBtnEnd],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _tealBtnStart.withOpacity(0.3),
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
                                    ? "Don't have an account? "
                                    : "Already have an account? ",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: isLogin ? "Sign Up" : "Log In",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : _textColorDark,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      UserRole role, String label, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
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
                ? AppColors.primaryAccent.withOpacity(0.2)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryAccent
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryAccent
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryAccent
                      : (isDark ? Colors.white : _textColorDark),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUploadSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _documentsUploaded
              ? AppColors.primaryAccent
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Legal Documents Required',
                  style: TextStyle(
                    color: isDark ? Colors.white : _textColorDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_documentsUploaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryAccent,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Please upload your legal documents (Business License, Registration Certificate, etc.)',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (!_documentsUploaded)
            OutlinedButton.icon(
              onPressed: _uploadDocuments,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Documents'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryAccent,
                side: const BorderSide(color: AppColors.primaryAccent),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
