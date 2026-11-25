import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models.dart';

/// Палітра з дизайну TeachLog: білий · світло-фіолетовий · темно-фіолетовий.
@immutable
class TL extends ThemeExtension<TL> {
  const TL({
    required this.bg,
    required this.card,
    required this.ink,
    required this.mut,
    required this.line,
    required this.dk,
    required this.md,
    required this.lt,
    required this.xl,
    required this.acc,
    required this.ok,
    required this.bad,
    required this.warn,
    required this.roblox,
    required this.start,
    required this.ma,
    required this.other,
  });

  final Color bg, card, ink, mut, line;
  final Color dk, md, lt, xl, acc;
  final Color ok, bad, warn;
  final Color roblox, start, ma, other;

  static const light = TL(
    bg: Color(0xFFF7F5FD),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF24153F),
    mut: Color(0xFF6E6489),
    line: Color(0xFFE6E0F5),
    dk: Color(0xFF3B1F7A),
    md: Color(0xFF6D3FD6),
    lt: Color(0xFFC9B8FB),
    xl: Color(0xFFEFE9FD),
    acc: Color(0xFFA78BFA),
    ok: Color(0xFFE4DCFB),
    bad: Color(0xFFF4F2F8),
    warn: Color(0xFFEFE9FD),
    roblox: Color(0xFF3B1F7A),
    start: Color(0xFF6D3FD6),
    ma: Color(0xFF9A74F2),
    other: Color(0xFF8A7FB0),
  );

  static const dark = TL(
    bg: Color(0xFF140B29),
    card: Color(0xFF1F1440),
    ink: Color(0xFFF3EFFE),
    mut: Color(0xFFB2A8D4),
    line: Color(0xFF33265E),
    dk: Color(0xFFB9A3FF),
    md: Color(0xFF9A7CF6),
    lt: Color(0xFF4B3591),
    xl: Color(0xFF2A1D55),
    acc: Color(0xFFA78BFA),
    ok: Color(0xFF3A2775),
    bad: Color(0xFF251A49),
    warn: Color(0xFF2D1F5C),
    roblox: Color(0xFFC9B8FB),
    start: Color(0xFFA78BFA),
    ma: Color(0xFF8B6DF0),
    other: Color(0xFF8A7FB0),
  );

  Color dir(String? d) => switch (d) {
    'Roblox' => roblox,
    'Start & Click' => start,
    'МА' => ma,
    _ => other,
  };

  Color status(LessonStatus s) => switch (s) {
    LessonStatus.done => ok,
    LessonStatus.cancelled => bad,
    LessonStatus.makeup => warn,
    LessonStatus.planned => xl,
  };

  @override
  TL copyWith() => this;

  @override
  TL lerp(TL? other, double t) => t < .5 || other == null ? this : other;
}

extension TLContext on BuildContext {
  TL get tl => Theme.of(this).extension<TL>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? TL.dark : TL.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.dk,
    brightness: brightness,
  ).copyWith(primary: c.dk, onPrimary: c.card, secondary: c.md, surface: c.card, onSurface: c.ink, outline: c.line);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final text = GoogleFonts.nunitoTextTheme(base.textTheme).apply(bodyColor: c.ink, displayColor: c.ink);
  final radius10 = BorderRadius.circular(10);
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: radius10,
    borderSide: BorderSide(color: color, width: 1.5),
  );

  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.bg,
    textTheme: text.copyWith(
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.card,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: c.ink),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.dk,
        foregroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: radius10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: radius10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.md,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      labelStyle: TextStyle(color: c.mut),
      border: border(c.line),
      enabledBorder: border(c.line),
      focusedBorder: border(c.dk),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.dk,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: s.contains(WidgetState.selected) ? c.dk : c.mut,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.card : c.mut),
      ),
    ),
    dividerColor: c.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.dk,
      contentTextStyle: TextStyle(color: c.card, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
