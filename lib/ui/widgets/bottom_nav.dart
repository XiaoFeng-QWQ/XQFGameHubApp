import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';
import 'breakpoints.dart';

/// 手绘风底部导航栏。
///
/// Web 端没有对应物，这里沿用同一套语言自造：顶部 2px 虚线分隔，
/// 选中项套一枚便签黄手绘圆角胶囊 + 错位实心阴影，未选中为浅灰线性图标。
class XqfBottomBar extends StatelessWidget {
  const XqfBottomBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<XqfNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceHeader,
        border: Border(top: BorderSide(color: p.borderLight, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 宽屏（横屏 / 平板）用的左侧导航栏。
class XqfNavRail extends StatelessWidget {
  const XqfNavRail({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.header,
  });

  final List<XqfNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: p.surfaceHeader,
        border: Border(right: BorderSide(color: p.borderLight, width: 2)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: <Widget>[
            if (header != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: header,
              ),
              DashedLine(color: p.borderLight),
            ],
            const SizedBox(height: 10),
            for (int i = 0; i < items.length; i++)
              _NavButton(
                item: items[i],
                selected: i == index,
                onTap: () => onChanged(i),
                vertical: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.vertical = false,
  });

  final XqfNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Color fg = selected ? p.inkBlue : p.textSubtle;

    final Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: selected
          ? BoxDecoration(
              color: p.noteYellow,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: XqfRadii.chip,
              boxShadow: XqfShadows.chip(p),
            )
          : null,
      child: AppIcon(item.icon, size: 19, color: fg),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: vertical ? 12 : 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              chip,
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 与 [DashedDivider] 等价的横向分隔线（避免循环依赖时使用）。
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color ?? p.borderLight)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const double dash = 5;
    const double gap = 4;
    double x = 0;
    final double y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
