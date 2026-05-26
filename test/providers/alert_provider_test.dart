import 'package:ecoalert/providers/alert_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AlertProvider initializes without supabase', () async {
    final provider = AlertProvider(supabaseService: null);
    await provider.init();
    expect(provider.alerts, isEmpty);
  });
}
