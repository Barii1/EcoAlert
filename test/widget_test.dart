import 'package:flutter_test/flutter_test.dart';
import 'package:ecoalert/main.dart';
import 'package:ecoalert/providers/alert_provider.dart';
import 'package:ecoalert/providers/auth_provider.dart';
import 'package:ecoalert/providers/hazard_zone_provider.dart';
import 'package:ecoalert/providers/report_provider.dart';
import 'package:ecoalert/providers/theme_provider.dart';

void main() {
  testWidgets('App shows splash screen on launch',
      (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider();
    final alertProvider = AlertProvider(supabaseService: null);
    final reportProvider = ReportProvider(supabaseService: null);
    final hazardZoneProvider = HazardZoneProvider(supabaseService: null);
    await alertProvider.init();
    await reportProvider.init();
    await tester.pumpWidget(EcoAlertApp(
      themeProvider: themeProvider,
      authProvider: authProvider,
      alertProvider: alertProvider,
      reportProvider: reportProvider,
      hazardZoneProvider: hazardZoneProvider,
    ));
    expect(find.text('EcoAlert'), findsOneWidget);
  });
}
