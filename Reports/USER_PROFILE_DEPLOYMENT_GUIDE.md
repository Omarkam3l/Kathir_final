# 🎨 User Profile Screen Redesign - Deployment Guide

## 📋 Overview

Complete redesign of the user profile screen with:
- ✅ New modern UI matching the design from Kathir_app/user_profile_page
- ✅ Profile image upload to Supabase Storage
- ✅ Address management (add, edit, delete up to 3 addresses)
- ✅ Profile stats (orders count, food saved)
- ✅ Edit profile functionality
- ✅ Using app colors (green primary theme)

---

## 🚀 Deployment Steps

### Step 1: Deploy Storage Bucket SQL (5 minutes)

1. Open **Supabase Dashboard** → **SQL Editor**
2. Open file: `migrations/profile-images-bucket-setup.sql`
3. Copy **ALL** contents
4. Paste into SQL Editor
5. Click **"Run"**
6. Wait for ✅ Success message

**This creates**:
- `profile-images` storage bucket (public, 5MB limit)
- 4 storage policies (view, upload, update, delete)
- 4 user_addresses RLS policies
- Verifies avatar_url column exists in profiles table

---

### Step 2: Update App Router (2 minutes)

Add the new profile screen route to your app router.

**File**: `lib/features/_shared/router/app_router.dart`

Find the profile routes section and add:

```dart
GoRoute(
  path: UserProfileScreenNew.routeName,
  name: 'user-profile-new',
  builder: (context, state) => const UserProfileScreenNew(),
),
GoRoute(
  path: AddressesScreen.routeName,
  name: 'addresses',
  builder: (context, state) => const AddressesScreen(),
),
```

---

### Step 3: Update Navigation (1 minute)

Update your bottom navigation or wherever you navigate to the profile screen.

**Change from**:
```dart
Navigator.pushNamed(context, UserProfileScreen.routeName);
// or
context.go(UserProfileScreen.routeName);
```

**Change to**:
```dart
Navigator.pushNamed(context, UserProfileScreenNew.routeName);
// or
context.go(UserProfileScreenNew.routeName);
```

---

### Step 4: Restart App (1 minute)

```bash
flutter run
```

---

## ✅ What's Included

### New Files Created:

1. **lib/features/profile/presentation/screens/user_profile_screen_new.dart**
   - Complete redesigned profile screen
   - Profile image upload
   - Profile stats (orders, food saved)
   - Edit profile dialog
   - Account settings section
   - Security & app section
   - Logout functionality

2. **lib/features/profile/presentation/screens/addresses_screen.dart**
   - Full address management
   - Add up to 3 addresses
   - Edit existing addresses
   - Delete addresses
   - Set default address
   - Beautiful UI with cards

3. **migrations/profile-images-bucket-setup.sql**
   - Storage bucket setup
   - Storage policies
   - User addresses RLS policies

### Updated Files:

1. **lib/features/authentication/presentation/blocs/auth_provider.dart**
   - Added `avatarUrl` to `AuthUserView`
   - Added `refreshUser()` method
   - Updated `user` getter to include avatar_url

---

## 🎨 Features

### Profile Image Upload
- Click edit button on profile picture
- Select image from gallery
- Automatic resize to 512x512
- Upload to Supabase Storage
- Public URL stored in database
- Max 5MB, JPEG/PNG/WebP only

### Address Management
- Add up to 3 addresses
- Each address has a label (Home, Work, etc.)
- Set one as default
- Edit any address
- Delete addresses
- Beautiful card UI

### Profile Stats
- Total orders count (from orders table)
- Food saved calculation (0.5kg per order)
- Real-time updates

### Edit Profile
- Edit name
- Edit phone number
- Email is read-only
- Validation included

### Account Settings
- My Orders - View order history
- Addresses - Manage delivery addresses
- Payment Methods - Coming soon

### Security & App
- Change Password - Coming soon
- Notifications toggle
- Help & Support - Coming soon

---

## 📊 Database Schema

### profiles table (already exists):
```sql
- id (uuid, PK)
- email (text)
- full_name (text)
- phone_number (text)
- avatar_url (text) ← Used for profile image
- role (text)
- is_verified (boolean)
- approval_status (text)
- created_at (timestamp)
- updated_at (timestamp)
```

### user_addresses table (already exists):
```sql
- id (uuid, PK)
- user_id (uuid, FK → profiles.id)
- label (text) ← e.g., "Home", "Work"
- address_text (text) ← Full address
- location_lat (double precision)
- location_long (double precision)
- is_default (boolean) ← One address can be default
```

### Storage bucket:
```
profile-images/
  {user_id}/
    profile.jpg ← User's profile image
```

---

## 🔍 How It Works

### Profile Image Upload Flow:

1. User clicks edit button on profile picture
2. Image picker opens (gallery only)
3. Image is resized to 512x512, quality 85%
4. File is uploaded to `profile-images/{user_id}/profile.{ext}`
5. Public URL is generated
6. URL is saved to `profiles.avatar_url`
7. Auth provider refreshes user data
8. UI updates automatically

### Address Management Flow:

1. User clicks "Addresses" in account settings
2. Loads addresses from `user_addresses` table
3. Can add new address (up to 3 max)
4. Can edit existing address
5. Can delete address
6. Can set one as default
7. All operations use RLS policies for security

---

## 🔒 Security (RLS Policies)

### Storage Policies:
- ✅ Public can view profile images (public bucket)
- ✅ Users can upload to their own folder only
- ✅ Users can update their own images only
- ✅ Users can delete their own images only

### User Addresses Policies:
- ✅ Users can view their own addresses
- ✅ Users can insert their own addresses
- ✅ Users can update their own addresses
- ✅ Users can delete their own addresses

---

## 🎨 Design Colors

Using `AppColors` from `lib/core/utils/app_colors.dart`:

- **Primary**: `AppColors.primary` (Green #2E7D32)
- **Background**: `AppColors.backgroundLight` (#F0F0F0)
- **Surface**: `AppColors.white` (#FFFFFF)
- **Text**: Black for titles, Grey for subtitles
- **Error**: Red for logout and delete actions

---

## 🧪 Testing Checklist

### Profile Image:
- [ ] Click edit button on profile picture
- [ ] Select image from gallery
- [ ] Image uploads successfully
- [ ] Profile picture updates in UI
- [ ] Image persists after app restart

### Profile Edit:
- [ ] Click "Edit Profile" button
- [ ] Change name
- [ ] Change phone number
- [ ] Save changes
- [ ] Changes reflect in UI

### Addresses:
- [ ] Click "Addresses" in account settings
- [ ] Add first address (becomes default)
- [ ] Add second address
- [ ] Add third address
- [ ] Try to add 4th address (should show max limit message)
- [ ] Edit an address
- [ ] Set different address as default
- [ ] Delete an address
- [ ] All changes persist after app restart

### Stats:
- [ ] Orders count shows correct number
- [ ] Food saved calculation is correct
- [ ] Stats update after placing new order

### Navigation:
- [ ] Back button works
- [ ] Navigate to My Orders
- [ ] Navigate to Addresses
- [ ] Logout works correctly

---

## 🆘 Troubleshooting

### Problem: Image upload fails
**Solution**:
1. Check if storage bucket was created: `SELECT * FROM storage.buckets WHERE id = 'profile-images';`
2. Check storage policies exist
3. Verify user is authenticated
4. Check image size < 5MB
5. Check image format (JPEG/PNG/WebP only)

### Problem: Addresses not loading
**Solution**:
1. Check RLS policies: `SELECT * FROM pg_policies WHERE tablename = 'user_addresses';`
2. Verify user is authenticated
3. Check console logs for errors
4. Re-run the SQL file

### Problem: Can't add more than 3 addresses
**Solution**: This is by design! Maximum 3 addresses allowed.

### Problem: Avatar not showing
**Solution**:
1. Check if avatar_url is in database: `SELECT avatar_url FROM profiles WHERE id = 'YOUR_USER_ID';`
2. Check if URL is accessible (public bucket)
3. Check network connection
4. Try re-uploading image

---

## 📝 API Reference

### Supabase Storage Upload:
```dart
await _supabase.storage
    .from('profile-images')
    .upload(
      '$userId/profile.$fileExt',
      file,
      fileOptions: const FileOptions(upsert: true),
    );
```

### Get Public URL:
```dart
final imageUrl = _supabase.storage
    .from('profile-images')
    .getPublicUrl('$userId/profile.$fileExt');
```

### Update Profile:
```dart
await _supabase
    .from('profiles')
    .update({'avatar_url': imageUrl})
    .eq('id', userId);
```

### Address Operations:
```dart
// Load addresses
final addresses = await _supabase
    .from('user_addresses')
    .select()
    .eq('user_id', userId);

// Add address
await _supabase.from('user_addresses').insert({
  'user_id': userId,
  'label': 'Home',
  'address_text': '123 Main St',
  'is_default': true,
});

// Update address
await _supabase
    .from('user_addresses')
    .update({'label': 'Work'})
    .eq('id', addressId);

// Delete address
await _supabase
    .from('user_addresses')
    .delete()
    .eq('id', addressId);
```

---

## 🎉 Summary

**What's Done**:
- ✅ Complete UI redesign matching design specs
- ✅ Profile image upload with Supabase Storage
- ✅ Address management (CRUD operations)
- ✅ Profile editing
- ✅ Stats display
- ✅ All RLS policies
- ✅ Beautiful modern UI

**Time to Deploy**: ~10 minutes
**Difficulty**: Easy (just run SQL and update routes)
**Impact**: Complete profile management system!

---

**Deploy the SQL file now and enjoy your new profile screen!** 🚀

**Questions?** Check the troubleshooting section or review the code comments.
