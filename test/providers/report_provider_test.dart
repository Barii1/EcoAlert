import 'package:ecoalert/providers/report_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo mode addReport returns success and stores report', () async {
    final provider = ReportProvider(firestoreService: null);
    await provider.init();

    final ok = await provider.addReport(
      hazardType: 'Flood',
      details: 'Road underpass is submerged.',
      imageCount: 0,
      locationLabel: 'Lahore',
      reporterUid: 'u-1',
      reporterName: 'Tester',
    );

    expect(ok, isTrue);
    expect(provider.reports.length, 1);
    expect(provider.errorMessage, isNull);
  });
}
