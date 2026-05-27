// dashboard_screen.dart — register: daily
// Warm near-black, amber accent, Cormorant Garamond + Sora.
// A beautifully typeset personal journal that happens to be interactive.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/jarvy_theme.dart';
import 'dashboard_provider.dart';

// ── Helpers ──────────────────────────────────────────────────────────────

String _dayToWord(int day) {
  const words = [
    '', 'first', 'second', 'third', 'fourth', 'fifth',
    'sixth', 'seventh', 'eighth', 'ninth', 'tenth',
    'eleventh', 'twelfth', 'thirteenth', 'fourteenth', 'fifteenth',
    'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth', 'twentieth',
    'twenty-first', 'twenty-second', 'twenty-third', 'twenty-fourth',
    'twenty-fifth', 'twenty-sixth', 'twenty-seventh', 'twenty-eighth',
    'twenty-ninth', 'thirtieth', 'thirty-first',
  ];
  return day >= 1 && day <= 31 ? words[day] : day.toString();
}

String _weekKicker() {
  final now = DateTime.now();
  final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final wd = weekdays[now.weekday - 1].toUpperCase();
  final jan1 = DateTime(now.year, 1, 1);
  final weekNum = ((now.difference(jan1).inDays + jan1.weekday) / 7).ceil();
  return '$wd · WEEK $weekNum';
}

String _fmtKcal(int n) {
  if (n >= 1000) {
    return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
  }
  return n.toString();
}

// ── Screen ───────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = JarvyTheme.of(context);
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: dashAsync.when(
        loading: () => _buildContent(context, t, null),
        error: (e, _) => Center(
            child: Text('Error loading data', style: t.body.copyWith(color: t.muted))),
        data: (data) => _buildContent(context, t, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, JarvyRegister t, DashboardData? data) {
    final now = DateTime.now();
    final month = DateFormat('MMMM').format(now);
    final dayWord = _dayToWord(now.day);

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          JarvySpacing.lg, JarvySpacing.md, JarvySpacing.lg,
          MediaQuery.paddingOf(context).bottom + 80,
        ),
        children: [
          // ── Kicker + gear ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_weekKicker(),
                  style: t.kicker.copyWith(color: t.accentDim ?? t.accent)),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/settings'),
                child: _GearIcon(color: t.muted),
              ),
            ],
          ),
          const SizedBox(height: JarvySpacing.xl),

          // ── Date — typeset large ───────────────────────────────────────
          Text(month, style: t.displayLarge),
          Text(
            dayWord,
            style: t.displayLarge.copyWith(
              fontStyle: FontStyle.italic,
              color: t.accent,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: JarvySpacing.sm),
          Text(
            '"The days are long, but the decades are short."',
            style: t.title.copyWith(
              fontStyle: FontStyle.italic,
              color: t.muted,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: JarvySpacing.xl),

          // ── Identity habits ───────────────────────────────────────────
          _SectionRule(
            label: 'IDENTITY',
            trailing: data == null
                ? null
                : '${data.habits.where((h) => h.completedToday).length} OF ${data.habits.take(3).length}',
            t: t,
          ),
          if (data == null)
            ..._placeholderHabits(t)
          else
            ...data.habits.take(3).map((row) => _IdentityRow(
                  label: row.habit.name,
                  sub: row.habit.sub ?? '',
                  done: row.completedToday,
                  count: row.durationMinutes != null
                      ? '${row.durationMinutes}m'
                      : '—',
                  t: t,
                )),

          const SizedBox(height: JarvySpacing.lg),

          // ── Today / active task ───────────────────────────────────────
          _SectionRule(label: 'TODAY', t: t),
          if (data?.activeTask != null)
            _ActiveTaskRow(task: data!.activeTask!, t: t)
          else
            _EmptyRow(label: 'No active task — add one in Log', t: t),

          const SizedBox(height: JarvySpacing.lg),

          // ── Body strip ────────────────────────────────────────────────
          _SectionRule(label: 'BODY', t: t),
          _CaloriesRow(
            summary: data?.calorieSummary,
            t: t,
          ),
          _WorkoutRow(workout: data?.todayWorkout, t: t),

          // ── Closing ornament ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: JarvySpacing.xl),
            child: Center(
              child: Text('—— ✦ ——',
                  style: t.mono.copyWith(color: t.faint, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _placeholderHabits(JarvyRegister t) => [
        _IdentityRow(label: 'Chess — one tactic, one game', sub: '49 day streak', done: true, count: '20m', t: t),
        _IdentityRow(label: 'Guitar — fingerstyle warm-up', sub: 'working on Blackbird', done: true, count: '18m', t: t),
        _IdentityRow(label: 'One line of writing', sub: 'morning pages · open', done: false, count: '—', t: t),
      ];
}

// ── Section rule ─────────────────────────────────────────────────────────

class _SectionRule extends StatelessWidget {
  final String label;
  final String? trailing;
  final JarvyRegister t;
  const _SectionRule({required this.label, required this.t, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.only(bottom: JarvySpacing.md),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: t.kicker),
            if (trailing != null)
              Text(trailing!, style: t.metadata.copyWith(letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Identity habit row ────────────────────────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final String label, sub, count;
  final bool done;
  final JarvyRegister t;
  const _IdentityRow({
    required this.label,
    required this.sub,
    required this.done,
    required this.count,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16×16 square checkbox
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 4, right: JarvySpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                  color: done ? t.accent : t.faint, width: 1),
              color: done ? t.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(JarvySpacing.radiusTight),
            ),
            child: done
                ? Icon(Icons.check, size: 10, color: t.background)
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: t.title.copyWith(
                    color: done ? t.muted : t.ink,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: t.faint,
                  ),
                ),
                const SizedBox(height: 3),
                if (sub.isNotEmpty)
                  Text(
                    sub.toUpperCase(),
                    style: t.kicker.copyWith(
                      color: t.muted,
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          Text(count, style: t.metadata),
        ],
      ),
    );
  }
}

// ── Active task row ───────────────────────────────────────────────────────

class _ActiveTaskRow extends StatelessWidget {
  final dynamic task;
  final JarvyRegister t;
  const _ActiveTaskRow({required this.task, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVE',
              style: t.kicker.copyWith(color: t.muted, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: t.title.copyWith(fontSize: 22),
              children: [
                TextSpan(text: task.title as String),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if ((task.sub as String?) != null)
            Text(task.sub as String, style: t.metadata),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String label;
  final JarvyRegister t;
  const _EmptyRow({required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Text(label,
          style: t.body.copyWith(
              color: t.faint, fontStyle: FontStyle.italic)),
    );
  }
}

// ── Calorie ring row ──────────────────────────────────────────────────────

class _CaloriesRow extends StatelessWidget {
  final CalorieSummary? summary;
  final JarvyRegister t;
  const _CaloriesRow({required this.summary, required this.t});

  @override
  Widget build(BuildContext context) {
    final s = summary ??
        const CalorieSummary(
            total: 1364, goal: 2200, protein: 92, carbs: 148, fat: 51);
    final pct = s.pct;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: _RingPainter(
                pct: pct,
                rule: t.rule,
                accent: t.accent,
              ),
            ),
          ),
          const SizedBox(width: JarvySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: t.title.copyWith(fontSize: 19),
                    children: [
                      TextSpan(text: '${_fmtKcal(s.total)} '),
                      TextSpan(
                          text: 'of',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: t.muted,
                              fontSize: 14)),
                      const TextSpan(text: ' 2,200 kcal'),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'protein ${s.protein.toStringAsFixed(0)}g · '
                  'carbs ${s.carbs.toStringAsFixed(0)}g · '
                  'fat ${s.fat.toStringAsFixed(0)}g',
                  style: t.metadata,
                ),
              ],
            ),
          ),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: t.metadata.copyWith(color: t.faint, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

// ── Workout row ───────────────────────────────────────────────────────────

class _WorkoutRow extends StatelessWidget {
  final dynamic workout; // Workout? from DB
  final JarvyRegister t;
  const _WorkoutRow({required this.workout, required this.t});

  @override
  Widget build(BuildContext context) {
    final hasWorkout = workout != null;
    final workoutLabel =
        hasWorkout ? workout.type as String : 'not yet';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: t.title.copyWith(fontSize: 18),
                    children: [
                      const TextSpan(text: 'Workout — '),
                      TextSpan(
                        text: workoutLabel,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: hasWorkout ? t.ink : t.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasWorkout
                      ? '${workout.durationMinutes}m · completed'
                      : 'Push day · planned 18:30',
                  style: t.metadata,
                ),
              ],
            ),
          ),
          if (!hasWorkout)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: t.accentDim ?? t.accent, width: 0.5),
                borderRadius:
                    BorderRadius.circular(JarvySpacing.radiusTight),
              ),
              child: Text('BEGIN',
                  style: t.kicker
                      .copyWith(color: t.accent, letterSpacing: 1.4)),
            ),
        ],
      ),
    );
  }
}

// ── Ring painter (48×48) ──────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double pct;
  final Color rule, accent;
  const _RingPainter({required this.pct, required this.rule, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    final bg = Paint()
      ..color = rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fg = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.accent != accent;
}

// ── Gear icon ─────────────────────────────────────────────────────────────

class _GearIcon extends StatelessWidget {
  final Color color;
  const _GearIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.settings_outlined, size: 18, color: color);
  }
}
