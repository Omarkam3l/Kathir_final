import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

class PaymentMethodScreen extends StatelessWidget {
  static const routeName = '/payment-method';
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          ListTile(
            leading: Icon(Icons.credit_card, color: AppColors.primaryAccent),
            title: Text('Credit/Debit Card'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet,
                color: AppColors.primaryAccent),
            title: Text('Wallet'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.money, color: AppColors.primaryAccent),
            title: Text('Cash on Delivery'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
