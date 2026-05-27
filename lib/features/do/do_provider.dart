// do_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';

class HabitWithHeat {
  final Habit habit;
  final bool completedToday;
  final List<int> heat21; // 0 = missed, 1 = done, 2 = today-open
  const HabitWithHeat({
    required this.habit,
    required this.completedToday,
    required this.heat21,
  });
}

final habitsWithHeatProvider =
    FutureProvider<List<HabitWithHeat>>((ref) async {
  final db = ref.watch(dbProvider);
  final habits = await db.select(db.habits).get();
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  final result = <HabitWithHeat>[];
  for (final h in habits) {
    final completions = await db.completionsForHabit(h.id, days: 21);
    final heat = <int>[];
    for (int i = 20; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      if (i == 0) {
        // today
        final done = completions.any((c) =>
            c.date.year == day.year &&
            c.date.month == day.month &&
            c.date.day == day.day &&
            c.completed);
        heat.add(done ? 1 : 2); // 2 = today, open
      } else {
        final done = completions.any((c) =>
            c.date.year == day.year &&
            c.date.month == day.month &&
            c.date.day == day.day &&
            c.completed);
        heat.add(done ? 1 : 0);
      }
    }
    final completedToday = heat.last == 1;
    result.add(HabitWithHeat(
        habit: h, completedToday: completedToday, heat21: heat));
  }
  return result;
});

final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(dbProvider).watchTodayTasks();
});

final weekTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(dbProvider).watchWeekTasks();
});

// Action provider for toggling tasks
final taskToggleProvider =
    Provider<Future<void> Function(int, bool)>((ref) {
  final db = ref.watch(dbProvider);
  return (id, completed) => db.toggleTask(id, completed);
});

// Action provider for toggling habit completion
final habitToggleProvider =
    Provider<Future<void> Function(int, bool)>((ref) {
  final db = ref.watch(dbProvider);
  return (id, completed) => db.toggleHabitCompletion(id, completed);
});
