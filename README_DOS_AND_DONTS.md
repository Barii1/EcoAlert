# EcoAlert Team Do's and Don'ts

This document is the team checklist for daily development decisions.
It is based on the current repository state as of May 2026.

## 1) Team Do's

1. Keep app state in Providers.
   Use providers in `lib/providers/` as the source of truth for loading, errors, and cached state.

2. Follow startup loading pattern from home screen.
   For context-dependent startup calls, use `WidgetsBinding.instance.addPostFrameCallback`.

3. Use real + fallback data strategy.
   Keep the pattern already used in AQI/Flood providers: real API first, local/demo fallback second, cache fallback for offline.

4. Preserve offline behavior.
   When online calls fail, read cached data from `CacheService` before showing an error.

5. Keep auth mode explicit.
   Respect Firebase mode vs demo mode in `AuthProvider`, and keep transitions clean (init/dispose Firestore streams correctly).

6. Keep routes centralized.
   Add new routes in `main.dart` and reuse existing transition patterns (fade-through and slide-up).

7. Keep UI components reusable.
   Add presentational pieces to `lib/widgets/` instead of growing large screen files.

8. Validate changes before merge.
   Run at least: `flutter analyze` and `flutter test`.

9. Keep secrets and keys out of source.
   Prefer `--dart-define` and environment variables for deploy-time values.

10. Update docs when behavior changes.
   If you change architecture, endpoints, or setup steps, update README files in the same PR.

## 2) Team Don'ts

1. Do not hardcode city assumptions.
   Avoid forcing Lahore for all users when location or profile city is available.

2. Do not ship debug/demo shortcuts in release.
   Keep demo login and test-only flows behind debug guards.

3. Do not commit environment artifacts.
   Never commit `.env`, local virtual environments, generated build output, or machine-specific config.

4. Do not introduce direct API calls from widgets.
   Keep networking in services/providers, not in UI widgets.

5. Do not bypass provider loading/error state.
   Every async feature should expose loading and error states to UI.

6. Do not add new map stacks without team decision.
   The app currently uses `flutter_map` + OSM; avoid mixing parallel map implementations without a migration plan.

7. Do not leave production URLs hardcoded for local networks.
   LAN and emulator URLs are useful for development only and must be replaced by deploy config.

8. Do not rely on synthetic data silently.
   If using demo/simulated values, label them clearly in UI or docs.

## 3) Release Gate (Must Pass Before Final Build)

1. Firebase auth and Firestore rules validated.
2. No debug-only auth paths in release mode.
3. Backend deployed and reachable from mobile/web clients.
4. All required API keys supplied through secure config.
5. No secrets or local environment files tracked in git.
6. Critical flows tested: login, location, AQI, flood, alerts, report submission.

## 4) Current Application Progress (May 2026)

### Completed / Working

1. Core Flutter architecture is in place (Provider + Material 3 + routed navigation).
2. Multi-screen app is implemented (Home, Map, Alerts, Community, Learn, Profile, Admin, Auth flows).
3. AQI pipeline exists with fallback and cache behavior.
4. Flood risk pipeline exists with backend-first prediction and local calculator fallback.
5. Weather integration is active via Open-Meteo.
6. Alert and report modules are wired for Firebase streams, with demo-safe fallbacks.
7. Offline banner/cached mode behavior is present in home flows.
8. Backend health/model status UI is available for diagnostics.

### In Progress / Partially Complete

1. Theme preference loading exists, but app theme mode is still fixed to dark in `main.dart`.
2. City usage is mixed; several startup paths still default to Lahore.
3. Backend URL and API config still include local development values in config.
4. AQI model prediction endpoint is currently pass-through in app service (real AQI ML path not fully deployed).

### Pending / High Priority

1. Production hardening of Firestore admin logic and role handling.
2. Remove or isolate demo-only behavior for release builds.
3. Final backend deployment and environment-based URL/key configuration.
4. Secrets and local environment hygiene audit (`.env`, `.venv`, and related files).
5. End-to-end regression pass on real device and web before final presentation.

## 5) Suggested Branch Policy

1. Use feature branches per module (auth/map/alerts/backend/model).
2. Keep PRs small and focused.
3. Require one reviewer and passing analyze/test checks before merge.
4. Include doc update in every PR that changes behavior or setup.
