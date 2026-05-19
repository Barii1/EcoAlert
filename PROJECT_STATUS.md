# EcoAlert — Project status & work order

Work **one item at a time**. Mark ✅ only when tested on a real device or emulator.

---

## Phase 1 — Foundation (do first)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.1 | Remove demo auth & fake data | ✅ Done | Demo services deleted; real APIs + cache |
| 1.2 | Firebase-only auth + route guards | ✅ Done | `AuthGate`, `AdminGate`, logout fix |
| 1.3 | App compiles (`flutter analyze` clean) | ✅ Done | Zero analyzer errors; encoding fixed |
| 1.4 | Commit Phase 1 | ✅ Done | Commit 41479e7 on main branch |

---

## Phase 2 — Firebase & sign-in (blocking for real users)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.1 | Google Sign-In SHA fingerprints | ⬜ Pending | ApiException 10 on Android |
| 2.2 | Email/password login E2E test | ⬜ Pending | Sign up → verify → home |
| 2.3 | iOS Firebase (`firebase_options.dart`) | ⬜ Pending | Add iOS app in Firebase Console |
| 2.4 | Android release signing | ⬜ Pending | Play Store keystore |

---

## Phase 3 — Admin & data (after auth works)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.1 | Admin report approval flow | ⬜ Pending | `admin_report_management_screen.dart` |
| 3.2 | Admin content CRUD | ⬜ Pending | Replace TODOs in content management |
| 3.3 | GPS → city for AQI/flood/weather | ⬜ Pending | Stop defaulting to Lahore only |
| 3.4 | OpenWeather API key | ⬜ Pending | `--dart-define=OPENWEATHER_API_KEY=` |

---

## Phase 4 — Quality & release

| # | Task | Status | Notes |
|---|------|--------|-------|
| 4.1 | Push notifications on device | ⬜ Pending | FCM + routing |
| 4.2 | Alert settings persistence | ⬜ Pending | Save to Firestore/SharedPreferences |
| 4.3 | Provider/unit tests | ⬜ Pending | Auth, alerts, AQI |
| 4.4 | Release build on physical device | ⬜ Pending | |

---

## Already done ✅

- Flutter UI (home, map, alerts, learn, profile, admin shells)
- Provider state management
- WAQI AQI + OpenWeather rainfall + ML predict service
- Offline cache (`CacheService`)
- Firestore rules (admin from user doc; users delete own reports)
- Railway backend config (optional; skipped for now)
- Theme preference (light/dark)
- Demo login buttons removed
- Map uses OpenStreetMap tiles (Mapbox token optional)

---

## Skipped / deferred

- Railway production URL (per team decision)
- Mapbox tiles (OSM works without token)
- i18n, Analytics, App Store listing

---

*Update this file when each phase item is completed.*
