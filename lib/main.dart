import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/onboarding/onboarding_gate.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

/// Entry point for the LifeLink application.
///
/// Initializes Firebase, loads the theme preference, and starts the app.
Future<void> main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load the persisted Light/Dark/System appearance preference before the
  // first frame, so the app doesn't briefly flash the wrong theme.
  await ThemeController.instance.load();

  // Start the application
  runApp(const MyApp());
}

/// Root widget of the LifeLink application.
///
/// Wraps the app in an AnimatedBuilder to listen for theme changes
/// and rebuilds the entire app when the theme mode changes.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app whenever the Appearance selection changes,
    // anywhere in the app (see AppearanceSelectorSheet).
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LifeLink',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.mode,
          home: const OnboardingGate(),
        );
      },
    );
  }
}
