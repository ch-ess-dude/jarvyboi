// main_nav.dart — 6-tab register-adaptive bottom navigation.
// Long-press on nav bar summons the agent panel overlay.
// Sliding pill indicator follows the active tab.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/jarvy_theme.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/do/do_screen.dart';
import '../features/log/log_screen.dart';
import '../features/body/body_screen.dart';
import '../features/build/build_screen.dart';
import '../features/library/library_screen.dart';
import '../features/agent/agent_panel.dart';
import '../features/agent/agent_provider.dart';

// ── Tab state ─────────────────────────────────────────────────────────────

final activeTabProvider = StateProvider<int>((ref) => 0);

// ── Tab metadata ──────────────────────────────────────────────────────────

const _tabIds     = ['day',  'do',    'log',  'body',    'build',    'library'];
const _tabLabels  = ['Day',  'Do',    'Log',  'Body',    'Build',    'Library'];

JarvyRegister _registerFor(int i) {
  switch (i) {
    case 1:  return JarvyRegisters.ritual;
    case 3:  return JarvyRegisters.kinetic;
    case 4:  return JarvyRegisters.ambition;
    case 5:  return JarvyRegisters.literary;
    default: return JarvyRegisters.daily; // 0 = dashboard, 2 = log
  }
}

// ── Main Nav ──────────────────────────────────────────────────────────────

class MainNav extends ConsumerWidget {
  const MainNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIdx   = ref.watch(activeTabProvider);
    final activeReg   = _registerFor(activeIdx);
    final panelVisible = ref.watch(agentPanelVisibleProvider);

    return JarvyTheme(
      register: activeReg,
      child: Scaffold(
        backgroundColor: activeReg.background,
        body: Stack(
          children: [
            // ── Screen stack (IndexedStack preserves scroll / state) ───
            IndexedStack(
              index: activeIdx,
              children: const [
                _WrappedDashboard(),
                _WrappedDo(),
                _WrappedLog(),
                _WrappedBody(),
                _WrappedBuild(),
                _WrappedLibrary(),
              ],
            ),

            // ── Agent panel overlay ───────────────────────────────────
            if (panelVisible)
              Positioned.fill(
                child: GestureDetector(
                  // Tap outside the panel to dismiss.
                  onTap: () =>
                      ref.read(agentPanelVisibleProvider.notifier).hide(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.62,
                      child: GestureDetector(
                        // Prevent tap-through to dismissal layer.
                        onTap: () {},
                        child: const AgentPanel(),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Bottom nav overlay ────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _JarvyBottomNav(
                activeIndex: activeIdx,
                activeRegister: activeReg,
                onTap: (i) =>
                    ref.read(activeTabProvider.notifier).state = i,
                onLongPress: () =>
                    ref.read(agentPanelVisibleProvider.notifier).toggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widgets so each screen always has its JarvyTheme regardless of
// which tab is currently active at the top of the stack.

class _WrappedDashboard extends StatelessWidget {
  const _WrappedDashboard();
  @override
  Widget build(BuildContext context) =>
      JarvyTheme(register: JarvyRegisters.daily,    child: const DashboardScreen());
}

class _WrappedDo extends StatelessWidget {
  const _WrappedDo();
  @override
  Widget build(BuildContext context) =>
      JarvyTheme(register: JarvyRegisters.ritual,   child: const DoScreen());
}

class _WrappedLog extends StatelessWidget {
  const _WrappedLog();
  @override
  Widget build(BuildContext context) =>
      JarvyTheme(register: JarvyRegisters.daily,    child: const LogScreen());
}

class _WrappedBody extends StatelessWidget {
  const _WrappedBody();
  @override
  Widget build(BuildContext context) =>
      JarvyTheme(register: JarvyRegisters.kinetic,  child: const BodyScreen());
}

class _WrappedBuild extends StatelessWidget {
  const _WrappedBuild();
  @override
  Widget build(BuildContext context) =>
      JarvyTheme(register: JarvyRegisters.ambition, child: const BuildScreen());
}

class _WrappedLibrary extends StatelessWidget {
  const _WrappedLibrary();
  @override
  Widget build(BuildContext context) =>
      JarvyTheme(register: JarvyRegisters.literary, child: const LibraryScreen());
}

// ── Bottom nav bar ────────────────────────────────────────────────────────

class _JarvyBottomNav extends StatelessWidget {
  final int activeIndex;
  final JarvyRegister activeRegister;
  final ValueChanged<int> onTap;
  final VoidCallback onLongPress;

  const _JarvyBottomNav({
    required this.activeIndex,
    required this.activeRegister,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: activeRegister.background.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: 12,
              bottom: math.max(bottomPad, 12),
            ),
            child: Stack(
              children: [
                // ── Sliding pill indicator ─────────────────────────────
                _SlidingPill(
                  activeIndex: activeIndex,
                  tabCount: _tabIds.length,
                  color: activeRegister.accent,
                ),
                // ── Tab items ──────────────────────────────────────────
                Row(
                  children: List.generate(
                    _tabIds.length,
                    (i) => _NavItem(
                      id: _tabIds[i],
                      label: _tabLabels[i],
                      active: i == activeIndex,
                      accent: activeRegister.accent,
                      muted: activeRegister.muted,
                      onTap: () => onTap(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sliding pill indicator ────────────────────────────────────────────────

class _SlidingPill extends StatefulWidget {
  final int activeIndex;
  final int tabCount;
  final Color color;

  const _SlidingPill({
    required this.activeIndex,
    required this.tabCount,
    required this.color,
  });

  @override
  State<_SlidingPill> createState() => _SlidingPillState();
}

class _SlidingPillState extends State<_SlidingPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.activeIndex.toDouble();
    _to   = widget.activeIndex.toDouble();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );
  }

  @override
  void didUpdateWidget(_SlidingPill old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) {
      _from = old.activeIndex.toDouble();
      _to   = widget.activeIndex.toDouble();
      _ctrl
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final tabW = constraints.maxWidth / widget.tabCount;
      return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final pos = _from + (_to - _from) * _anim.value;
          return Padding(
            padding: EdgeInsets.only(left: pos * tabW + tabW * 0.2),
            child: Container(
              width: tabW * 0.6,
              height: 2,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        },
      );
    });
  }
}

// ── Individual nav item ───────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final String id, label;
  final bool active;
  final Color accent, muted;
  final VoidCallback onTap;

  const _NavItem({
    required this.id,
    required this.label,
    required this.active,
    required this.accent,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : muted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(
                painter: _NavIconPainter(id: id, color: color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav icon painter (22×22 SVG units → 20×20 px) ────────────────────────

class _NavIconPainter extends CustomPainter {
  final String id;
  final Color color;
  const _NavIconPainter({required this.id, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 22.0;
    canvas.scale(scale, scale);

    final s = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (id) {
      case 'day':
        canvas.drawCircle(const Offset(11, 11), 4, s);
        for (final pair in [
          [const Offset(11,  2), const Offset(11,  4)],
          [const Offset(11, 18), const Offset(11, 20)],
          [const Offset( 2, 11), const Offset( 4, 11)],
          [const Offset(18, 11), const Offset(20, 11)],
          [const Offset(4.6, 4.6),   const Offset(6.0,  6.0)],
          [const Offset(16.0, 16.0), const Offset(17.4, 17.4)],
          [const Offset(4.6, 17.4),  const Offset(6.0,  16.0)],
          [const Offset(16.0, 6.0),  const Offset(17.4, 4.6)],
        ]) {
          canvas.drawLine(pair[0], pair[1], s);
        }

      case 'do':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(4, 4, 14, 14), const Radius.circular(1)),
          s,
        );
        canvas.drawPath(
          Path()
            ..moveTo(7, 11.5)
            ..lineTo(9.6, 14.1)
            ..lineTo(15.5, 8.2),
          s,
        );

      case 'log':
        final ps = Paint()
          ..color = color
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(11, 4),  const Offset(11, 18), ps);
        canvas.drawLine(const Offset( 4, 11), const Offset(18, 11), ps);

      case 'body':
        canvas.drawPath(
          Path()
            ..moveTo(3, 18)
            ..lineTo(9, 9)
            ..lineTo(13, 13)
            ..lineTo(19, 4),
          s,
        );
        canvas.drawCircle(
          const Offset(19, 4), 1.4,
          Paint()..color = color..style = PaintingStyle.fill,
        );

      case 'build':
        canvas.drawLine(const Offset( 4,  5), const Offset(18, 5), s);
        canvas.drawLine(const Offset( 4, 11), const Offset(14, 11), s);
        canvas.drawLine(const Offset( 4, 17), const Offset(10, 17), s);

      case 'library':
        canvas.drawLine(const Offset(4, 4), const Offset(4, 18), s);
        canvas.drawLine(const Offset(8, 4), const Offset(8, 18), s);
        canvas.drawPath(
          Path()
            ..moveTo(13, 5)
            ..lineTo(17, 18),
          s,
        );
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter old) =>
      old.color != color || old.id != id;
}
