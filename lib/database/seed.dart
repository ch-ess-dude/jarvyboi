// seed.dart — populates the database with realistic dummy data on first run.

import 'package:drift/drift.dart';
import 'database.dart';

Future<void> seedIfEmpty(AppDatabase db) async {
  final habits = await db.select(db.habits).get();
  if (habits.isNotEmpty) return; // already seeded

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // ── Habits ────────────────────────────────────────────────────────────
  final chessId = await db.into(db.habits).insert(HabitsCompanion.insert(
    name: 'Chess — one tactic, one game',
    streakCount: const Value(49),
    sub: const Value('49 day streak'),
  ));
  final guitarId = await db.into(db.habits).insert(HabitsCompanion.insert(
    name: 'Guitar — fingerstyle warm-up',
    streakCount: const Value(47),
    sub: const Value('working on Blackbird'),
  ));
  final writingId = await db.into(db.habits).insert(HabitsCompanion.insert(
    name: 'One line of writing',
    streakCount: const Value(3),
    sub: const Value('morning pages · open'),
  ));
  final runId = await db.into(db.habits).insert(HabitsCompanion.insert(
    name: 'Morning run',
    streakCount: const Value(0),
    sub: const Value('every other day'),
  ));

  // ── Habit completions — last 21 days ──────────────────────────────────
  // Chess: perfect 21/21
  final chessPattern = List.filled(21, 1);
  // Guitar: one miss on day 5 from the end
  final guitarPattern = [1,1,1,1,0,1,1, 1,1,1,1,1,1,1, 1,1,1,1,1,1,1];
  // Writing: sporadic
  final writingPattern = [1,1,1,0,0,1,0, 1,0,1,1,0,1,1, 1,0,1,0,0,1,1];
  // Run: every other day
  final runPattern = [0,0,1,0,1,0,0, 1,0,1,0,1,0,0, 1,0,1,0,1,0,0];

  Future<void> insertPattern(int habitId, List<int> pattern) async {
    for (int i = 0; i < pattern.length; i++) {
      final daysAgo = pattern.length - 1 - i;
      final date = today.subtract(Duration(days: daysAgo));
      if (pattern[i] == 1) {
        await db.into(db.habitCompletions).insert(HabitCompletionsCompanion.insert(
          habitId: habitId,
          date: date,
          completed: const Value(true),
          durationMinutes: Value(habitId == chessId ? 20 : habitId == guitarId ? 18 : 5),
        ));
      }
    }
  }

  await insertPattern(chessId, chessPattern);
  await insertPattern(guitarId, guitarPattern);
  await insertPattern(writingId, writingPattern);
  await insertPattern(runId, runPattern);

  // Today's completions (chess and guitar done, writing done, run not yet)
  // Already covered by the patterns above (index 20 = today)

  // ── Today's calories ──────────────────────────────────────────────────
  await db.into(db.calorieEntries).insert(CalorieEntriesCompanion.insert(
    date: today.add(const Duration(hours: 9, minutes: 32)),
    mealName: 'overnight oats, blueberries',
    calories: 412,
    protein: const Value(14.0),
    carbs: const Value(72.0),
    fat: const Value(8.0),
  ));
  await db.into(db.calorieEntries).insert(CalorieEntriesCompanion.insert(
    date: today.add(const Duration(hours: 11, minutes: 42)),
    mealName: 'cold brew + 2 boiled eggs',
    calories: 208,
    protein: const Value(18.0),
    carbs: const Value(4.0),
    fat: const Value(14.0),
  ));
  await db.into(db.calorieEntries).insert(CalorieEntriesCompanion.insert(
    date: today.add(const Duration(hours: 13, minutes: 0)),
    mealName: 'chicken rice bowl',
    calories: 544,
    protein: const Value(48.0),
    carbs: const Value(58.0),
    fat: const Value(14.0),
  ));
  await db.into(db.calorieEntries).insert(CalorieEntriesCompanion.insert(
    date: today.add(const Duration(hours: 15, minutes: 30)),
    mealName: 'greek yoghurt, almonds',
    calories: 200,
    protein: const Value(12.0),
    carbs: const Value(14.0),
    fat: const Value(15.0),
  ));

  // ── This week's workouts ──────────────────────────────────────────────
  final mon = today.subtract(Duration(days: today.weekday - 1));
  final workoutDays = [
    (mon, 'Push · Bench, OHP, Dips', 38),
    (mon.add(const Duration(days: 1)), 'Run · easy 5k', 22),
    // Wednesday: rest
    (mon.add(const Duration(days: 3)), 'Pull · Rows, Curls, Facepulls', 44),
    (mon.add(const Duration(days: 4)), 'Run · tempo intervals', 30),
  ];
  for (final (date, type, dur) in workoutDays) {
    await db.into(db.workouts).insert(WorkoutsCompanion.insert(
      date: date,
      type: type,
      durationMinutes: dur,
    ));
  }

  // ── Projects ──────────────────────────────────────────────────────────
  await db.into(db.projects).insert(ProjectsCompanion.insert(
    name: 'A life,',
    italicTail: const Value('instrumented.'),
    description: const Value('Building Jarvy — a personal OS for a deliberate life.'),
    status: const Value('now'),
    createdAt: today.subtract(const Duration(days: 47)),
    progressPct: const Value(48),
    nextStep: const Value('Wire register-based theming into all six screens. Then ship the prototype.'),
    mood: const Value('on pace'),
    since: const Value('started apr 9 · 47 days'),
  ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
    name: 'Learn to read a chess endgame',
    description: const Value('Working through Silman\'s endgame course.'),
    status: const Value('active'),
    createdAt: today.subtract(const Duration(days: 127)),
    progressPct: const Value(23),
    nextStep: const Value('K+P vs K, rule of the square — ch. 4 of Silman.'),
    since: const Value('127d in · returned 4× this month'),
  ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
    name: 'Write 50,000 words this year',
    description: const Value('35,210 / 50,000 written.'),
    status: const Value('active'),
    createdAt: today.subtract(const Duration(days: 146)),
    progressPct: const Value(71),
    mood: const Value('on pace'),
    since: const Value('35,210 / 50,000 · on pace'),
  ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
    name: 'Move the website to a writing-first home',
    description: const Value('Redesigning personal site around long-form writing.'),
    status: const Value('stalled'),
    createdAt: today.subtract(const Duration(days: 52)),
    progressPct: const Value(42),
    nextStep: const Value('Stuck on the typography pass. Next sit-down Saturday morning.'),
    mood: const Value('re-engage'),
    since: const Value('last touched may 5'),
  ));
  await db.into(db.projects).insert(ProjectsCompanion.insert(
    name: 'Stop drinking soda',
    description: const Value('52 days clean.'),
    status: const Value('quiet'),
    createdAt: today.subtract(const Duration(days: 52)),
    progressPct: const Value(88),
    since: const Value('52 days clean'),
  ));

  // ── Tasks ─────────────────────────────────────────────────────────────
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Draft register-based theming spec',
    dueDate: Value(today),
    priority: const Value(2),
    sub: const Value('ambition · in flight'),
    scheduledLabel: const Value('09:30'),
  ));
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Reply to dad',
    dueDate: Value(today.subtract(const Duration(days: 2))),
    overdue: const Value(true),
    sub: const Value('overdue · 2d'),
  ));
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Pick up dry-cleaning',
    dueDate: Value(today),
    sub: const Value('errand'),
  ));
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Bench press, 5 × 5 @ 185',
    dueDate: Value(today),
    sub: const Value('kinetic · planned 18:30'),
  ));
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Renew passport — submit form',
    dueDate: Value(_nextWeekday(today, DateTime.thursday)),
    sub: const Value('thu · deadline'),
    scheduledLabel: const Value('THU'),
  ));
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Call mom — Sunday lunch',
    dueDate: Value(_nextWeekday(today, DateTime.saturday)),
    sub: const Value('sat'),
    scheduledLabel: const Value('SAT'),
  ));
  await db.into(db.tasks).insert(TasksCompanion.insert(
    title: 'Submit quarterly review',
    dueDate: Value(today.add(const Duration(days: 6))),
    sub: const Value('work · end of week'),
    scheduledLabel: const Value('FRI'),
  ));

  // ── Pins (Library) ────────────────────────────────────────────────────
  await db.into(db.pins).insert(PinsCompanion.insert(
    content: 'Inventing on Principle',
    type: 'essay',
    createdAt: today.subtract(const Duration(days: 1)),
    note: const Value('Creators must be able to see what they\'re making. Every barrier to that vision is a failure of design.'),
    author: const Value('Bret Victor'),
    numeral: const Value('ccxli'),
    tags: const Value('["design","tools","manifesto"]'),
    returnsLabel: const Value('returned 4×'),
  ));
  await db.into(db.pins).insert(PinsCompanion.insert(
    content: 'A photograph of my grandfather\'s library, 1978',
    type: 'pin',
    createdAt: today.subtract(const Duration(days: 2)),
    numeral: const Value('ccxl'),
    tags: const Value('["family","image"]'),
  ));
  await db.into(db.pins).insert(PinsCompanion.insert(
    content: 'Endgame: K+P vs K, the rule of the square',
    type: 'study log',
    createdAt: today.subtract(const Duration(days: 3)),
    note: const Value('If the king of the side without the pawn is inside the square, it catches the pawn. Otherwise it doesn\'t.'),
    numeral: const Value('ccxxxix'),
    tags: const Value('["chess","endgame"]'),
    returnsLabel: const Value('3 reviews'),
  ));
  await db.into(db.pins).insert(PinsCompanion.insert(
    content: 'Christopher Alexander on the Quality Without a Name',
    type: 'video · 54m',
    createdAt: today.subtract(const Duration(days: 8)),
    author: const Value('lecture, Berkeley 1996'),
    numeral: const Value('ccxxxviii'),
    tags: const Value('["architecture","pattern language"]'),
  ));
  await db.into(db.pins).insert(PinsCompanion.insert(
    content: 'On giving things their proper names',
    type: 'quote',
    createdAt: today.subtract(const Duration(days: 14)),
    note: const Value('If names be not correct, language is not in accordance with the truth of things.'),
    author: const Value('Confucius'),
    numeral: const Value('ccxxxvii'),
    tags: const Value('["language"]'),
  ));
  await db.into(db.pins).insert(PinsCompanion.insert(
    content: 'A Pattern Language: Towns, Buildings, Construction',
    type: 'book',
    createdAt: today.subtract(const Duration(days: 21)),
    author: const Value('Christopher Alexander'),
    numeral: const Value('ccxxxvi'),
    tags: const Value('["architecture","design","reference"]'),
    note: const Value('253 patterns for human-scale design. The most influential book I have ever read.'),
    returnsLabel: const Value('returned 11×'),
  ));

  // ── Daily log entry ───────────────────────────────────────────────────
  await db.into(db.dailyLogs).insert(DailyLogsCompanion.insert(
    date: today,
    notes: const Value('Good morning. Chess puzzle was a queen sacrifice — took 12 minutes but found it. Guitar session was productive, Blackbird bridge is clicking.'),
  ));
}

DateTime _nextWeekday(DateTime from, int weekday) {
  var d = from.add(const Duration(days: 1));
  while (d.weekday != weekday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}
