// settings_screen.dart — register: utility
// Neutral darks. Geist only. Boring on purpose. Fast, invisible when done.

import 'package:flutter/material.dart';
import '../theme/jarvy_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReview = true;
  bool _workoutReminder = true;
  bool _streakNudges = false;
  bool _libraryHighlights = false;
  bool _kineticAccent = true;
  bool _reduceMotion = false;

  @override
  Widget build(BuildContext context) {
    final t = JarvyTheme.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            JarvySpacing.md,
            0,
            MediaQuery.paddingOf(context).bottom + 80,
          ),
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  JarvySpacing.md, JarvySpacing.sm,
                  JarvySpacing.md, JarvySpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // Back chevron — visible when pushed as modal route
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: JarvySpacing.md),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 14, color: t.muted),
                      ),
                    ),
                  Expanded(
                    child: Text('Settings', style: t.displayLarge),
                  ),
                  Text('v0.3.1 · build 247',
                      style: t.mono.copyWith(color: t.faint, fontSize: 10)),
                ],
              ),
            ),

            // ── Account ───────────────────────────────────────────────────
            _Section(
              title: 'Account',
              t: t,
              children: [
                _NavRow(
                    label: 'Mira Singh', value: 'mira@jarvy.app', t: t),
                _NavRow(
                    label: 'iCloud sync', value: '2 min ago', t: t),
                _NavRow(
                    label: 'Export data', value: 'JSON · CSV', t: t,
                    last: true),
              ],
            ),

            // ── Day starts ────────────────────────────────────────────────
            _Section(
              title: 'Day starts',
              t: t,
              children: [
                _NavRow(
                    label: 'Wake time anchor', value: '6:30', t: t),
                _NavRow(
                    label: 'Day rolls over at', value: '3:00', t: t),
                _NavRow(
                    label: 'Week begins', value: 'Monday', t: t,
                    last: true),
              ],
            ),

            // ── Notifications ─────────────────────────────────────────────
            _Section(
              title: 'Notifications',
              t: t,
              children: [
                _ToggleRow(
                  label: 'Daily review',
                  hint: '22:30 · summarize the day',
                  value: _dailyReview,
                  onChanged: (v) => setState(() => _dailyReview = v),
                  t: t,
                ),
                _ToggleRow(
                  label: 'Workout reminder',
                  hint: '30m before scheduled session',
                  value: _workoutReminder,
                  onChanged: (v) => setState(() => _workoutReminder = v),
                  t: t,
                ),
                _ToggleRow(
                  label: 'Streak nudges',
                  hint: 'when an identity habit is at risk',
                  value: _streakNudges,
                  onChanged: (v) => setState(() => _streakNudges = v),
                  t: t,
                ),
                _ToggleRow(
                  label: 'Library highlights',
                  value: _libraryHighlights,
                  onChanged: (v) =>
                      setState(() => _libraryHighlights = v),
                  t: t,
                  last: true,
                ),
              ],
            ),

            // ── Registers ─────────────────────────────────────────────────
            _Section(
              title: 'Registers',
              t: t,
              children: [
                _NavRow(label: 'Active theme', value: 'auto', t: t),
                _NavRow(
                  label: 'Reduce motion',
                  value: _reduceMotion ? 'on' : 'off',
                  t: t,
                ),
                _ToggleRow(
                  label: 'Kinetic accent on workouts',
                  value: _kineticAccent,
                  onChanged: (v) => setState(() => _kineticAccent = v),
                  t: t,
                  last: true,
                ),
              ],
            ),

            // ── Restore CTA (the only blue thing) ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: JarvySpacing.md,
                  vertical: JarvySpacing.sm),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(
                            JarvySpacing.radiusSoft),
                      ),
                      child: Text(
                        'Restore from backup',
                        style: t.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: t.background,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: JarvySpacing.sm),
                  Text(
                    'Last backup: yesterday, 23:14',
                    style: t.metadata.copyWith(color: t.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: JarvySpacing.sm),

            // ── Danger zone ───────────────────────────────────────────────
            _Section(
              title: 'Danger zone',
              t: t,
              children: [
                _DangerRow(label: 'Sign out', t: t),
                _DangerRow(label: 'Delete all logs', t: t),
                _DangerRow(label: 'Delete account', t: t, last: true),
              ],
            ),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: JarvySpacing.md),
              child: Center(
                child: Text(
                  'jarvy · 2026 · made for one person at a time',
                  style:
                      t.mono.copyWith(color: t.faint, fontSize: 9, letterSpacing: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final JarvyRegister t;
  const _Section(
      {required this.title, required this.children, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: JarvySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                JarvySpacing.md, 0, JarvySpacing.md, 6),
            child: Text(
              title.toUpperCase(),
              style: t.kicker.copyWith(
                  color: t.muted, letterSpacing: 1.2),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: JarvySpacing.sm),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.rule, width: 0.5),
              borderRadius:
                  BorderRadius.circular(JarvySpacing.radiusSoft),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav row ───────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final String label;
  final String? value;
  final JarvyRegister t;
  final bool last;
  const _NavRow(
      {required this.label, required this.t, this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: JarvySpacing.md, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: t.rule, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: t.body),
          ),
          if (value != null) ...[
            Text(value!, style: t.metadata),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right, size: 14, color: t.faint),
        ],
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  final JarvyRegister t;
  final bool last;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.t,
    this.hint,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: JarvySpacing.md, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: t.rule, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.body),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!, style: t.metadata.copyWith(color: t.muted)),
                ],
              ],
            ),
          ),
          _JarvyToggle(value: value, onChanged: onChanged, t: t),
        ],
      ),
    );
  }
}

// ── Custom toggle switch ──────────────────────────────────────────────────

class _JarvyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final JarvyRegister t;
  const _JarvyToggle(
      {required this.value, required this.onChanged, required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 32,
        height: 19,
        decoration: BoxDecoration(
          color: value ? t.ink : t.rule,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: value ? t.ink : t.faint, width: 0.5),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              left: value ? 14.5 : 1.5,
              top: 1.5,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: value ? t.background : t.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Danger row ────────────────────────────────────────────────────────────

class _DangerRow extends StatelessWidget {
  final String label;
  final JarvyRegister t;
  final bool last;
  const _DangerRow(
      {required this.label, required this.t, this.last = false});

  @override
  Widget build(BuildContext context) {
    final red = t.destructive ?? oklch(.58, .16, 25);
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: JarvySpacing.md, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: t.rule, width: 0.5)),
        ),
        child: Text(label,
            style: t.body.copyWith(color: red)),
      ),
    );
  }
}
