class CityMappings {
  static const Map<String, String> waqiStationIds = {
    'lahore': 'lahore',
    'islamabad': 'islamabad',
    'karachi': 'karachi',
    'faisalabad': 'faisalabad',
    'peshawar': 'peshawar',
    'multan': 'multan',
    'rawalpindi': 'rawalpindi',
  };

  static const Map<String, String> owmCityNames = {
    'lahore': 'Lahore,PK',
    'islamabad': 'Islamabad,PK',
    'karachi': 'Karachi,PK',
    'faisalabad': 'Faisalabad,PK',
    'peshawar': 'Peshawar,PK',
    'multan': 'Multan,PK',
    'rawalpindi': 'Rawalpindi,PK',
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

  static String getWaqiStation(String city) =>
      waqiStationIds[city.toLowerCase()] ?? 'lahore';

  static String getOwmCity(String city) =>
      owmCityNames[city.toLowerCase()] ?? 'Lahore,PK';

  static List<String> get allCities => owmCityNames.keys.toList();
}
