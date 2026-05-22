# EcoAlert — Full Supabase Integration Plan

**Decisions baked in:**
- Hard cutover (feature branch, one switch)
- Keep `firebase_core` + `firebase_messaging` for push only — all other Firebase SDKs removed
- Google Sign-In via Supabase OAuth (browser redirect on Android, no `google_sign_in` package needed)
- Dev/demo database — start fresh with seed data provided below
- Target: Android + Web only

---

## Phase 0 — Supabase Project Setup (do this first, ~30 min)

1. Go to https://supabase.com → New Project → name it `ecoalert`
2. Save these three values from **Settings → API**:
   - `Project URL`  → `SUPABASE_URL`
   - `anon public`  → `SUPABASE_ANON_KEY`
   - `service_role secret` → `SUPABASE_SERVICE_KEY` (backend only, never ship to app)
3. Save from **Settings → API → JWT Settings**:
   - `JWT Secret` → `SUPABASE_JWT_SECRET` (Python backend token verification)

### Enable Auth Providers in Dashboard
- **Authentication → Providers → Email**: enable "Confirm email" if you want email verification
- **Authentication → Providers → Google**:
  - Add your Google OAuth Client ID + Secret (same one from Firebase Console, or create a new one at console.cloud.google.com)
  - Redirect URL Supabase gives you: `https://<project-ref>.supabase.co/auth/v1/callback`
  - Add this URL to your Google Cloud Console → OAuth 2.0 → Authorized redirect URIs

### Android Deep Link for OAuth
In `android/app/src/main/AndroidManifest.xml`, inside `<activity>` add:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.ecoalert"
        android:host="login-callback" />
</intent-filter>
```

---

## Phase 1 — Database Schema (run in Supabase SQL Editor)

```sql
-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: profiles
-- Mirrors auth.users, one row per registered user.
-- Created automatically via trigger (see below).
-- ============================================================
CREATE TABLE public.profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email         TEXT NOT NULL,
    username      TEXT NOT NULL DEFAULT '',
    phone_number  TEXT NOT NULL DEFAULT '',
    cnic_hash     TEXT NOT NULL DEFAULT '',   -- SHA-256 of CNIC, never raw
    province      TEXT NOT NULL DEFAULT '',
    city          TEXT NOT NULL DEFAULT '',
    role          TEXT NOT NULL DEFAULT 'registered'
                      CHECK (role IN ('general','registered','premium','admin')),
    fcm_token     TEXT,
    photo_url     TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_city   ON public.profiles(city);
CREATE INDEX idx_profiles_role   ON public.profiles(role);

-- ============================================================
-- TABLE: alerts
-- Admin-created environmental alerts broadcast to users.
-- ============================================================
CREATE TABLE public.alerts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title         TEXT NOT NULL,
    description   TEXT NOT NULL DEFAULT '',
    severity      TEXT NOT NULL DEFAULT 'medium'
                      CHECK (severity IN ('low','medium','high','critical')),
    location      TEXT NOT NULL DEFAULT '',   -- human readable, e.g. "Lahore, Punjab"
    city          TEXT NOT NULL DEFAULT '',   -- lowercase slug for filtering, e.g. "lahore"
    type          TEXT NOT NULL DEFAULT 'other'
                      CHECK (type IN ('flood','air_quality','cloudburst','heatwave','other')),
    action_text   TEXT NOT NULL DEFAULT 'View Details',
    created_by    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    timestamp     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_city      ON public.alerts(city);
CREATE INDEX idx_alerts_type      ON public.alerts(type);
CREATE INDEX idx_alerts_severity  ON public.alerts(severity);
CREATE INDEX idx_alerts_timestamp ON public.alerts(timestamp DESC);
CREATE INDEX idx_alerts_active    ON public.alerts(is_active) WHERE is_active = TRUE;

-- ============================================================
-- TABLE: reports
-- User-submitted hazard reports; admin reviews & approves.
-- ============================================================
CREATE TABLE public.reports (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_uid    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reporter_name   TEXT NOT NULL DEFAULT '',
    hazard_type     TEXT NOT NULL DEFAULT '',
    details         TEXT NOT NULL DEFAULT '',
    image_count     INT  NOT NULL DEFAULT 0,
    image_urls      TEXT[] NOT NULL DEFAULT '{}',
    location_label  TEXT NOT NULL DEFAULT '',
    status          TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','approved','rejected','resolved')),
    aqi             INT NOT NULL DEFAULT 0,
    main_pollutant  TEXT NOT NULL DEFAULT '',
    confidence      FLOAT NOT NULL DEFAULT 0.0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_reporter_uid ON public.reports(reporter_uid);
CREATE INDEX idx_reports_status       ON public.reports(status);
CREATE INDEX idx_reports_created_at   ON public.reports(created_at DESC);
CREATE INDEX idx_reports_hazard_type  ON public.reports(hazard_type);

-- ============================================================
-- TABLE: aqi_readings
-- Cached AQI data per city; written by backend cron/API calls.
-- One row per city (upsert by city).
-- ============================================================
CREATE TABLE public.aqi_readings (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city           TEXT NOT NULL UNIQUE,  -- lowercase, e.g. "lahore"
    aqi_value      INT NOT NULL DEFAULT 0,
    main_pollutant TEXT NOT NULL DEFAULT '',
    station_name   TEXT NOT NULL DEFAULT '',
    source         TEXT NOT NULL DEFAULT 'WAQI',
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: weather_data
-- Cached weather per city; written by backend cron.
-- ============================================================
CREATE TABLE public.weather_data (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city       TEXT NOT NULL UNIQUE,
    data       JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: alert_settings
-- Per-user notification preferences.
-- ============================================================
CREATE TABLE public.alert_settings (
    user_id              UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    flood_alerts         BOOLEAN NOT NULL DEFAULT TRUE,
    aqi_alerts           BOOLEAN NOT NULL DEFAULT TRUE,
    cloudburst_alerts    BOOLEAN NOT NULL DEFAULT TRUE,
    heatwave_alerts      BOOLEAN NOT NULL DEFAULT TRUE,
    min_severity         TEXT NOT NULL DEFAULT 'low'
                             CHECK (min_severity IN ('low','medium','high','critical')),
    notification_radius_km INT NOT NULL DEFAULT 50,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: fcm_tokens
-- One token per user (overwritten on refresh).
-- ============================================================
CREATE TABLE public.fcm_tokens (
    user_id    UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    token      TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: admin_logs
-- Audit trail for all admin actions.
-- ============================================================
CREATE TABLE public.admin_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_uid   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    action      TEXT NOT NULL,            -- e.g. "approve_report", "create_alert"
    target_type TEXT NOT NULL DEFAULT '', -- e.g. "report", "alert", "user"
    target_id   TEXT NOT NULL DEFAULT '',
    metadata    JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_admin_logs_admin_uid  ON public.admin_logs(admin_uid);
CREATE INDEX idx_admin_logs_created_at ON public.admin_logs(created_at DESC);

-- ============================================================
-- TABLE: prediction_logs
-- Stores every ML prediction call from the Python backend.
-- ============================================================
CREATE TABLE public.prediction_logs (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_type   TEXT NOT NULL,   -- "aqi_numerical", "cloudburst"
    input_data   JSONB NOT NULL DEFAULT '{}',
    prediction   JSONB NOT NULL DEFAULT '{}',
    user_uid     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: hazard_zones
-- Static / admin-curated geographic risk zones shown on the map.
-- Matches HazardZoneModel (lat/lon/radius_m column names).
-- ============================================================
CREATE TABLE public.hazard_zones (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          TEXT NOT NULL,
    city          TEXT NOT NULL DEFAULT '',
    type          TEXT NOT NULL DEFAULT 'aqi'
                      CHECK (type IN ('aqi','flood','heatwave','other')),
    lat           DOUBLE PRECISION NOT NULL,
    lon           DOUBLE PRECISION NOT NULL,
    radius_m      DOUBLE PRECISION NOT NULL DEFAULT 800,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hazard_zones_city   ON public.hazard_zones(city);
CREATE INDEX idx_hazard_zones_type   ON public.hazard_zones(type);
CREATE INDEX idx_hazard_zones_active ON public.hazard_zones(is_active) WHERE is_active = TRUE;

-- ============================================================
-- TABLE: community_posts
-- User-generated community feed posts (text + optional image).
-- ============================================================
CREATE TABLE public.community_posts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_uid  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    author_name TEXT NOT NULL DEFAULT '',
    content     TEXT NOT NULL DEFAULT '',
    image_url   TEXT,
    city        TEXT NOT NULL DEFAULT '',
    likes       INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_community_posts_city       ON public.community_posts(city);
CREATE INDEX idx_community_posts_created_at ON public.community_posts(created_at DESC);

-- ============================================================
-- TRIGGER: auto-create profile on new auth.users row
-- Runs after every INSERT into auth.users.
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, username, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        'registered',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- TRIGGER: auto-update updated_at on reports
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER reports_updated_at
    BEFORE UPDATE ON public.reports
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
```

---

## Phase 2 — Row Level Security Policies

Enable RLS on every table first:

```sql
ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aqi_readings    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weather_data    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_settings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_logs      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_logs ENABLE ROW LEVEL SECURITY;
```

### Helper: is_admin()

```sql
-- Reusable inline check so policy SQL stays readable.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;
```

### profiles

```sql
-- Anyone authenticated can read their own profile.
CREATE POLICY "profiles: user reads own"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (id = auth.uid());

-- Admins can read all profiles.
CREATE POLICY "profiles: admin reads all"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Users can update their own profile (except role).
CREATE POLICY "profiles: user updates own"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (
        id = auth.uid()
        AND role = (SELECT role FROM public.profiles WHERE id = auth.uid())
    );

-- Admins can update any profile (including role changes).
CREATE POLICY "profiles: admin updates any"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (public.is_admin());

-- INSERT is handled by the trigger (service_role context), so no user INSERT policy.
-- Supabase service_role bypasses RLS automatically.
```

### alerts

```sql
-- All authenticated users (and anonymous) can read active alerts.
CREATE POLICY "alerts: public read active"
    ON public.alerts FOR SELECT
    USING (is_active = TRUE);

-- Admins can read ALL alerts (including inactive).
CREATE POLICY "alerts: admin reads all"
    ON public.alerts FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Only admins can insert alerts.
CREATE POLICY "alerts: admin insert"
    ON public.alerts FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());

-- Only admins can update alerts.
CREATE POLICY "alerts: admin update"
    ON public.alerts FOR UPDATE
    TO authenticated
    USING (public.is_admin());

-- Only admins can delete alerts.
CREATE POLICY "alerts: admin delete"
    ON public.alerts FOR DELETE
    TO authenticated
    USING (public.is_admin());
```

### reports

```sql
-- Users can see their own reports.
CREATE POLICY "reports: user reads own"
    ON public.reports FOR SELECT
    TO authenticated
    USING (reporter_uid = auth.uid());

-- Admins can see all reports.
CREATE POLICY "reports: admin reads all"
    ON public.reports FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Authenticated users can submit reports.
CREATE POLICY "reports: user inserts own"
    ON public.reports FOR INSERT
    TO authenticated
    WITH CHECK (reporter_uid = auth.uid());

-- Users can update their OWN pending reports (e.g. add image URLs).
CREATE POLICY "reports: user updates own pending"
    ON public.reports FOR UPDATE
    TO authenticated
    USING (reporter_uid = auth.uid() AND status = 'pending')
    WITH CHECK (reporter_uid = auth.uid());

-- Admins can update any report (status changes, approvals).
CREATE POLICY "reports: admin updates any"
    ON public.reports FOR UPDATE
    TO authenticated
    USING (public.is_admin());

-- Admins can delete reports.
CREATE POLICY "reports: admin deletes"
    ON public.reports FOR DELETE
    TO authenticated
    USING (public.is_admin());
```

### aqi_readings & weather_data

```sql
-- Public read — anyone (anon or authenticated) can read cached data.
CREATE POLICY "aqi_readings: public read"
    ON public.aqi_readings FOR SELECT
    USING (TRUE);

CREATE POLICY "weather_data: public read"
    ON public.weather_data FOR SELECT
    USING (TRUE);

-- Only service_role (Python backend) can write — no user-level INSERT/UPDATE policy.
-- service_role bypasses RLS automatically, so nothing else needed here.
```

### alert_settings & fcm_tokens

```sql
-- Users manage only their own row.
CREATE POLICY "alert_settings: own row"
    ON public.alert_settings FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "fcm_tokens: own row"
    ON public.fcm_tokens FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
```

### admin_logs & prediction_logs

```sql
-- Only admins can read audit logs.
CREATE POLICY "admin_logs: admin reads"
    ON public.admin_logs FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Service_role inserts (from backend) — no user-level INSERT policy needed.

-- prediction_logs: only service_role writes, admins read.
CREATE POLICY "prediction_logs: admin reads"
    ON public.prediction_logs FOR SELECT
    TO authenticated
    USING (public.is_admin());
```

### hazard_zones & community_posts

```sql
ALTER TABLE public.hazard_zones    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

-- hazard_zones: public read, admin write
CREATE POLICY "hazard_zones: public read"
    ON public.hazard_zones FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "hazard_zones: admin write"
    ON public.hazard_zones FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- community_posts: authenticated read, own insert/update, admin delete
CREATE POLICY "community_posts: authenticated read"
    ON public.community_posts FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "community_posts: user insert"
    ON public.community_posts FOR INSERT
    TO authenticated
    WITH CHECK (author_uid = auth.uid());

CREATE POLICY "community_posts: user updates own"
    ON public.community_posts FOR UPDATE
    TO authenticated
    USING (author_uid = auth.uid())
    WITH CHECK (author_uid = auth.uid());

CREATE POLICY "community_posts: admin deletes"
    ON public.community_posts FOR DELETE
    TO authenticated
    USING (public.is_admin());
```

---

## Phase 2b — Realtime Setup

Enable realtime for the tables that need live updates in the Dashboard:
**Database → Replication → 0 Tables → enable for:**

| Table | Why |
|---|---|
| `alerts` | Home screen shows new alerts instantly |
| `reports` | Admin panel + user "my reports" status updates |
| `aqi_readings` | Home AQI card refreshes without polling |

For `community_posts` enable only if you build a live feed (avoids wasted connections).

**Flutter usage pattern (using `.stream()`):**

```dart
// Alerts — full snapshot + live inserts/updates
_client
  .from('alerts')
  .stream(primaryKey: ['id'])
  .eq('is_active', true)
  .order('timestamp', ascending: false)
  .limit(20)
  .listen((rows) => /* rebuild */);

// My reports — postgres_changes filter (server-side filter, cheaper)
_client
  .channel('my_reports_$uid')
  .onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'reports',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'reporter_uid',
      value: uid,
    ),
    callback: (payload) => /* update status chip */,
  )
  .subscribe();
```

> **Pitfall:** `.stream()` does NOT support server-side `filter` — it downloads all matching rows and filters client-side. For user-specific filtered streams use `.onPostgresChanges()` with a filter instead.

---

## Phase 2c — Sample Queries: Insert Report → Auto-create Alert

### Option A: Database Function (recommended — runs inside Postgres, atomic)

```sql
-- Function: admin calls this after approving a report to auto-generate an alert.
CREATE OR REPLACE FUNCTION public.approve_report_and_create_alert(
    p_report_id   UUID,
    p_admin_uid   UUID,
    p_severity    TEXT DEFAULT 'medium'
)
RETURNS UUID   -- returns the new alert id
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_report      public.reports%ROWTYPE;
    v_alert_id    UUID;
    v_alert_type  TEXT;
BEGIN
    -- 1. Fetch and lock the report row
    SELECT * INTO v_report
    FROM public.reports
    WHERE id = p_report_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Report % not found', p_report_id;
    END IF;

    -- 2. Map hazard_type → alert type enum
    v_alert_type := CASE v_report.hazard_type
        WHEN 'Flood'         THEN 'flood'
        WHEN 'Air Quality'   THEN 'air_quality'
        WHEN 'Cloudburst'    THEN 'cloudburst'
        WHEN 'Heatwave'      THEN 'heatwave'
        ELSE 'other'
    END;

    -- 3. Mark report approved
    UPDATE public.reports
    SET status = 'approved', updated_at = NOW()
    WHERE id = p_report_id;

    -- 4. Insert alert derived from the report
    INSERT INTO public.alerts (
        title, description, severity, location, city,
        type, action_text, created_by, timestamp, is_active
    )
    VALUES (
        v_report.hazard_type || ' reported — ' || v_report.location_label,
        v_report.details,
        p_severity,
        v_report.location_label,
        lower(split_part(v_report.location_label, ',', 1)),
        v_alert_type,
        'View Details',
        p_admin_uid,
        NOW(),
        TRUE
    )
    RETURNING id INTO v_alert_id;

    -- 5. Audit log
    INSERT INTO public.admin_logs (admin_uid, action, target_type, target_id, metadata)
    VALUES (
        p_admin_uid, 'approve_report', 'report', p_report_id::text,
        jsonb_build_object('alert_id', v_alert_id, 'severity', p_severity)
    );

    RETURN v_alert_id;
END;
$$;

-- GRANT to authenticated so admin Flutter client can call it via RPC.
-- RLS on the function itself is enforced via the is_admin() check in the caller,
-- or add a guard inside the function body:
-- IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin only'; END IF;
```

**Flutter call (admin panel):**

```dart
final alertId = await Supabase.instance.client.rpc(
  'approve_report_and_create_alert',
  params: {
    'p_report_id': reportId,
    'p_admin_uid':  currentUser.id,
    'p_severity':  'high',
  },
);
// alertId is the new alert's UUID; realtime subscribers see the new alert instantly.
```

### Option B: Two-step from Flutter (simpler, no function needed)

```dart
// Step 1 — approve the report
await _client.from('reports')
  .update({'status': 'approved'})
  .eq('id', reportId);

// Step 2 — insert derived alert
final alert = {
  'title':       '${report.hazardType} — ${report.locationLabel}',
  'description': report.details,
  'severity':    selectedSeverity,
  'location':    report.locationLabel,
  'city':        report.locationLabel.split(',').first.trim().toLowerCase(),
  'type':        _mapHazardTypeToAlertType(report.hazardType),
  'action_text': 'View Details',
  'created_by':  currentUser.id,
  'is_active':   true,
};
await _client.from('alerts').insert(alert);
```

> **Pitfall:** Option B has a race condition if the admin clicks twice — the function (Option A) is atomic and idempotent-friendly with the `FOR UPDATE` lock.

---

## Phase 3 — Seed Data (run after schema)

```sql
-- ── Sample Alerts ────────────────────────────────────────────
INSERT INTO public.alerts (title, description, severity, location, city, type, action_text, timestamp, is_active)
VALUES
(
    'High Flood Risk — Lahore',
    'River Ravi levels rising rapidly near Shahdara. Low-lying areas should evacuate immediately.',
    'high', 'Lahore, Punjab', 'lahore', 'flood', 'See Evacuation Routes',
    NOW() - INTERVAL '2 hours', TRUE
),
(
    'Unhealthy Air Quality — Karachi',
    'AQI has reached 185 (Unhealthy). PM2.5 is the primary pollutant. Limit outdoor activity.',
    'medium', 'Karachi, Sindh', 'karachi', 'air_quality', 'View AQI Details',
    NOW() - INTERVAL '4 hours', TRUE
),
(
    'Cloudburst Warning — Islamabad',
    'Heavy rainfall (80 mm/hr) forecast in the next 3 hours. Move vehicles to higher ground.',
    'critical', 'Islamabad, ICT', 'islamabad', 'cloudburst', 'Emergency Checklist',
    NOW() - INTERVAL '30 minutes', TRUE
),
(
    'Heatwave Advisory — Multan',
    'Temperatures expected to reach 48°C over the next 48 hours. Stay hydrated, avoid noon-3pm outdoors.',
    'high', 'Multan, Punjab', 'multan', 'heatwave', 'Safety Tips',
    NOW() - INTERVAL '6 hours', TRUE
),
(
    'Flood Watch — Peshawar',
    'River Kabul discharge elevated. Downstream villages on amber alert.',
    'medium', 'Peshawar, KPK', 'peshawar', 'flood', 'View Risk Map',
    NOW() - INTERVAL '1 hour', TRUE
);

-- ── Sample AQI Readings ──────────────────────────────────────
INSERT INTO public.aqi_readings (city, aqi_value, main_pollutant, station_name, source, updated_at)
VALUES
    ('lahore',    162, 'PM2.5', 'Lahore-Cantt',       'WAQI', NOW()),
    ('karachi',    95, 'PM10',  'Karachi-Port',        'WAQI', NOW()),
    ('islamabad',  78, 'O3',    'Islamabad-F8/2',      'WAQI', NOW()),
    ('peshawar',  110, 'PM2.5', 'Peshawar-Hayatabad',  'WAQI', NOW()),
    ('multan',    130, 'PM2.5', 'Multan-Cantt',        'WAQI', NOW()),
    ('rawalpindi', 88, 'NO2',   'Rawalpindi-Saddar',   'WAQI', NOW())
ON CONFLICT (city) DO UPDATE
    SET aqi_value = EXCLUDED.aqi_value,
        main_pollutant = EXCLUDED.main_pollutant,
        updated_at = NOW();

-- ── Create Admin User ────────────────────────────────────────
-- Step 1: Create a user via Supabase Dashboard → Authentication → Users → Add User
--         Use email: admin@ecoalert.pk, set a strong password
-- Step 2: Then run this to promote them:
--
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@ecoalert.pk';
```

---

## Phase 4 — Flutter Changes

### 4.1 pubspec.yaml — packages to add/remove

**REMOVE these Firebase packages:**
```yaml
# DELETE these lines:
firebase_auth: ^4.16.0
cloud_firestore: ^4.15.0
google_sign_in: ^6.2.0
```

**KEEP these (FCM still needs them):**
```yaml
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10
flutter_local_notifications: ^17.0.0
```

**ADD:**
```yaml
supabase_flutter: ^2.5.0
```

### 4.2 lib/config/app_config.dart — add Supabase keys

```dart
class AppConfig {
  // ── Supabase ─────────────────────────────────────────────
  static const String supabaseUrl     = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // ── OAuth deep link ──────────────────────────────────────
  static const String oauthRedirectUri = 'io.supabase.ecoalert://login-callback';

  // ── Existing keys stay as-is ─────────────────────────────
  static const String uploadApiBaseUrl = '...';
  // etc.
}
```

### 4.3 lib/main.dart — initialize Supabase + keep Firebase for FCM

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (FCM only — Auth/Firestore no longer used)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const EcoAlertApp());
}
```

### 4.4 lib/config/supabase_paths.dart — replaces firestore_paths.dart

```dart
/// Supabase table name constants (replaces firestore_paths.dart).
class SupabasePaths {
  static const String profiles        = 'profiles';
  static const String alerts          = 'alerts';
  static const String reports         = 'reports';
  static const String aqiReadings     = 'aqi_readings';
  static const String weatherData     = 'weather_data';
  static const String alertSettings   = 'alert_settings';
  static const String fcmTokens       = 'fcm_tokens';
  static const String adminLogs       = 'admin_logs';
  static const String predictionLogs  = 'prediction_logs';

  // Storage bucket names
  static const String bucketReportImages    = 'report-images';
  static const String bucketProfilePictures = 'profile-pictures';
}
```

### 4.5 lib/services/supabase_auth_service.dart — replaces firebase_auth_service.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/supabase_paths.dart';
import '../utils/hash_utils.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Auth State ──────────────────────────────────────────────

  User? getCurrentUser() => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Sign Up ─────────────────────────────────────────────────
  /// Creates Supabase Auth user. The trigger auto-creates the profiles row.
  /// We then fill in the extra profile fields the trigger cannot know.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},  // trigger uses this for the username column
    );

    final user = response.user;
    if (user != null) {
      // Patch the profile with fields the trigger could not set
      await _client.from(SupabasePaths.profiles).update({
        'phone_number': phoneNumber,
        'cnic_hash':    HashUtils.hashCnic(cnicNumber),
        'province':     province,
        'city':         city,
      }).eq('id', user.id);
    }

    return response;
  }

  // ─── Sign In ─────────────────────────────────────────────────

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ─── Google OAuth ────────────────────────────────────────────
  /// Opens a browser for Google sign-in via Supabase OAuth.
  /// Returns true if the OAuth flow started (result comes via authStateChanges).
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUri,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // ─── Sign Out ────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Password Reset ──────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${AppConfig.oauthRedirectUri}/reset-password',
    );
  }

  // ─── Profile ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final data = await _client
        .from(SupabasePaths.profiles)
        .select()
        .eq('id', uid)
        .maybeSingle();
    return data;
  }

  Future<void> updateUserField(String uid, String field, dynamic value) async {
    await _client
        .from(SupabasePaths.profiles)
        .update({field: value})
        .eq('id', uid);
  }
}
```

### 4.6 lib/services/supabase_data_service.dart — replaces firestore_service.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_paths.dart';
import '../models/alert_model.dart';
import '../models/hazard_report_model.dart';
import '../models/user_model.dart';

class SupabaseDataService {
  final SupabaseClient _client = Supabase.instance.client;

  // ══════════════════════════════════════════════
  //  ALERTS
  // ══════════════════════════════════════════════

  Future<List<AlertModel>> getAlerts({int limit = 20}) async {
    final data = await _client
        .from(SupabasePaths.alerts)
        .select()
        .eq('is_active', true)
        .order('timestamp', ascending: false)
        .limit(limit);
    return (data as List).map((row) => AlertModel.fromSupabase(row)).toList();
  }

  Future<List<AlertModel>> getAlertsForCity(String city, {int limit = 10}) async {
    final data = await _client
        .from(SupabasePaths.alerts)
        .select()
        .eq('city', city.toLowerCase())
        .eq('is_active', true)
        .order('timestamp', ascending: false)
        .limit(limit);
    return (data as List).map((row) => AlertModel.fromSupabase(row)).toList();
  }

  /// Real-time stream — delivers initial snapshot + all changes.
  Stream<List<AlertModel>> alertsStream({int limit = 20}) {
    return _client
        .from(SupabasePaths.alerts)
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('timestamp', ascending: false)
        .limit(limit)
        .map((data) =>
            data.map((row) => AlertModel.fromSupabase(row)).toList());
  }

  Future<String> addAlert(AlertModel alert) async {
    final data = await _client
        .from(SupabasePaths.alerts)
        .insert(alert.toSupabaseJson())
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> deleteAlert(String alertId) async {
    await _client
        .from(SupabasePaths.alerts)
        .delete()
        .eq('id', alertId);
  }

  // ══════════════════════════════════════════════
  //  REPORTS
  // ══════════════════════════════════════════════

  Future<String> addReport(HazardReportModel report) async {
    final data = await _client
        .from(SupabasePaths.reports)
        .insert(report.toSupabaseJson())
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> updateReport(String reportId, Map<String, dynamic> fields) async {
    await _client
        .from(SupabasePaths.reports)
        .update(fields)
        .eq('id', reportId);
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _client
        .from(SupabasePaths.reports)
        .update({'status': status})
        .eq('id', reportId);
  }

  Future<List<HazardReportModel>> getAllReports() async {
    final data = await _client
        .from(SupabasePaths.reports)
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((row) => HazardReportModel.fromSupabase(row))
        .toList();
  }

  Future<List<HazardReportModel>> getReportsByStatus(String status) async {
    final data = await _client
        .from(SupabasePaths.reports)
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);
    return (data as List)
        .map((row) => HazardReportModel.fromSupabase(row))
        .toList();
  }

  Future<List<HazardReportModel>> getUserReports(String userId) async {
    final data = await _client
        .from(SupabasePaths.reports)
        .select()
        .eq('reporter_uid', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((row) => HazardReportModel.fromSupabase(row))
        .toList();
  }

  Stream<List<HazardReportModel>> reportsStream({int limit = 50}) {
    return _client
        .from(SupabasePaths.reports)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) =>
            data.map((row) => HazardReportModel.fromSupabase(row)).toList());
  }

  // ══════════════════════════════════════════════
  //  USERS (admin panel)
  // ══════════════════════════════════════════════

  Future<List<UserModel>> getAllUsers() async {
    final data = await _client
        .from(SupabasePaths.profiles)
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((row) => UserModel.fromSupabase(row)).toList();
  }

  Future<void> setUserRole(String uid, UserRole role) async {
    await _client
        .from(SupabasePaths.profiles)
        .update({'role': role.name})
        .eq('id', uid);
  }

  Future<UserModel?> getUser(String uid) async {
    final data = await _client
        .from(SupabasePaths.profiles)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromSupabase(data);
  }

  // ══════════════════════════════════════════════
  //  AQI & WEATHER (read-only from Flutter)
  // ══════════════════════════════════════════════

  Future<Map<String, dynamic>?> getAqiReading(String city) async {
    return await _client
        .from(SupabasePaths.aqiReadings)
        .select()
        .eq('city', city.toLowerCase())
        .maybeSingle();
  }

  Stream<Map<String, dynamic>?> aqiStream(String city) {
    return _client
        .from(SupabasePaths.aqiReadings)
        .stream(primaryKey: ['id'])
        .eq('city', city.toLowerCase())
        .limit(1)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  Future<Map<String, dynamic>?> getWeatherData(String city) async {
    return await _client
        .from(SupabasePaths.weatherData)
        .select()
        .eq('city', city.toLowerCase())
        .maybeSingle();
  }

  // ══════════════════════════════════════════════
  //  ALERT SETTINGS
  // ══════════════════════════════════════════════

  Future<void> saveAlertSettings(
      String uid, Map<String, dynamic> settings) async {
    await _client
        .from(SupabasePaths.alertSettings)
        .upsert({'user_id': uid, ...settings});
  }

  Future<Map<String, dynamic>?> getAlertSettings(String uid) async {
    return await _client
        .from(SupabasePaths.alertSettings)
        .select()
        .eq('user_id', uid)
        .maybeSingle();
  }

  // ══════════════════════════════════════════════
  //  FCM TOKENS
  // ══════════════════════════════════════════════

  Future<void> saveFcmToken(String uid, String token) async {
    await _client.from(SupabasePaths.fcmTokens).upsert({
      'user_id': uid,
      'token': token,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFcmToken(String uid) async {
    await _client
        .from(SupabasePaths.fcmTokens)
        .delete()
        .eq('user_id', uid);
  }

  // ══════════════════════════════════════════════
  //  ADMIN LOGS
  // ══════════════════════════════════════════════

  Future<void> logAdminAction({
    required String adminUid,
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _client.from(SupabasePaths.adminLogs).insert({
      'admin_uid': adminUid,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'metadata': metadata,
    });
  }

  // ══════════════════════════════════════════════
  //  REALTIME — Admin approvals listener
  //  Usage: call subscribe once after login in AuthProvider.
  //  Returns the channel; call channel.unsubscribe() on dispose.
  // ══════════════════════════════════════════════

  RealtimeChannel subscribeToMyReports({
    required String userId,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    final channel = _client.channel('my_reports_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabasePaths.reports,
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'reporter_uid',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToAllAlerts({
    required void Function(Map<String, dynamic> payload) onInsert,
  }) {
    final channel = _client.channel('all_alerts');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabasePaths.alerts,
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
    return channel;
  }
}
```

### 4.7 Updated lib/providers/auth_provider.dart

Replace the entire Firebase-specific implementation with Supabase:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supa show User;
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserRole get currentRole => _currentUser?.role ?? UserRole.general;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isPremium => currentRole == UserRole.premium;
  bool get isBasic => currentRole == UserRole.registered;

  /// Call once from main.dart or a top-level widget to wire up the auth stream.
  void initAuth() {
    _authService.authStateChanges.listen((authState) async {
      final supaUser = authState.session?.user;
      if (supaUser == null) {
        _clearState();
      } else {
        await _loadProfile(supaUser);
      }
      notifyListeners();
    });

    // Handle current session on cold start
    final existingUser = _authService.getCurrentUser();
    if (existingUser != null) {
      _loadProfile(existingUser).then((_) => notifyListeners());
    }
  }

  Future<void> _loadProfile(supa.User supaUser) async {
    final profile = await _authService.getUserProfile(supaUser.id);
    _currentUser = _profileToModel(supaUser.id, supaUser.email ?? '', profile);
    _isAuthenticated = true;
  }

  void _clearState() {
    _currentUser = null;
    _isAuthenticated = false;
  }

  UserModel _profileToModel(
      String id, String email, Map<String, dynamic>? profile) {
    final roleStr = profile?['role'] as String? ?? 'registered';
    return UserModel(
      id: id,
      username: profile?['username'] as String? ?? 'User',
      email: email,
      phoneNumber: profile?['phone_number'] as String? ?? '',
      cnicNumber: '',
      province: profile?['province'] as String? ?? '',
      city: profile?['city'] as String? ?? '',
      createdAt: profile != null
          ? DateTime.tryParse(profile['created_at'] as String? ?? '') ??
              DateTime.now()
          : DateTime.now(),
      role: UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.registered,
      ),
    );
  }

  // ─── Email / Password Login ───────────────────────────────

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
      // Stream listener above will fire and call _loadProfile
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign Up ─────────────────────────────────────────────

  Future<bool> signup({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        username: username,
        phoneNumber: phoneNumber,
        cnicNumber: cnicNumber,
        province: province,
        city: city,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Google OAuth ─────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
      // Result arrives via the authStateChanges stream
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Logout ───────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.signOut();
    _clearState();
    notifyListeners();
  }

  // ─── Password Reset ───────────────────────────────────────

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.sendPasswordReset(email.trim());
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

### 4.8 Model updates — remove Firestore imports

**lib/models/alert_model.dart** — add `fromSupabase` + `toSupabaseJson`, remove Firestore import:

```dart
// Remove:  import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  // ... existing fields unchanged ...

  factory AlertModel.fromSupabase(Map<String, dynamic> row) {
    return AlertModel(
      id:          row['id'] as String,
      title:       row['title'] as String,
      description: row['description'] as String? ?? '',
      severity:    row['severity'] as String? ?? 'medium',
      location:    row['location'] as String? ?? '',
      timestamp:   DateTime.tryParse(row['timestamp'] as String? ?? '') ??
                   DateTime.now(),
      type:        row['type'] as String? ?? 'other',
      actionText:  row['action_text'] as String? ?? 'View Details',
    );
  }

  Map<String, dynamic> toSupabaseJson() => {
    'title':       title,
    'description': description,
    'severity':    severity,
    'location':    location,
    'city':        location.toLowerCase().split(',').first.trim(),
    'timestamp':   timestamp.toIso8601String(),
    'type':        type,
    'action_text': actionText,
    'is_active':   true,
  };

  // Keep fromJson for backward compat during migration, update _timestampFromJson:
  static DateTime _timestampFromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
```

**lib/models/hazard_report_model.dart** — add `fromSupabase` + `toSupabaseJson`, remove Firestore import:

```dart
// Remove:  import 'package:cloud_firestore/cloud_firestore.dart';

// Inside HazardReportModel class, add:

  factory HazardReportModel.fromSupabase(Map<String, dynamic> row) {
    return HazardReportModel(
      id:            row['id'] as String? ?? '',
      hazardType:    row['hazard_type'] as String? ?? '',
      details:       row['details'] as String? ?? '',
      imageCount:    (row['image_count'] as num?)?.toInt() ?? 0,
      imageUrls:     List<String>.from(row['image_urls'] ?? []),
      locationLabel: row['location_label'] as String? ?? '',
      createdAt:     DateTime.tryParse(row['created_at'] as String? ?? '') ??
                     DateTime.now(),
      status:        ReportStatus.values.firstWhere(
                       (s) => s.name == row['status'],
                       orElse: () => ReportStatus.pending,
                     ),
      aqi:           (row['aqi'] as num?)?.toInt() ?? 0,
      mainPollutant: row['main_pollutant'] as String? ?? '',
      confidence:    (row['confidence'] as num?)?.toDouble() ?? 0.0,
      reporterUid:   row['reporter_uid'] as String? ?? '',
      reporterName:  row['reporter_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toSupabaseJson() => {
    'hazard_type':    hazardType,
    'details':        details,
    'image_count':    imageCount,
    'image_urls':     imageUrls,
    'location_label': locationLabel,
    'status':         status.name,
    'aqi':            aqi,
    'main_pollutant': mainPollutant,
    'confidence':     confidence,
    'reporter_uid':   reporterUid,
    'reporter_name':  reporterName,
  };

  // Update _parseDateTime to remove Timestamp reference:
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
```

**lib/models/user_model.dart** — add `fromSupabase`:

```dart
  factory UserModel.fromSupabase(Map<String, dynamic> row) {
    return UserModel(
      id:          row['id'] as String,
      username:    row['username'] as String? ?? '',
      email:       row['email'] as String? ?? '',
      phoneNumber: row['phone_number'] as String? ?? '',
      cnicNumber:  '',  // never stored raw
      province:    row['province'] as String? ?? '',
      city:        row['city'] as String? ?? '',
      createdAt:   DateTime.tryParse(row['created_at'] as String? ?? '') ??
                   DateTime.now(),
      role:        UserRole.values.firstWhere(
                     (r) => r.name == (row['role'] as String? ?? 'registered'),
                     orElse: () => UserRole.registered,
                   ),
    );
  }
```

### 4.9 Updated lib/services/notification_service.dart — FCM token to Supabase

Replace the Firestore calls in `NotificationService` with Supabase:

```dart
// Replace import:
// import 'firestore_service.dart';
import 'supabase_data_service.dart';

// In NotificationService, replace the FirestoreService reference:
final _dataService = SupabaseDataService();

// Wherever you call saveFcmToken / removeFcmToken, the API is identical — no changes needed.
// The methods exist with the same signature in SupabaseDataService.
```

### 4.10 Updated lib/services/upload_service.dart — replace Firebase token with Supabase token

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
// Remove: import 'package:firebase_auth/firebase_auth.dart';

class UploadService {
  // Replace _requireAuthToken():
  static Future<String> _requireAuthToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw UploadException('You must be signed in to upload files.');
    }
    return session.accessToken;  // Supabase JWT — send as Bearer token to backend
  }

  // Rest of the file stays the same — just the token source changes.
}
```

### 4.11 Updated lib/widgets/auth_gate.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Replace FirebaseAuth stream with:
StreamBuilder<AuthState>(
  stream: Supabase.instance.client.auth.onAuthStateChange,
  builder: (context, snapshot) {
    final session = snapshot.data?.session;
    if (session != null) {
      return const HomeRoot();
    }
    return const LoginScreen();
  },
)
```

---

## Phase 5 — Python Backend Changes

### 5.1 New: backend/ecoalert-backend/services/supabase_auth_service.py

Create this file (replaces using `firestore_service.py` for auth):

```python
"""
Supabase JWT verification and user role checks.
Replaces firestore_service.py auth functions.
"""
import os
from functools import lru_cache
from supabase import Client, create_client


@lru_cache(maxsize=1)
def _get_client() -> Client:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_KEY")  # service_role key bypasses RLS
    if not url or not key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set.")
    return create_client(url, key)


def verify_token(access_token: str) -> dict:
    """
    Verify a Supabase access token (JWT) and return user info.
    Raises ValueError on invalid/expired token.
    """
    if not access_token:
        raise ValueError("Missing access token")
    client = _get_client()
    result = client.auth.get_user(access_token)
    if result.user is None:
        raise ValueError("Invalid or expired token")
    return {
        "uid":   result.user.id,
        "email": result.user.email,
    }


def report_belongs_to_user(report_id: str, uid: str) -> bool:
    """Check that the report exists and was submitted by uid."""
    result = (
        _get_client()
        .table("reports")
        .select("reporter_uid")
        .eq("id", report_id)
        .maybe_single()
        .execute()
    )
    if not result.data:
        return False
    return result.data.get("reporter_uid") == uid


def user_is_admin(uid: str) -> bool:
    """Return True if the user's profile has role='admin'."""
    result = (
        _get_client()
        .table("profiles")
        .select("role")
        .eq("id", uid)
        .maybe_single()
        .execute()
    )
    if not result.data:
        return False
    return result.data.get("role") == "admin"


def update_report_image_urls(report_id: str, image_urls: list[str]) -> None:
    """Write image URLs back to the reports table."""
    _get_client().table("reports").update(
        {"image_urls": image_urls, "image_count": len(image_urls)}
    ).eq("id", report_id).execute()


def update_profile_photo(uid: str, photo_url: str) -> None:
    """Update a user's photo_url in the profiles table."""
    _get_client().table("profiles").update(
        {"photo_url": photo_url}
    ).eq("id", uid).execute()
```

### 5.2 Updated: backend/ecoalert-backend/routes/upload_routes.py

Change the import at the top from firestore_service to supabase_auth_service:

```python
# Replace:
# from services.firestore_service import verify_id_token, report_belongs_to_user, ...
# With:
from services.supabase_auth_service import (
    verify_token,
    report_belongs_to_user,
    user_is_admin,
    update_report_image_urls,
    update_profile_photo,
)

# In every route that did:
#   claims = verify_id_token(token)
#   uid = claims['uid']
# Now do:
#   claims = verify_token(token)
#   uid = claims['uid']
#
# The rest of your route logic stays unchanged.
```

### 5.3 Updated: .env.example

```env
# Supabase (already present — add JWT secret)
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key-here
SUPABASE_JWT_SECRET=your-jwt-secret-here

# Firebase (keep ONLY if backend still sends FCM push directly)
# GOOGLE_APPLICATION_CREDENTIALS=firebase-adminsdk.json

# ML backend
MODEL_PATH=models/best_cloudburst_model.pkl
```

### 5.4 requirements.txt — remove firebase-admin if backend no longer verifies Firebase tokens

```txt
# REMOVE (if no longer needed):
# firebase-admin

# KEEP:
supabase>=2.3.0
python-dotenv
flask
gunicorn
scikit-learn
pandas
numpy
Pillow
PyJWT>=2.8.0   # optional — for local JWT decode without API call
```

---

## Phase 6 — Supabase Storage Setup

In the Supabase Dashboard → **Storage**:

1. **Create bucket `report-images`**
   - Public: **No** (private — URLs are signed or accessed via service role)
   - File size limit: 5 MB
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

2. **Create bucket `profile-pictures`**
   - Public: **Yes** (profile photos can be publicly readable)
   - File size limit: 2 MB
   - Allowed MIME types: `image/jpeg, image/png`

3. **Storage RLS Policies** (run in SQL Editor):

```sql
-- report-images: users can upload to their own folder (path = uid/reportId/...)
-- This is enforced in the backend (Python), not client-side.
-- No client INSERT policy needed — uploads go via backend.

-- profile-pictures: public read, owner write
CREATE POLICY "profile_pictures: public read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'profile-pictures');

CREATE POLICY "profile_pictures: owner upload"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'profile-pictures'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "profile_pictures: owner delete"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'profile-pictures'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
```

---

## Phase 7 — Step-by-Step Migration Checklist

Work through these in order on a `feature/supabase` branch.

### Week 1 — Infrastructure

- [ ] Create Supabase project, save all credentials
- [ ] Run Phase 1 SQL (schema + triggers) in SQL Editor — verify tables exist
- [ ] Run Phase 2 SQL (RLS policies) — verify via Table Editor → Auth policies
- [ ] Run Phase 3 SQL (seed data) — check rows appear in Table Editor
- [ ] Create admin user via Dashboard, run `UPDATE profiles SET role = 'admin'`
- [ ] Configure Google OAuth in Supabase Dashboard
- [ ] Add deep link intent-filter to AndroidManifest.xml
- [ ] Create Storage buckets (`report-images`, `profile-pictures`)
- [ ] Apply Storage RLS policies

### Week 2 — Backend

- [ ] Add `SUPABASE_JWT_SECRET` to backend `.env`
- [ ] Create `supabase_auth_service.py` (Phase 5.1)
- [ ] Update `upload_routes.py` to use `verify_token` instead of `verify_id_token`
- [ ] Test upload route with a Supabase access token (use Postman — get token via `supabase.auth.signInWithPassword`)
- [ ] Remove `firebase-admin` from `requirements.txt` (only if no other backend route uses it)
- [ ] Deploy backend changes

### Week 3 — Flutter

- [ ] `git checkout -b feature/supabase`
- [ ] Update `pubspec.yaml` (remove firebase_auth, cloud_firestore, google_sign_in; add supabase_flutter)
- [ ] Run `flutter pub get`
- [ ] Add `AppConfig.supabaseUrl` and `AppConfig.supabaseAnonKey`
- [ ] Update `main.dart` (add Supabase.initialize, keep Firebase.initializeApp for FCM)
- [ ] Create `supabase_paths.dart`
- [ ] Create `supabase_auth_service.dart`
- [ ] Create `supabase_data_service.dart`
- [ ] Update `auth_provider.dart`
- [ ] Update `alert_model.dart` (fromSupabase, toSupabaseJson, remove Timestamp)
- [ ] Update `hazard_report_model.dart` (fromSupabase, toSupabaseJson, remove Timestamp)
- [ ] Update `user_model.dart` (fromSupabase)
- [ ] Update `notification_service.dart` (swap FirestoreService for SupabaseDataService)
- [ ] Update `upload_service.dart` (Supabase session token)
- [ ] Update all providers (alert_provider, report_provider, aqi_provider) to use SupabaseDataService
- [ ] Update `auth_gate.dart` to listen to Supabase auth stream
- [ ] Update `firestore_paths.dart` references → `supabase_paths.dart`
- [ ] Delete: `firebase_auth_service.dart`, `firestore_service.dart`, `firestore_paths.dart`
- [ ] Run `flutter analyze` — fix all remaining Firebase import errors
- [ ] Run app on Android emulator — test signup flow end-to-end
- [ ] Run app on web — test Google OAuth flow
- [ ] Test FCM push in background (should still work via firebase_messaging)

### Week 4 — Testing & Polish

- [ ] Run all existing widget tests, fix failures
- [ ] Test admin role: alert creation, report approval
- [ ] Test real-time: have two devices open, post a report on one, see update on the other
- [ ] Test image upload: report images appear in Supabase Storage bucket
- [ ] Test RLS: a regular user cannot read another user's reports (check via Supabase API test tool)
- [ ] Merge `feature/supabase` → `main`

---

## Phase 8 — Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Google OAuth Android redirect not working | Medium | Verify SHA-1 fingerprint added to Google Cloud Console for your `io.supabase.ecoalert` scheme; test on a real device not just emulator |
| Supabase free tier realtime connection limit (200 concurrent) | Low for FYP | Not a concern at demo scale; upgrade tier before production |
| `auth.uid()` in RLS returns null for service_role requests | Known behaviour | Service_role bypasses RLS entirely — your Python backend uses service_role and is unaffected |
| Trigger fails silently, profile row missing | Low | Add error handling in `signUp()` — after signup, call `getUserProfile()` and throw if null |
| FCM token not saved because FirestoreService removed | Medium | In `notification_service.dart`, make sure you swap to `SupabaseDataService.saveFcmToken()` before removing old service |
| `image_urls` stored as Postgres `text[]` — JSON decode issues in Flutter | Low | `List<String>.from(row['image_urls'] ?? [])` handles both `List` and null correctly |
| Backend Firebase Admin SDK dependency left over | Medium | Grep for `firebase_admin` in requirements.txt and all Python imports before deploying |

---

## Phase 9 — Testing Checklist (sign off each)

**Auth**
- [ ] Email signup creates a row in `profiles` table
- [ ] Email login returns a session
- [ ] Google OAuth completes and profile row exists
- [ ] JWT from `session.accessToken` is accepted by Python backend
- [ ] Logout clears session in app and Supabase dashboard shows no active session

**Data**
- [ ] Alerts load on home screen from Supabase
- [ ] New alert created by admin appears on home screen in real-time (no refresh)
- [ ] Hazard report submitted by user appears in admin panel
- [ ] Admin approves report → user's report card updates status in real-time
- [ ] AQI data loaded for user's city

**Storage**
- [ ] Report image uploads to `report-images/{report_id}/image_0.jpg`
- [ ] Profile picture uploads to `profile-pictures/{uid}/avatar.jpg`
- [ ] Uploaded image URL is stored in `reports.image_urls` array

**RLS**
- [ ] Unauthenticated request cannot read `profiles` table
- [ ] User A cannot see User B's reports (test via Supabase REST API with User A's token)
- [ ] Regular user cannot insert into `alerts` table
- [ ] Admin can update any report's status

**FCM (kept)**
- [ ] FCM token saved to `fcm_tokens` table after login
- [ ] Push notification received when app is in background (Android)
