import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../orders/presentation/models/figma_models.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = DemoData.notifications();

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
                      'Notifications',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings, color: AppColors.darkText),
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
                          color: Colors.black.withValues(alpha: 0.04),
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
                              ? AppColors.primaryAccent
                              : AppColors.lightBackground,
                          child: Icon(
                            item.isNew
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: item.isNew
                                ? Colors.white
                                : AppColors.primaryAccent,
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
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
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                              if (item.isNew) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => context.go('/my-orders'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppColors.secondaryAccent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          backgroundColor: AppColors
                                              .secondaryAccent
                                              .withValues(alpha: 0.08),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                        ),
                                        child: const Text('View Orders'),
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
                color: Colors.black.withValues(alpha: 0.08),
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
