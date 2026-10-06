import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';
import 'doodle.dart';
import 'paper.dart';

/// 玩法条目定义（与 Web 端首页 `hub-grid` 一一对应）。
class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.tone,
    required this.group,
    this.metas = const <String>[],
    this.stamp,
    this.stampTone = StampTone.danger,
    this.external = false,
    this.ready = false,
  });

  final String id;
  final String title;
  final String desc;
  final String icon;
  final NoteTone tone;

  /// reason / board / chat / card
  final String group;
  final List<String> metas;
  final String? stamp;
  final StampTone stampTone;
  final bool external;

  /// 该玩法是否已在本 App 内实现（未实现则提示后续版本接入）。
  final bool ready;
}

/// 磁带形态玩法卡（Web 端 `.hub-card`）。
///
/// 结构：便签色点阵封面 + 白底小窗图标 + 角标印章 + 标签正文 + 虚线元信息。
class HubCard extends StatefulWidget {
  const HubCard({super.key, required this.entry, this.onTap});

  final GameEntry entry;
  final VoidCallback? onTap;

  @override
  State<HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<HubCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final GameEntry e = widget.entry;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: p.surfaceWhite,
            border: Border.all(color: p.inkBlack, width: 2),
            boxShadow: XqfShadows.card(p),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ---- 封面：便签色 + 点阵纸 + 白底小窗 ----
              Stack(
                children: <Widget>[
                  SizedBox(
                    height: 88,
                    width: double.infinity,
                    child: DotGridBackground(
                      spacing: 16,
                      dotRadius: 1.2,
                      backgroundColor: e.tone.resolve(p),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 48,
                          decoration: BoxDecoration(
                            color: p.surfaceWhite,
                            border: Border.all(color: p.inkBlack, width: 2),
                            borderRadius: XqfRadii.window,
                            boxShadow: XqfShadows.window(p),
                          ),
                          child: Center(
                            child: AppIcon(e.icon, size: 28, color: p.inkBlue),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DashedDivider(color: p.borderLight),
                  ),
                  if (e.stamp != null)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: DoodleStamp(label: e.stamp!, tone: e.stampTone),
                    ),
                  if (e.external)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: AppIcon('link', size: 13, color: p.textSubtle),
                    ),
                ],
              ),
              // ---- 正文 ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: <Widget>[
                    Text(
                      e.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: p.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                        color: p.textMuted,
                      ),
                    ),
                    if (e.metas.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: e.metas
                            .map((String m) => DashedBorder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: p.textSubtle,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主推游戏盒（Web 端 `.hub-box`：书脊 + 封面带 + 正文 + 开口按钮）。
class HubBox extends StatelessWidget {
  const HubBox({super.key, required this.entry, this.onTap, this.ctaLabel = '开始匹配'});

  final GameEntry entry;
  final VoidCallback? onTap;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final GameEntry e = entry;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: p.noteGreen,
          border: Border.all(color: p.inkBlack, width: 2),
          boxShadow: XqfShadows.card(p),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 书脊
              Container(
                width: 34,
                color: p.inkBlack,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    '图灵测试 · 1v1',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 3,
                      color: p.surfaceWhite,
                    ),
                  ),
                ),
              ),
              // 封面带
              Container(
                width: 96,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: p.borderLight, width: 2)),
                ),
                child: DotGridBackground(
                  spacing: 16,
                  dotRadius: 1.2,
                  backgroundColor: p.surfaceWhite,
                  child: Center(
                    child: AppIcon(e.icon, size: 46, color: p.inkBlue),
                  ),
                ),
              ),
              // 正文
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              e.title,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: p.inkBlack,
                              ),
                            ),
                          ),
                          DoodleStamp(label: '主推', tone: StampTone.danger),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.desc,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.6,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: e.metas
                            .map((String m) => DashedBorder(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: p.textSubtle,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: p.surfaceWhite,
                            border: Border.all(color: p.inkBlack, width: 2),
                            borderRadius: XqfRadii.hand,
                            boxShadow: XqfShadows.chip(p),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                ctaLabel,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: p.inkBlack,
                                ),
                              ),
                              const SizedBox(width: 7),
                              AppIcon('arrow-right', size: 15, color: p.inkBlack),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 服务票根（Web 端 `.hub-ticket`）。
class HubTicket extends StatelessWidget {
  const HubTicket({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.tag,
    this.onTap,
    this.showDivider = true,
  });

  final String index;
  final String icon;
  final String label;
  final String tag;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: p.borderLight, width: 2))
              : null,
        ),
        child: Row(
          children: <Widget>[
            Text(
              index,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: p.inkBlue,
              ),
            ),
            const SizedBox(width: 10),
            AppIcon(icon, size: 16, color: p.inkBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: p.inkBlack,
                ),
              ),
            ),
            Text(
              tag,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 1,
                color: p.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
