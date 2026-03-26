import '../models/aqi_model.dart';

abstract class AqiDataSource {
  Future<AqiReading> fetchCurrent(String city);
  Future<List<HourlyAqiPoint>> fetchHourly(String city, {int hours = 24});
}
