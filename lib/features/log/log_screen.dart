// log_screen.dart — register: daily (kinetic accent on workout)
// Speed-first. Journal header, recent entries, sticky quick-add sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/jarvy_theme.dart';
import 'log_provider.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  LogKind _pick = LogKind.meal;
  final _inputController = TextEditingController();
  bool _showInput = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = JarvyTheme.of(context);
    final entriesAsync = ref.watch(todayLogEntriesProvider);
    final isWorkout = _pick == LogKind.workout;
    final inputAccent =
        isWorkout ? JarvyRegisters.kinetic.accent : t.accent;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────────────
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                JarvySpacing.lg,
                JarvySpacing.md,
                JarvySpacing.lg,
                MediaQuery.paddingOf(context).bottom + 220,
              ),
              children: [
                // ── Kicker ─────────────────────────────────────────────
                entriesAsync.when(
                  loading: () => Text('QUICK LOG',
                      style: t.kicker.copyWith(color: t.muted)),
                  error: (_, __) => Text('QUICK LOG',
                      style: t.kicker.copyWith(color: t.muted)),
                  data: (entries) => Text(
                    'QUICK LOG · ${entries.length} ENTRIES TODAY',
                    style: t.kicker.copyWith(color: t.muted),
                  ),
                ),
                const SizedBox(height: JarvySpacing.lg),

                // ── Title ──────────────────────────────────────────────
                RichText(
                  text: TextSpan(
                    style: t.displayLarge.copyWith(fontSize: 56),
                    children: [
                      const TextSpan(text: 'Mark it\n'),
                      TextSpan(
                        text: 'down.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: t.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: JarvySpacing.xl),

                // ── Earlier today ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: t.rule, width: 0.5)),
                  ),
                  child: Text('EARLIER TODAY',
                      style: t.kicker.copyWith(color: t.accent)),
                ),

                entriesAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: JarvySpacing.md),
                    child: Text('Loading…',
                        style: t.body.copyWith(color: t.faint)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: JarvySpacing.md),
                    child: Text('Could not load log entries.',
                        style: t.body.copyWith(color: t.muted)),
                  ),
                  data: (entries) => entries.isEmpty
                      ? _EmptyLog(t: t)
                      : Column(
                          children: entries
                              .map((e) => _LogEntryRow(entry: e, t: t))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),

          // ── Quick-add sheet (sticky above nav) ───────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 64,
            child: _QuickAddSheet(
              pick: _pick,
              onPick: (p) => setState(() {
                _pick = p;
                _showInput = true;
              }),
              inputAccent: inputAccent,
              showInput: _showInput,
              inputController: _inputController,
              t: t,
              onSubmit: _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    switch (_pick) {
      case LogKind.meal:
        await ref.read(logMealProvider).call(
              name: text,
              calories: 0, // user can fill in later
            );
      case LogKind.workout:
        await ref.read(logWorkoutProvider).call(text, 0, '');
      case LogKind.link:
        await ref.read(logPinProvider).call(text, 'link', '');
      case LogKind.habit:
        // toggle habit — handled elsewhere
        break;
    }

    _inputController.clear();
    setState(() => _showInput = false);
  }
}

// ── Log entry row ─────────────────────────────────────────────────────────

class _LogEntryRow extends StatelessWidget {
  final LogEntry entry;
  final JarvyRegister t;
  const _LogEntryRow({required this.entry, required this.t});

  Color _kindColor(JarvyRegister t) {
    switch (entry.kind) {
      case LogKind.workout:
        return JarvyRegisters.kinetic.accent;
      case LogKind.meal:
      case LogKind.habit:
        return t.accent;
      case LogKind.link:
        return t.muted;
    }
  }

  String get _kindLabel {
    switch (entry.kind) {
      case LogKind.meal:    return 'MEAL';
      case LogKind.habit:   return 'HABIT';
      case LogKind.workout: return 'WORKOUT';
      case LogKind.link:    return 'LINK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule, width: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Time
          SizedBox(
            width: 38,
            child: Text(entry.time,
                style: t.mono.copyWith(color: t.faint, fontSize: 10)),
          ),
          const SizedBox(width: 8),
          // Kind chip
          SizedBox(
            width: 52,
            child: Text(_kindLabel,
                style: t.mono.copyWith(
                    color: _kindColor(t),
                    fontSize: 9,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(width: 8),
          // Label
          Expanded(
            child: Text(
              entry.label,
              style: t.title.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          // Value
          Text(entry.value,
              style: t.mono.copyWith(color: t.muted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Quick-add sheet ───────────────────────────────────────────────────────

class _QuickAddSheet extends StatelessWidget {
  final LogKind pick;
  final void Function(LogKind) onPick;
  final Color inputAccent;
  final bool showInput;
  final TextEditingController inputController;
  final JarvyRegister t;
  final VoidCallback onSubmit;

  const _QuickAddSheet({
    required this.pick,
    required this.onPick,
    required this.inputAccent,
    required this.showInput,
    required this.inputController,
    required this.t,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(
          top: BorderSide(color: t.rule, width: 0.5),
          bottom: BorderSide(
              color: pick == LogKind.workout
                  ? JarvyRegisters.kinetic.accent
                  : Colors.transparent,
              width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: t.background.withValues(alpha: 0.9),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          JarvySpacing.lg, JarvySpacing.md, JarvySpacing.lg, JarvySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: t.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Picker row
          Row(
            children: [
              _PickerChip(
                label: 'MEAL',
                icon: Icons.restaurant_outlined,
                active: pick == LogKind.meal,
                accent: t.accent,
                onTap: () => onPick(LogKind.meal),
                t: t,
              ),
              const SizedBox(width: JarvySpacing.sm),
              _PickerChip(
                label: 'HABIT',
                icon: Icons.check_outlined,
                active: pick == LogKind.habit,
                accent: t.accent,
                onTap: () => onPick(LogKind.habit),
                t: t,
              ),
              const SizedBox(width: JarvySpacing.sm),
              _PickerChip(
                label: 'WORKOUT',
                icon: Icons.show_chart,
                active: pick == LogKind.workout,
                accent: JarvyRegisters.kinetic.accent,
                onTap: () => onPick(LogKind.workout),
                t: t,
              ),
              const SizedBox(width: JarvySpacing.sm),
              _PickerChip(
                label: 'LINK',
                icon: Icons.link_outlined,
                active: pick == LogKind.link,
                accent: t.accent,
                onTap: () => onPick(LogKind.link),
                t: t,
              ),
            ],
          ),

          const SizedBox(height: JarvySpacing.md),

          // Contextual input
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(JarvySpacing.md),
            decoration: BoxDecoration(
              color: inputAccent.withValues(alpha: 0.08),
              border: Border.all(color: inputAccent, width: 0.5),
              borderRadius: BorderRadius.circular(JarvySpacing.radiusTight),
            ),
            child: Row(
              children: [
                // Kind label
                SizedBox(
                  width: 60,
                  child: Text(
                    _pickLabel(pick),
                    style: t.mono.copyWith(
                        color: inputAccent,
                        fontSize: 10,
                        letterSpacing: 1.4),
                  ),
                ),
                const SizedBox(width: 8),
                // Input field
                Expanded(
                  child: TextField(
                    controller: inputController,
                    style: t.title.copyWith(fontSize: 18),
                    cursorColor: inputAccent,
                    decoration: InputDecoration(
                      hintText: _hintText(pick),
                      hintStyle: t.title.copyWith(
                          fontSize: 18,
                          color: t.faint,
                          fontStyle: FontStyle.italic),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                // Submit button
                GestureDetector(
                  onTap: onSubmit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: inputAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_upward,
                        color: t.background, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HOLD TO DICTATE',
                  style: t.metadata.copyWith(
                      color: t.muted, letterSpacing: 1.4)),
              if (pick == LogKind.workout)
                Text('↑↑ KINETIC MODE',
                    style: t.metadata.copyWith(
                        color: JarvyRegisters.kinetic.accent,
                        letterSpacing: 1.4)),
            ],
          ),
        ],
      ),
    );
  }

  String _pickLabel(LogKind k) {
    switch (k) {
      case LogKind.meal:    return 'meal';
      case LogKind.habit:   return 'habit';
      case LogKind.workout: return 'kinetic';
      case LogKind.link:    return 'link';
    }
  }

  String _hintText(LogKind k) {
    switch (k) {
      case LogKind.meal:    return 'What did you eat?';
      case LogKind.habit:   return 'Which habit?';
      case LogKind.workout: return 'Push day, working set…';
      case LogKind.link:    return 'Paste a URL or title…';
    }
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  final JarvyRegister t;
  const _PickerChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.10) : Colors.transparent,
            border: Border.all(
                color: active ? accent : t.rule, width: 0.5),
            borderRadius: BorderRadius.circular(JarvySpacing.radiusTight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18, color: active ? accent : t.muted),
              const SizedBox(height: 4),
              Text(
                label,
                style: t.kicker.copyWith(
                  color: active ? accent : t.muted,
                  fontSize: 9,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  final JarvyRegister t;
  const _EmptyLog({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JarvySpacing.xl),
      child: Center(
        child: Text(
          'Nothing logged yet — tap above to start.',
          style: t.body.copyWith(
              color: t.faint, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
