import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../data/game_catalog.dart';
import '../widgets/app_header.dart';
import '../widgets/breakpoints.dart';
import '../widgets/doodle.dart';
import '../widgets/fold_section.dart';
import '../widgets/hub_card.dart';
import '../widgets/toast.dart';
import 'web_page.dart';

/// 打开一个玩法。外部站点走系统浏览器，其余玩法暂未接入。
Future<void> openGame(BuildContext context, GameEntry entry) async {
  final String? url = GameCatalog.externalUrls[entry.id];
  if (url != null) {
    // 外部玩法也留在 App 内打开，需要时可在页面右上角切到浏览器
    await openInAppWeb(context, url: url, title: entry.title);
    return;
  }
  if (!context.mounted) return;
  showTopToast(context, '「${entry.title}」将在后续版本接入，敬请期待');
}

/// 玩法页：全部玩法 + 分类筛选。
class GamesPage extends StatefulWidget {
  const GamesPage({super.key, required this.onToggleTheme, required this.isDark});

  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  String _group = 'all';

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final List<GameEntry> games = GameCatalog.byGroup(_group);

    return Column(
      children: <Widget>[
        AppHeader(
          title: '玩法',
          actions: <Widget>[
            HeaderIconButton(
              icon: widget.isDark ? 'sun' : 'moon',
              tooltip: '主题切换',
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: XqfBreakpoints.contentMaxWidth(MediaQuery.of(context).size.width),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SectionHead(
                      title: '全部玩法',
                      note: '共 ${GameCatalog.all.length} 个',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: GameCatalog.filters.map((List<String> f) {
                        return _FilterChip(
                          label: f[1],
                          active: f[0] == _group,
                          onTap: () => setState(() => _group = f[0]),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    _GameGrid(
                      games: games,
                      onTap: (GameEntry g) => openGame(context, g),
                    ),
                    const SizedBox(height: 22),
                    const EmptyTip(
                      text: '更多玩法（方块世界等）仍在打磨，'
                          '接入后会直接出现在这里。',
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '玩法入口按 Web 端首页同步维护',
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
          ),
        ),
      ],
    );
  }
}

/// 玩法网格：按宽度自适应列数。
class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.games, required this.onTap, this.extent});

  final List<GameEntry> games;
  final ValueChanged<GameEntry> onTap;
  final double? extent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int columns = XqfBreakpoints.columns(c.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: games.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: extent ?? 252,
          ),
          itemBuilder: (BuildContext context, int i) => HubCard(
            entry: games[i],
            onTap: () => onTap(games[i]),
          ),
        );
      },
    );
  }
}

/// 玩法网格（供首页复用）。
class GameGrid extends StatelessWidget {
  const GameGrid({
    super.key,
    required this.games,
    required this.onTap,
    this.mainAxisExtent = 252,
  });

  final List<GameEntry> games;
  final ValueChanged<GameEntry> onTap;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) =>
      _GameGrid(games: games, onTap: onTap, extent: mainAxisExtent);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
    );
  }
}
