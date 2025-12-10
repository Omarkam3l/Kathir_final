import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:kathir_final/features/_shared/providers/theme_provider.dart';

import 'change_password_screen.dart';
import 'package:kathir_final/features/_shared/router/app_router.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _offers = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
              child: Row(
                children: [
                  _diamondButton(
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
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                children: [
                  _Section(
                    title: 'Notifications',
                    children: [
                      SwitchListTile(
                        value: _notifications,
                        onChanged: (value) =>
                            setState(() => _notifications = value),
                        title: const Text('Push notifications'),
                        subtitle: const Text('Order updates & delivery status'),
                        activeTrackColor: AppColors.primaryAccent,
                      ),
                      SwitchListTile(
                        value: _offers,
                        onChanged: (value) => setState(() => _offers = value),
                        title: const Text('Promotions'),
                        subtitle: const Text('Special foodie deals & vouchers'),
                        activeTrackColor: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: 'Appearance',
                    children: [
                      SwitchListTile(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        title: const Text('Dark mode'),
                        subtitle: const Text('Sync with Figma design tokens'),
                        activeTrackColor: AppColors.primaryAccent,
                      ),
                      ListTile(
                        title: const Text(
                          'Language',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('English (US)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: 'Security',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline,
                            color: AppColors.primaryAccent),
                        title: const Text('Change password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.pushRoute(ChangePasswordScreen.routeName),
                      ),
                      const ListTile(
                        leading:
                            Icon(Icons.devices, color: AppColors.primaryAccent),
                        title: Text('Devices'),
                        subtitle: Text('Manage logged in devices'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text(
                          'Sign out of all devices',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          final auth = context.read<AuthProvider>();
                          final router = GoRouter.of(context);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: const Text('This action is permanent. Do you want to continue?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await auth.deleteAccount();
                            router.go('/auth');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diamondButton({required IconData icon, required VoidCallback onTap}) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(icon, color: AppColors.darkText),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
