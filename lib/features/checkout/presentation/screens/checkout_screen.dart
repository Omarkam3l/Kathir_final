import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import 'choose_address_screen.dart';
import 'payment_method_screen.dart';

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
  
  // Mock address state - in a real app this would come from an AddressProvider
  final String _addressTitle = 'Work • 212 Kathir Heights';
  final String _addressSubtitle = 'Tech Park, Floor 11';

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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<FoodieState>(
          builder: (context, foodie, _) {
            final total = foodie.total;
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
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
                          l10n.checkoutTitle,
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
                                label: Text(l10n.buyerRole),
                                selected: _purchaseMode == PurchaseMode.buyer,
                                onSelected: (_) => setState(
                                    () => _purchaseMode = PurchaseMode.buyer),
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: Text(l10n.donorRole),
                                selected: _purchaseMode == PurchaseMode.donor,
                                onSelected: (_) => setState(
                                    () => _purchaseMode = PurchaseMode.donor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                        _SectionCard(
                          title: l10n.deliveryAddress,
                          trailing: TextButton(
                            onPressed: () async {
                              await context.push(ChooseAddressScreen.routeName);
                              // In a real app, we'd handle the result here if it returns a selected address
                              // For now, we'll just simulate a change if needed or rely on provider updates
                            },
                            child: Text(l10n.changeAction),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _addressTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _addressSubtitle,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: l10n.deliverySlot,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(3, (index) {
                              final slots = [
                                l10n.nowSlot,
                                '18:30 - 19:00',
                                l10n.scheduleSlot
                              ];
                              final isSelected = _slot == index;
                              return GestureDetector(
                                onTap: () => setState(() => _slot = index),
                                child: Container(
                                  width: 110,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slots[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).scaffoldBackgroundColor
                                            : Theme.of(context).textTheme.bodyLarge?.color,
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
                          title: l10n.paymentMethod,
                          child: Column(
                            children: [
                              for (int i = 0; i < _methods.length; i++) ...[
                                RadioListTile<int>(
                                  value: i,
                                  groupValue: _selected,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  onChanged: (value) =>
                                      setState(() => _selected = value ?? 0),
                                  title: Text(
                                    '${_methods[i].brand} • ${_methods[i].maskedNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    child: Icon(_methods[i].icon,
                                        color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                if (i != _methods.length - 1)
                                  const Divider(indent: 12, endIndent: 12),
                              ],
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(PaymentMethodScreen.routeName),
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.addNewCard),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: l10n.orderSummary,
                          child: Column(
                            children: [
                              _SummaryRow(label: l10n.subtotalItems(foodie.cartCount), value: foodie.subtotal),
                              _SummaryRow(label: l10n.deliveryLabel, value: foodie.deliveryFee),
                              _SummaryRow(label: l10n.platformFeeLabel, value: foodie.platformFee),
                              const Divider(height: 28),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child:
                                    Icon(Icons.discount, color: Theme.of(context).scaffoldBackgroundColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  l10n.freeDeliveryMessage(50),
                                  style: TextStyle(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(l10n.addCodeAction,
                                    style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
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
                          Text(l10n.totalLabel, style: const TextStyle(color: Colors.grey)),
                          const Spacer(),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
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
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () {
                            // Handle order placement based on mode
                            final modeText = _purchaseMode == PurchaseMode.buyer
                                ? 'buying'
                                : 'donating';
                            
                            // Show placing order message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.placingOrderMessage(modeText)),
                                duration: const Duration(seconds: 1),
                              ),
                            );

                            // Simulate network delay then complete order
                            Future.delayed(const Duration(seconds: 2), () {
                              if (context.mounted) {
                                foodie.clearCart();
                                
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => AlertDialog(
                                    title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                                    content: Text(
                                      l10n.orderPlacedMessage,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          context.go('/home');
                                        },
                                        child: Text(l10n.doneAction),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            });
                          },
                          child: Text(
                            _purchaseMode == PurchaseMode.buyer
                                ? l10n.placeOrder
                                : l10n.completeDonation,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          const Spacer(),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
