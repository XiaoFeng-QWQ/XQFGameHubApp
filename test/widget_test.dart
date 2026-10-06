// XQFGameHub —— Widget 冒烟测试。
//
// 不依赖真实后端：只渲染设计系统组件与账号中心「未登录」视图，
// 用于验证布局不会抛异常、关键文案与结构存在。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xqf_game_hub/core/env.dart';
import 'package:xqf_game_hub/core/storage/app_prefs.dart';
import 'package:xqf_game_hub/core/theme/app_theme.dart';
import 'package:xqf_game_hub/data/models/account.dart';
import 'package:xqf_game_hub/data/hub_socket.dart';
import 'package:xqf_game_hub/state/app_state.dart';
import 'package:xqf_game_hub/ui/pages/about_page.dart';
import 'package:xqf_game_hub/ui/pages/account/account_guest.dart';
import 'package:xqf_game_hub/ui/pages/account/account_hero.dart';
import 'package:xqf_game_hub/ui/pages/account/account_page.dart';
import 'package:xqf_game_hub/ui/pages/turing/turing_page.dart';
import 'package:xqf_game_hub/ui/widgets/app_icon.dart';
import 'package:xqf_game_hub/ui/widgets/doodle.dart';
import 'package:xqf_game_hub/ui/pages/app_shell.dart';
import 'package:xqf_game_hub/ui/pages/games_page.dart';
import 'package:xqf_game_hub/ui/widgets/bottom_nav.dart';
import 'package:xqf_game_hub/ui/widgets/fold_section.dart';
import 'package:xqf_game_hub/ui/widgets/hub_card.dart';
import 'package:xqf_game_hub/ui/widgets/paper.dart';

Future<AppScope> _scope(Widget child, {bool bare = false}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final AppPrefs prefs = await AppPrefs.init();
  final AppServices services = AppServices(prefs);
  final AuthController auth = AuthController(prefs)..restore();
  final ThemeController theme = ThemeController(prefs);
  return AppScope(
    services: services,
    auth: auth,
    theme: theme,
    child: MaterialApp(
      theme: XqfTheme.light(),
      home: bare ? child : Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUpAll(() {
    // 测试里不发起真实 WebSocket 连接
    HubSocket.disabled = true;
  });

  testWidgets('设计系统组件可渲染', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      Column(
        children: <Widget>[
          const SectionHead(title: '区块标题', note: '附注'),
          const SizedBox(height: 12),
          DoodlePanel(
            tone: NoteTone.pink,
            child: Column(
              children: <Widget>[
                DoodleButton.label(label: '普通按钮', icon: 'edit', onPressed: () {}),
                const SizedBox(height: 10),
                DoodleButton.label(
                  label: '危险按钮',
                  variant: DoodleButtonVariant.danger,
                  onPressed: () {},
                ),
                const SizedBox(height: 10),
                const DoodleTag(label: '标签'),
                const SizedBox(height: 10),
                const DoodleStamp(label: 'NEW'),
                const SizedBox(height: 10),
                const AppIcon('grid', size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 80,
            child: DotGridBackground(child: Center(child: Text('点阵纸'))),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 80,
            child: RuledPaper(child: Center(child: Text('横格纸'))),
          ),
          const SizedBox(height: 12),
          const DashedDivider(),
        ],
      ),
    ));

    expect(find.text('区块标题'), findsOneWidget);
    expect(find.text('普通按钮'), findsOneWidget);
    expect(find.text('危险按钮'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('点阵纸'), findsOneWidget);
    expect(find.text('横格纸'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全部线性图标都能解析渲染', (WidgetTester tester) async {
    final List<String> names = AppIcons.all.keys.toList();
    await tester.pumpWidget(await _scope(
      Wrap(
        children: <Widget>[
          for (final String name in names) AppIcon(name, size: 20),
        ],
      ),
    ));
    // SVG 解析失败会抛异常，这里确保 47 个图标全部可用
    expect(tester.takeException(), isNull);
    expect(names.length, AppIcons.all.length);
    expect(find.byType(AppIcon), findsNWidgets(names.length));
  });

  testWidgets('玩法卡可渲染', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      const SizedBox(
        width: 200,
        height: 260,
        child: HubCard(
          entry: GameEntry(
            id: 'soup',
            title: '海龟汤',
            desc: '横向思维 · 问答推理',
            icon: 'soup',
            tone: NoteTone.blue,
            group: 'reason',
            metas: <String>['问答推理', '共享汤面'],
            stamp: 'NEW',
          ),
        ),
      ),
    ));

    expect(find.text('海龟汤'), findsOneWidget);
    expect(find.text('横向思维 · 问答推理'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('账号中心未登录视图', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      AccountGuestView(onSignedIn: () async {}),
    ));
    await tester.pumpAndSettle();

    // 「找回账号」已并入登录卡，改成 tab 切换
    expect(find.text('登录账号'), findsOneWidget);
    expect(find.text('邮箱验证码'), findsOneWidget);
    expect(find.text('账号密码'), findsOneWidget);
    expect(find.text('第三方登录'), findsOneWidget);
    // 默认是邮箱验证码 tab
    expect(find.text('登录 / 注册'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('《用户协议》'), findsOneWidget);
    expect(find.text('《隐私政策》'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未登录视图：tab 切换邮箱验证码 / 账号密码', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      AccountGuestView(onSignedIn: () async {}),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('账号密码'));
    await tester.pumpAndSettle();

    // 切到密码 tab：验证码与协议文案随邮箱表单一起消失，换成密码登录
    expect(find.text('获取验证码'), findsNothing);
    expect(find.text('登录 / 注册'), findsNothing);
    expect(find.text('《用户协议》'), findsNothing);
    expect(find.text('登录'), findsOneWidget);
    // 讲清楚密码登录的适用范围（邮箱注册的账号默认没有密码）
    expect(find.textContaining('仅适用于已设置密码的账号'), findsOneWidget);

    await tester.tap(find.text('邮箱验证码'));
    await tester.pumpAndSettle();

    // 切回来，邮箱表单恢复
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('登录 / 注册'), findsOneWidget);
    expect(find.text('登录'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未登录时「我的」页也能切换外观（三态）', (WidgetTester tester) async {
    final AppScope scope = await _scope(
      const Scaffold(body: AccountPage()),
      bare: true,
    );
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    // 主题是设备级偏好：未登录（测试里没有会话）也必须看得到
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('亮色'), findsOneWidget);
    expect(find.text('暗色'), findsOneWidget);
    expect(scope.theme.mode, ThemeMode.system);

    // 页面比测试画布长，先把该行滚进视口再点
    await tester.ensureVisible(find.text('暗色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('暗色'));
    await tester.pumpAndSettle();
    expect(scope.theme.mode, ThemeMode.dark);

    await tester.tap(find.text('亮色'));
    await tester.pumpAndSettle();
    expect(scope.theme.mode, ThemeMode.light);

    // 回归：点过之后仍能回到「跟随系统」——旧版页头按钮做不到这一点
    await tester.tap(find.text('跟随系统'));
    await tester.pumpAndSettle();
    expect(scope.theme.mode, ThemeMode.system);

    expect(tester.takeException(), isNull);
  });

  testWidgets('图灵测试落地页：未登录时引导去登录', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      TuringPage(onRequireLogin: () {}),
      bare: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('屏幕那边的家伙，\n真的是人吗？'), findsOneWidget);
    expect(find.text('需要登录后才能开始对局'), findsOneWidget);
    expect(find.text('去「我的」登录'), findsOneWidget);
    // 未登录不出现开局入口
    expect(find.text('马上开始匹配'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('图灵测试落地页：已登录时可选时长并开局', (WidgetTester tester) async {
    final AppScope scope = await _scope(
      TuringPage(onRequireLogin: () {}),
      bare: true,
    );
    await scope.auth.signIn(token: 'tk_1', nickname: '测试者');
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    expect(find.text('马上开始匹配'), findsOneWidget);
    expect(find.text('10 分钟'), findsOneWidget);
    expect(find.text('5 分钟'), findsOneWidget);
    expect(find.text('需要登录后才能开始对局'), findsNothing);

    // 开局 → 进入匹配中（匹配页有常驻动画，不能用 pumpAndSettle）
    await tester.tap(find.text('马上开始匹配'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('正在为你寻找对手…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('竖屏用底部导航：三个页签 + 切换', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await _scope(const AppShell(), bare: true));
    await tester.pumpAndSettle();

    // 导航标签与页面内标题可能同名，按祖先精确定位到导航栏内的那个
    Finder nav(String label) => find.descendant(
          of: find.byType(XqfBottomBar),
          matching: find.text(label),
        );

    expect(find.byType(XqfBottomBar), findsOneWidget);
    expect(find.byType(XqfNavRail), findsNothing);
    expect(nav('首页'), findsOneWidget);
    expect(nav('玩法'), findsOneWidget);
    expect(nav('我的'), findsOneWidget);

    // 默认在首页
    expect(find.text('主推位'), findsOneWidget);
    expect(find.text('XQFGameHub'), findsWidgets);

    // 切到「玩法」页签
    await tester.tap(nav('玩法'));
    await tester.pumpAndSettle();
    expect(find.text('全部玩法'), findsOneWidget);
    expect(find.text('推理对局'), findsOneWidget);

    // 切到「我的」页签（未登录 → 登录卡，默认邮箱验证码 tab）
    await tester.tap(nav('我的'));
    await tester.pumpAndSettle();
    expect(find.text('登录账号'), findsOneWidget);
    expect(find.text('邮箱验证码'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏改用左侧导航栏', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await _scope(const AppShell(), bare: true));
    await tester.pumpAndSettle();

    expect(find.byType(XqfNavRail), findsOneWidget);
    expect(find.byType(XqfBottomBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('玩法页展示全部玩法与筛选', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      Scaffold(body: GamesPage(onRequireLogin: () {})),
      bare: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('全部玩法'), findsOneWidget);
    expect(find.text('海龟汤'), findsOneWidget);
    expect(find.text('公共聊天室'), findsOneWidget);
    expect(find.text('污染卡牌'), findsOneWidget);
    expect(find.text('临时聊天'), findsOneWidget);
    expect(find.text('五子棋'), findsOneWidget);
    expect(find.text('围棋'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关于页承载原页脚内容', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(const AboutPage(), bare: true));
    await tester.pumpAndSettle();

    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('备案信息'), findsOneWidget);
    expect(find.text('萌ICP备20269944号'), findsOneWidget);
    expect(find.text('假ICP备1202612号'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关于页客户端信息展示开发协助模型', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(const AboutPage(), bare: true));
    await tester.pumpAndSettle();

    expect(find.text('客户端信息'), findsOneWidget);
    expect(find.text('开发协助'), findsOneWidget);
    // 「关于」页与 README 的「开发说明」共用同一个常量
    expect(find.text(XqfEnv.aiModel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关于页「赞助支持」是弹窗而不是跳外链', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(const AboutPage(), bare: true));
    await tester.pumpAndSettle();

    expect(find.text('赞助支持'), findsOneWidget);
    // 页面比测试画布长，先滚动到该行再点
    await tester.ensureVisible(find.text('赞助支持'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('赞助支持'));
    await tester.pumpAndSettle();

    // 弹窗打开：标题与提示同时出现（测试环境图片加载失败走 errorBuilder）
    expect(find.text('赞助支持'), findsNWidgets(2));
    expect(find.text('微信扫一扫 · 金额随意 · 心意最重要'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('折叠分组默认收起、点击展开', (WidgetTester tester) async {
    await tester.pumpWidget(await _scope(
      const CollapsibleGroup(
        title: '内容管理',
        note: '标签、表情与对局内容',
        children: <Widget>[Text('面板内容')],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('内容管理'), findsOneWidget);

    // SizeTransition 收起时子节点仍在树上，用实际高度判断是否展开
    final double collapsed = tester.getSize(find.byType(CollapsibleGroup)).height;

    await tester.tap(find.text('内容管理'));
    await tester.pumpAndSettle();

    final double expanded = tester.getSize(find.byType(CollapsibleGroup)).height;
    expect(expanded, greaterThan(collapsed));
    expect(find.text('面板内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('账号中心身份卡', (WidgetTester tester) async {
    const AccountOverview overview = AccountOverview(
      playerId: 'abc123',
      nickname: '小明',
      discriminator: 42,
      createdAt: 1700000000,
      lastPlayedAt: 1751000000,
      wornTags: <String>['理性', '幽默'],
      wornSpecialTags: <String>['新年快乐'],
      canRename: true,
      renameHint: '本月可修改一次',
      stats: AccountStats(totalGames: 42, winRate: 60, avgMsgs: 8),
    );

    await tester.pumpWidget(await _scope(
      AccountHero(
        overview: overview,
        onChanged: (_) {},
        onAvatarUploaded: () {},
      ),
    ));

    expect(find.text('小明'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget);
    expect(find.text('理性'), findsOneWidget);
    expect(find.text('新年快乐'), findsOneWidget);
    expect(find.text('42'), findsOneWidget); // 总对局
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('总对局'), findsOneWidget);
    expect(find.text('修改昵称'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
