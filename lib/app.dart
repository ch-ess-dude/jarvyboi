// app.dart — MaterialApp shell. No cloud, no Firebase, just the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/jarvy_theme.dart';
import 'navigation/main_nav.dart';
import 'settings/settings_screen.dart';

class JarvyApp extends StatelessWidget {
  const JarvyApp({super.key});

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
      home: const MainNav(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/settings':
            return _fadeRoute(
              JarvyTheme(
                register: JarvyRegisters.utility,
                child: const SettingsScreen(),
              ),
            );
          default:
            return null;
        }
      },
    );
  }

  static PageRoute<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(
            parent: anim, curve: const Cubic(0.16, 1, 0.3, 1)),
        child: child,
      ),
    );
  }
}
