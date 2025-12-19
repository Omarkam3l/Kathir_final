import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../orders/presentation/models/figma_models.dart';
import '../../../orders/presentation/screens/order_tracking_screen.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifications = DemoData.notifications(l10n);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.notifications,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.settings,
                        color: Theme.of(context).iconTheme.color),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: item.isNew
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).scaffoldBackgroundColor,
                          child: Icon(
                            item.isNew
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: item.isNew
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.timeAgo,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                              if (item.isNew) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.of(context)
                                            .pushNamed(
                                                OrderTrackingScreen.routeName),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).colorScheme.secondary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.08),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                        ),
                                        child: Text(l10n.trackOrderAction),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: notifications.length,
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
