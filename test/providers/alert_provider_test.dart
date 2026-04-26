import 'package:ecoalert/providers/alert_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo alerts use normalized uppercase severities', () async {
    final provider = AlertProvider(firestoreService: null);
    await provider.init();

    expect(provider.alerts, isNotEmpty);
    for (final alert in provider.alerts) {
      expect(alert.severity, alert.severity.toUpperCase());
    }
  });
}
