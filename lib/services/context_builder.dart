// context_builder.dart — Assembles a rich system context string from Drift data
// before every inference call. Jarvis gets a full picture of the user's life.

import 'package:intl/intl.dart';
import '../database/database.dart';

class ContextBuilder {
  static final ContextBuilder instance = ContextBuilder._();
  ContextBuilder._();

  final _dateFmt = DateFormat('EEE MMM d');

  /// Build a complete system prompt with live Drift data.
  Future<String> build(AppDatabase db) async {
    final buf = StringBuffer();

    buf.writeln('You are Jarvis, a focused personal AI assistant embedded in Jarvy — '
        'a private life tracker. You are direct, warm, and concise. '
        'You NEVER make up data — only reference what is provided below. '
        'When the user asks about their life, draw from this context. '
        'Today is ${_dateFmt.format(DateTime.now())}.\n');

    // ── User config / goals ───────────────────────────────────────────────
    buf.writeln('## User Goals');
    final calorieTarget = await db.getConfig('calorie_target');
    final proteinPct = await db.getConfig('macro_protein_pct');
    final carbPct = await db.getConfig('macro_carb_pct');
    final fatPct = await db.getConfig('macro_fat_pct');
    final trainingDays = await db.getConfig('training_days_per_week');
    final trainingType = await db.getConfig('training_type');

    if (calorieTarget != null) buf.writeln('- Calorie target: $calorieTarget kcal/day');
    if (proteinPct != null) buf.writeln('- Macro split: ${proteinPct}P / ${carbPct}C / ${fatPct}F');
    if (trainingDays != null) buf.writeln('- Training: $trainingDays days/week ($trainingType)');
    buf.writeln();

    // ── Habits (last 7 days) ──────────────────────────────────────────────
    buf.writeln('## Habits (last 7 days)');
    final habits = await db.watchHabits().first;
    if (habits.isEmpty) {
      buf.writeln('No habits tracked yet.');
    } else {
      for (final h in habits) {
        final completions = await db.completionsForHabit(h.id, days: 7);
        final doneCount = completions.where((c) => c.completed).length;
        buf.writeln('- ${h.name}: $doneCount/7 days completed (streak: ${h.streakCount})');
      }
    }
    buf.writeln();

    // ── Calories today ────────────────────────────────────────────────────
    buf.writeln('## Nutrition (today)');
    final calorieEntries = await db.watchTodayCalorieEntries().first;
    if (calorieEntries.isEmpty) {
      buf.writeln('No meals logged today.');
    } else {
      int totalCal = 0;
      double totalP = 0, totalC = 0, totalF = 0;
      for (final e in calorieEntries) {
        totalCal += e.calories;
        totalP += e.protein;
        totalC += e.carbs;
        totalF += e.fat;
        buf.writeln('- ${e.mealName}: ${e.calories} kcal '
            '(P${e.protein.toInt()}g C${e.carbs.toInt()}g F${e.fat.toInt()}g)');
      }
      buf.writeln('TOTAL: $totalCal kcal | P${totalP.toInt()}g C${totalC.toInt()}g F${totalF.toInt()}g');
      if (calorieTarget != null) {
        final target = int.tryParse(calorieTarget) ?? 0;
        final remaining = target - totalCal;
        buf.writeln('Remaining: $remaining kcal vs $target target');
      }
    }
    buf.writeln();

    // ── Workouts this week ────────────────────────────────────────────────
    buf.writeln('## Workouts (this week)');
    final workouts = await db.watchWeekWorkouts().first;
    if (workouts.isEmpty) {
      buf.writeln('No workouts logged this week.');
    } else {
      for (final w in workouts) {
        buf.writeln('- ${_dateFmt.format(w.date)}: ${w.type} — ${w.durationMinutes} min'
            '${w.notes != null ? " (${w.notes})" : ""}');
      }
    }
    buf.writeln();

    // ── Projects & tasks ──────────────────────────────────────────────────
    buf.writeln('## Active Projects & Tasks');
    final projects = await db.watchActiveProjects().first;
    if (projects.isEmpty) {
      buf.writeln('No active projects.');
    } else {
      for (final p in projects) {
        buf.writeln('- ${p.name} [${p.progressPct}%] — ${p.status}');
        if (p.nextStep != null) buf.writeln('  Next: ${p.nextStep}');
        // Fetch tasks for this project
        final projectTasks = await db.watchTasksForProject(p.id).first;
        final open = projectTasks.where((t) => !t.completed).take(3);
        for (final t in open) {
          buf.writeln('  • ${t.title}${t.dueDate != null ? " (due ${_dateFmt.format(t.dueDate!)})" : ""}');
        }
      }
    }
    buf.writeln();

    // ── Today's tasks ─────────────────────────────────────────────────────
    buf.writeln('## Today\'s Priority Tasks');
    final todayTasks = await db.watchTodayTasks().first;
    if (todayTasks.isEmpty) {
      buf.writeln('No tasks due today.');
    } else {
      for (final t in todayTasks.take(5)) {
        final overdue = t.overdue ? ' [OVERDUE]' : '';
        buf.writeln('- ${t.title}$overdue');
      }
    }
    buf.writeln();

    // ── Library pins ──────────────────────────────────────────────────────
    buf.writeln('## Library (recent pins)');
    final pins = await db.watchPins().first;
    if (pins.isEmpty) {
      buf.writeln('No pins saved yet.');
    } else {
      for (final pin in pins.take(5)) {
        buf.writeln('- [${pin.type}] ${pin.content}'
            '${pin.author != null ? " — ${pin.author}" : ""}');
      }
      if (pins.length > 5) buf.writeln('  ... and ${pins.length - 5} more');
    }
    buf.writeln();

    // ── Interests (last 14 days) ──────────────────────────────────────────
    buf.writeln('## Recent Interests');
    final interests = await db.select(db.interests).get();
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final recentInterests =
        interests.where((i) => i.dateAdded.isAfter(cutoff)).toList();
    if (recentInterests.isEmpty) {
      buf.writeln('No new interests in the last 14 days.');
    } else {
      for (final i in recentInterests) {
        buf.writeln('- ${i.topic}${i.notes != null ? ": ${i.notes}" : ""}');
      }
    }
    buf.writeln();

    // ── Study sessions ────────────────────────────────────────────────────
    buf.writeln('## Study Sessions');
    final sessions = await db.watchStudySessions().first;
    if (sessions.isEmpty) {
      buf.writeln('No study sessions logged.');
    } else {
      for (final s in sessions.take(4)) {
        buf.writeln('- ${_dateFmt.format(s.date)}: ${s.subject} — ${s.durationMinutes} min');
      }
    }

    buf.writeln('\n---');
    buf.writeln('Respond conversationally. Be brief unless detail is asked for. '
        'Reference specific data when relevant. Never invent facts.');

    return buf.toString();
  }

  /// Lightweight context for onboarding (no data yet, just personality).
  String onboardingSystemPrompt() {
    return '''You are Jarvis, a focused personal AI assistant embedded in Jarvy — a private life tracker.

This is a first-time user. Your job is to conduct a friendly, concise onboarding conversation to understand their goals. Ask ONE question at a time. After collecting all answers, summarise what you've learned and confirm.

Questions to cover (in order, naturally):
1. Daily calorie target (or "I don't track calories")
2. Macro preference — balanced / high-protein / low-carb / custom (get rough percentages)
3. Training frequency — how many days per week they work out, and what kind (strength / cardio / mixed)
4. One or two main life areas they want to focus on (e.g. work project, study, health)
5. Anything specific they want Jarvis to help them stay on top of

Be warm but efficient. Today is ${_dateFmt.format(DateTime.now())}.
After the final confirmation, output EXACTLY this tag on its own line: [ONBOARDING_COMPLETE]''';
  }
}
