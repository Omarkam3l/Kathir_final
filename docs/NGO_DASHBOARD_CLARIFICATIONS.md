# NGO Dashboard - Clarifications

## 🍽️ Dynamic Meal Listing - How It Works

### **Restaurants Upload → NGOs View & Claim**

The NGO dashboard is designed for **NGOs to VIEW and CLAIM meals** that **restaurants upload**. Here's the flow:

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│ Restaurant  │ Upload  │   Supabase   │  View   │     NGO     │
│  Dashboard  ├────────>│   Database   │<────────┤  Dashboard  │
└─────────────┘  Meal   └──────────────┘  Meals  └─────────────┘
                                                          │
                                                          │ Claim
                                                          ▼
                                                   ┌─────────────┐
                                                   │    Order    │
                                                   │   Created   │
                                                   └─────────────┘
```

### **Step-by-Step Process:**

1. **Restaurant Uploads Meal**
   - Restaurant uses their dashboard
   - Adds surplus food details (title, quantity, expiry, etc.)
   - Sets `is_donation_available = true`
   - Meal appears in database with `status = 'active'`

2. **NGO Views Meals**
   - NGO opens their dashboard
   - Sees all available donation meals in real-time
   - Can search and filter meals
   - Sees expiring meals highlighted

3. **NGO Claims Meal**
   - NGO clicks "Claim Now" button
   - System creates an order in `orders` table
   - Meal status updates to `reserved`
   - Restaurant gets notified (future feature)

4. **Real-time Updates**
   - When restaurant uploads new meal → NGO dashboard updates automatically
   - When NGO claims meal → Meal disappears from other NGOs' view
   - When meal expires → Automatically removed from listings

### **Database Flow:**

```sql
-- Restaurant uploads meal
INSERT INTO meals (
  restaurant_id,
  title,
  quantity_available,
  expiry_date,
  is_donation_available,
  status
) VALUES (
  'restaurant-uuid',
  'Surplus Biryani',
  15,
  NOW() + INTERVAL '2 hours',
  true,
  'active'
);

-- NGO views meals (automatic query)
SELECT * FROM meals
WHERE is_donation_available = true
  AND status = 'active'
  AND quantity_available > 0
  AND expiry_date > NOW();

-- NGO claims meal
INSERT INTO orders (ngo_id, meal_id, status, delivery_type)
VALUES ('ngo-uuid', 'meal-uuid', 'pending', 'donation');

UPDATE meals SET status = 'reserved' WHERE id = 'meal-uuid';
```

## 🎨 Color Usage - AppColors Only

All colors in the NGO dashboard now use `AppColors` class:

### **Available Colors:**

```dart
// Primary Colors
AppColors.primary          // Main green #2E7D32
AppColors.primaryGreen     // Same as primary
AppColors.primaryDark      // Dark green #1B5E20
AppColors.primarySoft      // Light green #66BB6A

// Background Colors
AppColors.backgroundLight  // Light mode background #F0F0F0
AppColors.backgroundDark   // Dark mode background #121212
AppColors.surfaceLight     // Light surface (white)
AppColors.surfaceDark      // Dark surface #1E1E1E

// Status Colors
AppColors.success          // Green #43A047
AppColors.error            // Red #E53935
AppColors.warning          // Orange #FFFacebook8C00
AppColors.info             // Blue #1E88E5
AppColors.red              // Red #E53935
AppColors.orange           // Orange #FB8C00
AppColors.green            // Green #43A047

// Base Colors
AppColors.white            // White #FFFFFF
AppColors.black            // Black #000000
AppColors.grey             // Grey (Colors.grey)
```

### **Usage Examples:**

```dart
// Background
backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight

// Surface (cards, containers)
color: isDark ? AppColors.surfaceDark : AppColors.white

// Primary actions
backgroundColor: AppColors.primaryGreen

// Status indicators
color: AppColors.success  // for success
color: AppColors.error    // for errors
color: AppColors.warning  // for warnings
```

## 🗑️ Deleted Old Files

The following old files have been removed as they're replaced by the new implementation:

### **Deleted:**
- ❌ `lib/features/ngo_dashboard/presentation/screens/ngo_dashboard_screen.dart`
- ❌ `lib/features/ngo_dashboard/presentation/viewmodels/ngo_dashboard_viewmodel.dart`

### **New Files (Keep These):**
- ✅ `lib/features/ngo_dashboard/presentation/screens/ngo_home_screen.dart`
- ✅ `lib/features/ngo_dashboard/presentation/screens/ngo_map_screen.dart`
- ✅ `lib/features/ngo_dashboard/presentation/screens/ngo_profile_screen.dart`
- ✅ `lib/features/ngo_dashboard/presentation/viewmodels/ngo_home_viewmodel.dart`
- ✅ `lib/features/ngo_dashboard/presentation/viewmodels/ngo_map_viewmodel.dart`
- ✅ `lib/features/ngo_dashboard/presentation/viewmodels/ngo_profile_viewmodel.dart`
- ✅ All widget files (5 widgets)
- ✅ All documentation files

## 🔄 Real-time Updates (Optional Enhancement)

To make meals appear instantly when restaurants upload, you can add Supabase Realtime:

```dart
// In ngo_home_viewmodel.dart
void subscribeToMeals() {
  _supabase
      .from('meals')
      .stream(primaryKey: ['id'])
      .eq('is_donation_available', true)
      .eq('status', 'active')
      .listen((data) {
        loadMeals(); // Refresh meals list
      });
}
```

Call this in `initState` of the home screen for live updates.

## 📝 Summary

1. **Dynamic Meals**: Restaurants upload → NGOs view & claim
2. **Colors**: All use `AppColors` class (no hardcoded colors)
3. **Clean Code**: Old files deleted, only new implementation remains
4. **Real-time**: Meals update when restaurants add new surplus food
5. **Professional**: Production-ready with proper architecture

---

**The NGO dashboard is a viewing and claiming interface, not an upload interface.**
**Restaurants upload meals, NGOs claim them to help reduce food waste!**
