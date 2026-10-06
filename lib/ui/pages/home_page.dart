import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/env.dart';
import '../../core/theme/palette.dart';
import '../../data/game_catalog.dart';
import '../../data/online_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_icon.dart';
import '../widgets/arcade_art.dart';
import '../widgets/breakpoints.dart';
import '../widgets/doodle.dart';
import '../widgets/hub_card.dart';
import '../widgets/paper.dart';
import '../widgets/sponsor.dart';
import '../widgets/toast.dart';
import 'games_page.dart';

/// 首页（游戏中心）。
///
/// 版式语言与 Web 端 `Public/index.html` 一致，但按移动端重排：
/// 走马灯压成一行、Hero 缩小、手绘游戏机仅在宽屏出现、玩法卡片提到主推之后，
/// 网页式页脚已移出主滚动流（改到「关于」页）。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenGames});

  /// 跳到「玩法」页签。
  final VoidCallback onOpenGames;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OnlineService _online = OnlineService();
  StreamSubscription<String>? _broadcastSub;

  @override
  void initState() {
    super.initState();
    _online.start();
    _broadcastSub = _online.broadcasts.listen((String text) {
      if (!mounted) return;
      showTopToast(context, '全服公告：$text');
    });
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    _online.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);

    return Column(
      children: <Widget>[
        AppHeader(title: XqfEnv.appName),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: XqfBreakpoints.contentMaxWidth(c.maxWidth),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _HeroSection(online: _online),
                        const SizedBox(height: 26),

                        // ---------- 主推位 ----------
                        const SectionHead(title: '主推位', note: '1v1 推理 · 新手友好'),
                        const SizedBox(height: 14),
                        HubBox(
                          entry: GameCatalog.featured,
                          onTap: () => openGame(context, GameCatalog.featured),
                        ),
                        const SizedBox(height: 28),

                        // ---------- 精选玩法（玩法卡片优先） ----------
                        SectionHead(
                          title: '精选玩法',
                          trailing: LinkTextButton(
                            label: '全部玩法 →',
                            icon: 'gamepad',
                            fontSize: 12,
                            onPressed: widget.onOpenGames,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GameGrid(
                          games: GameCatalog.featuredOnHome,
                          onTap: (GameEntry g) => openGame(context, g),
                        ),
                        const SizedBox(height: 28),

                        // ---------- 服务票根条 ----------
                        const SectionHead(title: '服务', note: '顺手拿一张票'),
                        const SizedBox(height: 14),
                        _TicketStrip(
                          onWeekly: () => showTopToast(context, '「全服周报」将在后续版本接入'),
                          onCommunity: () => showTopToast(context, '「交流社区」将在后续版本接入'),
                          onComment: () => showTopToast(context, '「评价与打分」将在后续版本接入'),
                          onSponsor: () => showSponsorDialog(context),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            '${XqfEnv.appName} · v${XqfEnv.version}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: p.textAa,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Hero：走马灯 + 横格纸大卡。窄屏压缩为纯文案卡，宽屏才出现手绘游戏机。
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.online});

  final OnlineService online;

  static const List<String> marquee = <String>[
    '图灵测试',
    '海龟汤',
    '五子棋',
    '围棋',
    '聊天室',
    '临时聊天',
  ];

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool compact = !XqfBreakpoints.isMedium(c.maxWidth);
        final bool showArt = c.maxWidth >= 760;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // 衬底纸
            Positioned(
              left: 18,
              right: 14,
              top: 36,
              bottom: -14,
              child: Transform.rotate(
                angle: 1.4 * 3.1415926535 / 180,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.noteBlue,
                    border: Border.all(color: p.inkBlack, width: 2),
                    borderRadius: XqfRadii.hand,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Marquee(compact: compact),
                const SizedBox(height: 16),
                Transform.rotate(
                  angle: -0.7 * 3.1415926535 / 180,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: p.inkBlack, width: 2),
                      borderRadius: XqfRadii.hand,
                      boxShadow: XqfShadows.panel(p),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RuledPaper(
                      backgroundColor: p.noteYellow,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          showArt ? 32 : 20,
                          showArt ? 28 : 20,
                          showArt ? 28 : 20,
                          showArt ? 24 : 20,
                        ),
                        child: showArt
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: _HeroCopy(online: online, compact: false),
                                  ),
                                  const SizedBox(width: 24),
                                  const ArcadeArt(width: 190),
                                ],
                              )
                            : _HeroCopy(online: online, compact: compact),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 街机招牌条。窄屏压成一行，避免换行三四行把首屏撑满。
class _Marquee extends StatelessWidget {
  const _Marquee({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Transform.rotate(
      angle: -0.6 * 3.1415926535 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: p.surfaceWhite,
          border: Border.all(color: p.inkBlack, width: 2),
          borderRadius: XqfRadii.chip,
          boxShadow: XqfShadows.chip(p),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: p.success,
                shape: BoxShape.circle,
                border: Border.all(color: p.surfaceWhite, width: 2),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'NOW PLAYING',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: p.inkBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _HeroSection.marquee.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: compact ? 0 : 1,
                  color: p.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.online, required this.compact});

  final OnlineService online;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: p.success,
                shape: BoxShape.circle,
                border: Border.all(color: p.surfaceWhite, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '# GAME HUB',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 4,
                color: p.inkBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          XqfEnv.appName,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: compact ? 32 : 42,
            height: 1.05,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: p.inkBlack,
          ),
        ),
        Text(
          XqfEnv.appNameCn,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: compact ? 15 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: p.inkBlack,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          '屏幕那边，不止一场对局。',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.6,
            color: p.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '匿名匹配 · 问答推理 · 在线对弈 · 大厅闲聊',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.6,
            color: p.textSubtle,
          ),
        ),
        SizedBox(height: compact ? 14 : 16),
        ListenableBuilder(
          listenable: online,
          builder: (BuildContext context, _) {
            final int? count = online.onlineCount;
            return Wrap(
              spacing: 18,
              runSpacing: 10,
              children: <Widget>[
                _HeroStat(
                  icon: 'user',
                  value: count == null ? '--' : '$count',
                  label: '名玩家在线',
                  muted: count == null,
                ),
                _HeroStat(
                  icon: 'gamepad',
                  value: '${GameCatalog.all.length + 1}',
                  label: '个玩法',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    this.muted = false,
  });

  final String icon;
  final String value;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIcon(icon, size: 16, color: muted ? p.textAa : p.inkBlue),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: muted ? p.textAa : p.inkBlack,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: p.textSubtle,
          ),
        ),
      ],
    );
  }
}

class _TicketStrip extends StatelessWidget {
  const _TicketStrip({
    required this.onWeekly,
    required this.onCommunity,
    required this.onComment,
    required this.onSponsor,
  });

  final VoidCallback onWeekly;
  final VoidCallback onCommunity;
  final VoidCallback onComment;
  final VoidCallback onSponsor;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceWhite,
        border: Border.all(color: p.inkBlack, width: 2),
        borderRadius: XqfRadii.chip,
        boxShadow: XqfShadows.card(p),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          HubTicket(
            index: '01',
            icon: 'grid',
            label: '全服周报',
            tag: '榜单',
            onTap: onWeekly,
          ),
          HubTicket(
            index: '02',
            icon: 'users',
            label: '交流社区',
            tag: '新',
            onTap: onCommunity,
          ),
          HubTicket(
            index: '03',
            icon: 'chat-lines',
            label: '评价与打分',
            tag: '表态',
            onTap: onComment,
          ),
          HubTicket(
            index: '04',
            icon: 'heart',
            label: '赞助支持',
            tag: '微信',
            onTap: onSponsor,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
