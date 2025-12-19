import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  static const routeName = '/privacy';
  const PrivacyScreen({super.key});

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
                      l10n.privacyPolicy,
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
                child: Container(
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
                        l10n.privacyPolicy,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.lastUpdated("January 2024"),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.privacyPolicyTitle1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.privacyPolicyText1,
                        style: const TextStyle(
                          color: Colors.grey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.privacyPolicyTitle2,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.privacyPolicyText2,
                        style: const TextStyle(
                          color: Colors.grey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.privacyPolicyTitle3,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.privacyPolicyText3,
                        style: const TextStyle(
                          color: Colors.grey,
                          height: 1.6,
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

  Widget _diamondButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
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

