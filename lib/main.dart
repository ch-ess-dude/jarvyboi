// main.dart — Jarvy entry point.
// Opens Drift SQLite, checks onboarding state, mounts the app.
// Data path (macOS): ~/Library/Containers/<bundle>/Data/Library/Application Support/jarvy.db

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  bool onboardingDone = false;
  try {
    onboardingDone = await db.isOnboardingComplete();
  } catch (_) {
    // DB not yet initialised — treat as first launch
    onboardingDone = false;
  }

  runApp(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: JarvyApp(onboardingDone: onboardingDone),
    ),
  );
}
