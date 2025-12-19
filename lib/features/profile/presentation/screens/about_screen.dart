import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  static const routeName = '/about';
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
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
                      l10n.aboutFoodie,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.foodieApp,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.versionLabel("1.0.0"),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.aboutDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.contactUs,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _ContactRow(
                              icon: Icons.email, text: 'support@foodie.com'),
                          const SizedBox(height: 12),
                          const _ContactRow(
                              icon: Icons.phone, text: '+1 (555) 123-4567'),
                          const SizedBox(height: 12),
                          const _ContactRow(
                              icon: Icons.location_on,
                              text: '123 Food Street, City'),
                        ],
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
