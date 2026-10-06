import 'package:flutter/material.dart';

import 'dart:ui' show PathMetric;

import '../../core/theme/palette.dart';

/// 点阵纸背景。
///
/// 对应 Web 端 `body { background-image: radial-gradient(var(--dot-color)
/// 1.5px, transparent 1.5px); background-size: 25px 25px; }`
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({
    super.key,
    required this.child,
    this.spacing = 25,
    this.dotRadius = 1.5,
    this.color,
    this.backgroundColor,
  });

  final Widget child;
  final double spacing;
  final double dotRadius;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    // 注意绘制顺序：底色 → 点阵 → 内容。
    // CustomPaint 的 painter 在 child 之前绘制，因此底色必须包在最外层，
    // 否则 ColoredBox 会把点阵盖掉。
    return ColoredBox(
      color: backgroundColor ?? p.paperBg,
      child: CustomPaint(
        painter: _DotGridPainter(
          color: color ?? p.dotColor,
          spacing: spacing,
          radius: dotRadius,
        ),
        child: child,
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color, required this.spacing, required this.radius});

  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double half = spacing / 2;
    for (double y = half; y < size.height + spacing; y += spacing) {
      for (double x = half; x < size.width + spacing; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.color != color || old.spacing != spacing || old.radius != radius;
}

/// 横格纸纹理（笔记本横线）。
///
/// 对应 Web 端 `repeating-linear-gradient(0deg, var(--border-lighter)
/// 0 1px, transparent 1px 26px)`。
class RuledPaper extends StatelessWidget {
  const RuledPaper({
    super.key,
    required this.child,
    this.lineHeight = 26,
    this.lineColor,
    this.backgroundColor,
  });

  final Widget child;
  final double lineHeight;
  final Color? lineColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    // 同样注意顺序：底色 → 横线 → 内容。
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: CustomPaint(
        painter: _RuledPaperPainter(
          color: lineColor ?? p.borderLighter,
          lineHeight: lineHeight,
        ),
        child: child,
      ),
    );
  }
}

class _RuledPaperPainter extends CustomPainter {
  _RuledPaperPainter({required this.color, required this.lineHeight});

  final Color color;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter old) =>
      old.color != color || old.lineHeight != lineHeight;
}

/// 虚线分隔线（Web 端 `border-bottom: 2px dashed var(--border-light)`）。
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.color, this.thickness = 2, this.dash = 6, this.gap = 5});

  final Color? color;
  final double thickness;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color ?? p.borderLight,
          thickness: thickness,
          dash: dash,
          gap: gap,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({
    required this.color,
    required this.thickness,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double thickness;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;
    final double y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final double end = (x + dash).clamp(0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color || old.thickness != thickness || old.dash != dash || old.gap != gap;
}

/// 虚线描边（Web 端 `border: 1.5px dashed var(--border-light)` 的小药丸标签）。
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.radius,
    this.color,
    this.thickness = 1.5,
    this.dash = 4,
    this.gap = 3,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius? radius;
  final Color? color;
  final double thickness;
  final double dash;
  final double gap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? p.borderLight,
        thickness: thickness,
        dash: dash,
        gap: gap,
        radius: radius ?? XqfRadii.tag,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.thickness,
    required this.dash,
    required this.gap,
    required this.radius,
  });

  final Color color;
  final double thickness;
  final double dash;
  final double gap;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..addRRect(radius.toRRect(Offset.zero & size).deflate(thickness / 2));
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = (distance + dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.thickness != thickness ||
      old.dash != dash ||
      old.gap != gap ||
      old.radius != radius;
}
