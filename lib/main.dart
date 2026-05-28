// main.dart — Jarvy entry point.
// Opens the Drift SQLite database and mounts the app.
// Data lives in jarvy.db in the platform's app-support directory:
//   macOS → ~/Library/Containers/<bundle>/Data/Library/Application Support/
//   iOS   → <app>/Documents/
// No seed data — clean slate from first launch.
// On first launch (onboarding_complete ≠ true) routes to OnboardingScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'database/database.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final onboardingDone = await db.isOnboardingComplete();

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
      ],
      child: JarvyApp(initialRoute: onboardingDone ? '/' : '/onboarding'),
    ),
  );
}
