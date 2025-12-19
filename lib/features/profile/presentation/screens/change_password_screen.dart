import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  static const routeName = '/profile/change-password';
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    try {
      final success = await auth.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() => _loading = false);

      if (success) {
        setState(() => _showSuccess = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            router.go('/home');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.currentPasswordIncorrectError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLabel(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    if (_showSuccess) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _ChangePasswordAppBar(textColor: textColor),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 64,
                                color: primaryColor,
                              ),
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: onPrimaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.passwordChangedTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              final router = GoRouter.of(context);
                              if (router.canPop()) {
                                router.pop();
                              } else {
                                router.go('/home');
                              }
                            },
                            child: Text(
                              l10n.doneAction,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: onPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _ChangePasswordAppBar(textColor: textColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: primaryColor,
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.refresh,
                                color: onPrimaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.changePassword,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.createNewPassword,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _PasswordField(
                            controller: _currentPasswordController,
                            label: l10n.currentPasswordLabel,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _PasswordField(
                            controller: _newPasswordController,
                            label: l10n.newPasswordLabel,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _PasswordField(
                            controller: _confirmPasswordController,
                            label: l10n.confirmNewPasswordLabel,
                            cardColor: cardColor,
                            textColor: textColor,
                            validator: (value) {
                              if (value != _newPasswordController.text) {
                                return l10n.passwordsNoMatch;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _loading ? null : _changePassword,
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                l10n.changeAction,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: onPrimaryColor,
                                ),
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
    );
  }
}

class _ChangePasswordAppBar extends StatelessWidget {
  const _ChangePasswordAppBar({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          _diamondButton(
            context,
            icon: Icons.arrow_back_ios_new,
            onTap: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/home');
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.changePassword,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _diamondButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final buttonColor = Theme.of(context).cardColor;
    final iconColor = Theme.of(context).iconTheme.color;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.cardColor,
    required this.textColor,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final Color cardColor;
  final Color textColor;
  final String? Function(String?)? validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final fieldColor = Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.pleaseEnterField(widget.label.toLowerCase());
            }
            if (value.length < 6) {
              return AppLocalizations.of(context)!.passwordLengthError;
            }
            return null;
          },
      style: TextStyle(color: widget.textColor),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
    );
  }
}
