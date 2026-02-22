# Eco-Impact Dashboard Implementation Guide

## Overview
This guide documents the enhanced user dashboard redesign with eco-impact features, including the Promo Hero Carousel, Category Filter Bar, Eco-Impact Basket, NGO Donation Grid, Frictionless Summary, and Success Screen.

## Completed Changes

### 1. Dashboard Foundation Updates

#### Modified Files:
- `lib/features/user_home/presentation/widgets/highlights_section.dart`
- `lib/features/user_home/presentation/screens/home_dashboard_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ar.arb`

#### Changes Made:
- Added category filtering support to highlights section
- Integrated category selection callback in home dashboard
- Added meal filtering logic based on category keywords
- Added 27 new localization strings for eco-impact features

### 2. Localization Strings Added

```json
{
  "rushHourDeals": "Rush Hour Deals",
  "limitedTime": "Limited Time",
  "ecoSpecial": "Eco Special",
  "giveBack": "Give Back",
  "yourEcoImpact": "Your Eco Impact",
  "kgCo2Saved": "KG CO₂ saved",
  "chooseNgoPartner": "Choose an NGO Partner",
  "verifiedPartner": "Verified Partner",
  "mealsServed": "{count} meals served",
  "basketSubtotal": "Basket Subtotal",
  "yourSavings": "Your Savings",
  "chooseImpactType": "Choose Impact Type",
  "donateToNgo": "Donate to NGO",
  "selfPickup": "Self Pickup",
  "confirmDonation": "Confirm Donation",
  "confirmCheckout": "Confirm Checkout",
  "orderSecured": "Order Secured!",
  "donationSecured": "Donation Secured!",
  "yourPickupCode": "Your Pickup Code",
  "showCodeWhenPickingUp": "Show this code when picking up",
  "pointsEarned": "Points Earned",
  "digitalReceiptSent": "Digital Receipt Sent",
  "trackOrder": "Track Order",
  "backToHome": "Back to Home",
  "reviewEcoImpactOrder": "Review your eco-impact order",
  "basketEmpty": "Your basket is empty",
  "addMealsToStart": "Add meals to start saving food and the planet!"
}
```

## Pending Implementation

The following components were designed but need to be created in the codebase:

### 1. Promo Hero Carousel
**File**: `lib/features/user_home/presentation/widgets/promo_hero_carousel.dart`

**Features**:
- 164px height carousel with auto-scrolling
- Deep emerald gradient overlay (from-emerald-900/80)
- "Limited Time" badge with amber styling
- "Rush Hour Deals" bold headline
- Page indicators with emerald-600 active state
- 3 promo items: Rush Hour Deals, Zero Waste Heroes, Donate & Impact

**Implementation**:
```dart
import 'package:flutter/material.dart';
import 'dart:async';

class PromoHeroCarousel extends StatefulWidget {
  const PromoHeroCarousel({super.key});

  @override
  State<PromoHeroCarousel> createState() => _PromoHeroCarouselState();
}

class _PromoHeroCarouselState extends State<PromoHeroCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<PromoItem> _promos = [
    PromoItem(
      title: 'Rush Hour Deals',
      subtitle: 'Save up to 60% on surplus meals',
      badge: 'Limited Time',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
    ),
    // ... more items
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_controller.hasClients) {
        final nextPage = (_currentPage + 1) % _promos.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 164,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _promos.length,
            itemBuilder: (context, index) => _buildPromoCard(_promos[index]),
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPromoCard(PromoItem promo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF065F46).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(promo.imageUrl, fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xCC064E3B), // emerald-900/80
                      Color(0x99065F46), // emerald-800/60
                      Color(0x4D047857), // emerald-700/30
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF78350F)),
                          const SizedBox(width: 4),
                          Text(
                            promo.badge,
                            style: const TextStyle(
                              color: Color(0xFF78350F),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      promo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_promos.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF059669) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

class PromoItem {
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;

  PromoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageUrl,
  });
}
```

### 2. Category Filter Bar
**File**: `lib/features/user_home/presentation/widgets/category_filter_bar.dart`

**Features**:
- Horizontal scrollable pill-shaped buttons
- 8 categories: All, Meat, Veg, Bakery, Dairy, Fruits, Drinks, Snacks
- Emerald-600 active state with shadow
- White/gray inactive state
- Icon + text for each category

**Key Colors**:
- Active: `Color(0xFF059669)` (emerald-600)
- Inactive (light): `Colors.white` with gray border
- Inactive (dark): `Color(0xFF374151)` (gray-700)

### 3. Eco-Impact Basket
**File**: `lib/features/cart/presentation/widgets/eco_impact_basket.dart`

**Features**:
- Items list with quantity steppers (+/-)
- Impact Card banner showing CO2 saved calculation
- Formula: `totalItems * 2.5 kg CO2 per meal`
- Emerald gradient styling
- Empty state with eco messaging

**Impact Card Design**:
- Gradient: emerald-600 to emerald-700
- Large CO2 number display (32px font)
- Eco icon in rounded container
- Item count badge

### 4. NGO Donation Grid
**File**: `lib/features/checkout/presentation/widgets/ngo_donation_grid.dart`

**Features**:
- 2-column grid layout
- 6 NGO partners with mock data
- Large initials in colored circles
- Distance in KM
- "Verified Partner" badge
- Meals served count
- Selection state with emerald highlight

**NGO Partners**:
1. Food For All Foundation (FFA) - 1.2 KM - 15,420 meals
2. Community Kitchen (CK) - 2.5 KM - 8,930 meals
3. Hunger Relief Network (HRN) - 3.1 KM - 22,150 meals
4. Share A Meal (SAM) - 4.8 KM - 5,670 meals (not verified)
5. Zero Hunger Initiative (ZHI) - 5.2 KM - 31,200 meals
6. Local Food Bank (LFB) - 1.8 KM - 12,890 meals

### 5. Frictionless Summary
**File**: `lib/features/checkout/presentation/widgets/frictionless_summary.dart`

**Features**:
- Bottom sheet design with rounded top corners (28px)
- Basket subtotal, savings (emerald), platform fee
- Impact Type selection: 2 large visual buttons
  - "Donate to NGO" with volunteer icon
  - "Self Pickup" with walk icon
- Total display (28px font, bold)
- "Confirm Checkout" button (rounded-24px, heavy shadow)

**Button States**:
- Selected: emerald-600 background, white text
- Unselected: gray background, dark text

### 6. Success Screen
**File**: `lib/features/checkout/presentation/screens/success_screen.dart`

**Features**:
- "Secured!" celebration header with animated checkmark
- Large checkmark circle (120px) with emerald gradient
- Digital Receipt: 4-digit OTP display
  - Each digit in separate rounded container (56x72px)
  - Gray background (rounded-40px)
  - Emerald border
- Progress indicators:
  - Points Earned: +150 with star icon
  - Digital Receipt Sent: with receipt icon
- Order details card:
  - Order ID
  - Amount Paid
  - CO₂ Saved (2.5 KG)
  - Donated To (if donation)
- Action buttons:
  - "Track Order" (emerald, primary)
  - "Back to Home" (outlined, secondary)

**Animations**:
- Checkmark scales in with elastic curve
- Content fades in after checkmark
- Duration: 600ms checkmark, 400ms content

### 7. Enhanced Checkout Screen
**File**: `lib/features/checkout/presentation/screens/enhanced_checkout_screen.dart`

**Features**:
- Integrates all new components
- Route: `/checkout/enhanced`
- Eco badge in app bar
- Scrollable content area
- Fixed bottom summary sheet
- Conditional NGO grid (only shows when donate is selected)

## Integration Steps

### Step 1: Create Widget Files
Create all 7 widget/screen files listed above in their respective directories.

### Step 2: Update Routes
Add the enhanced checkout route to `lib/features/checkout/routes.dart`:

```dart
GoRoute(
  path: EnhancedCheckoutScreen.routeName,
  builder: (context, state) => const EnhancedCheckoutScreen(),
),
GoRoute(
  path: SuccessScreen.routeName,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return SuccessScreen(
      orderId: extra?['orderId'] as String?,
      totalAmount: extra?['totalAmount'] as double?,
      isDonation: extra?['isDonation'] as bool? ?? false,
      ngoName: extra?['ngoName'] as String?,
    );
  },
),
```

### Step 3: Update Highlights Section
Replace the offer of the day section with the promo hero carousel in `highlights_section.dart`:

```dart
// Replace this:
// Offer of the Day section

// With this:
const PromoHeroCarousel(),
const SizedBox(height: 24),
CategoryFilterBar(onCategorySelected: onCategorySelected),
```

### Step 4: Update Cart Screen
Replace the cart items list with the Eco-Impact Basket in `cart_screen.dart`:

```dart
// In the cart screen body:
const EcoImpactBasket(),
```

### Step 5: Test Navigation Flow
1. Home Dashboard → Browse meals with category filters
2. Add meals to cart → View eco-impact
3. Checkout → Choose impact type (donate/pickup)
4. If donate → Select NGO partner
5. Confirm → Success screen with OTP

## Color Palette

### Emerald Theme
- `emerald-600`: `Color(0xFF059669)` - Primary actions, active states
- `emerald-700`: `Color(0xFF047857)` - Gradients, hover states
- `emerald-800`: `Color(0xFF065F46)` - Dark gradients
- `emerald-900`: `Color(0xFF064E3B)` - Darkest gradients
- `emerald-50`: `Color(0xFFD1FAE5)` - Light backgrounds, inactive indicators

### Amber Accents
- `amber-400`: `Color(0xFFFBBF24)` - Badges, highlights
- `amber-900`: `Color(0xFF78350F)` - Badge text

### Gray Scale
- `gray-700`: `Color(0xFF374151)` - Dark mode cards
- `gray-600`: `Color(0xFF4B5563)` - Dark mode borders
- `gray-500`: `Color(0xFF6B7280)` - Secondary text
- `gray-400`: `Color(0xFF9CA3AF)` - Tertiary text
- `gray-300`: `Color(0xFFD1D5DB)` - Light borders
- `gray-200`: `Color(0xFFE5E7EB)` - Dividers
- `gray-100`: `Color(0xFFF3F4F6)` - Light backgrounds

## Testing Checklist

- [ ] Promo carousel auto-scrolls every 4 seconds
- [ ] Category filter updates meal list
- [ ] Eco-impact card calculates CO2 correctly
- [ ] Quantity steppers work in basket
- [ ] NGO selection highlights card
- [ ] Impact type toggles between donate/pickup
- [ ] Success screen shows correct OTP
- [ ] Animations play smoothly
- [ ] Dark mode styling works
- [ ] Localization works for both English and Arabic

## Next Steps

1. Create all widget files as documented above
2. Test each component individually
3. Integrate into existing screens
4. Add unit tests for calculations
5. Add widget tests for interactions
6. Test on multiple screen sizes
7. Verify accessibility compliance
8. Performance test with large datasets

## Notes

- All components support dark mode
- RTL support is built-in via localization
- CO2 calculation is currently mock (2.5kg per meal)
- NGO data is currently hardcoded
- OTP generation is random (4 digits)
- Images use Unsplash URLs (replace with actual assets)

## Repository Status

✅ Foundation changes committed and pushed to GitHub
✅ Localization strings added
✅ Category filtering integrated
⏳ Widget files need to be created
⏳ Full integration pending

**Commit**: `feat: Enhanced user dashboard with eco-impact features`
**Branch**: `main`
**Status**: Pushed to origin
