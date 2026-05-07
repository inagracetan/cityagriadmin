import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'core/constants.dart';
import 'core/design_system.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_layout.dart';
import 'services/activity_form_provider.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/firebase_service.dart';
import 'services/navigation_provider.dart';
import 'services/settings_provider.dart';
import 'widgets/enhanced_states.dart';
import 'widgets/skeleton_loading.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Intl
  await initializeDateFormatting('en_US', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Offline Support
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<ActivityFormProvider>(
          create: (_) => ActivityFormProvider(),
        ),
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
      ],
      child: const LGUAgriApp(),
    ),
  );
}

class LGUAgriApp extends StatelessWidget {
  const LGUAgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textTheme = AppDesignSystem.createTextTheme(isDark: isDark);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appTitle,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            textTheme: textTheme,
            iconTheme: const IconThemeData(size: AppDesignSystem.iconSizeSmall),
            primaryIconTheme: const IconThemeData(
              size: AppDesignSystem.iconSizeSmall,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              tertiary: AppColors.accent,
              surface: AppColors.background,
              error: AppColors.error,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              iconTheme: const IconThemeData(
                size: AppDesignSystem.iconSizeSmall,
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.primary,
              centerTitle: false,
              elevation: 0,
              titleTextStyle: textTheme.headlineLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            dividerTheme: DividerThemeData(color: Slate.shade200, thickness: 1),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: AppDesignSystem.primaryButton(isDark: false),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusXLarge,
                ),
                side: const BorderSide(color: Slate.shade100, width: 1),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(AppDesignSystem.spacing20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusLarge,
                ),
                borderSide: const BorderSide(color: Slate.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusLarge,
                ),
                borderSide: const BorderSide(color: Slate.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusLarge,
                ),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            textTheme: textTheme,
            iconTheme: const IconThemeData(size: AppDesignSystem.iconSizeSmall),
            primaryIconTheme: const IconThemeData(
              size: AppDesignSystem.iconSizeSmall,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              tertiary: AppColors.accent,
              surface: AppColors.premiumNavy,
              error: AppColors.error,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.premiumNavy,
            appBarTheme: AppBarTheme(
              iconTheme: const IconThemeData(
                size: AppDesignSystem.iconSizeSmall,
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            cardTheme: CardThemeData(
              color: AppColors.premiumCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusXLarge,
                ),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
          ),
          home: const SelectionArea(child: AuthWrapper()),
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  bool showLogin = true;

  void toggleView() {
    setState(() => showLogin = !showLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        Widget content;
        try {
          if (authService.isLoading) {
            content = const Scaffold(
              key: ValueKey('loading'),
              body: SkeletonDashboard(),
            );
          } else {
            final user = authService.currentUser;
            if (user == null) {
              content = AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.98,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: showLogin
                    ? LoginScreen(
                        key: const ValueKey('login'),
                        onRegisterTap: toggleView,
                      )
                    : RegisterScreen(
                        key: const ValueKey('register'),
                        onLoginTap: toggleView,
                      ),
              );
            } else if (user.role == SystemConfig.adminRole ||
                user.role == SystemConfig.staffRole) {
              content = const MainLayout(key: ValueKey('main'));
            } else {
              // Unrecognized role or data error
              content = Scaffold(
                key: const ValueKey('error'),
                body: EnhancedErrorState(
                  title: 'Access Restricted',
                  message: user.role.isEmpty
                      ? 'Your account does not have a designated role yet. Please contact an administrator.'
                      : 'The role "${user.role}" is not recognized by the system.',
                  icon: Icons.lock_person_outlined,
                  actionLabel: 'Sign Out & Try Other Method',
                  onAction: () => authService.signOut(),
                ),
              );
            }
          }
        } catch (e) {
          // General error recovery
          content = Scaffold(
            key: const ValueKey('runtime_error'),
            body: EnhancedErrorState(
              title: 'Application Error',
              message: 'An unexpected error occurred: $e',
              icon: Icons.warning_amber_rounded,
              actionLabel: 'Back to Login',
              onAction: () => authService.signOut(),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.01), // Subtle upward slide
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: content,
        );
      },
    );
  }
}
