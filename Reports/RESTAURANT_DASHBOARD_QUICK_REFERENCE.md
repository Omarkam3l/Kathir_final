# ⚡ RESTAURANT DASHBOARD - QUICK REFERENCE

## 📦 WHAT YOU NEED TO DO

### 1. Deploy Storage Bucket (2 minutes)
```bash
File: meal-images-bucket-setup.sql
Action: Run in Supabase SQL Editor
Result: Creates 'meal-images' bucket with policies
```

### 2. Update Dashboard Screen (30 minutes)
- Remove form from dashboard
- Add meals list/grid
- Add "Add Meal" floating button
- Add bottom navigation bar

### 3. Create Add Meal Screen (1 hour)
- Image upload widget
- Form with all required fields
- Validation
- Save to database

### 4. Create Supporting Screens (1 hour)
- Edit Meal Screen
- Meal Details Screen
- Meal Card Widget

### 5. Update Router (15 minutes)
- Add new routes
- Configure navigation

---

## 🗄️ DATABASE FIELDS (Required)

```dart
// All fields needed in Add Meal form:
{
  'title': String,              // Required, 3-100 chars
  'description': String,        // Optional, max 500 chars
  'category': String,           // Required, dropdown
  'image_url': String,          // Required, from upload
  'original_price': double,     // Required, > 0
  'discounted_price': double,   // Required, > 0, <= original
  'quantity_available': int,    // Required, >= 1
  'expiry_date': DateTime,      // Required, future date
  'pickup_deadline': DateTime?, // Optional
  'restaurant_id': String,      // Auto (current user)
}
```

---

## 📦 STORAGE BUCKET DETAILS

**Bucket Name**: `meal-images`  
**Public**: Yes (images viewable by anyone)  
**Max Size**: 5MB per file  
**Allowed Types**: JPEG, PNG, WebP  
**Path Format**: `meal-images/{restaurant_id}/{meal_id}_{timestamp}.jpg`

**Example URL**:
```
https://your-project.supabase.co/storage/v1/object/public/meal-images/abc-123/meal-456_1706543210.jpg
```

---

## 🎨 SCREEN STRUCTURE

### Dashboard (Main)
```
┌─────────────────────────────┐
│ Header (Restaurant Info)    │
├─────────────────────────────┤
│ Stats Cards                 │
│ [Active] [Sales] [Rating]   │
├─────────────────────────────┤
│ Meals Grid/List             │
│ ┌────┐ ┌────┐ ┌────┐       │
│ │Meal│ │Meal│ │Meal│       │
│ └────┘ └────┘ └────┘       │
│                             │
│         [+ Add Meal] FAB    │
├─────────────────────────────┤
│ Bottom Navigation Bar       │
│ [Home][Meals][Orders][Me]   │
└─────────────────────────────┘
```

### Add Meal Screen
```
┌─────────────────────────────┐
│ [←] Add New Meal            │
├─────────────────────────────┤
│ [Image Upload Area]         │
│ [+ Add Photo]               │
├─────────────────────────────┤
│ Title: [____________]       │
│ Description: [_______]      │
│ Category: [Dropdown ▼]      │
│ Original Price: [____]      │
│ Discounted Price: [__]      │
│ Quantity: [- 5 +]           │
│ Expiry Date: [📅]           │
│ Pickup Deadline: [📅]       │
├─────────────────────────────┤
│ [Publish Meal] Button       │
└─────────────────────────────┘
```

---

## 🧭 NAVIGATION FLOW

```
Dashboard
  ├─→ Add Meal Screen → Save → Back to Dashboard
  ├─→ Meal Details → Edit → Edit Screen → Save → Back
  ├─→ Meal Details → Delete → Confirm → Back to Dashboard
  └─→ Bottom Nav → [Home|Meals|Orders|Profile]
```

---

## 📝 CATEGORY OPTIONS

```dart
const categories = [
  'Meals',
  'Bakery',
  'Meat & Poultry',
  'Seafood',
  'Vegetables',
  'Desserts',
  'Groceries',
];
```

---

## 🔧 KEY CODE SNIPPETS

### Upload Image
```dart
final path = '$restaurantId/${mealId}_${timestamp}.jpg';
await Supabase.instance.client.storage
    .from('meal-images')
    .upload(path, imageFile);
    
final url = Supabase.instance.client.storage
    .from('meal-images')
    .getPublicUrl(path);
```

### Save Meal
```dart
await Supabase.instance.client.from('meals').insert({
  'restaurant_id': restaurantId,
  'title': title,
  'image_url': imageUrl,
  'original_price': originalPrice,
  'discounted_price': discountedPrice,
  'quantity_available': quantity,
  'expiry_date': expiryDate.toIso8601String(),
  // ... other fields
});
```

### Get Meals List
```dart
final meals = await Supabase.instance.client
    .from('meals')
    .select()
    .eq('restaurant_id', restaurantId)
    .order('created_at', ascending: false);
```

---

## ✅ VALIDATION RULES

| Field | Rule |
|-------|------|
| Title | Required, 3-100 chars |
| Description | Optional, max 500 chars |
| Category | Required, from list |
| Image | Required, max 5MB, JPEG/PNG/WebP |
| Original Price | Required, > 0 |
| Discounted Price | Required, > 0, <= original |
| Quantity | Required, >= 1 |
| Expiry Date | Required, future date |
| Pickup Deadline | Optional, < expiry date |

---

## 🎯 TESTING CHECKLIST

Quick test flow:
1. ✅ Deploy storage bucket
2. ✅ Open dashboard → See meals list
3. ✅ Click "Add Meal" → Form opens
4. ✅ Upload image → Shows preview
5. ✅ Fill form → Validation works
6. ✅ Click "Publish" → Saves successfully
7. ✅ Back to dashboard → New meal appears
8. ✅ Click meal → Details show
9. ✅ Edit meal → Updates work
10. ✅ Delete meal → Removes correctly
11. ✅ Bottom nav → All tabs work

---

## 📚 DOCUMENTATION FILES

1. **RESTAURANT_DASHBOARD_REDESIGN.md** - Complete specification
2. **RESTAURANT_DASHBOARD_IMPLEMENTATION_GUIDE.md** - Step-by-step guide
3. **meal-images-bucket-setup.sql** - Storage bucket SQL
4. **RESTAURANT_DASHBOARD_QUICK_REFERENCE.md** - This file

---

## 🚀 QUICK START

```bash
# 1. Deploy storage
Run: meal-images-bucket-setup.sql in Supabase

# 2. Create files
- restaurant_dashboard_screen.dart (update)
- add_meal_screen.dart (new)
- meal_card.dart (new)
- image_upload_widget.dart (new)
- restaurant_bottom_nav.dart (new)

# 3. Update router
Add routes for add-meal, edit-meal, meal-details

# 4. Test
Follow testing checklist above
```

---

**Time to Implement**: 4-6 hours  
**Difficulty**: Medium  
**Files to Create**: 5 new files  
**Files to Update**: 2 files (dashboard, router)

