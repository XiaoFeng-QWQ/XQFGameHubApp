import 'package:flutter/material.dart';

import 'palette.dart';

/// 全局主题。字体与 Web 端一致使用等宽字体栈
/// （Menlo / Consolas / Monaco → Android 上回退到系统 monospace）。
class XqfTheme {
  const XqfTheme._();

  /// Web 端 `font-family: Menlo, Consolas, Monaco, Liberation Mono,
  /// Lucida Console, ui-monospace`。Android 上最接近的是系统 monospace，
  /// 中文由系统 CJK 字体回退，与浏览器表现一致。
  static const String monoFont = 'monospace';

  static ThemeData light() => _build(XqfPalette.light, Brightness.light);
  static ThemeData dark() => _build(XqfPalette.dark, Brightness.dark);

  static ThemeData _build(XqfPalette p, Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: p.inkBlue,
      brightness: brightness,
    ).copyWith(
      primary: p.inkBlue,
      onPrimary: p.surfaceWhite,
      secondary: p.inkBlue,
      surface: p.surfaceWhite,
      onSurface: p.inkBlack,
      error: p.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: monoFont,
      scaffoldBackgroundColor: p.paperBg,
      canvasColor: p.paperBg,
      dividerColor: p.borderLight,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: p.highlighter,
      textTheme: _textTheme(p),
      iconTheme: IconThemeData(color: p.inkBlack, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surfaceHeader,
        foregroundColor: p.inkBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: monoFont,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: p.inkBlack,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.borderLight, thickness: 2),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.paperBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: XqfRadii.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceWhite,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.inkBlue),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.judgeBg,
        contentTextStyle: TextStyle(
          fontFamily: monoFont,
          fontSize: 13,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.inkBlack,
        selectionColor: p.highlighter,
        selectionHandleColor: p.inkBlue,
      ),
    );
  }

  static TextTheme _textTheme(XqfPalette p) {
    TextStyle base(double size, {FontWeight? weight, Color? color, double? spacing, double? height}) =>
        TextStyle(
          fontFamily: monoFont,
          fontSize: size,
          fontWeight: weight,
          color: color ?? p.inkBlack,
          letterSpacing: spacing,
          height: height,
        );

    return TextTheme(
      displayLarge: base(54, weight: FontWeight.bold, height: 1.05),
      displayMedium: base(46, weight: FontWeight.bold, height: 1.2),
      displaySmall: base(30, weight: FontWeight.bold),
      headlineLarge: base(26, weight: FontWeight.bold),
      headlineMedium: base(23, weight: FontWeight.bold),
      headlineSmall: base(19, weight: FontWeight.bold, spacing: 3),
      titleLarge: base(17, weight: FontWeight.bold, spacing: 3),
      titleMedium: base(16, weight: FontWeight.bold),
      titleSmall: base(14, weight: FontWeight.bold),
      bodyLarge: base(15),
      bodyMedium: base(13, color: p.textSecondary, height: 1.6),
      bodySmall: base(12, color: p.textMuted, height: 1.5),
      labelLarge: base(14, weight: FontWeight.bold),
      labelMedium: base(12, color: p.textSubtle, spacing: 1),
      labelSmall: base(11, color: p.textSubtle, spacing: 1),
    );
  }
}
