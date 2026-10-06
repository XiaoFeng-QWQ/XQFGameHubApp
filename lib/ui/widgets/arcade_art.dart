import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'doodle.dart';

/// 首页 Hero 右侧手绘游戏机。
///
/// 与 Web 端 `index.html` 里那段内联 SVG（显示器 + 手柄 + HUMAN?/AI? 标签）
/// 完全同构，用 [CustomPainter] 按同一坐标系（240 × 210）重绘。
class ArcadeArt extends StatelessWidget {
  const ArcadeArt({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            decoration: BoxDecoration(
              color: p.surfaceWhite,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: XqfRadii.panel,
              boxShadow: XqfShadows.panel(p),
            ),
            child: AspectRatio(
              aspectRatio: 240 / 210,
              child: CustomPaint(painter: _ArcadePainter(p)),
            ),
          ),
          Positioned(
            top: -12,
            left: 10,
            child: Transform.rotate(
              angle: -5 * 3.1415926535 / 180,
              child: const _ArtTag(label: 'HUMAN?', tone: NoteTone.green),
            ),
          ),
          Positioned(
            bottom: -12,
            right: 10,
            child: Transform.rotate(
              angle: 4 * 3.1415926535 / 180,
              child: const _ArtTag(label: 'AI?', tone: NoteTone.pink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtTag extends StatelessWidget {
  const _ArtTag({required this.label, required this.tone});

  final String label;
  final NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.resolve(p),
        border: Border.all(color: p.inkBlack, width: 2),
        borderRadius: XqfRadii.window,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 1,
          color: p.inkBlack,
        ),
      ),
    );
  }
}

class _ArcadePainter extends CustomPainter {
  _ArcadePainter(this.p);

  final XqfPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    const double vw = 240;
    final double s = size.width / vw;
    canvas.save();
    canvas.scale(s, s);

    final Paint stroke = Paint()
      ..color = p.inkBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Paint fill(Color c) => Paint()..color = c;

    // 显示器外框
    final RRect frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 10, 136, 102),
      const Radius.circular(6),
    );
    canvas.drawRRect(frame, fill(p.surfaceWhite));
    canvas.drawRRect(frame, stroke);

    // 屏幕
    final Rect screen = const Rect.fromLTWH(60, 18, 120, 86);
    canvas.drawRect(screen, fill(p.noteBlue));
    canvas.drawRect(screen, stroke);

    // 屏幕文字
    void text(String s, double x, double y) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: p.inkBlue,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y - tp.height));
    }

    text('HUMAN?', 66, 36);
    text('……', 66, 54);
    text('AI?', 140, 84);

    // 支架
    canvas.drawLine(const Offset(120, 112), const Offset(120, 126), stroke);
    canvas.drawLine(const Offset(98, 126), const Offset(142, 126), stroke);

    // 手柄线
    final Path cable = Path()
      ..moveTo(120, 126)
      ..cubicTo(128, 138, 120, 144, 130, 152);
    canvas.drawPath(cable, stroke);

    // 手柄
    final RRect pad = RRect.fromRectAndRadius(
      const Rect.fromLTWH(62, 152, 116, 44),
      const Radius.circular(20),
    );
    canvas.drawRRect(pad, fill(p.surfaceWhite));
    canvas.drawRRect(pad, stroke);

    // 十字键
    canvas.drawCircle(const Offset(86, 174), 8, fill(p.surfaceWhite));
    canvas.drawCircle(const Offset(86, 174), 8, stroke);
    canvas.drawLine(const Offset(86, 165), const Offset(86, 183), stroke);
    canvas.drawLine(const Offset(77, 174), const Offset(95, 174), stroke);

    // A / B 键
    canvas.drawCircle(const Offset(146, 172), 5, fill(p.notePink));
    canvas.drawCircle(const Offset(146, 172), 5, stroke);
    canvas.drawCircle(const Offset(160, 172), 5, fill(p.noteGreen));
    canvas.drawCircle(const Offset(160, 172), 5, stroke);

    // 中间小横线
    canvas.drawLine(const Offset(128, 172), const Offset(130, 172), stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArcadePainter old) => old.p != p;
}
