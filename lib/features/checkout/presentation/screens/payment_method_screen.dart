import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PaymentMethodScreen extends StatelessWidget {
  static const routeName = '/payment-method';
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethod),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ListTile(
            leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.creditDebitCard),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.wallet),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.money, color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.cashOnDelivery),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
