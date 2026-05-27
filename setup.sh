#!/usr/bin/env bash
# Jarvy — one-time setup script.
# Run this after cloning or on a fresh machine.
set -e

echo "→ Installing Flutter dependencies…"
flutter pub get

echo "→ Generating Drift database code…"
dart run build_runner build --delete-conflicting-outputs

echo "→ All done. Run with: flutter run"
