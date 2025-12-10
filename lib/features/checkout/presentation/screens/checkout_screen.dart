import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final List<PaymentMethod> _methods;
  int _selected = 0;
  int _slot = 0;
  PurchaseMode _purchaseMode = PurchaseMode.buyer;

  @override
  void initState() {
    super.initState();
    _methods = demoPaymentMethods();
  }

  /// Checks if current user can choose buyer/donor mode
  bool _canChooseBuyerDonor(BuildContext context) {
    final user = s.Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final role = (user.userMetadata?['role'] as String?) ?? '';
    return role.toLowerCase() == UserRole.user.name.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    const subtotal = 52.5;
    const delivery = 3.5;
    const tip = 4.0;
    const total = subtotal + delivery + tip;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
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
                      'Checkout',
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
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                child: Column(
                  children: [
                    // Buyer/Donor Selection (only for UserRole.user)
                    if (_canChooseBuyerDonor(context)) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Buyer'),
                            selected: _purchaseMode == PurchaseMode.buyer,
                            onSelected: (_) => setState(
                                () => _purchaseMode = PurchaseMode.buyer),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Donor'),
                            selected: _purchaseMode == PurchaseMode.donor,
                            onSelected: (_) => setState(
                                () => _purchaseMode = PurchaseMode.donor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    _SectionCard(
                      title: 'Delivery address',
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('Change'),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work • 212 Kathir Heights',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Tech Park, Floor 11'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Delivery slot',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(3, (index) {
                          const slots = [
                            'Now (25 min)',
                            '18:30 - 19:00',
                            'Schedule'
                          ];
                          return GestureDetector(
                            onTap: () => setState(() => _slot = index),
                            child: Container(
                              width: 110,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _slot == index
                                    ? AppColors.darkText
                                    : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  slots[index],
                                  style: TextStyle(
                                    color: _slot == index
                                        ? Colors.white
                                        : AppColors.darkText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Payment method',
                      child: Column(
                        children: [
                          for (int i = 0; i < _methods.length; i++) ...[
                            RadioListTile<int>(
                              value: i,
                              groupValue: _selected,
                              activeColor: AppColors.primaryAccent,
                              onChanged: (value) =>
                                  setState(() => _selected = value ?? 0),
                              title: Text(
                                '${_methods[i].brand} • ${_methods[i].maskedNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                              secondary: CircleAvatar(
                                backgroundColor:
                                    AppColors.primaryAccent.withOpacity(0.12),
                                child: Icon(_methods[i].icon,
                                    color: AppColors.primaryAccent),
                              ),
                            ),
                            if (i != _methods.length - 1)
                              const Divider(indent: 12, endIndent: 12),
                          ],
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add),
                              label: const Text('Add new card'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionCard(
                      title: 'Order summary',
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Subtotal (3 items)', value: 52.5),
                          _SummaryRow(label: 'Delivery fee', value: 3.5),
                          _SummaryRow(label: 'Courier tip', value: 4.0),
                          Divider(height: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.darkText,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child:
                                const Icon(Icons.discount, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Free delivery on orders above \$50',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Add code',
                                style: TextStyle(color: Colors.white)),
                          ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Total', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  // Handle order placement based on mode
                  final modeText = _purchaseMode == PurchaseMode.buyer
                      ? 'buying'
                      : 'donating';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Placing order as $modeText...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed')),
                  );
                },
                child: Text(
                  _purchaseMode == PurchaseMode.buyer
                      ? 'Place order'
                      : 'Complete donation',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
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
                color: Colors.black.withOpacity(0.08),
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

enum PurchaseMode { buyer, donor }

class PaymentMethod {
  final String brand;
  final String maskedNumber;
  final IconData icon;
  const PaymentMethod({required this.brand, required this.maskedNumber, required this.icon});
}

List<PaymentMethod> demoPaymentMethods() => const [
      PaymentMethod(brand: 'Visa', maskedNumber: '•••• 4242', icon: Icons.credit_card),
      PaymentMethod(brand: 'Mastercard', maskedNumber: '•••• 5454', icon: Icons.credit_card),
      PaymentMethod(brand: 'Apple Pay', maskedNumber: 'Linked', icon: Icons.phone_iphone),
    ];

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const Spacer(),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
