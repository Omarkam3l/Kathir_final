import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../profile/presentation/screens/addresses_screen.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../checkout/data/services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _supabase = Supabase.instance.client;
  final _orderService = OrderService();
  String _paymentMethod = 'card'; // card, wallet, cod
  bool _isCreatingOrder = false;
  String? _deliveryAddress;
  bool _isLoadingAddress = true;
  String? _selectedNgoId;
  List<Map<String, dynamic>> _ngos = [];
  bool _isLoadingNgos = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    _loadNgos();
  }

  Future<void> _loadNgos() async {
    setState(() => _isLoadingNgos = true);
    try {
      debugPrint('🔍 Loading NGOs using RPC function...');
      
      // Use RPC function to avoid recursion issues
      final response = await _supabase.rpc('get_approved_ngos');

      debugPrint('✅ NGO Query successful. Raw response count: ${(response as List).length}');

      if ((response).isEmpty) {
        debugPrint('⚠️ No approved NGOs found in database');
        setState(() {
          _ngos = [];
          _isLoadingNgos = false;
        });
        return;
      }

      setState(() {
        _ngos = (response).map((ngo) {
          debugPrint('  Processing NGO: ${ngo['organization_name']} (ID: ${ngo['profile_id']})');
          return {
            'id': ngo['profile_id'],
            'full_name': ngo['organization_name'],
            'avatar_url': ngo['avatar_url'],
          };
        }).toList();
        _isLoadingNgos = false;
      });
      
      debugPrint('✅ Loaded ${_ngos.length} approved NGOs');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading NGOs: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _ngos = [];
        _isLoadingNgos = false;
      });
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingAddress = false);
        return;
      }

      final response = await _supabase
          .from('user_addresses')
          .select('address_text, label')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _deliveryAddress = response['address_text'];
          _isLoadingAddress = false;
        });
      } else {
        // No default address, try to get any address
        final anyAddress = await _supabase
            .from('user_addresses')
            .select('address_text, label')
            .eq('user_id', userId)
            .limit(1)
            .maybeSingle();

        setState(() {
          _deliveryAddress = anyAddress?['address_text'];
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
      setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    const primaryColor = AppColors.primary;
    final borderColor = isDark ? Colors.white10 : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Payment',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.go('/cart'),
        ),
      ),
      bottomNavigationBar: Consumer<FoodieState>(builder: (context, foodie, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFooterRow(
                  'Subtotal',
                  'EGP ${foodie.subtotal.toStringAsFixed(2)}',
                  subTextColor,
                  textColor),
              const SizedBox(height: 8),
              _buildFooterRow(
                  'Service Fee',
                  'EGP ${foodie.platformFee.toStringAsFixed(2)}',
                  subTextColor,
                  textColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Amount',
                          style: TextStyle(fontSize: 12, color: subTextColor)),
                      Text('EGP ${foodie.total.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ],
                  ),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: _isCreatingOrder || _isButtonDisabled(foodie) ? null : () async {
                        final userId = _supabase.auth.currentUser?.id;
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please login first')),
                          );
                          return;
                        }

                        if (foodie.cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart is empty')),
                          );
                          return;
                        }

                        setState(() => _isCreatingOrder = true);

                        try {
                          // Validate NGO selection for donation orders
                          if (foodie.deliveryMethod == DeliveryMethod.donate) {
                            if (_selectedNgoId == null || _selectedNgoId!.isEmpty) {
                              throw Exception('Please select an NGO for donation');
                            }
                          }

                          // Get delivery address based on delivery method
                          String? finalAddress;
                          if (foodie.deliveryMethod == DeliveryMethod.delivery) {
                            if (_deliveryAddress == null || _deliveryAddress!.isEmpty) {
                              throw Exception('Please add a delivery address in your profile');
                            }
                            finalAddress = _deliveryAddress;
                          } else if (foodie.deliveryMethod == DeliveryMethod.pickup) {
                            finalAddress = 'Self Pickup';
                          } else {
                            finalAddress = 'Donated to NGO';
                          }

                          // Create order in database (may create multiple orders if multiple restaurants)
                          final results = await _orderService.createOrder(
                            userId: userId,
                            items: foodie.cartItems,
                            deliveryType: foodie.deliveryMethod.name,
                            subtotal: foodie.subtotal,
                            serviceFee: foodie.platformFee,
                            deliveryFee: foodie.deliveryFee,
                            total: foodie.total,
                            paymentMethod: _paymentMethod,
                            deliveryAddress: finalAddress,
                            ngoId: _selectedNgoId,  // Pass NGO ID
                          );

                          // Clear memory cart
                          await foodie.clearCart();

                          // Navigate to order summary (show first order, or create a multi-order summary)
                          if (mounted) {
                            if (results.length == 1) {
                              // Single restaurant order
                              context.go('/order-summary/${results[0]['order_id']}');
                            } else {
                              // Multiple restaurant orders - navigate to my orders screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${results.length} orders created successfully!'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              context.go('/my-orders');
                            }
                          }
                        } catch (e, stackTrace) {
                          debugPrint('❌ Error creating order: $e');
                          debugPrint('Stack trace: $stackTrace');
                          setState(() => _isCreatingOrder = false);
                          
                          if (mounted) {
                            // Parse error message for user-friendly display
                            String errorMessage = 'Failed to create order';
                            if (e.toString().contains('platform_fee')) {
                              errorMessage = 'Database error: Invalid fee structure';
                            } else if (e.toString().contains('subtotal')) {
                              errorMessage = 'Database error: Invalid order calculation';
                            } else if (e.toString().contains('NGO')) {
                              errorMessage = 'Please select an NGO for donation';
                            } else if (e.toString().contains('address')) {
                              errorMessage = 'Please add a delivery address';
                            } else {
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Dismiss',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: AppColors.primaryGreen.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCreatingOrder)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else ...[
                            Text('Pay Now',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      body: Consumer<FoodieState>(
        builder: (context, foodie, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text('Review your order before paying.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: subTextColor)),
                const SizedBox(height: 16),

                // Order Items
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...foodie.cartItems.map((item) => _buildOrderItem(item,
                          textColor, subTextColor, primaryColor, borderColor)),
                      const SizedBox(height: 16),
                      // Delivery Info
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                            border:
                                Border(top: BorderSide(color: borderColor))),
                        child: Column(
                          children: [
                            if (foodie.deliveryMethod == DeliveryMethod.delivery) ...[
                              _buildSummaryRow(
                                  Icon(Icons.local_shipping,
                                      size: 16, color: subTextColor),
                                  'Delivery Fee',
                                  'EGP ${foodie.deliveryFee.toStringAsFixed(2)}',
                                  textColor,
                                  subTextColor),
                              const SizedBox(height: 8),
                              _isLoadingAddress
                                  ? Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 16, color: subTextColor),
                                        const SizedBox(width: 6),
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Loading address...',
                                            style: TextStyle(fontSize: 14, color: subTextColor)),
                                      ],
                                    )
                                  : _deliveryAddress != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildSummaryRow(
                                              Icon(Icons.location_on,
                                                  size: 16, color: subTextColor),
                                              'Delivery to',
                                              _deliveryAddress!,
                                              textColor,
                                              subTextColor),
                                            const SizedBox(height: 8),
                                            // Change address button
                                            InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => const AddressesScreen(),
                                                  ),
                                                ).then((_) => _loadDefaultAddress());
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.edit_location, size: 16, color: primaryColor),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Change Address',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 13,
                                                        color: primaryColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : InkWell(
                                          onTap: () {
                                            // Navigate to addresses screen
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => const AddressesScreen(),
                                              ),
                                            ).then((_) => _loadDefaultAddress());
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.orange[200]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warning_amber, size: 20, color: Colors.orange[700]),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'No delivery address found. Tap to add one.',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.orange[900],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange[700]),
                                              ],
                                            ),
                                          ),
                                        ),
                            ] else if (foodie.deliveryMethod == DeliveryMethod.pickup) ...[
                              _buildSummaryRow(
                                  Icon(Icons.store,
                                      size: 16, color: subTextColor),
                                  'Pickup Method',
                                  'Self Pickup',
                                  textColor,
                                  subTextColor),
                            ] else ...[
                              _buildSummaryRow(
                                  Icon(Icons.volunteer_activism,
                                      size: 16, color: subTextColor),
                                  'Donation',
                                  'To NGO',
                                  textColor,
                                  subTextColor),
                              const SizedBox(height: 12),
                              // NGO Dropdown
                              _isLoadingNgos
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedNgoId,
                                          hint: Row(
                                            children: [
                                              Icon(Icons.business, size: 16, color: subTextColor),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Select NGO',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: subTextColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          isExpanded: true,
                                          icon: Icon(Icons.arrow_drop_down, color: subTextColor),
                                          dropdownColor: Colors.white,
                                          items: _ngos.map((ngo) {
                                            return DropdownMenuItem<String>(
                                              value: ngo['id'],
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundImage: ngo['avatar_url'] != null
                                                        ? NetworkImage(ngo['avatar_url'])
                                                        : null,
                                                    backgroundColor: primaryColor.withOpacity(0.1),
                                                    child: ngo['avatar_url'] == null
                                                        ? Text(
                                                            (ngo['full_name'] as String).isNotEmpty
                                                                ? (ngo['full_name'] as String)[0].toUpperCase()
                                                                : 'N',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: primaryColor,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      ngo['full_name'] ?? 'NGO',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() => _selectedNgoId = value);
                                            debugPrint('✅ NGO selected: $value');
                                          },
                                        ),
                                      ),
                                    ),
                              // Warning if no NGO selected
                              if (_ngos.isEmpty && !_isLoadingNgos) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber, size: 20, color: Colors.orange[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'No approved NGOs available. Please contact support.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_selectedNgoId == null && foodie.deliveryMethod == DeliveryMethod.donate) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, size: 20, color: Colors.red[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Please select an NGO to continue',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[900],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Promo Code Section
                Text('Offers & Discounts',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: GoogleFonts.plusJakartaSans(
                              color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Apply',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold, 
                                color: primaryColor,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Method',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 12, color: primaryColor),
                          SizedBox(width: 4),
                          Text('Secured',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPaymentOption(
                    'card',
                    'Credit / Debit Card',
                    'Visa, Mastercard (via Paymob)',
                    Icons.credit_card,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    'wallet',
                    'Mobile Wallet',
                    'Vodafone, Orange, Etisalat Cash',
                    Icons.account_balance_wallet,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    'cod',
                    'Cash on Delivery',
                    'Pay cash when order arrives',
                    Icons.payments,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, Color textColor, Color subTextColor,
      Color primaryColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                  image: NetworkImage(item.meal.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(item.meal.title,
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('EGP ${item.lineTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                Text(item.meal.restaurant.name,
                    style: TextStyle(fontSize: 12, color: subTextColor)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Qty: ${item.qty}',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Surplus Food',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(Widget icon, String label, String value,
      Color textColor, Color subTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, color: subTextColor)),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow(
      String label, String value, Color subTextColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor)),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildPaymentOption(
      String value,
      String title,
      String subtitle,
      IconData icon,
      Color borderColor,
      Color primaryColor,
      Color textColor,
      Color subTextColor) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? primaryColor : borderColor,
              width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? primaryColor : subTextColor, width: 2),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, color: textColor)),
                      Icon(icon, color: subTextColor),
                    ],
                  ),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if Pay Now button should be disabled
  bool _isButtonDisabled(FoodieState foodie) {
    // Check if cart is empty
    if (foodie.cartItems.isEmpty) {
      return true;
    }

    // Check delivery method specific requirements
    if (foodie.deliveryMethod == DeliveryMethod.delivery) {
      // Delivery requires address
      if (_deliveryAddress == null || _deliveryAddress!.isEmpty) {
        return true;
      }
    } else if (foodie.deliveryMethod == DeliveryMethod.donate) {
      // Donation requires NGO selection
      if (_selectedNgoId == null || _selectedNgoId!.isEmpty) {
        return true;
      }
      // Also check if NGOs are available
      if (_ngos.isEmpty && !_isLoadingNgos) {
        return true;
      }
    }

    return false;
  }

  Widget _diamondButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
