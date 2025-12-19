import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCoupons();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _loadCoupons() {
    final l10n = AppLocalizations.of(context)!;
    // Demo coupons
    _availableCoupons = [
      CouponModel(
        id: '1',
        restaurantName: l10n.demoRestaurantName,
        description: l10n.demoCouponDescription,
        discount: 20,
        imageUrl:
            'https://source.unsplash.com/collection/1424340/200x200?restaurant',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _CouponsAppBar(),
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
  const _CouponsAppBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.couponsTitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
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

class _EmptyCouponsState extends StatelessWidget {
  const _EmptyCouponsState({required this.onAddCoupon});

  final VoidCallback onAddCoupon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                    painter: _CouponIconPainter(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noCouponsMessage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onAddCoupon,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addCouponAction,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        ...coupons.map(
          (coupon) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Icon(
                        Icons.restaurant,
                        color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.description,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${coupon.discount}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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
            side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.addCouponAction,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
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
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.enterCouponCodeTitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: l10n.enterCouponCodeHint,
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).scaffoldBackgroundColor,
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
                child: Text(
                  l10n.submitAction,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
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
  final Color color;
  _CouponIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
      text: TextSpan(
        text: '%',
        style: TextStyle(
          color: color,
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
  bool shouldRepaint(covariant _CouponIconPainter oldDelegate) => color != oldDelegate.color;
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
