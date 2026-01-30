# 🗄️ DATABASE SCHEMA REFERENCE

## 📊 COMPLETE SCHEMA

### auth.users (Supabase Auth Table)
```sql
-- Managed by Supabase Auth
id uuid PRIMARY KEY
email text UNIQUE
encrypted_password text
email_confirmed_at timestamptz
raw_user_meta_data jsonb  -- Contains: role, full_name, organization_name, phone_number
created_at timestamptz
updated_at timestamptz
```

### public.profiles
```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('user', 'restaurant', 'ngo', 'admin')),
  email text UNIQUE NOT NULL,
  full_name text,
  phone_number text,
  avatar_url text,
  is_verified boolean DEFAULT false,
  approval_status text DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_approval_status ON profiles(approval_status);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role_approval ON profiles(role, approval_status);
```

### public.restaurants
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

### public.ngos
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

### storage.buckets
```sql
-- legal-docs bucket
{
  id: 'legal-docs',
  name: 'legal-docs',
  public: false,
  file_size_limit: 10485760,  -- 10MB
  allowed_mime_types: ['application/pdf', 'image/jpeg', 'image/png']
}
```

---

## 🔧 TRIGGER FUNCTION

### handle_new_user()
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $
DECLARE
  user_role text;
  user_full_name text;
  user_phone text;
  org_name text;
  final_org_name text;
BEGIN
  -- Extract metadata
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User');
  user_phone := NEW.raw_user_meta_data->>'phone_number';
  org_name := NEW.raw_user_meta_data->>'organization_name';
  
  -- Create profile (CRITICAL - must succeed)
  INSERT INTO public.profiles (
    id, email, role, full_name, phone_number,
    is_verified, approval_status
  ) VALUES (
    NEW.id, NEW.email, user_role, user_full_name, user_phone,
    CASE WHEN user_role = 'user' THEN true ELSE false END,
    CASE WHEN user_role IN ('restaurant', 'ngo') THEN 'pending' ELSE 'approved' END
  );
  
  -- Create restaurant record (NON-CRITICAL)
  IF user_role = 'restaurant' THEN
    INSERT INTO public.restaurants (profile_id, restaurant_name)
    VALUES (NEW.id, COALESCE(org_name, 'Restaurant ' || SUBSTRING(NEW.id::text, 1, 8)));
  END IF;
  
  -- Create NGO record (NON-CRITICAL)
  IF user_role = 'ngo' THEN
    INSERT INTO public.ngos (profile_id, organization_name)
    VALUES (NEW.id, COALESCE(org_name, 'Organization ' || SUBSTRING(NEW.id::text, 1, 8)));
  END IF;
  
  RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
```

---

## 🔐 RPC FUNCTIONS

### append_restaurant_legal_doc()
```sql
CREATE OR REPLACE FUNCTION public.append_restaurant_legal_doc(p_url text)
RETURNS jsonb AS $
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
BEGIN
  v_profile_id := auth.uid();
  
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  UPDATE public.restaurants
  SET legal_docs_urls = array_append(COALESCE(legal_docs_urls, ARRAY[]::text[]), p_url)
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;
  
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'legal_docs_urls', v_updated_urls
  );
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

### append_ngo_legal_doc()
```sql
CREATE OR REPLACE FUNCTION public.append_ngo_legal_doc(p_url text)
RETURNS jsonb AS $
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
BEGIN
  v_profile_id := auth.uid();
  
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  UPDATE public.ngos
  SET legal_docs_urls = array_append(COALESCE(legal_docs_urls, ARRAY[]::text[]), p_url)
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;
  
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'legal_docs_urls', v_updated_urls
  );
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔒 RLS POLICIES

### Profiles Table
```sql
-- Users view own
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users update own (except approval_status)
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    approval_status = (SELECT approval_status FROM profiles WHERE id = auth.uid())
  );

-- Admins view all
CREATE POLICY "Admin can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    (auth.jwt()->>'role')::text = 'admin' OR
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Admins update approval_status
CREATE POLICY "Admin can update approval status"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    (auth.jwt()->>'role')::text = 'admin' OR
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );
```

### Restaurants Table
```sql
-- Owners view own
CREATE POLICY "Restaurant owners can view own record"
  ON restaurants FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Owners update own
CREATE POLICY "Restaurant owners can update own record"
  ON restaurants FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id);

-- Public view approved
CREATE POLICY "Public can view approved restaurants"
  ON restaurants FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = restaurants.profile_id
        AND profiles.approval_status = 'approved'
    )
  );
```

### Storage (legal-docs bucket)
```sql
-- Upload to own folder
CREATE POLICY "Authenticated users can upload to own folder"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'legal-docs' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- View own files
CREATE POLICY "Users can view own legal docs"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-docs' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Admins view all
CREATE POLICY "Admins can view all legal docs"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-docs' AND
    (
      (auth.jwt()->>'role')::text = 'admin' OR
      auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    )
  );
```

---

## 📊 USEFUL QUERIES

### Get user with all details
```sql
SELECT 
  p.*,
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
WHERE p.email = 'user@example.com';
```

### Get pending approvals count
```sql
SELECT COUNT(*) 
FROM profiles 
WHERE role IN ('restaurant', 'ngo') 
  AND approval_status = 'pending';
```

### Get users without documents
```sql
SELECT p.email, p.role
FROM profiles p
LEFT JOIN restaurants r ON r.profile_id = p.id
LEFT JOIN ngos n ON n.profile_id = p.id
WHERE p.role IN ('restaurant', 'ngo')
  AND (
    (p.role = 'restaurant' AND (r.legal_docs_urls IS NULL OR r.legal_docs_urls = ARRAY[]::text[]))
    OR
    (p.role = 'ngo' AND (n.legal_docs_urls IS NULL OR n.legal_docs_urls = ARRAY[]::text[]))
  );
```

