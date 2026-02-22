# 📦 Profile Images Storage Bucket - Setup Guide

## 🎯 Overview

This guide shows you how to create the storage bucket for profile images **without needing admin SQL access**. We'll use the Supabase Dashboard UI instead!

---

## 🚀 Step-by-Step Setup (5 minutes)

### Step 1: Create Bucket via Dashboard (2 minutes)

1. **Open Supabase Dashboard**
   - Go to your project: https://supabase.com/dashboard/project/YOUR_PROJECT_ID

2. **Navigate to Storage**
   - Click on **"Storage"** in the left sidebar
   - You'll see the Storage page with existing buckets (if any)

3. **Click "New bucket"**
   - Look for the green **"New bucket"** button in the top right
   - Click it to open the create bucket form

4. **Fill in the Bucket Details**:
   ```
   Name: profile-images
   
   Public bucket: ✅ YES (check this box!)
   
   File size limit: 5242880
   (This is 5MB in bytes)
   
   Allowed MIME types:
   - image/jpeg
   - image/png
   - image/webp
   - image/jpg
   ```

5. **Create the Bucket**
   - Click the **"Create bucket"** button
   - Wait for confirmation ✅

---

### Step 2: Deploy SQL Policies (2 minutes)

Now that the bucket exists, we can create the security policies.

1. **Open SQL Editor**
   - In Supabase Dashboard, click **"SQL Editor"** in the left sidebar

2. **Copy the SQL File**
   - Open: `migrations/profile-images-bucket-setup-simple.sql`
   - Copy **ALL** contents (Ctrl+A, Ctrl+C)

3. **Paste and Run**
   - Paste into the SQL Editor
   - Click **"Run"** button
   - Wait for ✅ Success message

4. **Verify Success**
   - You should see success messages in the output
   - Check that 4 storage policies were created
   - Check that 4 user_addresses policies were created

---

### Step 3: Verify Setup (1 minute)

1. **Check Bucket**
   - Go back to **Storage** in dashboard
   - You should see **"profile-images"** bucket
   - Click on it to view (should be empty)

2. **Check Policies**
   - In the bucket view, click **"Policies"** tab
   - You should see 4 policies:
     - ✅ Public can view profile images
     - ✅ Users can upload their own profile images
     - ✅ Users can update their own profile images
     - ✅ Users can delete their own profile images

---

## ✅ What You Just Created

### Storage Bucket:
```
profile-images/
  - Public: YES (anyone can view)
  - Max size: 5MB per file
  - Allowed: JPEG, PNG, WebP images
  - Structure: {user_id}/profile.jpg
```

### Security Policies:
1. **View** - Anyone can view images (public bucket)
2. **Upload** - Users can only upload to their own folder
3. **Update** - Users can only update their own images
4. **Delete** - Users can only delete their own images

### Database:
- ✅ `profiles.avatar_url` column verified
- ✅ `user_addresses` table RLS policies created

---

## 🎨 How It Works

### Upload Flow:
```
User clicks edit button
  ↓
Select image from gallery
  ↓
Image resized to 512x512
  ↓
Upload to: profile-images/{user_id}/profile.jpg
  ↓
Get public URL
  ↓
Save URL to profiles.avatar_url
  ↓
Display in app
```

### Security:
- Each user has their own folder: `{user_id}/`
- Users can only access their own folder
- Public can view all images (for displaying in app)
- RLS policies enforce these rules

---

## 📊 Bucket Settings Explained

### Name: `profile-images`
- This is the bucket ID used in code
- Must match exactly in your Flutter code

### Public: YES
- Images are publicly accessible via URL
- Anyone can view, but only owners can upload/edit/delete
- Needed so other users can see profile pictures

### File Size Limit: 5242880 bytes (5MB)
- Prevents users from uploading huge files
- 5MB is plenty for profile pictures
- Images are resized to 512x512 anyway

### Allowed MIME Types:
- `image/jpeg` - JPEG images
- `image/png` - PNG images  
- `image/webp` - WebP images (modern format)
- `image/jpg` - Alternative JPEG extension

---

## 🔍 Verification Queries

After setup, you can run these in SQL Editor to verify:

### Check bucket exists:
```sql
SELECT * FROM storage.buckets WHERE id = 'profile-images';
```
Should return 1 row with your bucket details.

### Check storage policies:
```sql
SELECT policyname 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%profile images%';
```
Should return 4 policies.

### Check user_addresses policies:
```sql
SELECT policyname 
FROM pg_policies 
WHERE tablename = 'user_addresses';
```
Should return 4 policies.

---

## 🆘 Troubleshooting

### Problem: Can't create bucket
**Solution**: Make sure you're logged in as project owner or admin.

### Problem: SQL file fails with "bucket doesn't exist"
**Solution**: You must create the bucket via Dashboard FIRST, then run the SQL.

### Problem: Policies not created
**Solution**: 
1. Check if policies already exist (they might have been created before)
2. The SQL file drops existing policies first, so it's safe to re-run
3. Check the output messages for specific errors

### Problem: Upload fails in app
**Solution**:
1. Verify bucket is public: `SELECT public FROM storage.buckets WHERE id = 'profile-images';`
2. Check policies exist (see verification queries above)
3. Make sure user is authenticated
4. Check image size < 5MB
5. Check image format is JPEG/PNG/WebP

---

## 📝 Quick Reference

### Bucket Details:
- **ID**: `profile-images`
- **Public**: Yes
- **Max Size**: 5MB
- **Formats**: JPEG, PNG, WebP

### File Path Format:
```
{user_id}/profile.{ext}

Example:
123e4567-e89b-12d3-a456-426614174000/profile.jpg
```

### Public URL Format:
```
https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/profile-images/{user_id}/profile.jpg
```

---

## 🎉 You're Done!

Once you've completed these steps:
- ✅ Bucket is created and configured
- ✅ Security policies are in place
- ✅ Users can upload profile pictures
- ✅ Images are publicly accessible
- ✅ Everything is secure with RLS

Now you can use the profile screen and upload images! 🚀

---

## 📚 Next Steps

1. Update your app router (see USER_PROFILE_DEPLOYMENT_GUIDE.md)
2. Test image upload in the app
3. Test address management
4. Enjoy your new profile screen!

---

**Questions?** 
- Check the main deployment guide: `USER_PROFILE_DEPLOYMENT_GUIDE.md`
- Review the SQL file: `migrations/profile-images-bucket-setup-simple.sql`
- Test with the verification queries above
