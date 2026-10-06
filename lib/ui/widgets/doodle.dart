import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';
import 'paper.dart';

/// 便签底色种类，对应 Web 端 `.acc-panel--pink/blue/green/yellow`。
enum NoteTone { plain, pink, blue, green, yellow }

extension NoteToneX on NoteTone {
  Color resolve(XqfPalette p) => switch (this) {
        NoteTone.plain => p.surfaceWhite,
        NoteTone.pink => p.notePink,
        NoteTone.blue => p.noteBlue,
        NoteTone.green => p.noteGreen,
        NoteTone.yellow => p.noteYellow,
      };
}

/// 手绘面板：2px 描边 + 不规则圆角 + 错位实心阴影。
///
/// 对应 Web 端 `.acc-panel` / `.doodle-border`。
class DoodlePanel extends StatelessWidget {
  const DoodlePanel({
    super.key,
    required this.child,
    this.tone = NoteTone.plain,
    this.radius,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    this.shadow = true,
    this.borderColor,
    this.background,
  });

  final Widget child;
  final NoteTone tone;
  final BorderRadius? radius;
  final EdgeInsets padding;
  final bool shadow;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? tone.resolve(p),
        border: Border.all(color: borderColor ?? p.inkBlack, width: 2),
        borderRadius: radius ?? XqfRadii.panel,
        boxShadow: shadow ? XqfShadows.panel(p) : null,
      ),
      child: child,
    );
  }
}

/// 按下时缩放 + 高亮的手绘按钮。
///
/// 对应 Web 端 `.doodle-btn`：hover 时 `scale(1.05) rotate(-2deg)` 且底色变
/// 荧光笔黄，按下 `scale(.95)`。移动端没有 hover，改为按下时触发。
class DoodleButton extends StatefulWidget {
  const DoodleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.icon,
    this.variant = DoodleButtonVariant.normal,
    this.expand = false,
    this.compact = false,
    this.padding,
    this.radius,
    this.fontSize,
    this.tooltip,
  });

  /// 便捷构造：图标 + 文案。
  factory DoodleButton.label({
    Key? key,
    required String label,
    String? icon,
    VoidCallback? onPressed,
    DoodleButtonVariant variant = DoodleButtonVariant.normal,
    bool expand = false,
    bool compact = false,
  }) =>
      DoodleButton(
        key: key,
        onPressed: onPressed,
        variant: variant,
        expand: expand,
        compact: compact,
        icon: icon,
        child: Text(label),
      );

  final Widget child;
  final VoidCallback? onPressed;
  final String? icon;
  final DoodleButtonVariant variant;
  final bool expand;
  final bool compact;
  final EdgeInsets? padding;
  final BorderRadius? radius;
  final double? fontSize;
  final String? tooltip;

  @override
  State<DoodleButton> createState() => _DoodleButtonState();
}

enum DoodleButtonVariant { normal, danger, success }

class _DoodleButtonState extends State<DoodleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool enabled = widget.onPressed != null;

    late final Color bg;
    late final Color fg;
    late final Color border;
    switch (widget.variant) {
      case DoodleButtonVariant.danger:
        bg = p.danger;
        fg = Colors.white;
        border = p.danger;
      case DoodleButtonVariant.success:
        bg = p.success;
        fg = Colors.white;
        border = p.success;
      case DoodleButtonVariant.normal:
        bg = _down ? p.highlighter : Colors.transparent;
        fg = p.inkBlack;
        border = p.inkBlack;
    }

    final Widget content = DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: widget.fontSize ?? (widget.compact ? 13 : 16),
        color: enabled ? fg : p.textAa,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            AppIcon(widget.icon!, size: (widget.fontSize ?? (widget.compact ? 13 : 16)) * 1.1,
                color: enabled ? fg : p.textAa),
            const SizedBox(width: 6),
          ],
          Flexible(child: widget.child),
        ],
      ),
    );

    Widget button = AnimatedScale(
      scale: _down ? 0.95 : 1,
      duration: const Duration(milliseconds: 110),
      child: Container(
        padding: widget.padding ??
            (widget.compact
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: enabled ? border : p.borderLight, width: 2),
          borderRadius: widget.radius ?? XqfRadii.button,
        ),
        child: content,
      ),
    );

    if (widget.expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: button,
    );

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}

/// 文字型按钮（Web 端 `.acc-link-btn`：波浪下划线、蓝色、无边框）。
class LinkTextButton extends StatelessWidget {
  const LinkTextButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.fontSize = 12,
  });

  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool enabled = onPressed != null;
    final Color c = enabled ? (color ?? p.inkBlue) : p.textAa;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              AppIcon(icon!, size: fontSize, color: c),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize,
                color: c,
                decoration: enabled ? TextDecoration.underline : TextDecoration.none,
                decorationStyle: TextDecorationStyle.wavy,
                decorationColor: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 小药丸标签（Web 端 `.acc-tag` / `.hub-card-meta span`）。
class DoodleTag extends StatelessWidget {
  const DoodleTag({
    super.key,
    required this.label,
    this.special = false,
    this.solid = false,
    this.color,
    this.fontSize = 11,
  });

  final String label;
  final bool special;
  final bool solid;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool inverted = special || solid;
    final Color bg = inverted ? (color ?? p.inkBlue) : p.surfaceWhite;
    final Color fg = inverted ? Colors.white : p.inkBlack;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: inverted ? bg : p.inkBlack, width: 1.5),
        borderRadius: XqfRadii.tag,
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'monospace', fontSize: fontSize, color: fg),
      ),
    );
  }
}

/// 手绘选择胶囊（对应 Web 端 `.hub-filter`）。
///
/// 玩法页的分类筛选与「我的 → 外观」的主题选择共用同一形态：
/// 选中态为便签黄底 + 2px 墨色描边 + 错位实心阴影，未选中为白底、无阴影。
class DoodleChoiceChip extends StatelessWidget {
  const DoodleChoiceChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Semantics(
      selected: active,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? p.noteYellow : p.surfaceWhite,
            border: Border.all(color: p.inkBlack, width: 2),
            borderRadius: XqfRadii.chip,
            boxShadow: active ? XqfShadows.chip(p) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: p.inkBlack,
            ),
          ),
        ),
      ),
    );
  }
}

/// 印章（Web 端 `.hub-stamp`：旋转 -6°、2px 描边、字距 2px）。
class DoodleStamp extends StatelessWidget {
  const DoodleStamp({
    super.key,
    required this.label,
    this.tone = StampTone.danger,
    this.angle = -6 * 3.1415926535 / 180,
  });

  final String label;
  final StampTone tone;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    late final Color border;
    late final Color fg;
    late final Color bg;
    switch (tone) {
      case StampTone.danger:
        border = p.danger;
        fg = p.danger;
        bg = Colors.transparent;
      case StampTone.ink:
        border = p.inkBlack;
        fg = p.surfaceWhite;
        bg = p.inkBlack;
      case StampTone.outline:
        border = p.inkBlack;
        fg = p.inkBlack;
        bg = Colors.transparent;
    }
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 2),
          borderRadius: XqfRadii.stamp,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: fg,
          ),
        ),
      ),
    );
  }
}

enum StampTone { danger, ink, outline }

/// 区块标题（Web 端 `.hub-section-head`：左标题 + 右附注 + 底部虚线）。
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.title,
    this.note,
    this.trailing,
    this.number,
    this.titleSize = 17,
  });

  final String title;
  final String? note;
  final Widget? trailing;
  final String? number;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            if (number != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  number!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: titleSize * 1.8,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: p.inkBlue,
                  ),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: p.inkBlack,
              ),
            ),
            const Spacer(),
            ?trailing,
            if (trailing == null && note != null)
              Flexible(
                child: Text(
                  note!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                    color: p.textSubtle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        DashedDivider(color: p.borderLight),
      ],
    );
  }
}

/// 分组标题（Web 端 `.acc-group-head`：标题 + 附注 + 右侧虚线延伸）。
class GroupHead extends StatelessWidget {
  const GroupHead({super.key, required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Row(
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: p.inkBlack,
          ),
        ),
        if (note != null) ...<Widget>[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              note!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: p.textSubtle,
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(child: DashedDivider(color: p.borderLight)),
      ],
    );
  }
}
