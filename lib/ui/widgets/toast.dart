import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// 顶部提示条（对应 Web 端 `showTopToast`）。
///
/// 便签黄底 + 2px 描边 + 不规则圆角 + 错位阴影，2.8 秒后自动消失。
void showTopToast(BuildContext context, String message, {bool isError = false}) {
  final OverlayState? overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext ctx) => _TopToast(
      message: message,
      isError: isError,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.isError,
    required this.onDone,
  });

  final String message;
  final bool isError;
  final VoidCallback onDone;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _controller,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isError ? p.roomWarnBg : p.noteYellow,
                  border: Border.all(
                    color: widget.isError ? p.danger : p.inkBlack,
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(14, 4),
                    topRight: Radius.elliptical(4, 14),
                    bottomRight: Radius.elliptical(14, 4),
                    bottomLeft: Radius.elliptical(4, 14),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: p.shadowMd, offset: const Offset(2, 3), blurRadius: 0),
                  ],
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                    color: widget.isError ? p.danger : p.inkBlack,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 确认对话框（手绘面板风格）。
Future<bool> showDoodleConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmText = '确定',
  String cancelText = '取消',
  bool danger = false,
}) async {
  final XqfPalette p = XqfPalette.of(context);
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierColor: p.overlayBg,
    builder: (BuildContext ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: p.surfaceWhite,
          border: Border.all(color: p.inkBlack, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.elliptical(20, 6),
            topRight: Radius.elliptical(6, 20),
            bottomRight: Radius.elliptical(20, 6),
            bottomLeft: Radius.elliptical(6, 20),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(color: p.shadowMd, offset: const Offset(4, 6), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: p.inkBlack,
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                  color: p.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _DialogButton(
                  label: cancelText,
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
                const SizedBox(width: 10),
                _DialogButton(
                  label: confirmText,
                  filled: true,
                  color: danger ? p.danger : p.inkBlue,
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Color bg = filled ? (color ?? p.inkBlue) : Colors.transparent;
    final Color fg = filled ? Colors.white : p.inkBlack;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: filled ? bg : p.inkBlack, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.elliptical(10, 255),
            topRight: Radius.elliptical(255, 15),
            bottomRight: Radius.elliptical(15, 225),
            bottomLeft: Radius.elliptical(225, 15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: fg),
        ),
      ),
    );
  }
}
