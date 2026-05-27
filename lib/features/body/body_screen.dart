// body_screen.dart — register: kinetic
// Cool dark, electric green. Sora Bold + JetBrains Mono.
// 3 concentric rings, macro split bar, weekly workout chart.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/jarvy_theme.dart';
import '../dashboard/dashboard_provider.dart' show CalorieSummary;
import 'body_provider.dart';

class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Cubic(0.16, 1, 0.3, 1), // ease-out-expo
    );
    // Trigger after first frame so the ring "draws in"
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = JarvyTheme.of(context);
    final bodyAsync = ref.watch(bodyDataProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: bodyAsync.when(
        loading: () => _buildContent(context, t, null, null),
        error: (e, _) => Center(
            child: Text('Error', style: t.body.copyWith(color: t.muted))),
        data: (data) =>
            _buildContent(context, t, data.calorieSummary, data.weekWorkouts),
      ),
    );
  }

  Widget _buildContent(BuildContext context, JarvyRegister t,
      CalorieSummary? cal, List<dynamic>? workouts) {
    final s = cal ??
        const CalorieSummary(
            total: 1364, goal: 2200, protein: 92, carbs: 148, fat: 51);

    // macro totals for ring percentages
    final macroTotal = s.protein + s.carbs + s.fat;
    final proteinPct = macroTotal > 0 ? s.protein / macroTotal : 0.27;
    final carbsPct = macroTotal > 0 ? s.carbs / macroTotal : 0.43;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          JarvySpacing.md,
          JarvySpacing.md,
          JarvySpacing.md,
          MediaQuery.paddingOf(context).bottom + 80,
        ),
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KINETIC · LIVE',
                      style: t.kicker.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text('Body', style: t.displayMedium),
                ],
              ),
              // HR live indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: t.accentDim ?? t.accent, width: 0.5),
                  borderRadius:
                      BorderRadius.circular(JarvySpacing.radiusTight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: t.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: t.accent.withValues(alpha: 0.6),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('HR 64',
                        style: t.mono.copyWith(
                            color: t.accent,
                            fontSize: 9,
                            letterSpacing: 1.4)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: JarvySpacing.lg),

          // ── Rings + macros ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) => SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _ThreeRingsPainter(
                      progress: _anim.value,
                      calPct: s.pct,
                      proteinPct: proteinPct,
                      carbsPct: carbsPct,
                      ruleColor: t.rule,
                      calColor: t.accent,
                      proteinColor: oklch(.80, .14, 70),
                      carbsColor: oklch(.75, .16, 230),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(s.pct * 100).toStringAsFixed(0)}%',
                            style: t.displayMedium.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text('OF DAILY',
                              style: t.mono.copyWith(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: t.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: JarvySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CALORIES',
                        style: t.mono.copyWith(
                            fontSize: 9,
                            color: t.muted,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: t.displayMedium.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1),
                        children: [
                          TextSpan(
                              text: _fmt(s.total)),
                          TextSpan(
                            text: ' / 2200',
                            style: t.mono.copyWith(
                                fontSize: 14, color: t.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MacroBar(s: s, t: t),
                  ],
                ),
              ),
            ],
          ),

          // ── Rule ───────────────────────────────────────────────────────
          Container(
              height: 0.5,
              color: t.rule,
              margin:
                  const EdgeInsets.symmetric(vertical: JarvySpacing.md)),

          // ── Stat row ───────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: _StatCell(
                        label: 'STEPS',
                        value: '5,284',
                        sub: '↑ 41% vs avg',
                        t: t)),
                Container(width: 0.5, color: t.rule),
                Expanded(
                    child: _StatCell(
                        label: 'RESTING HR',
                        value: '58',
                        unit: 'bpm',
                        sub: '−2 bpm 7d',
                        t: t)),
                Container(width: 0.5, color: t.rule),
                Expanded(
                    child: _StatCell(
                        label: 'SLEEP',
                        value: '7h 12m',
                        sub: '91% efficient',
                        t: t)),
              ],
            ),
          ),

          // ── Rule ───────────────────────────────────────────────────────
          Container(
              height: 0.5,
              color: t.rule,
              margin:
                  const EdgeInsets.symmetric(vertical: JarvySpacing.md)),

          // ── This week ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('THIS WEEK',
                  style: t.kicker.copyWith(letterSpacing: 1.4)),
              Text('${workouts?.length ?? 0} / 6 PLANNED',
                  style: t.mono.copyWith(fontSize: 10, color: t.muted)),
            ],
          ),
          const SizedBox(height: JarvySpacing.md),
          _WeekBars(workouts: workouts, t: t),
          const SizedBox(height: JarvySpacing.md),

          // ── Next session callout ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: JarvySpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.08),
              border: Border.all(
                  color: t.accentDim ?? t.accent, width: 0.5),
              borderRadius:
                  BorderRadius.circular(JarvySpacing.radiusTight),
            ),
            child: Row(
              children: [
                Text('NEXT',
                    style: t.mono.copyWith(
                        color: t.accent,
                        fontSize: 9,
                        letterSpacing: 1.4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Push · Bench, OHP, Dips',
                          style: t.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 2),
                      Text('18:30 · est. 52 min · last week +5lb',
                          style: t.mono.copyWith(
                              fontSize: 10, color: t.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius:
                        BorderRadius.circular(JarvySpacing.radiusTight),
                  ),
                  child: Text('START',
                      style: t.kicker.copyWith(
                          color: t.background,
                          fontSize: 11,
                          letterSpacing: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}

// ── Macro bar ─────────────────────────────────────────────────────────────

class _MacroBar extends StatelessWidget {
  final CalorieSummary s;
  final JarvyRegister t;
  const _MacroBar({required this.s, required this.t});

  @override
  Widget build(BuildContext context) {
    final total = s.protein + s.carbs + s.fat;
    if (total == 0) return const SizedBox.shrink();

    final items = [
      (
        label: 'P',
        value: s.protein,
        pct: s.protein / total,
        color: t.accent
      ),
      (
        label: 'C',
        value: s.carbs,
        pct: s.carbs / total,
        color: oklch(.78, .14, 70)
      ),
      (
        label: 'F',
        value: s.fat,
        pct: s.fat / total,
        color: oklch(.75, .14, 230)
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: items
                  .map((m) => Flexible(
                        flex: (m.pct * 100).round(),
                        child: Container(color: m.color),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items
              .map((m) => Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(m.label,
                          style: t.mono.copyWith(
                              color: m.color,
                              fontSize: 10,
                              letterSpacing: 0.6)),
                      const SizedBox(width: 4),
                      Text(m.value.toStringAsFixed(0),
                          style: t.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              letterSpacing: -0.3)),
                      const SizedBox(width: 2),
                      Text('g',
                          style: t.mono.copyWith(
                              color: t.muted, fontSize: 9)),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label, value;
  final String? unit, sub;
  final JarvyRegister t;
  const _StatCell(
      {required this.label,
      required this.value,
      required this.t,
      this.unit,
      this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(JarvySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: t.mono.copyWith(
                  fontSize: 9,
                  color: t.muted,
                  letterSpacing: 1.4)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    style: t.displayMedium.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8)),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit!,
                    style: t.mono.copyWith(
                        fontSize: 11, color: t.muted)),
              ],
            ],
          ),
          if (sub != null)
            Text(sub!,
                style: t.mono.copyWith(
                    fontSize: 9,
                    color: t.accent,
                    letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

// ── Weekly workout bars ───────────────────────────────────────────────────

class _WeekBars extends StatelessWidget {
  final List<dynamic>? workouts;
  final JarvyRegister t;
  const _WeekBars({required this.workouts, required this.t});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const maxH = 44.0;

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final day = days[i];
          final isToday = day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;
          final workout = workouts?.where((w) {
            final d = w.date as DateTime;
            return d.year == day.year &&
                d.month == day.month &&
                d.day == day.day;
          }).firstOrNull;

          final hasWorkout = workout != null;
          final dur =
              hasWorkout ? (workout.durationMinutes as int) : 0;
          final barH =
              hasWorkout ? (dur / 60.0 * maxH).clamp(4.0, maxH) : 3.0;

          return Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barH,
                    decoration: BoxDecoration(
                      color: hasWorkout
                          ? t.accent
                          : isToday
                              ? t.accent.withValues(alpha: 0.15)
                              : t.rule,
                      borderRadius: BorderRadius.circular(
                          JarvySpacing.radiusTight),
                      border: isToday && !hasWorkout
                          ? Border.all(
                              color: (t.accentDim ?? t.accent)
                                  .withValues(alpha: 0.5),
                              width: 0.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabels[i],
                    style: t.mono.copyWith(
                      fontSize: 9,
                      color: isToday ? t.accent : t.muted,
                      fontWeight: isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Three-ring painter (200×200) ──────────────────────────────────────────

class _ThreeRingsPainter extends CustomPainter {
  final double progress;
  final double calPct, proteinPct, carbsPct;
  final Color ruleColor, calColor, proteinColor, carbsColor;

  const _ThreeRingsPainter({
    required this.progress,
    required this.calPct,
    required this.proteinPct,
    required this.carbsPct,
    required this.ruleColor,
    required this.calColor,
    required this.proteinColor,
    required this.carbsColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rings = [
      (r: 84.0, pct: calPct.clamp(0, 1),     color: calColor),
      (r: 66.0, pct: proteinPct.clamp(0, 1), color: proteinColor),
      (r: 48.0, pct: carbsPct.clamp(0, 1),   color: carbsColor),
    ];

    for (final ring in rings) {
      final bg = Paint()
        ..color = ruleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      final fg = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(Offset(cx, cy), ring.r, bg);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: ring.r),
        -math.pi / 2,
        2 * math.pi * ring.pct * progress,
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_ThreeRingsPainter old) =>
      old.progress != progress ||
      old.calPct != calPct ||
      old.proteinPct != proteinPct ||
      old.carbsPct != carbsPct;
}
