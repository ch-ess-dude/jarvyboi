// do_screen.dart — register: ritual
// Warm dark, copper/rust accent. DM Serif Display + Geist.
// Habits as streak meters + heat strips; tasks as a today agenda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/jarvy_theme.dart';
import 'do_provider.dart';

class DoScreen extends ConsumerWidget {
  const DoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = JarvyTheme.of(context);
    final habitsAsync = ref.watch(habitsWithHeatProvider);
    final todayTasksAsync = ref.watch(todayTasksProvider);
    final weekTasksAsync = ref.watch(weekTasksProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                JarvySpacing.lg, JarvySpacing.md,
                JarvySpacing.lg, 0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Header ─────────────────────────────────────────────
                  Text(
                    'RITUAL · ${habitsAsync.maybeWhen(data: (h) => '${h.length} HABITS', orElse: () => '—')} · '
                    '${todayTasksAsync.maybeWhen(data: (tasks) => '${tasks.length} OPEN', orElse: () => '—')}',
                    style: t.kicker.copyWith(color: t.accent),
                  ),
                  const SizedBox(height: JarvySpacing.md),
                  RichText(
                    text: TextSpan(
                      style: t.displayLarge,
                      children: [
                        const TextSpan(text: 'The work\n'),
                        TextSpan(
                          text: 'repeated.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: t.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: JarvySpacing.lg),

                  // ── Habits section ─────────────────────────────────────
                  _SectionHeader(
                    left: 'HABITS · LAST 21 DAYS',
                    right: habitsAsync.maybeWhen(
                      data: (h) =>
                          '${h.where((e) => e.completedToday).length} / ${h.length} TODAY',
                      orElse: () => '',
                    ),
                    t: t,
                  ),
                  habitsAsync.when(
                    loading: () => _loadingRow(t),
                    error: (e, _) => _errorRow(t),
                    data: (habits) => Column(
                      children: habits
                          .map((h) => _HabitRow(row: h, t: t, ref: ref))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: JarvySpacing.lg),

                  // ── Today tasks ────────────────────────────────────────
                  _SectionHeader(
                    left: 'TODAY',
                    right: '+ NEW',
                    t: t,
                  ),
                  todayTasksAsync.when(
                    loading: () => _loadingRow(t),
                    error: (e, _) => _errorRow(t),
                    data: (tasks) => tasks.isEmpty
                        ? _EmptyTasks(t: t)
                        : Column(
                            children: tasks
                                .map((task) =>
                                    _TaskRow(task: task, t: t, ref: ref))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: JarvySpacing.lg),

                  // ── Later this week ────────────────────────────────────
                  weekTasksAsync.maybeWhen(
                    data: (tasks) => tasks.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                  left: 'LATER THIS WEEK', t: t),
                              ...tasks.map((task) =>
                                  _TaskRow(task: task, t: t, ref: ref)),
                            ],
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingRow(JarvyRegister t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
        child: Text('Loading…', style: t.body.copyWith(color: t.faint)),
      );

  Widget _errorRow(JarvyRegister t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
        child: Text('Could not load data.',
            style: t.body.copyWith(color: t.muted)),
      );
}

// ── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String left;
  final String? right;
  final JarvyRegister t;
  const _SectionHeader({required this.left, required this.t, this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: t.kicker),
          if (right != null)
            Text(right!, style: t.metadata.copyWith(letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

// ── Habit row with heat strip ─────────────────────────────────────────────

class _HabitRow extends StatelessWidget {
  final HabitWithHeat row;
  final JarvyRegister t;
  final WidgetRef ref;
  const _HabitRow({required this.row, required this.t, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.md),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        children: [
          // Left: habit name + state
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.habit.name,
                    style: t.body.copyWith(
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      row.completedToday
                          ? 'TODAY · DONE'
                          : 'TODAY · OPEN',
                      style: t.kicker.copyWith(
                          color: row.completedToday ? t.accent : t.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: JarvySpacing.md),
          // Right: streak number + heat strip
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    row.habit.streakCount.toString(),
                    style: t.displayMedium.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('days',
                      style: t.kicker.copyWith(
                          color: t.muted, fontSize: 9)),
                ],
              ),
              const SizedBox(height: 8),
              _HeatStrip(heat: row.heat21, t: t),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 21-cell heat strip ────────────────────────────────────────────────────

class _HeatStrip extends StatelessWidget {
  final List<int> heat;
  final JarvyRegister t;
  const _HeatStrip({required this.heat, required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 14,
      child: Row(
        children: heat.map((cell) {
          Color bg;
          if (cell == 1) {
            bg = t.accent;
          } else if (cell == 2) {
            // today, open
            bg = (t.accentDim ?? t.accent).withValues(alpha: 0.35);
          } else {
            bg = t.rule;
          }
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    BorderRadius.circular(JarvySpacing.radiusTight),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final dynamic task;
  final JarvyRegister t;
  final WidgetRef ref;
  const _TaskRow({required this.task, required this.t, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.overdue as bool? ?? false;
    final isDone = task.completed as bool? ?? false;
    final overdueColor = t.destructive ?? oklch(.62, .16, 30);

    return GestureDetector(
      onTap: () {
        ref.read(taskToggleProvider)
            .call(task.id as int, !(task.completed as bool));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 3, right: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDone
                      ? t.accent
                      : isOverdue
                          ? overdueColor
                          : t.faint,
                  width: 1,
                ),
                color: isDone ? t.accent : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(JarvySpacing.radiusTight),
              ),
              child: isDone
                  ? Icon(Icons.check, size: 9, color: t.background)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title as String,
                    style: t.body.copyWith(
                      color: isDone ? t.muted : t.ink,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: t.faint,
                    ),
                  ),
                  if ((task.sub as String?) != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.sub as String,
                      style: t.metadata.copyWith(
                        color: isOverdue ? overdueColor : t.muted,
                        fontWeight: isOverdue
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if ((task.scheduledLabel as String?) != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  task.scheduledLabel as String,
                  style: t.kicker.copyWith(
                      color: t.accent, letterSpacing: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final JarvyRegister t;
  const _EmptyTasks({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.lg),
      child: Text('All clear — nothing due today.',
          style: t.body.copyWith(
              color: t.faint, fontStyle: FontStyle.italic)),
    );
  }
}
