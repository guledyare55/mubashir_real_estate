-- Safe Initialization (Preserves existing data)
-- DROP TABLE IF EXISTS ... CASCADE; -- Removed for safety/preservation

-- Create an ENUM type safely
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 1. Create the profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  phone text,
  avatar_url text,
  role user_role DEFAULT 'customer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create the properties table
CREATE TABLE IF NOT EXISTS public.properties (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  price NUMERIC NOT NULL,
  type TEXT NOT NULL,
  beds INTEGER DEFAULT 0,
  baths INTEGER DEFAULT 0,
  size NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'Available',
  main_image_url TEXT,
  gallery_urls TEXT[] DEFAULT '{}',
  video_url TEXT,
  lat NUMERIC,
  lng NUMERIC,
  owner_id UUID, -- Linked to owners table
  agent_id UUID, -- Linked to employees table
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure columns exist for older versions of the table
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS owner_id UUID;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS agent_id UUID;

-- 11. Owners Table
CREATE TABLE IF NOT EXISTS public.owners (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  bank_details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE owners ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public/Admins can manage owners." ON owners;
CREATE POLICY "Public/Admins can manage owners." ON owners FOR ALL USING (true); -- Simplified for admin use

-- 12. Employees/Staff Table
CREATE TABLE IF NOT EXISTS public.employees (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'Agent',
  salary NUMERIC DEFAULT 0,
  phone TEXT,
  email TEXT,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_pay_date TIMESTAMP WITH TIME ZONE
);

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public/Admins can manage employees." ON employees;
CREATE POLICY "Public/Admins can manage employees." ON employees FOR ALL USING (true);

-- 3. Create the inquiries table
CREATE TABLE IF NOT EXISTS public.inquiries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  customer_phone TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'New',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;

-- Helper Function to check if current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Profiles RLS Policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON profiles;
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile." ON profiles;
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- 6. Properties RLS Policies
DROP POLICY IF EXISTS "Public properties are viewable by everyone." ON properties;
CREATE POLICY "Public properties are viewable by everyone." ON properties FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert properties." ON properties;
CREATE POLICY "Authenticated users can insert properties." ON properties FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update properties." ON properties;
CREATE POLICY "Authenticated users can update properties." ON properties FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can delete properties." ON properties;
CREATE POLICY "Admins can delete properties." ON properties FOR DELETE USING (public.is_admin());

-- 7. Inquiries RLS Policies
DROP POLICY IF EXISTS "Public can embed inquiries." ON inquiries;
CREATE POLICY "Public can embed inquiries." ON inquiries FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can read inquiries." ON inquiries;
CREATE POLICY "Admins can read inquiries." ON inquiries FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update inquiries." ON inquiries;
CREATE POLICY "Admins can update inquiries." ON inquiries FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete inquiries." ON inquiries;
CREATE POLICY "Admins can delete inquiries." ON inquiries FOR DELETE USING (public.is_admin());

-- 8. Trigger function: Auto-create Profile row when User completes Auth sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, avatar_url, role)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'avatar_url',
    'customer'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 9. User Favorites (Save for later)
CREATE TABLE IF NOT EXISTS public.user_favorites (
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, property_id)
);

ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own favorites." ON user_favorites;
CREATE POLICY "Users can manage their own favorites." 
ON user_favorites FOR ALL 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- 10. Agency Settings (Global Configuration)
CREATE TABLE IF NOT EXISTS public.agency_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1), -- Enforce single row
  name TEXT DEFAULT 'Mubashir Real Estate',
  logo_url TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  currency_symbol TEXT DEFAULT '$',
  support_phone TEXT,
  default_commission_rate NUMERIC DEFAULT 10.0,
  is_maintenance_mode BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure column exists for older versions
ALTER TABLE public.agency_settings ADD COLUMN IF NOT EXISTS default_commission_rate NUMERIC DEFAULT 10.0;
ALTER TABLE public.agency_settings ADD COLUMN IF NOT EXISTS support_phone TEXT;

ALTER TABLE agency_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view agency settings." ON agency_settings;
CREATE POLICY "Public can view agency settings." ON agency_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can update agency settings." ON agency_settings;
CREATE POLICY "Admins can update agency settings." ON agency_settings FOR UPDATE USING (public.is_admin());

-- Seed the initial row
INSERT INTO agency_settings (id, name) VALUES (1, 'Mubashir Real Estate') ON CONFLICT DO NOTHING;

-- 14. Financials & Management Tables
CREATE TABLE IF NOT EXISTS public.office_expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.rentals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES profiles(id),
  agent_id UUID REFERENCES employees(id),
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  monthly_rent NUMERIC NOT NULL,
  commission_rate NUMERIC DEFAULT 10.0,
  status TEXT DEFAULT 'Active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payouts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  rental_id UUID REFERENCES rentals(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL,
  agency_cut NUMERIC NOT NULL,
  owner_cut NUMERIC NOT NULL,
  is_paid_to_owner BOOLEAN DEFAULT FALSE,
  payout_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. RLS for Financials
ALTER TABLE office_expenses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage expenses." ON office_expenses;
CREATE POLICY "Admins can manage expenses." ON office_expenses FOR ALL USING (public.is_admin());

ALTER TABLE rentals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage rentals." ON rentals;
CREATE POLICY "Admins can manage rentals." ON rentals FOR ALL USING (public.is_admin());

ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage payouts." ON payouts;
CREATE POLICY "Admins can manage payouts." ON payouts FOR ALL USING (public.is_admin());

-- 13. STORAGE BUCKETS (Ensures these exist for image uploads)
-- Note: Requires storage schema permissions
INSERT INTO storage.buckets (id, name, public)
VALUES ('properties', 'properties', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('branding', 'branding', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies (Fixes 403 Unauthorized errors)
-- 1. Allow anyone to view images
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'properties' OR bucket_id = 'branding');

-- 2. Allow authenticated users (Admins) to upload images
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
CREATE POLICY "Authenticated Upload" ON storage.objects FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND (bucket_id = 'properties' OR bucket_id = 'branding'));

-- 3. Allow authenticated users (Admins) to update/upsert images
DROP POLICY IF EXISTS "Authenticated Update" ON storage.objects;
CREATE POLICY "Authenticated Update" ON storage.objects FOR UPDATE USING (auth.role() = 'authenticated' AND (bucket_id = 'properties' OR bucket_id = 'branding'));
