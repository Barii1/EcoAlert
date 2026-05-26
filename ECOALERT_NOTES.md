# EcoAlert — Project Notes & Todo
> Last updated: May 2026 | Haseeb's responsibility scope

---

## ✅ Confirmed Info
- **Project Title:** EcoAlert: An AI-Powered Environmental Hazard Prediction and Alert System for Pakistan
- **Category:** AI
- **GitHub:** https://github.com/Barii1/EcoAlert

## 👥 Team Split
| Partner | Responsibility |
|---------|---------------|
| Haseeb | Backend (Flask), Supabase/Postgres, API integrations, Geolocation, Model wiring, Offline mode |
| Partner 2 | UI/UX, Firebase Console |
| Partner 3 | ML Model training |

---

## 🔴 Critical Bugs to Fix (When You Have Time)

### 1. Firestore Admin Rules Are Broken
- **File:** `firestore.rules`
- **Problem:** Rules check `request.auth.token.role == 'admin'` (Firebase custom claim) but the app stores role in a Firestore *document*, not as a custom claim. So `isAdmin()` always returns false.
- **Fix Options:**
  - Option A: Set custom claims server-side via Firebase Admin SDK in a Cloud Function triggered on user creation
  - Option B (quick): Change Firestore rules to read from the document instead — but this is less secure

### 2. Demo Login Has No Release Guard
- **File:** `lib/providers/auth_provider.dart`
- **Problem:** `demoAdminLogin()`, `demoPremiumLogin()` etc. are accessible in production builds
- **Fix:** Wrap all demo login methods in `if (kDebugMode)` or remove before final submission

### 3. `.env` File May Be in Git
- **File:** `backend/ecoalert-backend/.env`
- **Problem:** Real credentials (Supabase key, Firebase project ID) may be committed
- **Fix:** Add `.env` to `.gitignore`, rotate any exposed keys immediately

---

## 🟠 Major Issues to Fix

### 4. Location Hardcoded to Lahore
- **Files:** `lib/main.dart` lines where `loadForCity('Lahore')` is called
- **Problem:** Every user sees Lahore data regardless of their GPS location
- **Fix:** After LocationProvider gets GPS, call `loadForCity(detectedCity)` on AqiProvider and FloodProvider

### 5. Hourly AQI Data is Fake/Synthetic
- **File:** `lib/services/waqi_aqi_source.dart` — `fetchHourly()` method
- **Problem:** Generates made-up data using a math formula instead of real historical data
- **Fix Options:**
  - Option A: Use Open-Meteo air quality API for real hourly PM2.5/PM10 (free, no key)
  - Option B: Store real hourly readings in Firestore via a Cloud Function and fetch from there

### 6. Flask Backend Upload URL is Emulator-Only
- **File:** `lib/config/app_config.dart`
- **Default:** `http://10.0.2.2:5000` — only works on Android emulator
- **Fix:** Deploy Flask to Render/Railway and set real URL via `--dart-define=UPLOAD_API_BASE_URL=https://...`

### 7. `.venv` Folder Committed to Repo
- **Path:** `backend/ecoalert-backend/.venv/`
- **Fix:** Add `.venv/` to `backend/ecoalert-backend/.gitignore` and remove from git tracking

---

## 🟡 Moderate Issues

### 8. ThemeMode Hardcoded to Dark
- **File:** `lib/main.dart`
- **Problem:** `themeMode: ThemeMode.dark` is hardcoded, ThemeProvider preference loading is useless
- **Fix:** Change to `themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light`

### 9. Users Can't Delete Their Own Posts/Reports
- **File:** `firestore.rules`
- **Problem:** `allow delete: if false` blocks all user deletes
- **Fix:** Add `allow delete: if request.auth.uid == resource.data.reporterUid`

### 10. No Local Data Caching
- **Status:** ✅ Being fixed now (cache_service.dart)
- `shared_preferences` is in pubspec but not used for data caching

### 11. Google Sign-In Broken (ApiException 10)
- **File:** `lib/providers/auth_provider.dart` — error message comment
- **Fix:** Add correct SHA-1 and SHA-256 fingerprints in Firebase Console → Project Settings → Android App

---

## 🗺️ API Keys Needed

### Maps
| Service | Tier | Get Key At | Notes |
|---------|------|-----------|-------|
| **Mapbox** | Free (50k loads/month) | mapbox.com → Account → Tokens | Already wired in app as `MAPBOX_PUBLIC_TOKEN` |
| **Stadia Maps** | Free for open-source | client.stadiamaps.com | Better-looking tiles |
| **MapTiler** | Free (100k tiles/month) | maptiler.com | Good satellite tiles |

### Environmental Data
| API | Free Tier | Key Required | Best For |
|-----|-----------|-------------|----------|
| **Open-Meteo** | Completely free | ❌ No key | Weather + AQI + Flood forecasts |
| **WAQI** | Free token | ✅ aqicn.org/api | Real-time AQI (already integrated) |
| **OpenWeatherMap** | 1000 calls/day | ✅ openweathermap.org | Rainfall data (already integrated) |
| **NASA FIRMS** | Free | ✅ firms.modaps.eosdis.nasa.gov | Wildfire hotspots |
| **IQAir Community** | Free tier | ✅ iqair.com/dashboard | Richer AQI pollutant data |
| **GloFAS / Copernicus** | Free (registration) | ✅ cds.climate.copernicus.eu | Flood river discharge |
| **Tomorrow.io** | 500 calls/day free | ✅ tomorrow.io | Hyper-local weather |
| **BreezoMeter** | Paid ~$99/month | Paid | Best AQI accuracy |
| **Ambee** | Paid ~$49/month | Paid | Bundle: air, disasters, pollen |

---

## 🤖 Model Integration Plan
> Status: Infrastructure built — waiting for model file from Partner 3

### What's been set up:
- Flask endpoint: `POST /api/predict/flood` — accepts rainfall features, returns risk level
- Flask endpoint: `POST /api/predict/aqi` — accepts pollutant readings, returns AQI prediction
- Flutter service: `lib/services/remote_predict_service.dart` — calls the Flask API
- Fallback: If model file not found OR server offline → uses rule-based calculator

### When Partner 3 gives you the model file:
1. Drop `flood_model.pkl` (or `.h5`/`.pt`) into `backend/ecoalert-backend/models/`
2. Drop `aqi_model.pkl` into same folder
3. Update `backend/ecoalert-backend/services/model_service.py` — set correct feature column names
4. Redeploy Flask server
5. App automatically uses the real model — no Flutter code changes needed

### Feature contract (what Flutter sends to Flask):
**Flood:** `rainfall_24h`, `rainfall_48h`, `rainfall_per_hour`, `city`, `temperature`, `humidity`
**AQI:** `pm25`, `pm10`, `no2`, `o3`, `co`, `temperature`, `humidity`, `wind_speed`

---

## 📶 Online / Offline Architecture
> Status: ✅ Being built now

### How it works:
- Every time data loads successfully → saved to `SharedPreferences` with a timestamp
- When offline (ConnectivityProvider detects no internet) → load from cache
- Cache shown with a "Last updated X minutes ago" banner
- When back online → auto-refresh and update cache
- **No internet + no cache** → show friendly empty state (not a crash)

### Cache TTL (Time To Live):
| Data Type | Cache Duration |
|-----------|---------------|
| AQI reading | 1 hour |
| Flood risk | 2 hours |
| Weather | 1 hour |
| Alerts | 30 minutes |

---

## 📍 Geolocation Danger Zone — Implementation Plan
> Status: Not yet started

### Recommended Approach (Hybrid):
1. **Client-side polygon check** — danger zones as GeoJSON polygons stored in Firestore
2. **Native geofencing** — OS-level circular fences around known flood-prone river banks
3. **Server FCM push** — Cloud Function checks user city vs. danger threshold every 15 min

### Packages needed:
- `geofence_service` (pub.dev) — for native geofencing
- Already have: `geolocator`, `firebase_messaging`

### What happens when user enters danger zone:
- Red banner appears on home screen
- Push notification sent (even if app closed)
- Map screen highlights danger zone in red
- "Safe Routes" button appears → navigates to RouteInfoScreen

---

## 🚀 Deployment Checklist (Before Final Presentation)
- [ ] Deploy Flask backend to Render.com or Railway (free)
- [ ] Set `UPLOAD_API_BASE_URL` dart-define to production URL
- [ ] Set `WAQI_API_KEY` dart-define
- [ ] Set `OPENWEATHER_API_KEY` dart-define
- [ ] Set `MAPBOX_PUBLIC_TOKEN` dart-define
- [ ] Fix Firestore admin custom claims (or update rules)
- [ ] Add SHA-1/SHA-256 to Firebase for Google Sign-In
- [ ] Remove `.venv` from git
- [ ] Guard demo login behind `kDebugMode`
- [ ] Drop trained model `.pkl` files into `backend/models/`
- [ ] Test on real Android device (not emulator)

---
*Notes compiled from code review session — May 2026*
