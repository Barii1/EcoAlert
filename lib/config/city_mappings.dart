/// Maps Pakistani city display names to API-specific identifiers.
class CityMappings {
  CityMappings._();

  /// WAQI station feed names.
  /// Find station IDs at: https://aqicn.org/city/pakistan/
  static const Map<String, String> waqiStations = {
    'Lahore': 'lahore',
    'Islamabad': 'islamabad',
    'Karachi': 'karachi',
    'Faisalabad': 'faisalabad',
    'Peshawar': 'peshawar',
    'Multan': 'multan',
    'Rawalpindi': 'rawalpindi',
    'Quetta': 'quetta',
  };

  /// OpenWeatherMap city query strings (city,country code).
  static const Map<String, String> owmCities = {
    'Lahore': 'Lahore,PK',
    'Islamabad': 'Islamabad,PK',
    'Karachi': 'Karachi,PK',
    'Faisalabad': 'Faisalabad,PK',
    'Peshawar': 'Peshawar,PK',
    'Multan': 'Multan,PK',
    'Rawalpindi': 'Rawalpindi,PK',
    'Quetta': 'Quetta,PK',
  };

  /// Lat/lon for cities (used for forecast API).
  static const Map<String, List<double>> cityCoords = {
    'Lahore': [31.5204, 74.3587],
    'Islamabad': [33.6844, 73.0479],
    'Karachi': [24.8607, 67.0011],
    'Faisalabad': [31.4187, 73.0791],
    'Peshawar': [34.0151, 71.5249],
    'Multan': [30.1575, 71.5249],
    'Rawalpindi': [33.5651, 73.0169],
    'Quetta': [30.1798, 66.9750],
  };

  /// Get WAQI feed name for a city. Falls back to lowercase city name.
  static String getWaqiStation(String city) =>
      waqiStations[city] ?? city.toLowerCase();

  /// Get OWM city query for a city.
  static String getOwmCity(String city) =>
      owmCities[city] ?? '$city,PK';

  /// List of all supported cities.
  static List<String> get allCities => waqiStations.keys.toList();
}
