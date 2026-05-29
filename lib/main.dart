import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'config/app_colors.dart';
import 'config/app_config.dart';
import 'config/app_navigator.dart';
import 'services/notification_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_root.dart';
import 'screens/map_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/alert_settings_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_conditions_screen.dart';
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
import 'screens/settings_screen.dart';
import 'screens/aqi_detail_screen.dart';
import 'screens/flood_detail_screen.dart';
import 'screens/model_status_screen.dart';
import 'screens/aqi_image_classify_screen.dart';

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
import 'providers/hazard_zone_provider.dart';
import 'providers/community_provider.dart';
import 'models/user_model.dart';
import 'utils/page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — FCM push notifications only.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[EcoAlert] Firebase initialized (FCM only)');
  } catch (e) {
    debugPrint('[EcoAlert] Firebase init failed (FCM unavailable): $e');
  }

  // Supabase — Auth + DB + Storage + Realtime.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  final supabaseClient = Supabase.instance.client;
  final supabaseService = SupabaseService(supabaseClient);
  final supabaseAuthService = SupabaseAuthService(supabaseClient);

  // Load saved theme before runApp so first frame uses correct theme.
  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  final authProvider = AuthProvider(
    supabaseAuthService: supabaseAuthService,
    supabaseService: supabaseService,
    useSupabase: true,
  );
  await authProvider.tryAutoLogin();

  final alertProvider = AlertProvider(supabaseService: supabaseService);
  final reportProvider = ReportProvider(supabaseService: supabaseService);
  final hazardZoneProvider = HazardZoneProvider(supabaseService: supabaseService);

  authProvider.onAuthLoginSuccess = () {
    final user = authProvider.currentUser;
    reportProvider.init(
      isAdmin: authProvider.isAdmin,
      uid: user?.id,
    );
    hazardZoneProvider.init();
    if (user?.id != null) {
      NotificationService.instance.saveFcmToken(user!.id).catchError((_) {});
    }
  };

  authProvider.onAuthLogoutSuccess = (uid) {
    if (uid != null) {
      NotificationService.instance.removeFcmToken(uid).catchError((_) {});
    }
    reportProvider.init();
  };

  // Bootstrap public data (no auth required).
  await alertProvider.init();
  hazardZoneProvider.init();

  if (authProvider.isAuthenticated) {
    final user = authProvider.currentUser;
    await reportProvider.init(
      isAdmin: authProvider.isAdmin,
      uid: user?.id,
    );
  }

  // FCM push notifications.
  try {
    await NotificationService.instance.init();
    debugPrint('[EcoAlert] Notification service initialized');
    final uid = authProvider.currentUser?.id;
    if (uid != null) {
      NotificationService.instance.saveFcmToken(uid).catchError((_) {});
    }
  } catch (e) {
    debugPrint('[EcoAlert] FCM init failed: $e');
  }

  runApp(EcoAlertApp(
    themeProvider: themeProvider,
    authProvider: authProvider,
    alertProvider: alertProvider,
    reportProvider: reportProvider,
    hazardZoneProvider: hazardZoneProvider,
  ));
}

class EcoAlertApp extends StatelessWidget {
  const EcoAlertApp({
    super.key,
    required this.themeProvider,
    required this.authProvider,
    required this.alertProvider,
    required this.reportProvider,
    required this.hazardZoneProvider,
  });

  final ThemeProvider themeProvider;
  final AuthProvider authProvider;
  final AlertProvider alertProvider;
  final ReportProvider reportProvider;
  final HazardZoneProvider hazardZoneProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider<AlertProvider>.value(value: alertProvider),
        ChangeNotifierProvider(create: (_) => AqiProvider()..loadForCity('Lahore')),
        ChangeNotifierProvider(create: (_) => FloodProvider()..loadForCity('Lahore')),
        ChangeNotifierProvider(create: (_) => WeatherProvider()..loadForCity('Lahore')),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => DangerThemeProvider()),
        ChangeNotifierProvider<ReportProvider>.value(value: reportProvider),
        ChangeNotifierProvider<HazardZoneProvider>.value(value: hazardZoneProvider),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'EcoAlert',
            debugShowCheckedModeBanner: false,
            onGenerateRoute: (settings) {
              final routes = <String, Widget Function(RouteSettings)>{
                '/splash': (_) => const SplashScreen(),
                '/onboarding': (_) => const OnboardingScreen(),
                '/location': (_) => const LocationPromptScreen(),
                '/profile-setup': (_) => const ProfileSetupScreen(),
                '/login': (_) => const LoginScreen(),
                '/signup': (_) => const SignupScreen(),
                '/email-verification': (settings) {
                  final email = settings.arguments as String? ?? 'your email';
                  return EmailVerificationScreen(email: email);
                },
                '/terms': (_) => const TermsConditionsScreen(),
                '/privacy': (_) => const PrivacyPolicyScreen(),
                '/navigation': (_) => const MainNavigationScreen(),
                '/alert-detail': (_) => const AlertDetailScreen(),
                '/alert-settings': (_) => const AlertSettingsScreen(),
                '/route-info': (_) => const RouteInfoScreen(),
                '/report-hazard': (_) => const ReportHazardScreen(),
                '/report-confirmation': (_) => const ReportConfirmationScreen(),
                '/admin': (_) => const AdminDashboardScreen(),
                '/aqi-detail': (_) => const AqiDetailScreen(),
                '/flood-detail': (_) => const FloodDetailScreen(),
                '/model-status': (_) => const ModelStatusScreen(),
                '/aqi-scan': (_) => const AqiScanScreen(),
                '/aqi-image-classify': (_) => const AqiImageClassifyScreen(),
                '/alerts': (_) => const AlertsScreen(),
                '/profile': (_) => const ProfileScreen(),
                '/settings': (_) => const SettingsScreen(),
              };

              final pageBuilder = routes[settings.name];
              if (pageBuilder == null) return null;
              final page = pageBuilder(settings);

              const slideUpRoutes = {'/alert-detail', '/aqi-detail', '/flood-detail', '/report-hazard', '/aqi-scan', '/aqi-image-classify'};
              if (slideUpRoutes.contains(settings.name)) {
                return SlideUpPageRoute(page: page);
              }
              return FadeThroughPageRoute(page: page);
            },
            // Light theme
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF2C2C2E),
                secondary: const Color(0xFF555558),
                surface: const Color(0xFFF2F2F7),
                onSurface: const Color(0xFF111111),
                error: const Color(0xFFE03535),
              ),
              scaffoldBackgroundColor: const Color(0xFFF2F2F7),
              cardColor: Colors.white,
              textTheme: ThemeData.light().textTheme.apply(
                bodyColor: const Color(0xFF111111),
                displayColor: const Color(0xFF111111),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                foregroundColor: Color(0xFF111111),
                backgroundColor: Color(0xFFF2F2F7),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
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
                  backgroundColor: const Color(0xFF2C2C2E),
                  foregroundColor: Colors.white,
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
                        ? Colors.white
                        : const Color(0xFF888888)),
                trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFCCCCCC)),
              ),
            ),
            // Dark theme
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.primaryDim,
                surface: AppColors.bgSecondary,
                onSurface: AppColors.textPrimary,
                error: AppColors.danger,
              ),
              scaffoldBackgroundColor: AppColors.bgPrimary,
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
            themeMode: themeProvider.themeMode,
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
  AqiProvider? _aqiProvider;
  LocationProvider? _locationProvider;
  String _lastKnownCity = AppConfig.defaultCity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextAqiProvider = context.read<AqiProvider>();
    if (!identical(_aqiProvider, nextAqiProvider)) {
      _aqiProvider?.removeListener(_syncDangerThemeFromAqi);
      _aqiProvider = nextAqiProvider;
      _aqiProvider?.addListener(_syncDangerThemeFromAqi);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncDangerThemeFromAqi();
      });
    }

    final nextLocation = context.read<LocationProvider>();
    if (!identical(_locationProvider, nextLocation)) {
      _locationProvider?.removeListener(_onLocationChanged);
      _locationProvider = nextLocation;
      _locationProvider!.addListener(_onLocationChanged);
      // Sync immediately in case location was fetched before this screen loaded.
      _syncLocationToProviders();
    }
  }

  @override
  void dispose() {
    _aqiProvider?.removeListener(_syncDangerThemeFromAqi);
    _locationProvider?.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _syncDangerThemeFromAqi() {
    final aqi = _aqiProvider?.current;
    context.read<DangerThemeProvider>().updateFromAqi(aqi);
  }

  void _onLocationChanged() => _syncLocationToProviders();

  void _syncLocationToProviders() {
    final city = _locationProvider?.currentCity ?? AppConfig.defaultCity;
    if (city == _lastKnownCity) return;
    _lastKnownCity = city;
    if (!mounted) return;
    context.read<AqiProvider>().loadForCity(city);
    context.read<FloodProvider>().loadForCity(city);
    context.read<WeatherProvider>().loadForCity(city);
  }

  @override
  Widget build(BuildContext context) {
    final dangerTheme = context.watch<DangerThemeProvider>();

    final screens = <Widget>[
      const HomeScreen(),
      const MapScreen(),
      const AlertsScreen(),
      const CommunityScreen(),
      const LearnScreen(),
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
                    'Guest users can\'t report hazards. Please sign in to continue.',
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
              offset: const Offset(0, -2),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Transform.translate(
              offset: const Offset(0, -2),
              child: const Icon(Icons.notifications),
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
        ],
      ),
    );
  }
}
