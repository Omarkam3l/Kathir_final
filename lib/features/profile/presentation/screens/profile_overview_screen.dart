import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../providers/foodie_state.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import 'about_screen.dart';

class ProfileOverviewScreen extends StatelessWidget {
  static const routeName = '/profile-overview';
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final foodieState = context.watch<FoodieState>();
    final ordersController = context.watch<OrdersController>();
    final user = auth.user;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
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
                    context: context,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => GoRouter.of(context).push('/profile/settings'),
                    icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  children: [
                    Container
                    (
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Theme.of(context).cardColor,
                            child: user != null && user.name.isNotEmpty
                                ? Text(
                                    user.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryAccent,
                                    ),
                                  )
                                : Icon(Icons.person,
                                    size: 48, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'Guest User',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Not logged in',
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                  child: _HighlightTile(
                                      value:
                                          '${ordersController.allOrders.length}',
                                      label: 'Orders')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _HighlightTile(
                                      value: '${foodieState.favouritesCount}',
                                      label: 'Favourites')),
                              const SizedBox(width: 12),
                              const Expanded(
                                  child: _HighlightTile(
                                      value: '4.9', label: 'Rating')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.shopping_cart,
                            label: 'Cart',
                            color: AppColors.secondaryAccent,
                            onTap: () => GoRouter.of(context)
                                .push('/cart'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.favorite,
                            label: 'Favourites',
                            color: AppColors.primaryAccent,
                            onTap: () => GoRouter.of(context)
                                .push('/favourites'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.notifications,
                            label: 'Alerts',
                            color: AppColors.mintAqua,
                            onTap: () => GoRouter.of(context)
                                .push('/alerts'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.credit_card,
                            label: 'Cards',
                            color: AppColors.aquaCyan,
                            onTap: () => GoRouter.of(context)
                                .push('/profile/cards'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SettingsListSection(
                      title: 'Account',
                      items: [
                        _SettingsItem(
                            icon: Icons.map,
                            label: 'Saved addresses',
                            subtitle: user != null
                                ? '${user.addresses.length} active'
                                : '0 active',
                            onTap: () => GoRouter.of(context)
                                .push('/profile/saved-addresses')),
                        _SettingsItem(
                            icon: Icons.lock,
                            label: 'Change password',
                            onTap: () => GoRouter.of(context)
                                .push('/profile/change-password')),
                        _SettingsItem(
                            icon: Icons.history,
                            label: 'Order history',
                            onTap: () => GoRouter.of(context)
                                .push('/profile/order-history')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SettingsListSection(
                      title: 'Support',
                      items: [
                        _SettingsItem(
                            icon: Icons.help_center,
                            label: 'Need help?',
                            onTap: () =>
                                GoRouter.of(context).push('/profile/help')),
                        _SettingsItem(
                            icon: Icons.policy,
                            label: 'Privacy policy',
                            onTap: () =>
                                GoRouter.of(context).push('/profile/privacy')),
                        _SettingsItem(
                            icon: Icons.info,
                            label: 'About Foodie',
                            onTap: () =>
                                GoRouter.of(context).push(AboutScreen.routeName)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          final router = GoRouter.of(context);
                          await auth.signOut();
                          router.go('/auth');
                        },
                        child: const Text(
                          'Log out',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
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

  Widget _diamondButton({required IconData icon, required VoidCallback onTap, required BuildContext context}) {
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
                color: Colors.black.withValues(alpha: 0.08),
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

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }
}

class _SettingsListSection extends StatelessWidget {
  const _SettingsListSection({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Text(
              title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle:
                      item.subtitle == null ? null : Text(item.subtitle!, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  trailing:
                      Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: item.onTap,
                ),
                if (item != items.last)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
              ],
            )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SettingsItem {
  _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
}
