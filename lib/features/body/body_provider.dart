// body_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../dashboard/dashboard_provider.dart' show CalorieSummary;

class BodyData {
  final CalorieSummary calorieSummary;
  final List<Workout> weekWorkouts;
  const BodyData({required this.calorieSummary, required this.weekWorkouts});
}

final bodyCaloriesProvider = StreamProvider<List<CalorieEntry>>((ref) {
  return ref.watch(dbProvider).watchTodayCalorieEntries();
});

final bodyWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  return ref.watch(dbProvider).watchWeekWorkouts();
});

final bodyDataProvider = Provider<AsyncValue<BodyData>>((ref) {
  final cal = ref.watch(bodyCaloriesProvider);
  final wrk = ref.watch(bodyWorkoutsProvider);

  return cal.when(
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
    data: (calories) => wrk.when(
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
      data: (workouts) {
        int totalKcal = 0;
        double protein = 0, carbs = 0, fat = 0;
        for (final e in calories) {
          totalKcal += e.calories;
          protein += e.protein;
          carbs += e.carbs;
          fat += e.fat;
        }
        return AsyncData(BodyData(
          calorieSummary: CalorieSummary(
            total: totalKcal,
            goal: 2200,
            protein: protein,
            carbs: carbs,
            fat: fat,
          ),
          weekWorkouts: workouts,
        ));
      },
    ),
  );
});
