-- Supabase schema for EcoAlert analytics and audit logs.

create table if not exists prediction_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  type text not null,
  city text,
  using_model boolean,
  risk_level text,
  probability double precision,
  predicted_aqi integer,
  predicted_category text,
  predicted_class integer
);

create table if not exists upload_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  type text not null,
  actor_uid text,
  report_id text,
  count integer
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  actor_uid text,
  action text not null,
  context jsonb
);

-- ══════════════════════════════════════════════════════════════
-- REQUIRED MIGRATIONS — run these in Supabase SQL Editor
-- ══════════════════════════════════════════════════════════════

-- 1. Add missing columns to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'registered_user';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended bool DEFAULT false;

-- 2. RLS: admins can update any profile's role/suspension
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "admin_or_own_update" ON profiles;

CREATE POLICY "admin_or_own_update" ON profiles
FOR UPDATE TO authenticated
USING (
  auth.uid() = id
  OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  auth.uid() = id
  OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);

-- 3. RLS: admins can update report status (approve/reject/resolve)
DROP POLICY IF EXISTS "admin_can_update_reports" ON reports;

CREATE POLICY "admin_can_update_reports" ON reports
FOR UPDATE TO authenticated
USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  OR reporter_uid = auth.uid()
)
WITH CHECK (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  OR reporter_uid = auth.uid()
);

-- 4. Storage: authenticated users can upload to report-images bucket
INSERT INTO storage.buckets (id, name, public)
  VALUES ('report-images', 'report-images', true)
  ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "auth_upload_report_images" ON storage.objects;
DROP POLICY IF EXISTS "public_read_report_images" ON storage.objects;

CREATE POLICY "auth_upload_report_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'report-images');

CREATE POLICY "public_read_report_images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'report-images');

-- 5. Storage: authenticated users can upload to profile-images bucket
INSERT INTO storage.buckets (id, name, public)
  VALUES ('profile-images', 'profile-images', true)
  ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "auth_upload_profile_images" ON storage.objects;
DROP POLICY IF EXISTS "public_read_profile_images" ON storage.objects;

CREATE POLICY "auth_upload_profile_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "public_read_profile_images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'profile-images');

-- ══════════════════════════════════════════════════════════════
-- ADDITIONAL POLICIES — run these too if not already applied
-- ══════════════════════════════════════════════════════════════

-- Allow admins to SELECT all profiles (needed for role-change to read back)
DROP POLICY IF EXISTS "admin_can_read_profiles" ON profiles;
CREATE POLICY "admin_can_read_profiles" ON profiles
FOR SELECT TO authenticated
USING (
  id = auth.uid()
  OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);

-- Allow admins to SELECT all reports (needed for stream to see all reports)
DROP POLICY IF EXISTS "admin_can_read_reports" ON reports;
CREATE POLICY "admin_can_read_reports" ON reports
FOR SELECT TO authenticated
USING (
  reporter_uid = auth.uid()
  OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);

-- Allow authenticated users to INSERT their own reports
DROP POLICY IF EXISTS "users_can_insert_reports" ON reports;
CREATE POLICY "users_can_insert_reports" ON reports
FOR INSERT TO authenticated
WITH CHECK (reporter_uid = auth.uid());
