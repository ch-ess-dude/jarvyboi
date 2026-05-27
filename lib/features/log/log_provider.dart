// log_provider.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';

// ── Log entry — a unified view across meals, habits, workouts, pins

enum LogKind { meal, habit, workout, link }

class LogEntry {
  final String time;   // "11:42"
  final LogKind kind;
  final String label;
  final String value;
  const LogEntry({
    required this.time,
    required this.kind,
    required this.label,
    required this.value,
  });
}

// Converts today's DB records into a unified timeline
final todayLogEntriesProvider = StreamProvider<List<LogEntry>>((ref) {
  final db = ref.watch(dbProvider);
  // Merge calories + completions + workouts
  return db.watchTodayCalorieEntries().map((calories) {
    final entries = <LogEntry>[];
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    for (final c in calories) {
      entries.add(LogEntry(
        time: fmt(c.date),
        kind: LogKind.meal,
        label: c.mealName,
        value: '${c.calories} kcal · ${c.protein.toStringAsFixed(0)}p',
      ));
    }
    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries;
  });
});

// Active log-type picker
final logPickProvider = StateProvider<LogKind>((ref) => LogKind.meal);

// ── Write actions ─────────────────────────────────────────────────────────

final logMealProvider = Provider<
    Future<void> Function({
      required String name,
      required int calories,
      double protein,
      double carbs,
      double fat,
    })>((ref) {
  final db = ref.watch(dbProvider);
  return ({
    required String name,
    required int calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) =>
      db.addCalorieEntry(CalorieEntriesCompanion.insert(
        date: DateTime.now(),
        mealName: name,
        calories: calories,
        protein: Value(protein),
        carbs: Value(carbs),
        fat: Value(fat),
      ));
});

final logWorkoutProvider =
    Provider<Future<void> Function(String type, int minutes, String notes)>(
        (ref) {
  final db = ref.watch(dbProvider);
  return (type, minutes, notes) => db.addWorkout(WorkoutsCompanion.insert(
        date: DateTime.now(),
        type: type,
        durationMinutes: minutes,
        notes: Value(notes.isEmpty ? null : notes),
      ));
});

final logPinProvider =
    Provider<Future<void> Function(String content, String type, String note)>(
        (ref) {
  final db = ref.watch(dbProvider);
  return (content, type, note) => db.addPin(PinsCompanion.insert(
        content: content,
        type: type,
        createdAt: DateTime.now(),
        note: Value(note.isEmpty ? null : note),
      ));
});

final logTaskProvider = Provider<Future<void> Function(String title)>((ref) {
  final db = ref.watch(dbProvider);
  return (title) => db.addTask(TasksCompanion.insert(
        title: title,
        dueDate: Value(DateTime.now()),
      ));
});
