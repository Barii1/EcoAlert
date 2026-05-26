# EcoAlert — Remaining Work
Last updated: May 2026

---

## DONE THIS SESSION
- Removed Profile from bottom nav, added Settings gear to all screens (Home, Alerts, Community, Map, Learn)
- Remade Learn screen — 11 guides, 5 category tabs, search, emergency contacts with tel: links
- Remade Settings (Profile) screen — alert prefs, health conditions (asthma/heart/elderly), AQI threshold, dark mode, GPS refresh, legal, logout
- Admin dashboard — shows admin username, View User App button, Log Out button
- Admin button added to Settings screen — visible to all users for now
- AQI card overflow fixed — city name now truncates properly with ellipsis
- OfflineBanner fixed — no longer pushes home content down when online
- Android build fix — WRITE_EXTERNAL_STORAGE manifest conflict resolved
- Migrated auth from Firebase to Supabase
- Added admin_dashboard_screen.dart — reports approval, emergency broadcast, quick access, system status

---

## CRITICAL — FIX BEFORE SUBMISSION

- [ ] Restore `isAdmin` to real role check in `auth_provider.dart` line 50
      Currently: `bool get isAdmin => true;`
      Should be: `bool get isAdmin => currentRole == UserRole.admin;`
      Then set role in Supabase: UPDATE profiles SET role = 'admin' WHERE email = 'hassaanbari95@gmail.com';

- [ ] Create your account in Supabase Dashboard (hassaanbari95@gmail.com) if not done
      Go to: Supabase → Authentication → Users → Add User
      Then run the SQL above to set admin role

- [ ] Community posts table in Supabase — run SQL to create it so community screen loads real posts

- [ ] Supabase RLS (Row Level Security) policies — verify they allow read/write for authenticated users

---

## AUTH / LOGIN

- [ ] Supabase signup "bad request" — password policy might reject weak passwords
      Workaround: create users directly in Supabase Dashboard → Authentication → Users
- [ ] Old Firebase accounts don't carry over to Supabase — users need to re-register
- [ ] Google Sign-In not wired up on Supabase yet (was Firebase only)
- [ ] Email verification flow — test end-to-end after Supabase account created

---

## UI / SCREENS

- [ ] Flood detail screen — check it loads real data from Supabase/Open-Meteo
- [ ] AQI detail screen — 24h trend chart data source (currently may be mock)
- [ ] Route info screen — check if it still works after migration
- [ ] Admin dashboard "View User App" — currently opens MainNavigationScreen inside a nested Navigator, test for state conflicts
- [ ] Admin dashboard system status cards (AQI 210, River Levels) — hardcoded, wire to real data later
- [ ] Map screen heatmap layer — verify hazard zone data loads from Supabase
- [ ] Report hazard screen — uploads go to Supabase storage, verify bucket policy allows it
- [ ] AQI scan screen — async context warnings remain (use_build_context_synchronously) at lines 92 and 105

---

## BACKEND / DATA

- [ ] Flask server (ecoalert-backend) — needs to run with Wi-Fi IP for Android device
      Run: python app.py --host 0.0.0.0
      Then: flutter run --dart-define=UPLOAD_API_BASE_URL=http://<LAN_IP>:5000
- [ ] ML model status screen — connects to Flask /model-status endpoint, needs server running
- [ ] Flood prediction model — wired through FloodProvider → Open-Meteo rainfall + ML backend
- [ ] NDMA/emergency broadcast — inserts into Supabase `alerts` table, verify FCM push triggers

---

## NOTIFICATIONS

- [ ] FCM (Firebase Cloud Messaging) — kept for push notifications only, Supabase handles auth/data
- [ ] Notification routing on tap — deep link to correct screen (alert detail, AQI, flood)
- [ ] Alert settings (flood/smog/heat toggles, radius, AQI threshold) — saved in SharedPreferences, wire to FCM topic subscription

---

## ANDROID BUILD

- [ ] Test on physical device: Samsung SM-N950F
      Command: flutter run -d ce0717173c9374120c7e
- [ ] Release build not yet tested — run flutter build apk --release before submission
- [ ] Check permissions: location (fine + coarse), camera (for report photo), internet

---

## MINOR / POLISH

- [ ] upload_service.dart lines 42 and 63 — `prefer_const_declarations` lint warnings
- [ ] browser_online_web.dart — `avoid_web_libraries_in_flutter` warning (web-only file, safe to ignore)
- [ ] Long city names in home header _SplitFlapText — capped at 10 chars, verify looks good on device
- [ ] Dark mode toggle in Settings — test it actually persists across restarts
- [ ] Health conditions (asthma/heart/elderly) — affect AQI threshold label display, verify the logic in _effectiveAqiLabel
