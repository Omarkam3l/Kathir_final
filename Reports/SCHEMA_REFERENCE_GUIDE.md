# 📚 Complete Schema Reference Guide

## 📄 File: `migrations/COMPLETE_SCHEMA_REFERENCE.sql`

This file contains the **complete, final database schema** for the Kathir app.

---

## 📊 What's Included

### Tables (13 total)
1. **profiles** - User profiles (users, restaurants, NGOs, admins)
2. **restaurants** - Restaurant-specific data
3. **ngos** - NGO-specific data
4. **meals** - Meal listings with all fields
5. **orders** - Order records
6. **order_items** - Items in each order
7. **payments** - Payment transactions
8. **rush_hours** - Restaurant rush hour settings
9. **user_addresses** - User delivery addresses
10. **favorites** - User favorite meals
11. **cart_items** - Shopping cart items
12. **backup_profiles_role** - Backup table

### Meals Table Columns (Complete)
```sql
-- Core columns (from your schema)
id, restaurant_id, title, description, category,
image_url, original_price, discounted_price,
quantity_available, expiry_date, pickup_deadline,
embedding, created_at, updated_at

-- Additional columns (for app functionality)
status, location, unit, fulfillment_method,
is_donation_available, ingredients, allergens,
co2_savings, pickup_time
```

### RLS Policies (40+ total)
- **Profiles**: 3 policies
- **Restaurants**: 3 policies
- **NGOs**: 3 policies
- **Meals**: 6 policies
- **Orders**: 6 policies
- **Order_items**: 3 policies
- **Favorites**: 3 policies
- **Cart_items**: 4 policies
- **User_addresses**: 4 policies
- **Storage**: 4 policies

### Indexes (10+ total)
- Profile indexes (role, approval_status, email)
- Meal indexes (restaurant_id, status, expiry_date, created_at)
- Order indexes (user_id, restaurant_id)

### Constraints (20+ total)
- Primary keys
- Foreign keys
- Check constraints (status, category, role, etc.)
- Unique constraints

### Storage Buckets
- **meal-images** - For meal photos (5MB max, public read)

### Views
- **meals_with_restaurant** - Meals joined with restaurant info

---

## 🎯 Use Cases

### 1. As Reference
Use this file to understand the complete database structure:
- All tables and their relationships
- All columns and their types
- All constraints and validations
- All RLS policies

### 2. For New Deployments
Deploy this file to create the complete schema from scratch:
```bash
# In Supabase SQL Editor
# Copy and run COMPLETE_SCHEMA_REFERENCE.sql
```

### 3. For Documentation
Reference this file when:
- Writing queries
- Creating new features
- Debugging issues
- Onboarding new developers

### 4. For Comparison
Compare your current schema with this reference:
```sql
-- Check if all columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'meals'
ORDER BY ordinal_position;
```

---

## 📋 Key Features

### Meals Table
- **Categories**: Meals, Bakery, Meat & Poultry, Seafood, Vegetables, Desserts, Groceries
- **Status**: active, sold, expired
- **Units**: portions, kilograms, items, boxes
- **Fulfillment**: pickup, delivery
- **Extras**: ingredients, allergens, co2_savings

### Security
- Row-Level Security enabled on all tables
- Users can only access their own data
- Public can browse active meals
- Restaurants manage their own meals
- NGOs can view available meals

### Performance
- Indexes on frequently queried columns
- Optimized for fast meal browsing
- Efficient joins with restaurants table

---

## 🔍 Quick Queries

### Check Schema Version
```sql
SELECT 
  table_name,
  COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'public'
GROUP BY table_name
ORDER BY table_name;
```

### Check RLS Policies
```sql
SELECT 
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;
```

### Check Meals Columns
```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'meals'
ORDER BY ordinal_position;
```

### Check Active Meals
```sql
SELECT 
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active,
  COUNT(CASE WHEN status = 'sold' THEN 1 END) as sold,
  COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired
FROM meals;
```

---

## ⚠️ Important Notes

### 1. This is a Reference File
- **DO NOT** run this on an existing database (it will try to recreate everything)
- Use it as a reference for the complete schema
- Use specific migration files for updates

### 2. For New Databases
If starting fresh, you can run this file to create everything at once.

### 3. For Existing Databases
Use the specific migration files:
- `add-missing-columns.sql` - Adds missing columns
- `FINAL-fix-rls-policies.sql` - Creates RLS policies

### 4. Column Naming
The schema uses the actual column names from your database:
- `discounted_price` (not `donation_price`)
- `quantity_available` (not `quantity`)
- `expiry_date` (not `expiry`)
- `restaurant_name` (not `name`)

---

## 📚 Related Files

### Migration Files
1. `add-missing-columns.sql` - Adds missing columns to existing schema
2. `FINAL-fix-rls-policies.sql` - Creates all RLS policies
3. `meal-images-bucket-setup.sql` - Sets up storage bucket

### Documentation
1. `FINAL_DEPLOYMENT_GUIDE.md` - Complete deployment guide
2. `ACTUAL_SCHEMA_ANALYSIS.md` - Schema analysis
3. `SCHEMA_REFERENCE_GUIDE.md` - This file

### Code Files
1. `home_remote_datasource.dart` - Updated to match schema
2. `add_meal_screen.dart` - Uses correct column names
3. `edit_meal_screen.dart` - Uses correct column names

---

## ✅ Schema Validation

To validate your database matches this schema:

```sql
-- 1. Check table count
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public';
-- Should return 13

-- 2. Check meals columns
SELECT COUNT(*) FROM information_schema.columns
WHERE table_name = 'meals';
-- Should return 22+

-- 3. Check RLS policies
SELECT COUNT(*) FROM pg_policies
WHERE schemaname = 'public';
-- Should return 40+

-- 4. Check constraints
SELECT COUNT(*) FROM pg_constraint
WHERE conrelid IN (
  SELECT oid FROM pg_class
  WHERE relnamespace = 'public'::regnamespace
);
-- Should return 20+
```

---

## 🎉 Summary

This reference file provides:
- ✅ Complete table definitions
- ✅ All columns with types and defaults
- ✅ All constraints and validations
- ✅ All indexes for performance
- ✅ All RLS policies for security
- ✅ Storage bucket configuration
- ✅ Helper views
- ✅ Proper relationships

**Use this as your single source of truth for the database schema!**

---

**File Location**: `migrations/COMPLETE_SCHEMA_REFERENCE.sql`  
**Last Updated**: January 30, 2026  
**Version**: 1.0 (Final)
