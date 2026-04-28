import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/navigation_provider.dart';
import 'services/settings_provider.dart';
import 'services/activity_form_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_layout.dart';
import 'core/app_colors.dart';
import 'widgets/enhanced_states.dart';

import 'firebase_options.dart';

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
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      try {
        await FirebaseFirestore.instance.clearPersistence();
      } catch (e) {
        debugPrint('Failed to clear persistence: $e');
      }
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AgriWork & Financial Planning System (AWFPS)',
          themeMode: settingsProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
                .copyWith(
                  titleLarge: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  bodyMedium: GoogleFonts.inter(letterSpacing: -0.1),
                ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              primary: const Color(0xFF1B5E20),
              onPrimary: Colors.white,
              secondary: const Color(0xFFD4AF37),
              onSecondary: Colors.black,
              tertiary: const Color(0xFF2E7D32),
              surface: Colors.white,
              surfaceContainer: const Color(0xFFF8FAFC),
              error: const Color(0xFFDC2626),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF1B5E20),
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: TextStyle(
                inherit: true,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: Color(0xFF1B5E20),
              ),
            ),
            dividerTheme: DividerThemeData(color: Slate.shade200, thickness: 1),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style:
                  ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      inherit: true,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.1,
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Slate.shade100, width: 1),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Slate.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Slate.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2.0,
                ),
              ),
              labelStyle: const TextStyle(
                inherit: true,
                color: Slate.shade600,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: const TextStyle(inherit: true, color: Slate.shade400),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
                .copyWith(
                  titleLarge: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  bodyMedium: GoogleFonts.inter(letterSpacing: -0.1),
                ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CAF50),
              primary: const Color(0xFF4CAF50),
              onPrimary: Colors.black,
              secondary: const Color(0xFFD4AF37),
              onSecondary: Colors.black,
              tertiary: const Color(0xFF81C784),
              surface: const Color(0xFF111827),
              surfaceContainer: const Color(0xFF0F172A),
              error: const Color(0xFFEF4444),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleTextStyle: TextStyle(
                inherit: true,
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            dividerTheme: DividerThemeData(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  inherit: true,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1E293B),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF4CAF50),
                  width: 2.0,
                ),
              ),
              labelStyle: const TextStyle(
                inherit: true,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              hintStyle: const TextStyle(
                inherit: true,
                color: Color(0xFF64748B),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          home: const AuthWrapper(),
          navigatorObservers: [routeObserver],
          builder: (context, child) {
            return child!;
          },
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
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          final user = authService.currentUser;
          if (user == null) {
            content = AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
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
          } else if (user.role == 'admin' || user.role == 'staff') {
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
          duration: const Duration(milliseconds: 600),
          child: content,
        );
      },
    );
  }
}
