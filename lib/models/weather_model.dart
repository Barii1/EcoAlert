/// One data point in an hourly temperature series.
class HourlyWeatherPoint {
  const HourlyWeatherPoint({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
}

class DailyWeatherForecast {
  const DailyWeatherForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.weatherCode,
    required this.precipitationProbability,
  });

  final DateTime date;
  final double tempMin;
  final double tempMax;
  final int weatherCode;
  final int precipitationProbability;
}

/// Current weather conditions for display in the weather widget.
class WeatherCondition {
  const WeatherCondition({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
    required this.city,
    required this.timestamp,
    this.uvIndex = 0,
    this.visibility = 0,
    this.pressure = 0,
    this.tempMin,
    this.tempMax,
    this.hourly = const [],
    this.daily = const [],
  });

  final double temperature; // Celsius
  final double feelsLike;
  final int humidity; // 0-100%
  final double windSpeed; // km/h
  final int windDirection; // degrees
  final int weatherCode; // WMO weather code
  final String city;
  final DateTime timestamp;
  final double uvIndex;
  final double visibility; // km
  final double pressure; // hPa
  final double? tempMin;
  final double? tempMax;

  /// 24-hour series starting from midnight of today (one point per hour).
  final List<HourlyWeatherPoint> hourly;
  final List<DailyWeatherForecast> daily;

  /// Human-readable weather description from WMO code.
  String get description {
    switch (weatherCode) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
        return 'Light Rain';
      case 63:
        return 'Moderate Rain';
      case 65:
        return 'Heavy Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snowfall';
      case 77:
        return 'Snow Grains';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with Hail';
      default:
        return 'Unknown';
    }
  }

  /// Weather icon name (uses material icons).
  String get iconName {
    final hour = timestamp.hour;
    final isNight = hour < 6 || hour >= 19;

    switch (weatherCode) {
      case 0:
        return isNight ? 'nights_stay' : 'wb_sunny';
      case 1:
        return isNight ? 'nights_stay' : 'wb_sunny';
      case 2:
        return 'cloud_queue';
      case 3:
        return 'cloud';
      case 45:
      case 48:
        return 'foggy';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'grain';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'water_drop';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'ac_unit';
      case 95:
      case 96:
      case 99:
        return 'thunderstorm';
      default:
        return 'cloud';
    }
  }

  /// Wind direction as compass string.
  String get windDirectionLabel {
    if (windDirection >= 337 || windDirection < 23) return 'N';
    if (windDirection < 68) return 'NE';
    if (windDirection < 113) return 'E';
    if (windDirection < 158) return 'SE';
    if (windDirection < 203) return 'S';
    if (windDirection < 248) return 'SW';
    if (windDirection < 293) return 'W';
    return 'NW';
  }

  factory WeatherCondition.fromOpenMeteo(
      Map<String, dynamic> data, String city) {
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final daily = data['daily'] as Map<String, dynamic>?;
    final hourlyData = data['hourly'] as Map<String, dynamic>?;

    double? tempMin;
    double? tempMax;
    if (daily != null) {
      final mins = daily['temperature_2m_min'] as List<dynamic>?;
      final maxs = daily['temperature_2m_max'] as List<dynamic>?;
      if (mins != null && mins.isNotEmpty) {
        tempMin = (mins[0] as num).toDouble();
      }
      if (maxs != null && maxs.isNotEmpty) {
        tempMax = (maxs[0] as num).toDouble();
      }
    }

    final dailyForecast = <DailyWeatherForecast>[];
    if (daily != null) {
      final times = daily['time'] as List<dynamic>?;
      final mins = daily['temperature_2m_min'] as List<dynamic>?;
      final maxs = daily['temperature_2m_max'] as List<dynamic>?;
      final codes = daily['weather_code'] as List<dynamic>?;
      final precip = daily['precipitation_probability_max'] as List<dynamic>?;

      if (times != null && mins != null && maxs != null) {
        for (var i = 0; i < times.length; i++) {
          if (i >= mins.length || i >= maxs.length) continue;
          final date = DateTime.tryParse(times[i] as String? ?? '');
          if (date == null) continue;
          dailyForecast.add(DailyWeatherForecast(
            date: date,
            tempMin: (mins[i] as num?)?.toDouble() ?? 0,
            tempMax: (maxs[i] as num?)?.toDouble() ?? 0,
            weatherCode: (codes != null && i < codes.length)
                ? (codes[i] as num?)?.toInt() ?? 0
                : 0,
            precipitationProbability: (precip != null && i < precip.length)
                ? (precip[i] as num?)?.toInt() ?? 0
                : 0,
          ));
        }
      }
    }

    final hourly = <HourlyWeatherPoint>[];
    if (hourlyData != null) {
      final times = hourlyData['time'] as List<dynamic>?;
      final temps = hourlyData['temperature_2m'] as List<dynamic>?;
      final codes = hourlyData['weather_code'] as List<dynamic>?;
      if (times != null && temps != null) {
        for (var i = 0; i < times.length; i++) {
          final t = DateTime.tryParse(times[i] as String? ?? '');
          if (t == null) continue;
          hourly.add(HourlyWeatherPoint(
            time: t,
            temperature: (temps[i] as num?)?.toDouble() ?? 0,
            weatherCode: (codes != null && i < codes.length)
                ? (codes[i] as num?)?.toInt() ?? 0
                : 0,
          ));
        }
      }
    }

    return WeatherCondition(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      windDirection: (current['wind_direction_10m'] as num?)?.toInt() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      city: city,
      timestamp: DateTime.now(),
      uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0,
      visibility: (current['visibility'] as num?)?.toDouble() ?? 0,
      pressure: (current['surface_pressure'] as num?)?.toDouble() ?? 0,
      tempMin: tempMin,
      tempMax: tempMax,
      hourly: hourly,
      daily: dailyForecast,
    );
  }
}
