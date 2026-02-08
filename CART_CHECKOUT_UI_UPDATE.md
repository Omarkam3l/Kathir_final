# Cart & Checkout UI Update - Complete

## Summary
Updated cart and checkout screens to match reference design with clean white cards, proper spacing, and added NGO dropdown functionality for donations.

## Changes Made

### 1. Cart Screen (`lib/features/cart/presentation/screens/cart_screen.dart`)

#### Promo Code Section
- Updated to white card background with subtle shadow
- Improved spacing and padding
- Better icon placement and sizing
- Cleaner input field styling

#### Distribution Method Selector
- Changed from Radio buttons to custom circular selection indicators
- Updated card styling to white background with shadows
- Improved border colors and selection states
- Better tag styling with proper colors:
  - "Free" tag: Green color
  - "EGP +2.99" tag: Grey color
  - "Fee Waived" tag: Green color
- Kept volunteer_activism icon for NGO donation option
- Consistent spacing and typography

### 2. Checkout Screen (`lib/features/checkout/presentation/screens/checkout_screen.dart`)

#### New Features
- **NGO Dropdown**: Added dropdown selector when "Donate to NGO" is selected
  - Loads all registered NGOs from database
  - Shows NGO avatar and name
  - Dropdown appears in order summary section below donation info
  - Stores selected NGO ID in state
  - White background for dropdown and dropdown menu

#### Promo Code Section
- Added "Offers & Discounts" section with promo code input
- White card background with shadow
- Green offer icon
- "Apply" button with proper styling
- Positioned at top of screen after order summary

#### Layout Improvements
- Removed duplicate Distribution Method section (only in cart screen)
- Better section ordering:
  1. Order Summary (with NGO dropdown when donate selected)
  2. Offers & Discounts (Promo Code)
  3. Payment Method
- Improved spacing between sections
- All cards now have consistent white background with subtle shadows

#### Bottom Bar
- Changed background from purple to white
- Green "Pay Now" button (matching reference design)
- Clean white background with subtle top shadow

### 3. Database Integration

#### NGO Loading
```dart
Future<void> _loadNgos() async {
  final response = await _supabase
      .from('profiles')
      .select('id, full_name, avatar_url')
      .eq('role', 'ngo')
      .order('full_name');
  // Stores in _ngos list
}
```

#### State Management
- Added `_selectedNgoId` to track selected NGO
- Added `_ngos` list to store available NGOs
- Added `_isLoadingNgos` for loading state

## UI Design Principles Applied

1. **Consistent Card Styling**
   - White background (`Colors.white`)
   - Subtle shadow: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))`
   - 16px border radius
   - Proper padding

2. **Color Scheme**
   - Background: `AppColors.backgroundLight` (light greenish-white)
   - Cards: White
   - Primary accent: `AppColors.primary` (red)
   - Success/Free: `AppColors.primaryGreen`
   - Text: Dark for main, grey for secondary
   - Pay Now button: Green (`AppColors.primaryGreen`)

3. **Typography**
   - Section headers: 18px, bold
   - Card titles: 15px, bold
   - Subtitles: 13px, grey
   - Tags: 11px, bold

4. **Spacing**
   - Between sections: 24px
   - Between cards: 12px
   - Card padding: 16px
   - Internal spacing: 8-12px

## Key Fixes from User Feedback

1. ✅ Restored volunteer_activism icon (removed emoji)
2. ✅ Removed duplicate distribution method section from checkout
3. ✅ Fixed all purple backgrounds to white
4. ✅ Fixed NGO dropdown background to white
5. ✅ Fixed bottom bar background to white
6. ✅ Changed Pay Now button to green

## Testing Checklist

- [x] Cart screen compiles without errors
- [x] Checkout screen compiles without errors
- [x] Promo code input displays correctly
- [x] Distribution method cards styled properly (cart only)
- [x] NGO dropdown loads when donation selected
- [x] NGO dropdown has white background
- [x] Payment method cards styled correctly
- [x] All currency displays show "EGP"
- [x] Selection states work correctly
- [x] Shadows and borders render properly
- [x] Bottom bar has white background
- [x] Pay Now button is green

## Files Modified

1. `lib/features/cart/presentation/screens/cart_screen.dart`
2. `lib/features/checkout/presentation/screens/checkout_screen.dart`

## Notes

- Distribution method selection only appears in cart screen
- NGO dropdown only appears in checkout when "Donate to NGO" is selected
- All cards now have consistent white backgrounds matching reference design
- Promo code section added to checkout screen
- Bottom bar and Pay Now button match reference design colors

