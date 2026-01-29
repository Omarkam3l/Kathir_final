# 🚀 RESTAURANT DASHBOARD - COMPLETE IMPLEMENTATION GUIDE

## 📋 OVERVIEW

This guide provides step-by-step instructions to implement the redesigned restaurant dashboard with:
1. Meals list view
2. Add/Edit meal form in separate screen
3. Image upload to Supabase storage
4. Bottom navigation bar
5. Complete CRUD operations

---

## 🗄️ STEP 1: DEPLOY STORAGE BUCKET

### Deploy SQL Migration

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `meal-images-bucket-setup.sql`
3. Paste and click "Run"
4. Verify output shows: "✅ Bucket meal-images created successfully"

### Verify Bucket

```sql
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
WHERE id = 'meal-images';
```

Expected: 1 row with `file_size_limit = 5242880`

---

## 📱 STEP 2: CREATE NEW SCREENS

### File Structure
```
lib/features/restaurant_dashboard/
├── presentation/
│   ├── screens/
│   │   ├── restaurant_dashboard_screen.dart (UPDATE)
│   │   ├── add_meal_screen.dart (NEW)
│   │   ├── edit_meal_screen.dart (NEW)
│   │   └── meal_details_screen.dart (NEW)
│   └── widgets/
│       ├── meal_card.dart (NEW)
│       ├── image_upload_widget.dart (NEW)
│       └── restaurant_bottom_nav.dart (NEW)
```

---

## 🎨 STEP 3: IMPLEMENT SCREENS

### 3.1 Restaurant Dashboard (Main Screen)

**Features**:
- Header with restaurant info
- Stats cards
- Meals grid/list
- Floating "Add Meal" button
- Bottom navigation

**Key Changes**:
- Remove form from dashboard
- Add meals list section
- Add FAB for "Add Meal"
- Add bottom navigation

### 3.2 Add Meal Screen

**Route**: `/restaurant-dashboard/add-meal`

**Form Fields**:
1. Image Upload (required)
2. Title (text, required)
3. Description (textarea, optional)
4. Category (dropdown, required)
5. Original Price (number, required)
6. Discounted Price (number, required)
7. Quantity Available (number, required)
8. Expiry Date (datetime, required)
9. Pickup Deadline (datetime, optional)

**Validation**:
- Title: 3-100 characters
- Original Price: > 0
- Discounted Price: > 0 and <= original_price
- Quantity: >= 1
- Expiry Date: future date
- Image: required, max 5MB

### 3.3 Edit Meal Screen

**Route**: `/restaurant-dashboard/edit-meal/:id`

**Features**:
- Pre-fill form with existing meal data
- Allow image replacement
- Update meal in database
- Navigate back on success

### 3.4 Meal Details Screen

**Route**: `/restaurant-dashboard/meal/:id`

**Features**:
- Display meal image
- Show all meal details
- Edit button → Navigate to edit screen
- Delete button → Confirm and delete
- Toggle active/inactive status

---

## 🖼️ STEP 4: IMAGE UPLOAD IMPLEMENTATION

### Upload Flow

```dart
1. User selects image from device
   ↓
2. Validate file (size, type)
   ↓
3. Generate unique filename: {meal_id}_{timestamp}.jpg
   ↓
4. Upload to: meal-images/{restaurant_id}/{filename}
   ↓
5. Get public URL
   ↓
6. Save URL to meals.image_url
```

### Code Example

```dart
Future<String?> uploadMealImage(File imageFile, String restaurantId) async {
  try {
    // Validate file size (5MB max)
    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) {
      throw Exception('Image size must be less than 5MB');
    }
    
    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mealId = const Uuid().v4();
    final filename = 'meal_${mealId}_$timestamp.jpg';
    final path = '$restaurantId/$filename';
    
    // Upload to Supabase
    await Supabase.instance.client.storage
        .from('meal-images')
        .upload(path, imageFile);
    
    // Get public URL
    final url = Supabase.instance.client.storage
        .from('meal-images')
        .getPublicUrl(path);
    
    return url;
  } catch (e) {
    debugPrint('Error uploading image: $e');
    return null;
  }
}
```

### Image Picker Integration

```dart
import 'package:image_picker/image_picker.dart';

Future<File?> pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  
  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}
```

---

## 🧭 STEP 5: BOTTOM NAVIGATION

### Navigation Tabs

```dart
class RestaurantBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const RestaurantBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Meals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
```

### Navigation Logic

```dart
void _onNavTap(int index) {
  switch (index) {
    case 0:
      context.go('/restaurant-dashboard');
      break;
    case 1:
      context.go('/restaurant-dashboard/meals');
      break;
    case 2:
      context.go('/restaurant-dashboard/orders');
      break;
    case 3:
      context.go('/restaurant-dashboard/profile');
      break;
  }
}
```

---

## 🔄 STEP 6: CRUD OPERATIONS

### Create Meal

```dart
Future<void> createMeal({
  required String title,
  required String description,
  required String category,
  required String imageUrl,
  required double originalPrice,
  required double discountedPrice,
  required int quantity,
  required DateTime expiryDate,
  DateTime? pickupDeadline,
}) async {
  final restaurantId = Supabase.instance.client.auth.currentUser?.id;
  
  await Supabase.instance.client.from('meals').insert({
    'restaurant_id': restaurantId,
    'title': title,
    'description': description,
    'category': category,
    'image_url': imageUrl,
    'original_price': originalPrice,
    'discounted_price': discountedPrice,
    'quantity_available': quantity,
    'expiry_date': expiryDate.toIso8601String(),
    'pickup_deadline': pickupDeadline?.toIso8601String(),
  });
}
```

### Read Meals (List)

```dart
Future<List<Map<String, dynamic>>> getMeals() async {
  final restaurantId = Supabase.instance.client.auth.currentUser?.id;
  
  final response = await Supabase.instance.client
      .from('meals')
      .select()
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(response);
}
```

### Update Meal

```dart
Future<void> updateMeal(String mealId, Map<String, dynamic> updates) async {
  await Supabase.instance.client
      .from('meals')
      .update(updates)
      .eq('id', mealId);
}
```

### Delete Meal

```dart
Future<void> deleteMeal(String mealId, String? imageUrl) async {
  // Delete image from storage if exists
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final path = imageUrl.split('/meal-images/').last;
      await Supabase.instance.client.storage
          .from('meal-images')
          .remove([path]);
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
  
  // Delete meal from database
  await Supabase.instance.client
      .from('meals')
      .delete()
      .eq('id', mealId);
}
```

---

## 🛣️ STEP 7: UPDATE ROUTER

### Add New Routes

```dart
// In app_router.dart

GoRoute(
  name: 'restaurant_dashboard',
  path: '/restaurant-dashboard',
  builder: (context, state) => const RestaurantDashboardScreen(),
  routes: [
    GoRoute(
      name: 'add_meal',
      path: 'add-meal',
      builder: (context, state) => const AddMealScreen(),
    ),
    GoRoute(
      name: 'edit_meal',
      path: 'edit-meal/:id',
      builder: (context, state) {
        final mealId = state.pathParameters['id']!;
        return EditMealScreen(mealId: mealId);
      },
    ),
    GoRoute(
      name: 'meal_details',
      path: 'meal/:id',
      builder: (context, state) {
        final mealId = state.pathParameters['id']!;
        return MealDetailsScreen(mealId: mealId);
      },
    ),
  ],
),
```

---

## ✅ STEP 8: TESTING CHECKLIST

### Functional Testing

- [ ] Deploy storage bucket successfully
- [ ] Dashboard loads and shows meals list
- [ ] Click "Add Meal" navigates to form
- [ ] Image picker opens and allows selection
- [ ] Image uploads to Supabase storage
- [ ] Form validation works correctly
- [ ] Meal saves to database with image URL
- [ ] New meal appears in dashboard list
- [ ] Click meal card shows details
- [ ] Edit meal updates correctly
- [ ] Delete meal removes from database and storage
- [ ] Bottom navigation works
- [ ] All tabs navigate correctly

### Error Handling

- [ ] Image too large shows error
- [ ] Invalid file type shows error
- [ ] Network error shows message
- [ ] Form validation shows errors
- [ ] Upload failure handled gracefully

### UI/UX

- [ ] Loading states show during operations
- [ ] Success messages appear
- [ ] Error messages are clear
- [ ] Images display correctly
- [ ] Responsive layout works
- [ ] Dark mode supported

---

## 📊 STEP 9: DATABASE VERIFICATION

### Check Meals Table

```sql
-- View all meals for a restaurant
SELECT 
  id,
  title,
  category,
  image_url,
  original_price,
  discounted_price,
  quantity_available,
  expiry_date,
  created_at
FROM meals
WHERE restaurant_id = 'YOUR_RESTAURANT_ID'
ORDER BY created_at DESC;
```

### Check Storage Objects

```sql
-- View uploaded images
SELECT 
  name,
  bucket_id,
  created_at,
  metadata->>'size' as file_size
FROM storage.objects
WHERE bucket_id = 'meal-images'
ORDER BY created_at DESC;
```

---

## 🎯 SUCCESS CRITERIA

After implementation:

✅ **Dashboard**:
- Shows list of all restaurant meals
- Has "Add Meal" floating button
- Displays stats cards
- Has bottom navigation

✅ **Add Meal**:
- Form includes all required fields
- Image upload works
- Validation prevents invalid data
- Success message appears
- Navigates back to dashboard

✅ **Edit Meal**:
- Pre-fills existing data
- Allows updates
- Image can be replaced
- Saves changes correctly

✅ **Delete Meal**:
- Confirmation dialog appears
- Deletes from database
- Removes image from storage
- Updates dashboard list

✅ **Navigation**:
- Bottom nav works on all screens
- Routes are correct
- Back navigation works

---

## 📝 NEXT STEPS

1. **Deploy storage bucket** (meal-images-bucket-setup.sql)
2. **Create screen files** (follow file structure)
3. **Implement image upload** (use code examples)
4. **Update router** (add new routes)
5. **Test complete flow** (use checklist)
6. **Deploy to production**

---

## 🆘 TROUBLESHOOTING

### Image Upload Fails

**Check**:
- Bucket exists: `SELECT * FROM storage.buckets WHERE id = 'meal-images'`
- Policies exist: Check storage policies in Supabase dashboard
- User is authenticated
- File size < 5MB
- File type is JPEG/PNG/WebP

### Meals Not Showing

**Check**:
- Restaurant ID is correct
- Query filters by correct restaurant_id
- RLS policies allow reading
- Data exists in database

### Navigation Not Working

**Check**:
- Routes are defined in app_router.dart
- Route names match navigation calls
- Context is available for navigation

---

**Implementation Time**: ~4-6 hours  
**Difficulty**: Medium  
**Priority**: HIGH

