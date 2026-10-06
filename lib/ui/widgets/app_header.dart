import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';

/// 页面头部。对应 Web 端 `header`：
/// `background: var(--surface-header); border-bottom: 2px dashed var(--border-light)`。
///
/// 手机端把左右内边距从 36px 收到 14px，其余语言不变。
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.showLogo = true,
    this.titleSize = 20,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool showLogo;
  final double titleSize;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.surfaceHeader,
        border: Border(bottom: BorderSide(color: p.borderLight, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[leading!, const SizedBox(width: 10)],
            if (showLogo) ...<Widget>[
              AppIcon('grid', size: titleSize * 0.85, color: p.inkBlack),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: titleSize,
                  color: p.inkBlack,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.wavy,
                  decorationColor: p.inkBlue,
                  decorationThickness: 1.6,
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// 头部里的圆形图标按钮（对应 Web 端 `doodle-btn` + `border-radius:50%`）。
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 20,
  });

  final String icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Widget button = GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.inkBlack, width: 2),
        ),
        child: AppIcon(icon, size: size, color: p.inkBlack),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
