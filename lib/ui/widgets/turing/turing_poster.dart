import 'package:flutter/material.dart';

import '../../../core/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/turing.dart';
import '../app_icon.dart';
import 'turing_bubble.dart';

/// 对局宣传海报 —— 「导出为图片」真正导出的东西。
///
/// **不是结算界面截图**。对齐 Web 端 `exportChatImage()`：
/// 结果摘要（按对错着色）+ 完整聊天记录 + 品牌页脚与「扫码来玩」二维码。
/// 二维码才是它作为「宣传海报」的意义 —— 别人看到图能扫进来玩。
///
/// 两个刻意的约束：
/// 1. **固定 600 逻辑宽**（与 Web 一致），渲染在屏幕外再截取，不受设备宽度影响。
/// 2. **永远用亮色**：外面套 `XqfTheme.light()` 强制 `XqfPalette.of()` 走亮色。
///    Web 端也是这么干的（导出前在克隆文档里摘掉 `data-theme`）——
///    分享出去的图不该因为分享者开了暗色模式就变成深色卡片。
class TuringPoster extends StatelessWidget {
  const TuringPoster({
    super.key,
    required this.result,
    required this.feed,
    this.width = 600,
  });

  final TuringResult result;
  final List<TuringFeedItem> feed;
  final double width;

  /// 「扫码来玩」二维码地址（与 Web 端同一个服务）。
  static String get qrUrl =>
      'https://api.qrserver.com/v1/create-qr-code/?size=160x160&data='
      '${Uri.encodeComponent(XqfEnv.baseUrl)}';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: XqfTheme.light(),
      child: Builder(
        builder: (BuildContext context) {
          final XqfPalette p = XqfPalette.light;
          return Container(
            width: width,
            color: p.paperBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Header(result: result),
                Container(
                  color: p.surfaceWhite,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                  child: feed.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Text(
                            '暂无聊天记录',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: p.textAa,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (final TuringFeedItem item in feed)
                              TuringBubble(item: item),
                          ],
                        ),
                ),
                _Footer(palette: p),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 结果摘要：按对错着底色，三行对照。
class _Header extends StatelessWidget {
  const _Header({required this.result});

  final TuringResult result;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.light;
    final Color bg = result.isWin ? p.noteGreen : p.notePink;
    final Color fg = result.isWin ? p.successColor : p.dangerColor;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        children: <Widget>[
          Text(
            result.verdict,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.reveal,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _Stat(label: '你的判断', value: result.userGuessLabel),
              _Stat(label: '对方身份', value: result.opponentTruthLabel),
              _Stat(label: '对方猜你是', value: result.opponentGuessLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.light;
    return Column(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: p.textSubtle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: p.inkBlack,
          ),
        ),
      ],
    );
  }
}

/// 页脚：品牌 + 「扫码来玩」。
class _Footer extends StatelessWidget {
  const _Footer({required this.palette});

  final XqfPalette palette;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: p.surfaceWhite,
        border: Border(top: BorderSide(color: p.borderLight, width: 2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                AppIcon('grid', size: 22, color: p.inkBlack),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '图灵测试（1v1） · ${XqfEnv.appName}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      color: p.inkBlack,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.wavy,
                      decorationColor: p.inkBlue,
                      decorationThickness: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: <Widget>[
              Image.network(
                TuringPoster.qrUrl,
                width: 72,
                height: 72,
                errorBuilder: (_, _, _) =>
                    AppIcon('qr', size: 72, color: p.textAa),
              ),
              const SizedBox(height: 3),
              Text(
                '扫码来玩',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: p.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
