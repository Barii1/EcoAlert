import '../models/flood_model.dart';

abstract class WeatherDataSource {
  Future<RainfallData> fetchRainfall(String city);
}
