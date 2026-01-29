# 🍽️ RESTAURANT DASHBOARD REDESIGN - COMPLETE SPECIFICATION

## 📋 REQUIREMENTS

1. ✅ List all meals that the restaurant added in a section
2. ✅ Move the form to publish meal to a separate view
3. ✅ Add "Add Meal" button that navigates to form view
4. ✅ Check all required database fields are included in form
5. ✅ Ensure photo upload stores URL in Supabase bucket
6. ✅ Add bottom navigation bar
7. ✅ Complete flow implementation

---

## 🗄️ DATABASE SCHEMA

### Meals Table (Current)
```sql
CREATE TABLE public.meals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid REFERENCES restaurants(profile_id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  category text CHECK (category IN ('Meals', 'Bakery', 'Meat & Poultry', 'Seafood', 'Vegetables', 'Desserts', 'Groceries')),
  image_url text,
  original_price decimal(12,2) NOT NULL,
  discounted_price decimal(12,2) NOT NULL,
  quantity_available int NOT NULL DEFAULT 0,
  expiry_date timestamptz NOT NULL,
  pickup_deadline timestamptz,
  created_at timestamptz DEFAULT now()
);
```

### Required Fields for Form:
- ✅ title (text, required)
- ✅ description (text, optional)
- ✅ category (dropdown, required)
- ✅ image_url (from upload, required)
- ✅ original_price (decimal, required)
- ✅ discounted_price (decimal, required)
- ✅ quantity_available (int, required)
- ✅ expiry_date (datetime, required)
- ✅ pickup_deadline (datetime, optional)

---

## 📦 STORAGE BUCKET CONFIGURATION

### Bucket Name: `meal-images`

**Configuration**:
```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'meal-images',
  'meal-images',
  true,  -- Public bucket for meal images
  5242880,  -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']::text[]
);
```

**Storage Policies**:
```sql
-- Allow authenticated users to upload
CREATE POLICY "Restaurant can upload meal images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'meal-images' AND
    auth.uid() IN (SELECT profile_id FROM restaurants)
  );

-- Allow public to view
CREATE POLICY "Anyone can view meal images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'meal-images');

-- Allow restaurant to update own images
CREATE POLICY "Restaurant can update own meal images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'meal-images')
  WITH CHECK (bucket_id = 'meal-images');

-- Allow restaurant to delete own images
CREATE POLICY "Restaurant can delete own meal images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'meal-images');
```

**File Path Structure**:
```
meal-images/
  └── {restaurant_id}/
      └── {meal_id}_{timestamp}.jpg
```

**Example**:
```
meal-images/abc-123-def/meal-456_1706543210.jpg
```

---

## 🎨 NEW SCREEN STRUCTURE

### 1. Restaurant Dashboard (Main Screen)
**Route**: `/restaurant-dashboard`

**Sections**:
- Header with restaurant info
- Stats cards (Active Meals, Total Sales, Rating)
- Meals list (grid/list view)
- Floating "Add Meal" button
- Bottom navigation bar

### 2. Add/Edit Meal Screen
**Route**: `/restaurant-dashboard/add-meal` or `/restaurant-dashboard/edit-meal/:id`

**Sections**:
- Back button
- Form with all required fields
- Image upload section
- Save/Publish button

### 3. Meal Details Screen (Optional)
**Route**: `/restaurant-dashboard/meal/:id`

**Sections**:
- Meal image
- Details
- Edit/Delete buttons
- Status toggle (active/inactive)

---

## 🧭 BOTTOM NAVIGATION BAR

**Tabs**:
1. **Home** (Dashboard) - Icon: `Icons.home`
2. **Meals** (Meals List) - Icon: `Icons.restaurant_menu`
3. **Orders** (Orders Management) - Icon: `Icons.receipt_long`
4. **Profile** (Restaurant Profile) - Icon: `Icons.person`

---

## 📱 SCREEN FLOWS

### Flow 1: Add New Meal
```
Dashboard → Click "Add Meal" FAB → 
Add Meal Screen → Fill form → Upload image → 
Click "Publish" → Success → Navigate back to Dashboard → 
Meal appears in list
```

### Flow 2: Edit Meal
```
Dashboard → Click meal card → 
Meal Details → Click "Edit" → 
Edit Meal Screen → Update fields → 
Click "Save" → Success → Navigate back
```

### Flow 3: Delete Meal
```
Dashboard → Click meal card → 
Meal Details → Click "Delete" → 
Confirm dialog → Delete → Navigate back
```

---

## 🔧 IMPLEMENTATION FILES

### Files to Create:
1. `restaurant_dashboard_screen.dart` - Main dashboard (redesigned)
2. `add_meal_screen.dart` - Add/Edit meal form
3. `meal_details_screen.dart` - Meal details view
4. `restaurant_bottom_nav.dart` - Bottom navigation widget
5. `meal_card_widget.dart` - Reusable meal card
6. `image_upload_widget.dart` - Image upload component

### Files to Update:
1. `app_router.dart` - Add new routes
2. `FINAL_SCHEMA.sql` - Add storage bucket and policies

---

## 📊 VALIDATION RULES

### Form Validation:
- **Title**: Required, min 3 characters, max 100 characters
- **Description**: Optional, max 500 characters
- **Category**: Required, must be from predefined list
- **Image**: Required, max 5MB, JPEG/PNG/WebP only
- **Original Price**: Required, > 0, max 2 decimal places
- **Discounted Price**: Required, > 0, <= original_price
- **Quantity**: Required, integer, >= 1
- **Expiry Date**: Required, must be future date
- **Pickup Deadline**: Optional, must be before expiry date

---

## 🎯 SUCCESS CRITERIA

After implementation:
- ✅ Dashboard shows list of all restaurant meals
- ✅ "Add Meal" button navigates to form screen
- ✅ Form includes all required database fields
- ✅ Image upload works and stores URL in Supabase
- ✅ Bottom navigation bar is functional
- ✅ Complete CRUD operations for meals
- ✅ Proper error handling and validation
- ✅ Loading states and feedback

---

## 📝 NEXT STEPS

1. Create storage bucket SQL migration
2. Implement new screen files
3. Update router with new routes
4. Test complete flow
5. Add error handling and logging

