// dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';

// ── Domain models ─────────────────────────────────────────────────────────

class HabitRow {
  final Habit habit;
  final bool completedToday;
  final int? durationMinutes;
  const HabitRow({
    required this.habit,
    required this.completedToday,
    this.durationMinutes,
  });
}

class CalorieSummary {
  final int total;
  final int goal;
  final double protein;
  final double carbs;
  final double fat;
  double get pct => goal == 0 ? 0 : (total / goal).clamp(0, 1);
  const CalorieSummary({
    required this.total,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class DashboardData {
  final List<HabitRow> habits;
  final CalorieSummary calorieSummary;
  final Workout? todayWorkout;
  final Task? activeTask;
  const DashboardData({
    required this.habits,
    required this.calorieSummary,
    this.todayWorkout,
    this.activeTask,
  });
}

// ── Providers ──────────────────────────────────────────────────────────────

final _habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(dbProvider).watchHabits();
});

final _todayCompletionsProvider =
    StreamProvider<List<HabitCompletion>>((ref) {
  return ref.watch(dbProvider).watchTodayCompletions();
});

final _todayCaloriesProvider = StreamProvider<List<CalorieEntry>>((ref) {
  return ref.watch(dbProvider).watchTodayCalorieEntries();
});

final _weekWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  return ref.watch(dbProvider).watchWeekWorkouts();
});

final _todayTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(dbProvider).watchTodayTasks();
});

final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final habitsAsync = ref.watch(_habitsStreamProvider);
  final completionsAsync = ref.watch(_todayCompletionsProvider);
  final caloriesAsync = ref.watch(_todayCaloriesProvider);
  final workoutsAsync = ref.watch(_weekWorkoutsProvider);
  final tasksAsync = ref.watch(_todayTasksProvider);

  return habitsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
    data: (habits) => completionsAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
      data: (completions) => caloriesAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
        data: (calories) => workoutsAsync.when(
          loading: () => const AsyncLoading(),
          error: (e, s) => AsyncError(e, s),
          data: (workouts) => tasksAsync.when(
            loading: () => const AsyncLoading(),
            error: (e, s) => AsyncError(e, s),
            data: (tasks) {
              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final todayEnd = todayStart.add(const Duration(days: 1));
              final todayWorkout = workouts
                  .where((w) =>
                      w.date.isAfter(todayStart) &&
                      w.date.isBefore(todayEnd))
                  .firstOrNull;

              final habitRows = habits.map((h) {
                final comp = completions
                    .where((c) => c.habitId == h.id && c.completed)
                    .firstOrNull;
                return HabitRow(
                  habit: h,
                  completedToday: comp != null,
                  durationMinutes: comp?.durationMinutes,
                );
              }).toList();

              int totalKcal = 0;
              double protein = 0, carbs = 0, fat = 0;
              for (final e in calories) {
                totalKcal += e.calories;
                protein += e.protein;
                carbs += e.carbs;
                fat += e.fat;
              }

              return AsyncData(DashboardData(
                habits: habitRows,
                calorieSummary: CalorieSummary(
                  total: totalKcal,
                  goal: 2200,
                  protein: protein,
                  carbs: carbs,
                  fat: fat,
                ),
                todayWorkout: todayWorkout,
                activeTask: tasks.firstOrNull,
              ));
            },
          ),
        ),
      ),
    ),
  );
});
