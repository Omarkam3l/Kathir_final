import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/figma_models.dart';

class OrderTrackingScreen extends StatelessWidget {
  static const routeName = '/order-tracking';
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stages = DemoData.orderTimeline(l10n);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.orderStatusTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).cardColor,
                    child: Icon(Icons.chat_bubble_outline,
                        color: Theme.of(context).iconTheme.color),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.courierArriving,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            const Spacer(),
<<<<<<< HEAD
                            Text(l10n.orderNumber('921'),
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.courierArrivingMessage('Mathew', '5', '0.8'),
                          style: const TextStyle(color: Colors.grey),
=======
                            const Text('Order #921',
                                style: TextStyle(color: AppColors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mathew is 5 min away • 0.8 km',
                          style: TextStyle(color: AppColors.grey),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
<<<<<<< HEAD
                            color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
=======
                            color: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor ??
                                AppColors.inputFillDark,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).cardColor,
                                child: Icon(Icons.delivery_dining,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mathew Carter',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('White Toyota Prius • 421-B'),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.phone,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.timelineTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (int i = 0; i < stages.length; i++) ...[
                          _TimelineTile(
                            stage: stages[i],
                            isCompleted: i <= 2,
                            isLast: i == stages.length - 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
<<<<<<< HEAD
                            l10n.trackCourierMap,
                            style: const TextStyle(
                                color: Colors.white,
=======
                            'Track courier live on the map',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
<<<<<<< HEAD
                            l10n.openAction,
                            style: const TextStyle(color: Colors.white),
=======
                            'Open',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diamondButton(
      {required IconData icon,
      required VoidCallback onTap,
      required BuildContext context}) {
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
                color: AppColors.black.withOpacity(0.08),
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

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.stage,
    required this.isCompleted,
    required this.isLast,
  });

  final OrderStage stage;
  final bool isCompleted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              child: Icon(
                stage.icon,
                size: 18,
<<<<<<< HEAD
                color: isCompleted ? Colors.white : Theme.of(context).colorScheme.primary,
=======
                color: isCompleted ? AppColors.white : AppColors.primaryAccent,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.time,
                  style: TextStyle(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
