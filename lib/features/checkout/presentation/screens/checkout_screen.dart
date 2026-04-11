import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../profile/presentation/screens/addresses_screen.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../checkout/data/services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _supabase = Supabase.instance.client;
  final _paymentService = PaymentService();
  final _promoCodeController = TextEditingController();
  String _paymentMethod = 'card'; // card, wallet
  bool _isCreatingOrder = false;
  String? _deliveryAddress;
  double? _deliveryLatitude;
  double? _deliveryLongitude;
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

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
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
      debugPrint('🔍 Loading default address...');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No user ID found');
        setState(() => _isLoadingAddress = false);
        return;
      }

      debugPrint('✅ User ID: $userId');
      
      // First try to get default address
      final response = await _supabase
          .from('user_addresses')
          .select('address_text, label, latitude, longitude')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      debugPrint('📍 Default address query result: ${response != null ? "Found" : "Not found"}');
      
      if (response != null) {
        debugPrint('✅ Default address loaded:');
        debugPrint('   Address: ${response['address_text']}');
        debugPrint('   Label: ${response['label']}');
        setState(() {
          _deliveryAddress = response['address_text'];
          _deliveryLatitude = response['latitude'] as double?;
          _deliveryLongitude = response['longitude'] as double?;
          _isLoadingAddress = false;
        });
      } else {
        // No default address, try to get any address
        debugPrint('⚠️ No default address, trying to get any address...');
        final anyAddress = await _supabase
            .from('user_addresses')
            .select('address_text, label, latitude, longitude')
            .eq('user_id', userId)
            .limit(1)
            .maybeSingle();

        debugPrint('📍 Any address query result: ${anyAddress != null ? "Found" : "Not found"}');
        
        if (anyAddress != null) {
          debugPrint('✅ Address loaded:');
          debugPrint('   Address: ${anyAddress['address_text']}');
          debugPrint('   Label: ${anyAddress['label']}');
        } else {
          debugPrint('❌ No addresses found in database');
        }
        
        setState(() {
          _deliveryAddress = anyAddress?['address_text'];
          _deliveryLatitude = anyAddress?['latitude'] as double?;
          _deliveryLongitude = anyAddress?['longitude'] as double?;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading address: $e');
      setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors
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
        backgroundColor: Colors.white.withValues(alpha: 0.8),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
              if (foodie.discountAmount > 0) ...[
                const SizedBox(height: 8),
                _buildFooterRow(
                    'Discount (${foodie.promoCodeDiscount.toStringAsFixed(0)}%)',
                    '- EGP ${foodie.discountAmount.toStringAsFixed(2)}',
                    AppColors.primaryGreen,
                    AppColors.primaryGreen),
              ],
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
                      onPressed: _isCreatingOrder || _isButtonDisabled(foodie) ? null : () => _handleStripePayment(foodie),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                                                  color: primaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.edit_location, size: 16, color: primaryColor),
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
                                                    backgroundColor: primaryColor.withValues(alpha: 0.1),
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                          controller: _promoCodeController,
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
                          onSubmitted: (_) => _applyPromoCode(foodie),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _applyPromoCode(foodie),
                        child: Text('Apply',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold, 
                                color: primaryColor,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                
                // Show applied discount
                if (foodie.promoCode != null && foodie.promoCodeDiscount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Promo code "${foodie.promoCode}" applied',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              Text(
                                '${foodie.promoCodeDiscount.toStringAsFixed(0)}% discount - Save EGP ${foodie.discountAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.primaryGreen,
                          onPressed: () {
                            foodie.clearPromoCode();
                            _promoCodeController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],

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
                          color: primaryColor.withValues(alpha: 0.1),
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
                    'Pay with Visa, Mastercard via Stripe',
                    Icons.credit_card,
                    borderColor,
                    primaryColor,
                    textColor,
                    subTextColor),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    'wallet',
                    'Digital Wallet',
                    'Apple Pay, Google Pay',
                    Icons.account_balance_wallet,
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
              color: primaryColor.withValues(alpha: 0.1),
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
              color: Colors.black.withValues(alpha: 0.05),
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

  /// Handle Stripe payment flow
  Future<void> _handleStripePayment(FoodieState foodie) async {
    // Check if running on web (Stripe not supported)
    if (kIsWeb) {
      debugPrint('❌ Stripe payment not supported on web');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stripe payment is only available on mobile. Please use the mobile app.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      setState(() => _isCreatingOrder = false);
      return;
    }

    // Check if Stripe is configured
    if (Stripe.publishableKey.isEmpty) {
      debugPrint('❌ Stripe not configured');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment system not configured. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isCreatingOrder = false);
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
      }
      setState(() => _isCreatingOrder = false);
      return;
    }

    if (foodie.cartItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty')),
        );
      }
      setState(() => _isCreatingOrder = false);
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

      // Check if order is free (100% discount)
      final isFreeOrder = foodie.total <= 0;
      
      if (isFreeOrder) {
        debugPrint('🎁 Free order detected (100% discount)');
        debugPrint('   Skipping Stripe payment, creating order directly...');
        
        // Show processing dialog
        if (!mounted) return;
        final rootNav = Navigator.of(context, rootNavigator: true);
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Creating your free order...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        try {
          // Create free order directly via Edge Function
          final response = await _supabase.functions.invoke(
            'create-free-order',
            body: {
              'delivery_method': foodie.deliveryMethod.name,
              'delivery_address': finalAddress,
              'delivery_latitude': _deliveryLatitude,
              'delivery_longitude': _deliveryLongitude,
              'special_instructions': null,
              'ngo_id': _selectedNgoId,
              'promo_code': foodie.promoCode,
            },
          );

          if (!mounted) return;
          rootNav.pop(); // Close loading dialog

          if (response.status == 200) {
            final data = response.data as Map<String, dynamic>;
            final orderId = data['order_id'] as String;
            
            debugPrint('✅ Free order created: $orderId');
            
            // Increment promo code usage
            if (foodie.promoCode != null && foodie.promoCode!.isNotEmpty) {
              try {
                await _supabase.rpc('increment_promo_code_usage', params: {
                  'p_code': foodie.promoCode,
                });
              } catch (e) {
                debugPrint('⚠️ Failed to increment promo code usage: $e');
              }
            }

            await foodie.clearCart();
            
            if (!mounted) return;
            context.go('/order-summary/$orderId');
          } else {
            throw Exception('Failed to create free order');
          }
        } catch (e) {
          if (mounted) {
            rootNav.pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating free order: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isCreatingOrder = false);
        }
        return;
      }

      // STRIPE PAYMENT FLOW (for non-free orders)
      // Step 1: Create PaymentIntent on backend (server calculates prices)
      debugPrint('💳 Creating PaymentIntent...');
      debugPrint('   Payment Method: $_paymentMethod');
      final paymentIntent = await _paymentService.createPaymentIntent(
        deliveryMethod: foodie.deliveryMethod.name,
        deliveryAddress: finalAddress,
        deliveryLatitude: _deliveryLatitude,
        deliveryLongitude: _deliveryLongitude,
        specialInstructions: null, // Can be added later if needed
        ngoId: _selectedNgoId,
        promoCode: foodie.promoCode, // Pass promo code for server-side validation
      );

      debugPrint('✅ PaymentIntent created: ${paymentIntent.paymentIntentId}');
      debugPrint('   Amount: ${paymentIntent.amount} EGP');
      if (foodie.promoCode != null && foodie.promoCode!.isNotEmpty) {
        debugPrint('   Promo Code Applied: ${foodie.promoCode}');
        debugPrint('   Discount: ${foodie.discountAmount.toStringAsFixed(2)} EGP');
      }

      // Step 2: Initialize Stripe Payment Sheet with appropriate payment method
      debugPrint('🎨 Initializing Payment Sheet...');
      
      // Configure payment options based on selected method
      PaymentSheetGooglePay? googlePayConfig;
      PaymentSheetApplePay? applePayConfig;
      
      if (_paymentMethod == 'wallet') {
        // Enable digital wallets (Apple Pay / Google Pay)
        debugPrint('   Enabling digital wallet payments...');
        
        googlePayConfig = const PaymentSheetGooglePay(
          merchantCountryCode: 'EG',
          currencyCode: 'EGP',
          testEnv: true, // Set to false in production
        );
        
        applePayConfig = const PaymentSheetApplePay(
          merchantCountryCode: 'EG',
        );
      }
      
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'Kathir',
          customerId: paymentIntent.customerId,
          customerEphemeralKeySecret: paymentIntent.ephemeralKey,
          style: ThemeMode.system,
          googlePay: googlePayConfig,
          applePay: applePayConfig,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primary,
            ),
          ),
        ),
      );

      debugPrint('✅ Payment Sheet initialized');

      // Step 3: Present Payment Sheet to user
      debugPrint('📱 Presenting Payment Sheet...');
      await Stripe.instance.presentPaymentSheet();

      debugPrint('✅ Payment completed successfully!');

      // Step 4: Payment successful! Wait for webhook to create order
      if (!mounted) return;

      final rootNav = Navigator.of(context, rootNavigator: true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Processing your order...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirming payment and creating your order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      debugPrint('⏳ Waiting for webhook to create order...');
      List<OrderInfo> orders = [];
      try {
        orders = await _paymentService.waitForOrderCreation(
          paymentIntent.paymentIntentId,
        );
      } finally {
        if (mounted) {
          rootNav.pop();
        }
      }

      if (orders.isNotEmpty) {
        debugPrint('✅ Order(s) created by webhook!');

        // Increment promo code usage if one was applied
        if (foodie.promoCode != null && foodie.promoCode!.isNotEmpty) {
          try {
            debugPrint('📊 Incrementing promo code usage: ${foodie.promoCode}');
            await _supabase.rpc('increment_promo_code_usage', params: {
              'p_code': foodie.promoCode,
            });
            debugPrint('✅ Promo code usage incremented');
          } catch (e) {
            debugPrint('⚠️ Failed to increment promo code usage: $e');
            // Don't fail the order if this fails
          }
        }

        await foodie.clearCart();

        if (!mounted) return;

        if (orders.length == 1) {
          context.go('/order-summary/${orders[0].orderId}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${orders.length} orders created successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          context.go('/my-orders');
        }
      } else {
        debugPrint('⏰ No order record yet after payment');

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Payment received',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Your payment went through, but we could not confirm the order in the app yet. '
              'Pull to refresh on My Orders in a minute. If nothing appears, contact support with your receipt.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/my-orders');
                },
                child: const Text('My orders'),
              ),
            ],
          ),
        );
      }

      setState(() => _isCreatingOrder = false);

    } on StripeException catch (e) {
      // Payment failed or cancelled by user
      debugPrint('❌ Stripe error: ${e.error.code} - ${e.error.message}');
      setState(() => _isCreatingOrder = false);

      if (!mounted) return;

      String errorMessage = 'Payment failed';
      if (e.error.code == FailureCode.Canceled) {
        errorMessage = 'Payment cancelled';
      } else if (e.error.message != null) {
        errorMessage = e.error.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in payment flow: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isCreatingOrder = false);

      if (!mounted) return;

      // Parse error message for user-friendly display
      String errorMessage = 'Failed to process payment';
      if (e.toString().contains('Cart is empty')) {
        errorMessage = 'Your cart is empty';
      } else if (e.toString().contains('out of stock')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
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

  /// Apply promo code with percentage discount
  Future<void> _applyPromoCode(FoodieState foodie) async {
    final code = _promoCodeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a promo code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );

    try {
      // Calculate order amount for validation
      final orderAmount = foodie.subtotal + foodie.deliveryFee + foodie.platformFee;

      // Validate promo code against database
      final response = await _supabase.rpc(
        'validate_promo_code',
        params: {
          'p_code': code,
          'p_order_amount': orderAmount,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (response is List && response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final isValid = result['is_valid'] as bool;
        final discountPercentage = (result['discount_percentage'] as num?)?.toDouble() ?? 0.0;
        final message = result['message'] as String;

        if (isValid && discountPercentage > 0) {
          foodie.setPromoCode(code, discountPercentage);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$message! ${discountPercentage.toStringAsFixed(0)}% discount applied'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid promo code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error validating promo code: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog if still open
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error validating promo code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
