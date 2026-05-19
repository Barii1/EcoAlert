/// API keys — prefer `--dart-define` at build time (never commit secrets).
class ApiKeys {
  static const String waqi = String.fromEnvironment(
    'WAQI_API_KEY',
    defaultValue: 'd39f794b34254c07cba21aa80400d33dcf3cb501',
  );

  /// Public Mapbox token (pk.*). Optional: maps use OpenStreetMap when empty.
  static const String mapbox = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
    defaultValue: '',
  );
}
