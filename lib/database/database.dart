// database.dart — Drift (SQLite) schema for Jarvy.
// Run `dart run build_runner build` once to generate database.g.dart.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

// ── Tables ──────────────────────────────────────────────────────────────────

class DailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
}

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  TextColumn get sub => text().nullable()(); // subtitle shown on dashboard
}

class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get durationMinutes => integer().nullable()();
}

class CalorieEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealName => text()();
  IntColumn get calories => integer()();
  RealColumn get protein => real().withDefault(const Constant(0.0))();
  RealColumn get carbs => real().withDefault(const Constant(0.0))();
  RealColumn get fat => real().withDefault(const Constant(0.0))();
}

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()();
  IntColumn get durationMinutes => integer()();
  TextColumn get notes => text().nullable()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get italicTail => text().nullable()(); // e.g. "instrumented."
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get progressPct => integer().withDefault(const Constant(0))();
  TextColumn get nextStep => text().nullable()();
  TextColumn get mood => text().nullable()(); // "on pace", "re-engage"
  TextColumn get since => text().nullable()(); // human-readable "started apr 9 · 47 days"
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get projectId => integer().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get sub => text().nullable()(); // "ambition · in flight"
  TextColumn get scheduledLabel => text().nullable()(); // "09:30", "THU"
  BoolColumn get overdue => boolean().withDefault(const Constant(false))();
}

class Pins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()(); // title
  TextColumn get type => text()(); // essay, pin, video, quote, study_log, etc.
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array of strings
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().nullable()(); // italic annotation
  TextColumn get author => text().nullable()();
  TextColumn get numeral => text().nullable()(); // Roman numeral index
  TextColumn get returnsLabel => text().nullable()(); // "returned 4×"
}

class Interests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topic => text()();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get lastResearched => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
}

// ── Database ──────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  DailyLogs,
  Habits,
  HabitCompletions,
  CalorieEntries,
  Workouts,
  Projects,
  Tasks,
  Pins,
  Interests,
  StudySessions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Daily log ─────────────────────────────────────────────────────────
  Future<DailyLog?> todayLog() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyLogs)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .getSingleOrNull();
  }

  // ── Habits ────────────────────────────────────────────────────────────
  Stream<List<Habit>> watchHabits() => select(habits).watch();

  Future<void> addHabit(HabitsCompanion h) => into(habits).insert(h);

  // ── Habit completions ─────────────────────────────────────────────────
  Stream<List<HabitCompletion>> watchTodayCompletions() {
    final today = _dayStart(DateTime.now());
    final end = today.add(const Duration(days: 1));
    return (select(habitCompletions)
          ..where((t) => t.date.isBetweenValues(today, end)))
        .watch();
  }

  Future<List<HabitCompletion>> completionsForHabit(int habitId,
      {int days = 21}) async {
    final start = _dayStart(DateTime.now()).subtract(Duration(days: days - 1));
    return (select(habitCompletions)
          ..where((t) =>
              t.habitId.equals(habitId) &
              t.date.isBiggerOrEqualValue(start))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<void> toggleHabitCompletion(int habitId, bool completed,
      {int? durationMinutes}) async {
    final today = _dayStart(DateTime.now());
    final end = today.add(const Duration(days: 1));
    final existing = await (select(habitCompletions)
          ..where((t) =>
              t.habitId.equals(habitId) &
              t.date.isBetweenValues(today, end)))
        .getSingleOrNull();
    if (existing != null) {
      await (update(habitCompletions)
            ..where((t) => t.id.equals(existing.id)))
          .write(HabitCompletionsCompanion(
        completed: Value(completed),
        durationMinutes: Value(durationMinutes),
      ));
    } else {
      await into(habitCompletions).insert(HabitCompletionsCompanion(
        habitId: Value(habitId),
        date: Value(today),
        completed: Value(completed),
        durationMinutes: Value(durationMinutes),
      ));
    }
  }

  Future<void> addHabitCompletion(HabitCompletionsCompanion c) =>
      into(habitCompletions).insert(c);

  // ── Calories ──────────────────────────────────────────────────────────
  Stream<List<CalorieEntry>> watchTodayCalorieEntries() {
    final today = _dayStart(DateTime.now());
    final end = today.add(const Duration(days: 1));
    return (select(calorieEntries)
          ..where((t) => t.date.isBetweenValues(today, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<void> addCalorieEntry(CalorieEntriesCompanion e) =>
      into(calorieEntries).insert(e);

  // ── Workouts ──────────────────────────────────────────────────────────
  Stream<List<Workout>> watchWeekWorkouts() {
    final weekAgo = _dayStart(DateTime.now()).subtract(const Duration(days: 6));
    return (select(workouts)
          ..where((t) => t.date.isBiggerOrEqualValue(weekAgo))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<Workout?> todayWorkout() async {
    final today = _dayStart(DateTime.now());
    final end = today.add(const Duration(days: 1));
    return (select(workouts)
          ..where((t) => t.date.isBetweenValues(today, end)))
        .getSingleOrNull();
  }

  Future<void> addWorkout(WorkoutsCompanion w) => into(workouts).insert(w);

  // ── Tasks ─────────────────────────────────────────────────────────────
  Stream<List<Task>> watchTodayTasks() {
    final today = _dayStart(DateTime.now());
    final end = today.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.completed.equals(false) &
              (t.dueDate.isNull() | t.dueDate.isSmallerOrEqualValue(end)))
          ..orderBy([
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.dueDate)
          ]))
        .watch();
  }

  Stream<List<Task>> watchWeekTasks() {
    final today = _dayStart(DateTime.now());
    final end = today.add(const Duration(days: 7));
    return (select(tasks)
          ..where((t) =>
              t.completed.equals(false) &
              t.dueDate.isBetweenValues(today, end))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  Stream<List<Task>> watchTasksForProject(int projectId) {
    return (select(tasks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.completed),
            (t) => OrderingTerm.desc(t.priority)
          ]))
        .watch();
  }

  Future<Task?> activeTodayTask() async {
    final tasks = await watchTodayTasks().first;
    return tasks.isEmpty ? null : tasks.first;
  }

  Future<void> addTask(TasksCompanion t) => into(tasks).insert(t);

  Future<void> toggleTask(int id, bool completed) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(completed: Value(completed)));

  // ── Projects ──────────────────────────────────────────────────────────
  Stream<List<Project>> watchActiveProjects() {
    return (select(projects)
          ..where((t) => t.status.isNotValue('done'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<void> addProject(ProjectsCompanion p) => into(projects).insert(p);

  Future<void> updateProjectProgress(int id, int pct) =>
      (update(projects)..where((t) => t.id.equals(id)))
          .write(ProjectsCompanion(progressPct: Value(pct)));

  // ── Pins (Library) ────────────────────────────────────────────────────
  Stream<List<Pin>> watchPins({String? query}) {
    final stmt = select(pins)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (query != null && query.isNotEmpty) {
      stmt.where(
          (t) => t.content.like('%$query%') | t.note.like('%$query%'));
    }
    return stmt.watch();
  }

  Future<void> addPin(PinsCompanion pin) => into(pins).insert(pin);

  // ── Study sessions ────────────────────────────────────────────────────
  Stream<List<StudySession>> watchStudySessions() {
    return (select(studySessions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<void> addStudySession(StudySessionsCompanion s) =>
      into(studySessions).insert(s);

  // ── Helpers ───────────────────────────────────────────────────────────
  static DateTime _dayStart(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

QueryExecutor _openConnection() {
  // drift_flutter 0.2.x: `name` becomes the filename in the platform's
  // default app data directory (Documents on iOS, AppData on Windows, etc.)
  return driftDatabase(name: 'jarvy');
}

// ── Riverpod provider ─────────────────────────────────────────────────────

final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override dbProvider in main.dart');
});
