import '../ui/widgets/doodle.dart';
import '../ui/widgets/hub_card.dart';

/// 玩法目录。与 Web 端首页 `hub-grid` 一一对应。
///
/// 首页只展示 [featuredOnHome] 标记的精选，玩法页展示全部。
class GameCatalog {
  const GameCatalog._();

  /// 主推玩法（首页大卡）。同时也是玩法页「推理对局」里的一项。
  static const GameEntry featured = GameEntry(
    id: 'turing',
    title: '图灵测试（1v1）',
    desc: '匿名连线 · 试探识破 · 判定人类或 AI · 对局后可测默契',
    icon: 'chat-lines',
    tone: NoteTone.green,
    group: 'reason',
    metas: <String>['5 / 10 分钟', '真人优先', '战绩存档'],
  );

  static const List<GameEntry> all = <GameEntry>[
    featured,
    GameEntry(
      id: 'soup',
      title: '海龟汤',
      desc: '横向思维 · 问答推理',
      icon: 'soup',
      tone: NoteTone.blue,
      group: 'reason',
      metas: <String>['问答推理', '共享汤面'],
      stamp: 'NEW',
    ),
    GameEntry(
      id: 'lobby',
      title: '公共聊天室',
      desc: '实时聊天 · 全服公告',
      icon: 'chat',
      tone: NoteTone.yellow,
      group: 'chat',
      metas: <String>['全服大厅', '点歌 / 贴纸'],
      stamp: 'HOT',
      stampTone: StampTone.ink,
    ),
    GameEntry(
      id: 'pollution',
      title: '污染卡牌',
      desc: '卡牌对战 · 外部站点',
      icon: 'cards',
      tone: NoteTone.green,
      group: 'card',
      metas: <String>['卡牌对战', 'App 内打开'],
      external: true,
    ),
    GameEntry(
      id: 'temp-chat',
      title: '临时聊天',
      desc: '私密 · 隐秘空间',
      icon: 'bolt',
      tone: NoteTone.pink,
      group: 'chat',
      metas: <String>['私密房间', '邀请进入'],
    ),
    GameEntry(
      id: 'gomoku',
      title: '五子棋',
      desc: '单机 AI · 在线对弈',
      icon: 'gomoku',
      tone: NoteTone.green,
      group: 'board',
      metas: <String>['单机 / 联机', '可观战'],
    ),
    GameEntry(
      id: 'go',
      title: '围棋',
      desc: '中国规则数子 · 提子打劫',
      icon: 'go',
      tone: NoteTone.blue,
      group: 'board',
      metas: <String>['9/13/19 路', '单机 / 联机'],
    ),
  ];

  /// 首页「精选玩法」展示的条目。
  static const List<String> featuredOnHomeIds = <String>[
    'soup',
    'lobby',
    'gomoku',
    'temp-chat',
  ];

  static List<GameEntry> get featuredOnHome => all
      .where((GameEntry g) => featuredOnHomeIds.contains(g.id))
      .toList(growable: false);

  /// 分类筛选定义（Web 端 `.hub-filters` 的 `data-group`）。
  static const List<List<String>> filters = <List<String>>[
    <String>['all', '全部'],
    <String>['reason', '推理对局'],
    <String>['board', '棋盘竞技'],
    <String>['chat', '聊天社交'],
    <String>['card', '卡牌对战'],
  ];

  static List<GameEntry> byGroup(String group) => group == 'all'
      ? all
      : all.where((GameEntry g) => g.group == group).toList(growable: false);

  /// 外部站点玩法（用系统浏览器打开）。
  static const Map<String, String> externalUrls = <String, String>{
    'pollution': 'https://pollution.top/',
  };
}
