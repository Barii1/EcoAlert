import '../models/aqi_model.dart';

abstract class AqiDataSource {
  Future<AqiReading> fetchCurrent(
    String city, {
    double? latitude,
    double? longitude,
  });
  Future<List<HourlyAqiPoint>> fetchHourly(
    String city, {
    int hours = 24,
    double? latitude,
    double? longitude,
  });
}
