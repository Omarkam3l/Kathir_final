# 📊 CURRENT AUTH & DATABASE STATE REPORT

## 🗄️ DATABASE SCHEMA

### 1. Profiles Table
```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text CHECK (role IN ('user', 'restaurant', 'ngo', 'admin')),
  email text UNIQUE,
  full_name text,
  phone_number text,
  avatar_url text,
  is_verified boolean DEFAULT false,
  approval_status text DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

**Key Fields**:
- `role`: 'user', 'restaurant', 'ngo', 'admin'
- `approval_status`: 'pending', 'approved', 'rejected'
- `is_verified`: Email verification status

### 2. Restaurants Table
```sql
CREATE TABLE public.restaurants (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  restaurant_name text DEFAULT 'Unnamed Restaurant',
  address_text text,
  legal_docs_urls text[] DEFAULT ARRAY[]::text[],
  rating numeric DEFAULT 0,
  min_order_price numeric DEFAULT 0,
  rush_hour_active boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

**Key Fields**:
- `legal_docs_urls`: Array of document URLs
- `restaurant_name`: Can be null, has default

### 3. NGOs Table
```sql
CREATE TABLE public.ngos (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  organization_name text DEFAULT 'Unnamed Organization',
  address_text text,
  legal_docs_urls text[] DEFAULT ARRAY[]::text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

**Key Fields**:
- `legal_docs_urls`: Array of document URLs
- `organization_name`: Can be null, has default

---

## 🔐 AUTHENTICATION WORKFLOW

### User Signup Flow
```
1. User fills form → role='user'
2. signUp() → Creates auth.users
3. Trigger creates profile with approval_status='approved'
4. OTP email sent
5. User verifies OTP
6. Redirect to /home
```

### Restaurant/NGO Signup Flow
```
1. User fills form → role='restaurant' or 'ngo'
2. User selects legal documents
3. signUp() → Creates auth.users with role in metadata
4. Trigger creates:
   - Profile with approval_status='pending'
   - Restaurant/NGO record with empty legal_docs_urls
5. OTP email sent
6. User verifies OTP
7. Upload legal documents to storage
8. Call RPC to append URL to legal_docs_urls
9. Redirect to /pending-approval screen
10. Admin reviews and approves/rejects
11. After approval → Redirect to dashboard
```

---

## 📋 CURRENT ISSUES & FIXES

### Issue #1: Role Mismatch ✅ FIXED
- **Was**: Sending 'rest' instead of 'restaurant'
- **Fixed**: Changed wireValue to 'restaurant'
- **Status**: Code updated, needs SQL migration

### Issue #2: Empty legal_docs_urls ✅ FIXED
- **Was**: Using .update() which overwrites array
- **Fixed**: Using RPC append functions
- **Status**: Code updated, needs SQL deployment

### Issue #3: Missing Restaurant Records ✅ FIXED
- **Was**: Trigger didn't recognize 'rest' role
- **Fixed**: Role mismatch resolved
- **Status**: Migration ready to create missing records

---

## 🚀 REQUIRED DEPLOYMENTS

### 1. Role Migration (CRITICAL)
**File**: `database-migrate-rest-to-restaurant.sql`
- Updates 'rest' → 'restaurant' in auth.users
- Updates 'rest' → 'restaurant' in profiles
- Creates missing restaurant records

### 2. RPC Functions (CRITICAL)
**File**: `database-fix-legal-docs-append.sql`
- Creates append_restaurant_legal_doc()
- Creates append_ngo_legal_doc()

### 3. Complete Auth Rebuild (if not deployed)
**File**: `database-FINAL-AUTH-REBUILD.sql`
- Complete trigger function
- All RLS policies
- Storage bucket setup

