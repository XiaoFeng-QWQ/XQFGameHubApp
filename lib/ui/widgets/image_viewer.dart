import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';
import 'doodle.dart';

/// 在 App 内全屏查看一张图片（赞助收款码等）。
///
/// 支持双指缩放 / 拖动，右下角保留「用浏览器打开」兜底。
Future<void> showInAppImage(
  BuildContext context, {
  required String url,
  String? title,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => InAppImageViewer(url: url, title: title),
    ),
  );
}

class InAppImageViewer extends StatelessWidget {
  const InAppImageViewer({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Scaffold(
      backgroundColor: p.judgeBg,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext ctx, Widget child, ImageChunkEvent? e) {
                      if (e == null) return child;
                      final double? total = e.expectedTotalBytes?.toDouble();
                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: (total != null && total > 0)
                                ? e.cumulativeBytesLoaded / total
                                : null,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const AppIcon('image-off', size: 44, color: Colors.white54),
                          const SizedBox(height: 14),
                          const Text(
                            '图片加载失败',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinkTextButton(
                            label: '用浏览器打开',
                            color: Colors.white,
                            fontSize: 13,
                            onPressed: () => launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 顶栏
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: <Widget>[
                  _CircleButton(
                    icon: 'close',
                    tooltip: '关闭',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  _CircleButton(
                    icon: 'link',
                    tooltip: '用浏览器打开',
                    onTap: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final String icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Widget button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: p.scrim,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: AppIcon(icon, size: 18, color: Colors.white),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
