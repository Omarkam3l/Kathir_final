import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';

class CouponsScreen extends StatefulWidget {
  static const routeName = '/coupons';
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final TextEditingController _couponController = TextEditingController();
  List<CouponModel> _availableCoupons = [];
  final List<CouponModel> _userCoupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _loadCoupons() {
    // Demo coupons
    _availableCoupons = [
      const CouponModel(
        id: '1',
        restaurantName: 'Restaurant Name',
        description: 'Lorem ipsum dolor sit amet.',
        discount: 20,
        imageUrl:
            'https://source.unsplash.com/collection/1424340/200x200?restaurant',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.darkText;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _CouponsAppBar(textColor: textColor),
            Expanded(
              child: _userCoupons.isEmpty
                  ? _EmptyCouponsState(
                      onAddCoupon: () => _showAddCouponDialog(context),
                    )
                  : _CouponsList(
                      coupons: _userCoupons,
                      onAddCoupon: () => _showAddCouponDialog(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCouponDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddCouponDialog(
        availableCoupons: _availableCoupons,
        onApply: (coupon) {
          setState(() {
            if (!_userCoupons.any((c) => c.id == coupon.id)) {
              _userCoupons.add(coupon);
            }
          });
          Navigator.of(context).pop();
          Navigator.of(context).pop(coupon);
        },
      ),
    );
  }
}

class _CouponsAppBar extends StatelessWidget {
  const _CouponsAppBar({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
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
              'Coupons',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _diamondButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDarkMode ? const Color(0xFF1E1E1E) : AppColors.white;
    final iconColor = isDarkMode ? AppColors.white : AppColors.darkText;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.08);

    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _EmptyCouponsState extends StatelessWidget {
  const _EmptyCouponsState({required this.onAddCoupon});

  final VoidCallback onAddCoupon;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.05);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _CouponIconPainter(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You don\'t have coupon.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onAddCoupon,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.secondaryAccent, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: AppColors.secondaryAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Coupon',
                    style: TextStyle(
                      color: AppColors.secondaryAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
}

class _CouponsList extends StatelessWidget {
  const _CouponsList({required this.coupons, required this.onAddCoupon});

  final List<CouponModel> coupons;
  final VoidCallback onAddCoupon;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.darkText;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        ...coupons.map(
          (coupon) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    coupon.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.lightBackground,
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.restaurantName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.description,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${coupon.discount}%',
                  style: const TextStyle(
                    color: AppColors.secondaryAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onAddCoupon,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.secondaryAccent, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.secondaryAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Coupon',
                style: TextStyle(
                  color: AppColors.secondaryAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddCouponDialog extends StatefulWidget {
  const _AddCouponDialog({
    required this.onApply,
    required this.availableCoupons,
  });

  final Function(CouponModel) onApply;
  final List<CouponModel> availableCoupons;

  @override
  State<_AddCouponDialog> createState() => _AddCouponDialogState();
}

class _AddCouponDialogState extends State<_AddCouponDialog> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.darkText;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF5E6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: AppColors.secondaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter Coupon Code',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  if (_codeController.text.isNotEmpty) {
                    // Try to find matching coupon from available coupons
                    final matchingCoupon = widget.availableCoupons.firstWhere(
                      (c) =>
                          c.id.toLowerCase() ==
                          _codeController.text.toLowerCase(),
                      orElse: () => CouponModel(
                        id: _codeController.text,
                        restaurantName: 'Special Offer',
                        description: 'Discount applied',
                        discount: 10,
                        imageUrl:
                            'https://source.unsplash.com/collection/1424340/200x200?restaurant',
                      ),
                    );
                    widget.onApply(matchingCoupon);
                  }
                },
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw coupon ticket icons
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Left coupon
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 50, centerY - 20, 30, 40),
        const Radius.circular(4),
      ),
      paint,
    );

    // Right coupon with %
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 20, centerY - 20, 30, 40),
        const Radius.circular(4),
      ),
      paint,
    );

    // Draw % symbol
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '%',
        style: TextStyle(
          color: AppColors.secondaryAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX + 35 - textPainter.width / 2,
          centerY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CouponModel {
  const CouponModel({
    required this.id,
    required this.restaurantName,
    required this.description,
    required this.discount,
    required this.imageUrl,
  });

  final String id;
  final String restaurantName;
  final String description;
  final int discount;
  final String imageUrl;
}
