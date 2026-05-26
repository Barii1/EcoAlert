import 'package:ecoalert/providers/report_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReportProvider initializes without supabase', () async {
    final provider = ReportProvider(supabaseService: null);
    await provider.init();
    expect(provider.reports, isEmpty);
  });
}
