-- 0. Wipe existing to prevent "Already Exists" error (WARNING: Destroys old data)
DROP TABLE IF EXISTS inquiries CASCADE;
DROP TABLE IF EXISTS properties CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- Create an ENUM type for strict role enforcement
CREATE TYPE user_role AS ENUM ('customer', 'admin');

-- 1. Create the profiles table (Links to Supabase Auth UUID)
CREATE TABLE public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  phone text,
  avatar_url text,
  role user_role DEFAULT 'customer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create the properties table
CREATE TABLE properties (
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create the inquiries table
CREATE TABLE inquiries (
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
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- 6. Properties RLS Policies
CREATE POLICY "Public properties are viewable by everyone." ON properties FOR SELECT USING (true);
CREATE POLICY "Admins can insert properties." ON properties FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "Admins can update properties." ON properties FOR UPDATE USING (public.is_admin());
CREATE POLICY "Admins can delete properties." ON properties FOR DELETE USING (public.is_admin());

-- 7. Inquiries RLS Policies
CREATE POLICY "Public can embed inquiries." ON inquiries FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins can read inquiries." ON inquiries FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can update inquiries." ON inquiries FOR UPDATE USING (public.is_admin());
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
