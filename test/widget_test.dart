import 'package:flutter_test/flutter_test.dart';
import 'package:ecoalert/main.dart';
import 'package:ecoalert/providers/alert_provider.dart';
import 'package:ecoalert/providers/auth_provider.dart';
import 'package:ecoalert/providers/report_provider.dart';
import 'package:ecoalert/providers/theme_provider.dart';

void main() {
  testWidgets('App shows splash screen on launch', 
      (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider(useFirebase: false);
    await authProvider.initAuth();
    final alertProvider = AlertProvider(firestoreService: null);
    final reportProvider = ReportProvider(firestoreService: null);
    await alertProvider.init();
    await reportProvider.init();
    await tester.pumpWidget(EcoAlertApp(
      themeProvider: themeProvider,
      authProvider: authProvider,
      useFirebase: false,
      firestoreService: null,
      alertProvider: alertProvider,
      reportProvider: reportProvider,
    ));
    expect(find.text('EcoAlert'), findsOneWidget);
  });
}
