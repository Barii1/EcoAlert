import 'package:ecoalert/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('environment-backed secrets are empty by default', () {
    expect(AppConfig.waqiToken, isEmpty);
    expect(AppConfig.openWeatherApiKey, isEmpty);
  });

  test('upload api base url has safe local default', () {
    expect(AppConfig.uploadApiBaseUrl, 'http://10.0.2.2:5000');
  });
}
