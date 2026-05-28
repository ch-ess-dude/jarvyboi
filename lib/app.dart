// app.dart — MaterialApp shell.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/jarvy_theme.dart';
import 'navigation/main_nav.dart';
import 'settings/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

const _easeOutExpo = Cubic(0.16, 1, 0.3, 1);

class JarvyApp extends StatelessWidget {
  /// When false, shows OnboardingScreen first. When true, goes straight to MainNav.
  final bool onboardingDone;
  const JarvyApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Jarvy',
      debugShowCheckedModeBanner: false,
      theme: jarvyMaterialTheme(JarvyRegisters.daily),
      darkTheme: jarvyMaterialTheme(JarvyRegisters.daily),
      themeMode: ThemeMode.dark,
      // home: drives the first screen — no initialRoute ambiguity
      home: onboardingDone ? const MainNav() : const OnboardingScreen(),
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
