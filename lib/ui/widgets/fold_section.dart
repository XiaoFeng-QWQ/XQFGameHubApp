import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';
import 'paper.dart';

/// 可折叠区块。对应 Web 端 `.acc-fold`：
/// 蓝色标题行 + 箭头，展开后顶部一条虚线。
class FoldSection extends StatefulWidget {
  const FoldSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyOpen = false,
    this.titleWidget,
  });

  final String title;
  final Widget child;
  final bool initiallyOpen;
  final Widget? titleWidget;

  @override
  State<FoldSection> createState() => _FoldSectionState();
}

class _FoldSectionState extends State<FoldSection> with SingleTickerProviderStateMixin {
  late bool _open = widget.initiallyOpen;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: _open ? 1 : 0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Row(
            children: <Widget>[
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: AppIcon('chevron-down', size: 15, color: p.inkBlue),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: widget.titleWidget ??
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: p.inkBlue,
                      ),
                    ),
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 12),
              DashedDivider(color: p.borderLight),
              const SizedBox(height: 12),
              widget.child,
            ],
          ),
        ),
      ],
    );
  }
}

/// 空状态提示（Web 端 `emptyTip`）。
class EmptyTip extends StatelessWidget {
  const EmptyTip({super.key, required this.text, this.isError = false, this.padding});

  final String text;
  final bool isError;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 26, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: p.borderLight, width: 2),
        borderRadius: XqfRadii.tag,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: isError ? p.danger : p.textSubtle,
        ),
      ),
    );
  }
}

/// 加载动画：三个跳动的点（Web 端 `.dot-bounce`）。
class DotBounce extends StatefulWidget {
  const DotBounce({super.key, this.size = 9, this.color});

  final double size;
  final Color? color;

  @override
  State<DotBounce> createState() => _DotBounceState();
}

class _DotBounceState extends State<DotBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Color color = widget.color ?? p.inkBlue;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int i) {
            final double t = (_controller.value - i * 0.15) % 1.0;
            final double bounce = t < 0.5 ? (t * 2) : (1 - (t - 0.5) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -bounce * widget.size * 0.6),
                child: Opacity(
                  opacity: 0.4 + bounce * 0.6,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 居中加载块。
class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, this.text = '加载中…'});

  final String text;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: <Widget>[
          const DotBounce(),
          const SizedBox(height: 14),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: p.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 可折叠分组（账号页的「内容管理」「账号设置」）。
///
/// 手机上 7 个面板一路往下滚太长，这里默认收起，只留标题与摘要，
/// 点开才展开组内面板。
class CollapsibleGroup extends StatefulWidget {
  const CollapsibleGroup({
    super.key,
    required this.title,
    required this.children,
    this.note,
    this.initiallyOpen = false,
    this.gap = 22,
  });

  final String title;
  final String? note;
  final List<Widget> children;
  final bool initiallyOpen;
  final double gap;

  @override
  State<CollapsibleGroup> createState() => _CollapsibleGroupState();
}

class _CollapsibleGroupState extends State<CollapsibleGroup>
    with SingleTickerProviderStateMixin {
  late bool _open = widget.initiallyOpen;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: _open ? 1 : 0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: AppIcon('chevron-right', size: 17, color: p.inkBlack),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: p.inkBlack,
                  ),
                ),
                if (widget.note != null) ...<Widget>[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.note!,
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
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: widget.gap),
              for (int i = 0; i < widget.children.length; i++) ...<Widget>[
                if (i > 0) SizedBox(height: widget.gap),
                widget.children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
