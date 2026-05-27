// jarvy_theme.dart
// Register-based theming for a personal life tracker.
// Each "register" is a complete tonal world: background, surface, ink,
// muted, rule, accent + the typography pair that screen should use.
//
// Usage in a screen:
//   final t = JarvyTheme.of(context);
//   Container(color: t.background, child: Text('Hi', style: t.displayLarge))
//
// At the route level:
//   JarvyTheme(register: JarvyRegisters.daily, child: DashboardScreen())

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────
// OKLCH → Color  (accurate to ~0.001 in linear RGB)
// ─────────────────────────────────────────────────────────────────────────
Color oklch(double l, double c, double h, {double alpha = 1.0}) {
  final hr = h * math.pi / 180.0;
  final a = c * math.cos(hr);
  final b = c * math.sin(hr);

  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  final lc = l_ * l_ * l_;
  final mc = m_ * m_ * m_;
  final sc = s_ * s_ * s_;

  double r  =  4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc;
  double g  = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc;
  double bb = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc;

  double toSrgb(double x) {
    x = x.clamp(0.0, 1.0);
    return x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
  }

  return Color.fromARGB(
    (alpha * 255).round(),
    (toSrgb(r) * 255).round().clamp(0, 255),
    (toSrgb(g) * 255).round().clamp(0, 255),
    (toSrgb(bb) * 255).round().clamp(0, 255),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Spacing scale: 4 / 8 / 14 / 22 / 36 / 58
// ─────────────────────────────────────────────────────────────────────────
class JarvySpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 14.0;
  static const double lg  = 22.0;
  static const double xl  = 36.0;
  static const double xxl = 58.0;

  static const double radiusNone  = 0.0;
  static const double radiusTight = 2.0;
  static const double radiusSoft  = 4.0;
}

// ─────────────────────────────────────────────────────────────────────────
// Register — a complete tonal world.
// ─────────────────────────────────────────────────────────────────────────
class JarvyRegister {
  final String name;

  final Color background;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color faint;
  final Color rule;
  final Color accent;
  final Color? accentDim;
  final Color? destructive;

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyEmph;
  final TextStyle kicker;
  final TextStyle metadata;
  final TextStyle mono;

  const JarvyRegister({
    required this.name,
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.faint,
    required this.rule,
    required this.accent,
    this.accentDim,
    this.destructive,
    required this.displayLarge,
    required this.displayMedium,
    required this.title,
    required this.body,
    required this.bodyEmph,
    required this.kicker,
    required this.metadata,
    required this.mono,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Type-pair helpers
// ─────────────────────────────────────────────────────────────────────────
TextStyle _cormorant(double size,
    {FontWeight w = FontWeight.w400,
    double? lh,
    double letter = -0.2,
    FontStyle style = FontStyle.normal,
    Color? color}) =>
    GoogleFonts.cormorantGaramond(
      fontSize: size, fontWeight: w, height: lh,
      letterSpacing: letter, fontStyle: style, color: color);

TextStyle _playfair(double size,
    {FontWeight w = FontWeight.w500,
    double? lh,
    double letter = -0.3,
    FontStyle style = FontStyle.normal,
    Color? color}) =>
    GoogleFonts.playfairDisplay(
      fontSize: size, fontWeight: w, height: lh,
      letterSpacing: letter, fontStyle: style, color: color);

TextStyle _sora(double size,
    {FontWeight w = FontWeight.w400,
    double? lh,
    double letter = -0.1,
    Color? color}) =>
    GoogleFonts.sora(
      fontSize: size, fontWeight: w, height: lh,
      letterSpacing: letter, color: color);

TextStyle _dmsans(double size,
    {FontWeight w = FontWeight.w400,
    double? lh,
    double letter = -0.1,
    Color? color}) =>
    GoogleFonts.dmSans(
      fontSize: size, fontWeight: w, height: lh,
      letterSpacing: letter, color: color);

TextStyle _geist(double size,
    {FontWeight w = FontWeight.w400,
    double? lh,
    double letter = -0.1,
    Color? color}) {
  try {
    return GoogleFonts.getFont(
      'Geist',
      fontSize: size, fontWeight: w, height: lh,
      letterSpacing: letter, color: color);
  } catch (_) {
    // Geist may not be in this version of google_fonts — fall back to SpaceGrotesk
    return GoogleFonts.spaceGrotesk(
      fontSize: size, fontWeight: w, height: lh,
      letterSpacing: letter, color: color);
  }
}

TextStyle _jbMono(double size,
    {FontWeight w = FontWeight.w400, double letter = 0.3, Color? color}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size, fontWeight: w, letterSpacing: letter, color: color);

// ─────────────────────────────────────────────────────────────────────────
// JarvyRegisters — the six tonal worlds.
// ─────────────────────────────────────────────────────────────────────────
class JarvyRegisters {
  // 1 · daily — Dashboard, Log base
  static final daily = JarvyRegister(
    name: 'daily',
    background: oklch(.14, .008,  60),
    surface:    oklch(.18, .008,  60),
    ink:        oklch(.94, .012,  80),
    inkSoft:    oklch(.82, .010,  70),
    muted:      oklch(.62, .010,  70),
    faint:      oklch(.38, .008,  70),
    rule:       oklch(.28, .008,  70),
    accent:     oklch(.72, .14,   85),
    accentDim:  oklch(.55, .10,   85),

    displayLarge:  _cormorant(88, w: FontWeight.w400, lh: 0.92, letter: -2.0, color: oklch(.94, .012, 80)),
    displayMedium: _cormorant(34, w: FontWeight.w400, lh: 1.05, letter: -0.4, color: oklch(.94, .012, 80)),
    title:         _cormorant(22, w: FontWeight.w400, lh: 1.18, letter: -0.1, color: oklch(.94, .012, 80)),
    body:          _sora(14, color: oklch(.94, .012, 80)),
    bodyEmph:      _sora(14, w: FontWeight.w500, color: oklch(.94, .012, 80)),
    kicker:        _sora(10, w: FontWeight.w600, letter: 2.4,  color: oklch(.72, .14, 85)),
    metadata:      _sora(11, color: oklch(.62, .010, 70)),
    mono:          _jbMono(10, color: oklch(.62, .010, 70)),
  );

  // 2 · ritual — Do (habits + tasks)
  static final ritual = JarvyRegister(
    name: 'ritual',
    background: oklch(.13, .008,  40),
    surface:    oklch(.17, .010,  40),
    ink:        oklch(.95, .012,  50),
    inkSoft:    oklch(.80, .010,  50),
    muted:      oklch(.60, .014,  40),
    faint:      oklch(.38, .010,  40),
    rule:       oklch(.26, .010,  40),
    accent:     oklch(.68, .13,   45),
    accentDim:  oklch(.50, .11,   45),
    destructive: oklch(.62, .16,  30),

    displayLarge:  GoogleFonts.dmSerifDisplay(fontSize: 52, fontWeight: FontWeight.w400, height: 0.96, letterSpacing: -1.4, color: oklch(.95, .012, 50)),
    displayMedium: GoogleFonts.dmSerifDisplay(fontSize: 32, fontWeight: FontWeight.w400, height: 1.0,  letterSpacing: -0.5, color: oklch(.95, .012, 50)),
    title:         _geist(15, w: FontWeight.w500, color: oklch(.95, .012, 50)),
    body:          _geist(14, color: oklch(.95, .012, 50)),
    bodyEmph:      _geist(14, w: FontWeight.w500, color: oklch(.95, .012, 50)),
    kicker:        _geist(9,  w: FontWeight.w600, letter: 2.4, color: oklch(.68, .13, 45)),
    metadata:      _geist(10, color: oklch(.60, .014, 40)),
    mono:          _jbMono(10, color: oklch(.60, .014, 40)),
  );

  // 3 · kinetic — Body, Log workout-mode accent
  static final kinetic = JarvyRegister(
    name: 'kinetic',
    background: oklch(.10, .005, 200),
    surface:    oklch(.14, .005, 200),
    ink:        oklch(.96, .008, 200),
    inkSoft:    oklch(.82, .008, 200),
    muted:      oklch(.58, .012, 200),
    faint:      oklch(.34, .010, 200),
    rule:       oklch(.24, .008, 200),
    accent:     oklch(.72, .18,  145),
    accentDim:  oklch(.52, .14,  145),

    displayLarge:  _sora(48, w: FontWeight.w700, lh: 0.94, letter: -1.4, color: oklch(.96, .008, 200)),
    displayMedium: _sora(28, w: FontWeight.w700, lh: 1.0,  letter: -0.8, color: oklch(.96, .008, 200)),
    title:         _sora(18, w: FontWeight.w600,                          color: oklch(.96, .008, 200)),
    body:          _sora(13, color: oklch(.96, .008, 200)),
    bodyEmph:      _sora(13, w: FontWeight.w600, color: oklch(.96, .008, 200)),
    kicker:        _jbMono(9,  w: FontWeight.w600, letter: 1.6, color: oklch(.72, .18, 145)),
    metadata:      _jbMono(10, color: oklch(.58, .012, 200)),
    mono:          _jbMono(10, color: oklch(.58, .012, 200)),
  );

  // 4 · ambition — Build / Projects
  static final ambition = JarvyRegister(
    name: 'ambition',
    background: oklch(.09, .005, 250),
    surface:    oklch(.13, .006, 250),
    ink:        oklch(.96, .005, 250),
    inkSoft:    oklch(.82, .006, 250),
    muted:      oklch(.58, .008, 250),
    faint:      oklch(.34, .008, 250),
    rule:       oklch(.22, .008, 250),
    accent:     oklch(.88, .08,   85),
    accentDim:  oklch(.68, .06,   85),
    destructive: oklch(.58, .13,  25),

    displayLarge:  _playfair(56, w: FontWeight.w500, lh: 0.94, letter: -1.6, color: oklch(.96, .005, 250)),
    displayMedium: _playfair(28, w: FontWeight.w500, lh: 1.1,  letter: -0.4, color: oklch(.96, .005, 250)),
    title:         _playfair(17, w: FontWeight.w400, style: FontStyle.italic, color: oklch(.96, .005, 250)),
    body:          _geist(14, color: oklch(.96, .005, 250)),
    bodyEmph:      _geist(14, w: FontWeight.w500, color: oklch(.96, .005, 250)),
    kicker:        _geist(9,  w: FontWeight.w600, letter: 2.4, color: oklch(.88, .08, 85)),
    metadata:      _geist(11, color: oklch(.58, .008, 250)),
    mono:          _jbMono(10, color: oklch(.58, .008, 250)),
  );

  // 5 · literary — Library
  static final literary = JarvyRegister(
    name: 'literary',
    background: oklch(.13, .006,  80),
    surface:    oklch(.18, .008,  80),
    ink:        oklch(.94, .012,  70),
    inkSoft:    oklch(.82, .010,  70),
    muted:      oklch(.58, .010,  60),
    faint:      oklch(.38, .010,  60),
    rule:       oklch(.26, .008,  60),
    accent:     oklch(.58, .13,   20),
    accentDim:  oklch(.42, .12,   15),

    displayLarge:  _playfair(36, w: FontWeight.w500, lh: 1.05, letter: -0.6, color: oklch(.94, .012, 70)),
    displayMedium: _playfair(22, w: FontWeight.w500, lh: 1.18, letter: -0.2, color: oklch(.94, .012, 70)),
    title:         _playfair(17, w: FontWeight.w500,                          color: oklch(.94, .012, 70)),
    body:          _dmsans(13, color: oklch(.94, .012, 70)),
    bodyEmph:      _playfair(14, w: FontWeight.w400, style: FontStyle.italic, color: oklch(.82, .010, 70)),
    kicker:        _dmsans(9, w: FontWeight.w500, letter: 1.6, color: oklch(.58, .13, 20)),
    metadata:      _dmsans(10, color: oklch(.58, .010, 60)),
    mono:          _jbMono(10, color: oklch(.58, .010, 60)),
  );

  // 6 · utility — Settings
  static final utility = JarvyRegister(
    name: 'utility',
    background: oklch(.12, .002, 250),
    surface:    oklch(.16, .002, 250),
    ink:        oklch(.96, .002, 250),
    inkSoft:    oklch(.78, .003, 250),
    muted:      oklch(.62, .003, 250),
    faint:      oklch(.42, .003, 250),
    rule:       oklch(.24, .003, 250),
    accent:     oklch(.64, .16,  245),
    destructive: oklch(.58, .16,  25),

    displayLarge:  _geist(22, w: FontWeight.w600, letter: -0.4, color: oklch(.96, .002, 250)),
    displayMedium: _geist(18, w: FontWeight.w600, letter: -0.2, color: oklch(.96, .002, 250)),
    title:         _geist(15, w: FontWeight.w500, color: oklch(.96, .002, 250)),
    body:          _geist(14, color: oklch(.96, .002, 250)),
    bodyEmph:      _geist(14, w: FontWeight.w500, color: oklch(.96, .002, 250)),
    kicker:        _geist(10, w: FontWeight.w500, letter: 1.2, color: oklch(.62, .003, 250)),
    metadata:      _geist(11, color: oklch(.62, .003, 250)),
    mono:          _jbMono(10, letter: 0.4, color: oklch(.62, .003, 250)),
  );

  static final all = [daily, ritual, kinetic, ambition, literary, utility];
  static JarvyRegister byName(String n) =>
      all.firstWhere((r) => r.name == n, orElse: () => daily);
}

// ─────────────────────────────────────────────────────────────────────────
// JarvyTheme — InheritedWidget for register lookup at any depth.
// ─────────────────────────────────────────────────────────────────────────
class JarvyTheme extends InheritedWidget {
  final JarvyRegister register;
  const JarvyTheme({super.key, required this.register, required super.child});

  static JarvyRegister of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<JarvyTheme>();
    assert(w != null, 'No JarvyTheme found in widget tree.');
    return w!.register;
  }

  @override
  bool updateShouldNotify(JarvyTheme old) => old.register.name != register.name;
}

ThemeData jarvyMaterialTheme(JarvyRegister r) => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: r.background,
  canvasColor: r.background,
  colorScheme: ColorScheme.dark(
    surface: r.surface,
    onSurface: r.ink,
    primary: r.accent,
    onPrimary: r.background,
    error: r.destructive ?? oklch(.58, .16, 25),
  ),
  textTheme: TextTheme(
    displayLarge:  r.displayLarge,
    displayMedium: r.displayMedium,
    titleLarge:    r.title,
    bodyLarge:     r.body,
    labelLarge:    r.kicker,
    bodySmall:     r.metadata,
  ),
  dividerColor: r.rule,
  dividerTheme: DividerThemeData(color: r.rule, thickness: 0.5),
);
