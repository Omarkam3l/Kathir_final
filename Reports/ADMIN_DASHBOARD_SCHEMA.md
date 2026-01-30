# 🎛️ ADMIN DASHBOARD - DATABASE SCHEMA & QUERIES

## 📊 ADMIN DASHBOARD REQUIREMENTS

### What Admin Needs to See:

1. **Pending Approvals** (Restaurant/NGO)
2. **User Management** (All users)
3. **Document Review** (Legal docs)
4. **Approval Actions** (Approve/Reject)

---

## 🗄️ DATABASE QUERIES FOR ADMIN

### 1. Get All Pending Approvals

```sql
-- Restaurants pending approval
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.phone_number,
  p.role,
  p.approval_status,
  p.created_at,
  r.restaurant_name,
  r.address_text,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as docs_count
FROM profiles p
JOIN restaurants r ON r.profile_id = p.id
WHERE p.role = 'restaurant' 
  AND p.approval_status = 'pending'
ORDER BY p.created_at DESC;

-- NGOs pending approval
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.phone_number,
  p.role,
  p.approval_status,
  p.created_at,
  n.organization_name,
  n.address_text,
  n.legal_docs_urls,
  array_length(n.legal_docs_urls, 1) as docs_count
FROM profiles p
JOIN ngos n ON n.profile_id = p.id
WHERE p.role = 'ngo' 
  AND p.approval_status = 'pending'
ORDER BY p.created_at DESC;

-- Combined view
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.phone_number,
  p.role,
  p.approval_status,
  p.created_at,
  CASE 
    WHEN p.role = 'restaurant' THEN r.restaurant_name
    WHEN p.role = 'ngo' THEN n.organization_name
  END as organization_name,
  CASE 
    WHEN p.role = 'restaurant' THEN r.legal_docs_urls
    WHEN p.role = 'ngo' THEN n.legal_docs_urls
  END as legal_docs_urls
FROM profiles p
LEFT JOIN restaurants r ON r.profile_id = p.id
LEFT JOIN ngos n ON n.profile_id = p.id
WHERE p.role IN ('restaurant', 'ngo')
  AND p.approval_status = 'pending'
ORDER BY p.created_at DESC;
```

### 2. Get All Users (with filters)

```sql
-- All users
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.approval_status,
  p.is_verified,
  p.created_at,
  CASE 
    WHEN p.role = 'restaurant' THEN r.restaurant_name
    WHEN p.role = 'ngo' THEN n.organization_name
    ELSE NULL
  END as organization_name
FROM profiles p
LEFT JOIN restaurants r ON r.profile_id = p.id
LEFT JOIN ngos n ON n.profile_id = p.id
ORDER BY p.created_at DESC;

-- Filter by role
WHERE p.role = 'restaurant'

-- Filter by approval status
WHERE p.approval_status = 'pending'

-- Filter by verification status
WHERE p.is_verified = true

-- Search by email/name
WHERE p.email ILIKE '%search%' 
   OR p.full_name ILIKE '%search%'
```

### 3. Get User Details (for review)

```sql
-- Restaurant details
SELECT 
  p.*,
  r.restaurant_name,
  r.address_text,
  r.legal_docs_urls,
  r.rating,
  r.min_order_price,
  r.created_at as restaurant_created_at
FROM profiles p
JOIN restaurants r ON r.profile_id = p.id
WHERE p.id = 'USER_ID';

-- NGO details
SELECT 
  p.*,
  n.organization_name,
  n.address_text,
  n.legal_docs_urls,
  n.created_at as ngo_created_at
FROM profiles p
JOIN ngos n ON n.profile_id = p.id
WHERE p.id = 'USER_ID';
```

### 4. Approve User

```sql
UPDATE profiles 
SET 
  approval_status = 'approved',
  updated_at = NOW()
WHERE id = 'USER_ID'
  AND role IN ('restaurant', 'ngo');
```

### 5. Reject User

```sql
UPDATE profiles 
SET 
  approval_status = 'rejected',
  updated_at = NOW()
WHERE id = 'USER_ID'
  AND role IN ('restaurant', 'ngo');
```

### 6. Get Statistics

```sql
-- Dashboard stats
SELECT 
  COUNT(*) FILTER (WHERE role = 'user') as total_users,
  COUNT(*) FILTER (WHERE role = 'restaurant') as total_restaurants,
  COUNT(*) FILTER (WHERE role = 'ngo') as total_ngos,
  COUNT(*) FILTER (WHERE approval_status = 'pending') as pending_approvals,
  COUNT(*) FILTER (WHERE approval_status = 'approved') as approved,
  COUNT(*) FILTER (WHERE approval_status = 'rejected') as rejected,
  COUNT(*) FILTER (WHERE is_verified = true) as verified_users
FROM profiles;
```

---

## 🔒 RLS POLICIES FOR ADMIN

### Admin Identification

Admins are identified by:
1. `profiles.role = 'admin'`, OR
2. JWT claim: `auth.jwt()->>'role' = 'admin'`

### Required Policies

```sql
-- Admin can view all profiles
CREATE POLICY "Admin can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    OR (auth.jwt()->>'role')::text = 'admin'
  );

-- Admin can update approval_status
CREATE POLICY "Admin can update approval status"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    OR (auth.jwt()->>'role')::text = 'admin'
  )
  WITH CHECK (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    OR (auth.jwt()->>'role')::text = 'admin'
  );

-- Admin can view all restaurants
CREATE POLICY "Admin can view all restaurants"
  ON restaurants FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    OR (auth.jwt()->>'role')::text = 'admin'
  );

-- Admin can view all NGOs
CREATE POLICY "Admin can view all ngos"
  ON ngos FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    OR (auth.jwt()->>'role')::text = 'admin'
  );

-- Admin can view all legal docs
CREATE POLICY "Admin can view all legal docs"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-docs'
    AND (
      auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
      OR (auth.jwt()->>'role')::text = 'admin'
    )
  );
```

