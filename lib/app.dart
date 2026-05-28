// app.dart — MaterialApp shell. No cloud, no Firebase, just the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/jarvy_theme.dart';
import 'navigation/main_nav.dart';
import 'settings/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

// ease-out-expo approximation as a Cubic Bézier
const _easeOutExpo = Cubic(0.16, 1, 0.3, 1);

class JarvyApp extends StatelessWidget {
  final String initialRoute;
  const JarvyApp({super.key, this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    // Force dark status bar icons on the warm-dark background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Jarvy',
      debugShowCheckedModeBanner: false,
      // Material theme is minimal — all real theming comes from JarvyTheme
      theme: jarvyMaterialTheme(JarvyRegisters.daily),
      darkTheme: jarvyMaterialTheme(JarvyRegisters.daily),
      themeMode: ThemeMode.dark,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _slideRoute(const MainNav(), const Offset(-1, 0));
          case '/onboarding':
            return _slideRoute(const OnboardingScreen(), const Offset(0, 1));
          case '/settings':
            return _slideRoute(
              JarvyTheme(
                register: JarvyRegisters.utility,
                child: const SettingsScreen(),
              ),
              const Offset(1, 0),
            );
          default:
            return null;
        }
      },
    );
  }

  /// Directional slide transition — 300ms ease-out-expo.
  static PageRoute<T> _slideRoute<T>(Widget page, Offset begin) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: _easeOutExpo),
        ),
        child: child,
      ),
    );
  }
}
