// Smoke test — verifies the app widget tree mounts without throwing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarvy/app.dart';
import 'package:jarvy/database/database.dart';

void main() {
  testWidgets('app mounts without errors', (WidgetTester tester) async {
    final db = AppDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const JarvyApp(onboardingDone: true),
      ),
    );
    // If we reach here the widget tree built successfully.
    expect(find.byType(JarvyApp), findsOneWidget);
    await db.close();
  });
}
