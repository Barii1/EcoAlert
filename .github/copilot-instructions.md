# Copilot instructions for EcoAlert (Flutter)

## Project orientation
- App entrypoint is [lib/main.dart](../lib/main.dart): `EcoAlertApp` sets up `MultiProvider` and `MaterialApp` (Material 3).
- Main navigation is a bottom `NavigationBar` switching between screens: Home / Map / Alerts / Learn.
- State management is `provider` with `ChangeNotifier` classes in [lib/providers/](../lib/providers/).

## State + data flow (Provider)
- Providers are created at the app root (see `MultiProvider` in [lib/main.dart](../lib/main.dart)).
- Screen code typically reads providers via `Provider.of<T>(context)` or `Consumer<T>`.
- `HomeScreen` triggers initial async loads in `initState()` using `WidgetsBinding.instance.addPostFrameCallback` (see [lib/screens/home_screen.dart](../lib/screens/home_screen.dart)).
  - Follow that pattern for any `context`-dependent startup work.

## Key modules and conventions
- Models live in [lib/models/](../lib/models/) and commonly implement `fromJson`/`toJson` (example: [lib/models/alert_model.dart](../lib/models/alert_model.dart)).
- Reusable UI pieces live in [lib/widgets/](../lib/widgets/) and are mostly presentational (examples: [lib/widgets/hazard_card.dart](../lib/widgets/hazard_card.dart), [lib/widgets/alert_card.dart](../lib/widgets/alert_card.dart)).
- “Backend” calls are currently mocked:
  - [lib/providers/alert_provider.dart](../lib/providers/alert_provider.dart) uses `Future.delayed` + hardcoded demo alerts.
  - Firebase dependencies exist but are commented out in [pubspec.yaml](../pubspec.yaml) (“disabled for web build”). Don’t assume Firebase is wired up.

## Maps
- Map UI is currently Mapbox, not Google Maps:
  - [lib/screens/map_screen.dart](../lib/screens/map_screen.dart) uses `mapbox_maps_flutter` and creates annotations (circle hazards + safe route polyline).
  - Mapbox access token is a constant in [lib/config/app_config.dart](../lib/config/app_config.dart) (`mapboxAccessToken`).
- `google_maps_flutter` is still in dependencies; treat it as legacy/alternative until you confirm which map implementation a change should target.

## Location
- Location permissions + geocoding are encapsulated in [lib/providers/location_provider.dart](../lib/providers/location_provider.dart).
- UI typically reads `LocationProvider` state (`isLoading`, `errorMessage`, `currentCity`) rather than calling platform APIs directly.

## Developer workflows (Windows)
- Install deps: `flutter pub get`
- Run (Android/desktop): `flutter run`
- Run (web): `flutter run -d chrome`
- Tests: `flutter test`

## Lints/style
- Lints come from `flutter_lints` via [analysis_options.yaml](../analysis_options.yaml).
- Prefer the existing style: Material 3 widgets, simple `StatelessWidget` presentational components, and Provider for state.

## Repo gotchas to watch for
- The default test file [test/widget_test.dart](../test/widget_test.dart) appears out of sync with the current app entry (`MyApp` is referenced but the app class is `EcoAlertApp`). If you touch tests, update them to match current code.
- Secrets: Mapbox token is currently committed in config; don’t introduce new secrets in code—use a similar centralized config approach, or document required keys in README if needed.
