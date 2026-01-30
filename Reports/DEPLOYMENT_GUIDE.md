# 🚀 Restaurant Dashboard Deployment Guide

## Quick Start (5 Minutes)

### Step 1: Install Dependencies (1 min)
```bash
flutter pub get
```

### Step 2: Deploy Storage Bucket (2 min)
1. Open Supabase Dashboard
2. Navigate to SQL Editor
3. Open `meal-images-bucket-setup.sql`
4. Copy all contents
5. Paste into SQL Editor
6. Click "Run"
7. Wait for success message

### Step 3: Verify Setup (1 min)
Run this query in Supabase SQL Editor:
```sql
SELECT * FROM storage.buckets WHERE id = 'meal-images';
```
Should return 1 row with bucket details.

### Step 4: Test the App (1 min)
```bash
flutter run
```

---

## Testing Flow

### 1. Login as Restaurant
- Use restaurant credentials
- Should auto-redirect to meals list

### 2. Add a Meal
1. Click floating "Add Meal" button
2. Upload an image (test with < 5MB JPEG/PNG)
3. Fill required fields:
   - Title: "Test Meal"
   - Category: Select any
   - Original Price: 10
   - Discounted Price: 5
   - Quantity: 10
   - Expiry Date: Tomorrow
4. Click "Publish Meal"
5. Should see success message
6. Should redirect to meals list
7. Verify meal appears in grid

### 3. View Meal Details
1. Click on the meal card
2. Should see full details
3. Verify image displays
4. Check all fields are correct

### 4. Edit Meal
1. Click edit button (top right)
2. Modify title to "Updated Test Meal"
3. Click "Save Changes"
4. Should see success message
5. Verify changes in details screen

### 5. Delete Meal
1. Click delete button (top right)
2. Confirm deletion
3. Should redirect to meals list
4. Verify meal is removed

---

## Verification Queries

### Check Meals
```sql
SELECT 
  id,
  title,
  category,
  original_price,
  discounted_price,
  quantity_available,
  image_url,
  status,
  created_at
FROM meals
WHERE restaurant_id = 'YOUR_RESTAURANT_ID'
ORDER BY created_at DESC;
```

### Check Images
```sql
SELECT 
  name,
  bucket_id,
  owner,
  created_at,
  metadata->>'size' as size_bytes
FROM storage.objects
WHERE bucket_id = 'meal-images'
ORDER BY created_at DESC;
```

### Check Bucket Policies
```sql
SELECT * FROM storage.policies WHERE bucket_id = 'meal-images';
```

---

## Common Issues & Solutions

### Issue: "Bucket not found"
**Solution**: Deploy `meal-images-bucket-setup.sql` in Supabase SQL Editor

### Issue: "Image upload fails"
**Checks**:
- File size < 5MB
- File type is JPEG, PNG, or WebP
- User is authenticated
- Bucket policies are correct

### Issue: "Meal not appearing in list"
**Checks**:
- Check console logs for errors
- Verify restaurant_id is correct
- Run verification query above
- Try pull-to-refresh

### Issue: "Navigation not working"
**Checks**:
- Verify routes in `app_router.dart`
- Check screen imports
- Restart app

---

## File Locations

### Screens
```
lib/features/restaurant_dashboard/presentation/screens/
├── meals_list_screen.dart
├── add_meal_screen.dart
├── meal_details_screen.dart
├── edit_meal_screen.dart
└── restaurant_dashboard_screen.dart
```

### Widgets
```
lib/features/restaurant_dashboard/presentation/widgets/
├── meal_card.dart
├── restaurant_bottom_nav.dart
└── image_upload_widget.dart
```

### SQL
```
meal-images-bucket-setup.sql
```

### Router
```
lib/features/_shared/router/app_router.dart
```

---

## Production Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Storage bucket deployed
- [ ] Bucket policies verified
- [ ] All screens tested
- [ ] Image upload tested
- [ ] Form validation tested
- [ ] CRUD operations tested
- [ ] Navigation tested
- [ ] Dark mode tested
- [ ] Error handling tested
- [ ] Loading states verified
- [ ] Bottom navigation working
- [ ] Search functionality working
- [ ] Filter functionality working

---

## Support

If you encounter issues:
1. Check console logs
2. Verify Supabase connection
3. Check authentication status
4. Review error messages
5. Consult troubleshooting section in IMPLEMENTATION_STATUS.md

---

**Ready to Deploy!** 🎉
