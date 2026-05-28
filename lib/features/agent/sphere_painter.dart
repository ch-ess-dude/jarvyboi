// sphere_painter.dart — Animated mesh sphere CustomPainter.
// Latitude ellipses + rotated longitude ellipses, state-driven animation.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'agent_provider.dart';

class SpherePainter extends CustomPainter {
  final double rotation;     // 0..2π  — longitude rotation
  final double breathe;      // 0..1   — idle pulse scale
  final AgentState state;
  final double opacity;      // 0..1   — for fade transitions

  SpherePainter({
    required this.rotation,
    required this.breathe,
    required this.state,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Base radius, breathing scale for idle.
    final breathScale = state == AgentState.idle
        ? 1.0 + breathe * 0.04
        : state == AgentState.listening
            ? 1.0 + breathe * 0.08
            : 1.0;
    final r = (size.shortestSide / 2 - 6) * breathScale;

    // Sphere color per state.
    final color = _stateColor(state).withValues(alpha: opacity);
    final glowColor = _stateColor(state).withValues(alpha: opacity * 0.18);

    // Glow ring behind sphere.
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(cx, cy), r * 1.35, glowPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth(state);

    // ── Latitude circles (horizontal ellipses) ──────────────────────────
    const latCount = 7;
    for (int i = 0; i < latCount; i++) {
      final t = -1.0 + 2.0 * i / (latCount - 1); // -1..1
      final y = cy + r * t;
      final latR = r * math.sqrt(1 - t * t);
      if (latR < 1) continue;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, y), width: latR * 2, height: latR * 0.42),
        linePaint,
      );
    }

    // ── Longitude arcs (vertical ellipses rotated by angle) ───────────
    const lonCount = 6;
    for (int i = 0; i < lonCount; i++) {
      final angle = rotation + math.pi * i / lonCount;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: r * 0.42, height: r * 2),
        linePaint,
      );
      canvas.restore();
    }

    // ── Equator (brighter) ───────────────────────────────────────────
    final equatorPaint = Paint()
      ..color = color.withValues(alpha: opacity * (state == AgentState.offline ? 0.3 : 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth(state) * 1.4;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: r * 2, height: r * 0.42),
      equatorPaint,
    );

    // ── Processing: rotating highlight arc ────────────────────────────
    if (state == AgentState.processing || state == AgentState.responding) {
      final arcPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation * 2.2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi * 0.55,
        false,
        arcPaint,
      );
      canvas.restore();
    }

    // ── Offline: X over sphere ────────────────────────────────────────
    if (state == AgentState.offline) {
      final offlinePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(cx - r * 0.4, cy - r * 0.4),
          Offset(cx + r * 0.4, cy + r * 0.4),
          offlinePaint);
      canvas.drawLine(
          Offset(cx + r * 0.4, cy - r * 0.4),
          Offset(cx - r * 0.4, cy + r * 0.4),
          offlinePaint);
    }
  }

  Color _stateColor(AgentState s) {
    switch (s) {
      case AgentState.idle:
        return const Color(0xFF4DD9C0); // oklch(0.72, 0.18, 200) ≈ cyan
      case AgentState.listening:
        return const Color(0xFF7ECFFF); // lighter blue
      case AgentState.processing:
        return const Color(0xFFFFD97A); // amber
      case AgentState.responding:
        return const Color(0xFF82E8A0); // green
      case AgentState.offline:
        return const Color(0xFF888888); // grey
    }
  }

  double _strokeWidth(AgentState s) {
    switch (s) {
      case AgentState.listening:
        return 1.6;
      case AgentState.processing:
      case AgentState.responding:
        return 1.3;
      default:
        return 1.0;
    }
  }

  @override
  bool shouldRepaint(SpherePainter old) =>
      old.rotation != rotation ||
      old.breathe != breathe ||
      old.state != state ||
      old.opacity != opacity;
}

// ── Animated sphere widget ────────────────────────────────────────────────────
class AnimatedSphere extends StatefulWidget {
  final AgentState state;
  final double size;

  const AnimatedSphere({
    super.key,
    required this.state,
    this.size = 120,
  });

  @override
  State<AnimatedSphere> createState() => _AnimatedSphereState();
}

class _AnimatedSphereState extends State<AnimatedSphere>
    with TickerProviderStateMixin {
  late AnimationController _rotationCtrl;
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _breatheAnim = CurvedAnimation(
      parent: _breatheCtrl,
      curve: Curves.easeInOut,
    );

    _updateSpeeds();
  }

  @override
  void didUpdateWidget(AnimatedSphere old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _updateSpeeds();
  }

  void _updateSpeeds() {
    switch (widget.state) {
      case AgentState.idle:
        _rotationCtrl.duration = const Duration(seconds: 8);
        _breatheCtrl.duration = const Duration(milliseconds: 2600);
        break;
      case AgentState.listening:
        _rotationCtrl.duration = const Duration(seconds: 4);
        _breatheCtrl.duration = const Duration(milliseconds: 900);
        break;
      case AgentState.processing:
        _rotationCtrl.duration = const Duration(seconds: 2);
        _breatheCtrl.duration = const Duration(milliseconds: 500);
        break;
      case AgentState.responding:
        _rotationCtrl.duration = const Duration(seconds: 3);
        _breatheCtrl.duration = const Duration(milliseconds: 1200);
        break;
      case AgentState.offline:
        _rotationCtrl.duration = const Duration(seconds: 16);
        _breatheCtrl.duration = const Duration(seconds: 4);
        break;
    }
    // Re-trigger so new duration takes effect.
    _rotationCtrl
      ..reset()
      ..repeat();
    _breatheCtrl
      ..reset()
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationCtrl, _breatheCtrl]),
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: SpherePainter(
          rotation: _rotationCtrl.value * 2 * math.pi,
          breathe: _breatheAnim.value,
          state: widget.state,
        ),
      ),
    );
  }
}
