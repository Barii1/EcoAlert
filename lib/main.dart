import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_root.dart';
import 'screens/map_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/alert_settings_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/location_prompt_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/alert_detail_screen.dart';
import 'screens/route_info_screen.dart';
import 'screens/aqi_scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/community_screen.dart';
import 'screens/report_hazard_screen.dart';
import 'screens/report_confirmation_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/aqi_detail_screen.dart';
import 'screens/flood_detail_screen.dart';
import 'providers/alert_provider.dart';
import 'providers/aqi_provider.dart';
import 'providers/flood_provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/report_provider.dart';
import 'providers/danger_theme_provider.dart';
import 'providers/weather_provider.dart';
import 'models/user_model.dart';
import 'widgets/premium_ux.dart';
import 'utils/page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase on Android using google-services.json if present.
  // (We avoid committing secret API keys to the git repo.)
  bool firebaseReady = false;
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
      debugPrint('[EcoAlert] Firebase initialized successfully');
    } catch (e) {
      debugPrint('[EcoAlert] Firebase init failed, running in demo mode: $e');
    }
  } else {
    debugPrint('[EcoAlert] Web build — skipping Firebase init (demo mode)');
  }

  // Load theme preference before app starts
  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  // Create shared FirestoreService if Firebase is ready.
  final FirestoreService? firestoreService =
      firebaseReady ? FirestoreService() : null;

  // Initialize push notifications if Firebase is ready.
  if (firebaseReady) {
    await NotificationService.instance.init();
    debugPrint('[EcoAlert] Notification service initialized');
  }

  runApp(EcoAlertApp(
    themeProvider: themeProvider,
    useFirebase: firebaseReady,
    firestoreService: firestoreService,
  ));
}

class EcoAlertApp extends StatelessWidget {
  const EcoAlertApp({
    super.key,
    required this.themeProvider,
    this.useFirebase = false,
    this.firestoreService,
  });

  final ThemeProvider themeProvider;
  final bool useFirebase;
  final FirestoreService? firestoreService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(useFirebase: useFirebase)),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => AlertProvider(firestoreService: firestoreService)..init(),
        ),
        ChangeNotifierProvider(create: (_) => AqiProvider()..loadForCity('Lahore')),
        ChangeNotifierProvider(create: (_) => FloodProvider()..loadForCity('Lahore')),
        ChangeNotifierProvider(create: (_) => WeatherProvider()..loadForCity('Lahore')),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => DangerThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(
            firestoreService: firestoreService,
            storageService: useFirebase ? StorageService() : null,
          )..init(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'EcoAlert',
            debugShowCheckedModeBanner: false,
            onGenerateRoute: (settings) {
              final routes = <String, Widget>{
                '/splash': const SplashScreen(),
                '/onboarding': const OnboardingScreen(),
                '/location': const LocationPromptScreen(),
                '/profile-setup': const ProfileSetupScreen(),
                '/login': const LoginScreen(),
                '/signup': const SignupScreen(),
                '/navigation': const MainNavigationScreen(),
                '/alert-detail': const AlertDetailScreen(),
                '/alert-settings': const AlertSettingsScreen(),
                '/route-info': const RouteInfoScreen(),
                '/report-hazard': const ReportHazardScreen(),
                '/report-confirmation': const ReportConfirmationScreen(),
                '/admin': const AdminDashboardScreen(),
                '/aqi-detail': const AqiDetailScreen(),
                '/flood-detail': const FloodDetailScreen(),
                '/aqi-scan': const AqiScanScreen(),
                '/alerts': const AlertsScreen(),
              };

              final page = routes[settings.name];
              if (page == null) return null;

              // Use slide-up for detail/modal screens, fade-through for everything else.
              const slideUpRoutes = {'/alert-detail', '/aqi-detail', '/flood-detail', '/report-hazard', '/aqi-scan'};
              if (slideUpRoutes.contains(settings.name)) {
                return SlideUpPageRoute(page: page);
              }
              return FadeThroughPageRoute(page: page);
            },
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.primaryDim,
                surface: AppColors.bgSecondary,
                onSurface: AppColors.textPrimary,
                error: AppColors.danger,
              ),
              scaffoldBackgroundColor: AppColors.bgSecondary,
              cardColor: AppColors.bgCard,
              textTheme: ThemeData.dark().textTheme.apply(
                    bodyColor: AppColors.textPrimary,
                    displayColor: AppColors.textPrimary,
                  ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                foregroundColor: AppColors.textPrimary,
                backgroundColor: AppColors.bgPrimary,
              ),
              cardTheme: CardThemeData(
                color: AppColors.bgCard,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.primary
                        : AppColors.textDisabled),
                trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.borderSubtle),
              ),
            ),
            themeMode: ThemeMode.dark,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (!mounted) return;

      // Basic user upsell prompt (demo). Guest/admin/premium don't see it.
      if (auth.isBasic && !auth.hasShownUpgradePrompt) {
        auth.markUpgradePromptShown();
        await showUpgradePromptDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthProvider>().isPremium;
    final dangerTheme = context.watch<DangerThemeProvider>();

    // Update danger theme from AQI data whenever it changes.
    final aqiProvider = context.watch<AqiProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dangerTheme.updateFromAqi(aqiProvider.current);
    });

    final screens = <Widget>[
      const HomeScreen(),
      const MapScreen(),
      const AlertsScreen(),
      PremiumLock(
        locked: !isPremium,
        featureName: 'Community help network & emergency coordination',
        child: const CommunityScreen(),
      ),
      const LearnScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: screens[_currentIndex],
      floatingActionButton: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: dangerTheme.accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: dangerTheme.glowColor,
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            final role = context.read<AuthProvider>().currentRole;
            if (role == UserRole.general) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Guest users can’t report hazards. Please sign in to continue.',
                  ),
                ),
              );
              return;
            }

            Navigator.pushNamed(context, '/report-hazard');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add_alert,
            color: AppColors.textInverse,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bgPrimary,
        indicatorColor: dangerTheme.accentColor.withOpacity(0.2),
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Transform.translate(
              offset: Offset(0, -2),
              child: Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Transform.translate(
              offset: Offset(0, -2),
              child: Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
