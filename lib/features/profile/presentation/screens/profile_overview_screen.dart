import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../providers/foodie_state.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import 'about_screen.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileOverviewScreen extends StatelessWidget {
  static const routeName = '/profile-overview';
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    context: context,
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
                  const Spacer(),
                  IconButton(
                    onPressed: () => GoRouter.of(context).push('/profile/settings'),
                    icon: Icon(Icons.settings,
                        color: Theme.of(context).iconTheme.color),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            child: user != null && user.name.isNotEmpty
                                ? Text(
                                    user.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : Icon(Icons.person,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? l10n.guestUser,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? l10n.notLoggedIn,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                  child: _HighlightTile(
                                      value:
                                          '${ordersController.allOrders.length}',
                                      label: l10n.orders)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _HighlightTile(
                                      value: '${foodieState.favouritesCount}',
                                      label: l10n.favourites)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _HighlightTile(
                                      value: '4.9', label: l10n.rating)),
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
                            label: l10n.navCart,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () => GoRouter.of(context)
                                .push('/cart'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.favorite,
                            label: l10n.favourites,
                            color: Theme.of(context).colorScheme.primary,
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
                            label: l10n.navAlerts,
                            color: Colors.tealAccent,
                            onTap: () => GoRouter.of(context)
                                .push('/alerts'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.credit_card,
                            label: l10n.cards,
                            color: Colors.cyanAccent,
                            onTap: () => GoRouter.of(context)
                                .push('/profile/cards'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SettingsListSection(
                      title: l10n.account,
                      items: [
                        _SettingsItem(
                            icon: Icons.map,
                            label: l10n.savedAddresses,
                            subtitle: user != null
                                ? l10n.activeAddresses(user.addresses.length)
                                : l10n.activeAddresses(0),
                            onTap: () => GoRouter.of(context)
                                .push('/profile/saved-addresses')),
                        _SettingsItem(
                            icon: Icons.lock,
                            label: l10n.changePassword,
                            onTap: () => GoRouter.of(context)
                                .push('/profile/change-password')),
                        _SettingsItem(
                            icon: Icons.history,
                            label: l10n.orderHistory,
                            onTap: () => GoRouter.of(context)
                                .push('/profile/order-history')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SettingsListSection(
                      title: l10n.support,
                      items: [
                        _SettingsItem(
                            icon: Icons.help_center,
                            label: l10n.needHelp,
                            onTap: () =>
                                GoRouter.of(context).push('/profile/help')),
                        _SettingsItem(
                            icon: Icons.policy,
                            label: l10n.privacyPolicy,
                            onTap: () =>
                                GoRouter.of(context).push('/profile/privacy')),
                        _SettingsItem(
                            icon: Icons.info,
                            label: l10n.aboutFoodie,
                            onTap: () =>
                                GoRouter.of(context).push(AboutScreen.routeName)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () {
                          auth.logout();
                          GoRouter.of(context).go('/auth');
                        },
                        child: Text(
                          l10n.logOut,
                          style: const TextStyle(
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

  Widget _diamondButton(
      {required IconData icon, required VoidCallback onTap, required BuildContext context}) {
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

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
            style: const TextStyle(color: Colors.grey),
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
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
            const Icon(Icons.chevron_right, color: Colors.grey),
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
            color: Colors.black.withOpacity(0.04),
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
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        item.subtitle == null ? null : Text(item.subtitle!),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: item.onTap,
                  ),
                  if (item != items.last)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Divider(color: Colors.grey.withOpacity(0.2)),
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
