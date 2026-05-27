// main.dart — Jarvy entry point.
// Initialises the Drift database, seeds dummy data on first run,
// overrides dbProvider so every screen can watch live data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'database/database.dart';
import 'database/seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database (creates jarvy.db in app documents directory)
  final db = AppDatabase();

  // Populate with realistic dummy data on first launch
  await seedIfEmpty(db);

  runApp(
    ProviderScope(
      overrides: [
        // All features resolve the db through this single override
        dbProvider.overrideWithValue(db),
      ],
      child: const JarvyApp(),
    ),
  );
}
