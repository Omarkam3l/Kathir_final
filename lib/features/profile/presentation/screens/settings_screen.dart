import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import 'package:kathir_final/features/_shared/providers/theme_provider.dart';
import 'package:kathir_final/features/_shared/providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    
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
                  Expanded(
                    child: Text(
                      l10n.settings,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
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
                    title: l10n.notifications,
                    children: [
                      SwitchListTile(
                        value: _notifications,
                        onChanged: (value) =>
                            setState(() => _notifications = value),
                        title: Text(l10n.pushNotifications),
                        subtitle: const Text('Order updates & delivery status'),
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                      ),
                      SwitchListTile(
                        value: _offers,
                        onChanged: (value) => setState(() => _offers = value),
                        title: Text(l10n.promotions),
                        subtitle: const Text('Special foodie deals & vouchers'),
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: l10n.appearance,
                    children: [
                      SwitchListTile(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        title: Text(l10n.darkMode),
                        subtitle: const Text('Sync with Figma design tokens'),
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                      ),
                      ListTile(
                        title: Text(
                          l10n.language,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(localeProvider.locale.languageCode == 'ar' ? 'العربية' : 'English (US)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(
                                      l10n.language,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListTile(
                                      title: const Text('English (US)'),
                                      trailing: localeProvider.locale.languageCode == 'en' 
                                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                                          : null,
                                      onTap: () {
                                        localeProvider.setLocale(const Locale('en'));
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      title: const Text('العربية'),
                                      trailing: localeProvider.locale.languageCode == 'ar' 
                                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                                          : null,
                                      onTap: () {
                                        localeProvider.setLocale(const Locale('ar'));
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: l10n.security,
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock_outline,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.changePassword),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.pushRoute(ChangePasswordScreen.routeName),
                      ),
                      ListTile(
                        leading:
                            Icon(Icons.devices, color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.devices),
                        subtitle: const Text('Manage logged in devices'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(
                          l10n.signOut,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.logout();
                          if (context.mounted) {
                            GoRouter.of(context).go('/auth');
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: Text(
                          l10n.deleteAccount,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          final auth = context.read<AuthProvider>();
                          final router = GoRouter.of(context);
                          final l10n = AppLocalizations.of(context)!;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                l10n.deleteAccount,
                                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                l10n.deleteAccountConfirm,
                                style: Theme.of(ctx).textTheme.bodyMedium,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    l10n.cancelAction,
                                    style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                                  ),
                                  child: Text(
                                    l10n.deleteAccount,
                                    style: TextStyle(color: Theme.of(ctx).colorScheme.onPrimary),
                                  ),
                                ),
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
            color: Theme.of(context).cardColor,
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
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
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
