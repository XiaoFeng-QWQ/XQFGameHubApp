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
import 'package:xqf_game_hub/data/models/turing.dart';
import 'package:xqf_game_hub/data/turing/turing_client.dart';
import 'package:xqf_game_hub/state/app_state.dart';
import 'package:xqf_game_hub/ui/pages/about_page.dart';
import 'package:xqf_game_hub/ui/pages/account/account_guest.dart';
import 'package:xqf_game_hub/ui/pages/account/account_hero.dart';
import 'package:xqf_game_hub/ui/pages/account/account_page.dart';
import 'package:xqf_game_hub/ui/pages/turing/turing_page.dart';
import 'package:xqf_game_hub/ui/widgets/turing/turing_poster.dart';
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

  /// 造一个「已结束」的对局客户端（ticker 已取消，不会残留 pending timer），
  /// 并把它推到一个真实 Navigator 上，用于验证退出路径。
  Future<({TuringClient client, GlobalKey<NavigatorState> navKey})> pumpTuringOnNav(
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppPrefs prefs = await AppPrefs.init();
    final AppServices services = AppServices(prefs);
    final AuthController auth = AuthController(prefs)..restore();
    final ThemeController theme = ThemeController(prefs);
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(AppScope(
      services: services,
      auth: auth,
      theme: theme,
      child: MaterialApp(
        navigatorKey: navKey,
        theme: XqfTheme.light(),
        home: const Scaffold(body: Center(child: Text('占位首页'))),
      ),
    ));

    final TuringClient client = TuringClient(services.hub);
    client.start(
      nickname: '测试者',
      playerToken: 'tk',
      fingerprint: 'fp',
      durationSeconds: 300,
    );
    // 注意：不能用 pumpEventQueue() —— 它内部是零延迟 Timer，
    // 在 testWidgets 的 fake clock 下不会自己触发，会直接把测试挂住。
    // tester.pump() 会 flush microtask，广播流才会把消息派发给客户端。
    services.hub.debugEmit(<String, dynamic>{
      'type': 'matched',
      'opponent_name': '对手甲',
      'session_id': 's1',
      'duration': 300,
    });
    await tester.pump();
    services.hub.debugEmit(<String, dynamic>{
      'type': 'timeout',
      'reason': 'opponent_timeout',
      'opponent_truth': 'ai',
      'session_id': 's1',
    });
    await tester.pump();
    expect(client.phase, TuringPhase.finished);

    navKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => TuringPage(onRequireLogin: () {}, client: client),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return (client: client, navKey: navKey);
  }

  testWidgets('对局中退出能真的退出，不会卡死', (WidgetTester tester) async {
    // 回归：旧实现收尾用 Navigator.maybePop()，而 PopScope.canPop 依赖 phase，
    // reset() 只是把重建排进队列 —— maybePop 仍读到 canPop:false，
    // 判定 doNotPop → 回调 onPopInvokedWithResult(false) → 又回到 _handleBack
    // → 同步无限递归，主线程卡死（表现为「应用未响应」）。
    final ({TuringClient client, GlobalKey<NavigatorState> navKey}) t =
        await pumpTuringOnNav(tester);
    expect(find.text('再来一局'), findsOneWidget);
    // 分享战绩分享的是账号累计统计，不属于对局结算页
    expect(find.text('分享战绩到聊天室'), findsNothing);

    // 页头返回 → 二次确认 → 确认后必须真的退出
    await tester.tap(find.byTooltip('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('离开对局'), findsOneWidget);

    await tester.tap(find.text('离开'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('占位首页'), findsOneWidget);
    expect(find.text('再来一局'), findsNothing);

    t.client.dispose();
  });

  testWidgets('结果页「返回游戏中心」直接退出，不再二次确认', (WidgetTester tester) async {
    final ({TuringClient client, GlobalKey<NavigatorState> navKey}) t =
        await pumpTuringOnNav(tester);

    await tester.tap(find.text('返回游戏中心'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 对局已结束，不应弹确认框
    expect(find.text('离开对局'), findsNothing);
    expect(find.text('占位首页'), findsOneWidget);

    t.client.dispose();
  });

  testWidgets('发送消息后自动收起键盘', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppPrefs prefs = await AppPrefs.init();
    final AppServices services = AppServices(prefs);
    final AuthController auth = AuthController(prefs)..restore();
    final ThemeController theme = ThemeController(prefs);
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(AppScope(
      services: services,
      auth: auth,
      theme: theme,
      child: MaterialApp(
        navigatorKey: navKey,
        theme: XqfTheme.light(),
        home: const Scaffold(body: Center(child: Text('占位首页'))),
      ),
    ));

    // 需要「对局中」阶段输入框才可用；ticker 结束时由 dispose 收掉
    final TuringClient client = TuringClient(services.hub);
    client.start(
      nickname: '测试者',
      playerToken: 'tk',
      fingerprint: 'fp',
      durationSeconds: 300,
    );
    services.hub.debugEmit(<String, dynamic>{
      'type': 'matched',
      'opponent_name': '对手甲',
      'session_id': 's1',
      'duration': 300,
    });
    await tester.pump();
    expect(client.phase, TuringPhase.chatting);

    navKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => TuringPage(onRequireLogin: () {}, client: client),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final Finder input = find.descendant(
      of: find.byKey(const Key('turing-input')),
      matching: find.byType(EditableText),
    );
    expect(input, findsOneWidget);

    await tester.showKeyboard(input);
    await tester.pump();
    expect(tester.widget<EditableText>(input).focusNode.hasFocus, isTrue);

    await tester.enterText(input, '你好');
    await tester.pump();
    await tester.tap(find.text('发送'));
    await tester.pump();

    // 发完就收键盘：否则会挡住聊天区，判定区也被顶掉
    expect(tester.widget<EditableText>(input).focusNode.hasFocus, isFalse);

    client.dispose();
  });

  testWidgets('判定区的标签默认折叠，点击才展开', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppPrefs prefs = await AppPrefs.init();
    final AppServices services = AppServices(prefs);
    final AuthController auth = AuthController(prefs)..restore();
    final ThemeController theme = ThemeController(prefs);
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(AppScope(
      services: services,
      auth: auth,
      theme: theme,
      child: MaterialApp(
        navigatorKey: navKey,
        theme: XqfTheme.light(),
        home: const Scaffold(body: Center(child: Text('占位首页'))),
      ),
    ));

    final TuringClient client = TuringClient(services.hub);
    client.start(
      nickname: '测试者',
      playerToken: 'tk',
      fingerprint: 'fp',
      durationSeconds: 300,
    );
    services.hub.debugEmit(<String, dynamic>{
      'type': 'matched',
      'opponent_name': '对手甲',
      'session_id': 's1',
      'duration': 300,
    });
    await tester.pump();
    // 解锁判定并让自己发过消息
    services.hub.debugEmit(<String, dynamic>{
      'type': 'judge_notify',
      'message': '对方已作出判定',
      'seconds_remaining': 60,
    });
    await tester.pump();
    client.sendMessage('你好');
    await tester.pump();

    navKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => TuringPage(onRequireLogin: () {}, client: client),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 可判定了：两个按钮 + 折叠的标签入口
    expect(find.text('它是人类'), findsOneWidget);
    expect(find.text('贴个标签（可选）'), findsOneWidget);
    // 默认折叠 —— 全页只有聊天输入框一个可编辑区
    expect(find.byType(EditableText), findsOneWidget);

    await tester.tap(find.text('贴个标签（可选）'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('收起标签'), findsOneWidget);
    expect(find.byType(EditableText), findsNWidgets(2));

    await tester.tap(find.text('收起标签'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EditableText), findsOneWidget);

    client.dispose();
  });

  testWidgets('关闭举报面板后不应把焦点还给输入框', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppPrefs prefs = await AppPrefs.init();
    final AppServices services = AppServices(prefs);
    final AuthController auth = AuthController(prefs)..restore();
    final ThemeController theme = ThemeController(prefs);
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(AppScope(
      services: services,
      auth: auth,
      theme: theme,
      child: MaterialApp(
        navigatorKey: navKey,
        theme: XqfTheme.light(),
        home: const Scaffold(body: Center(child: Text('占位首页'))),
      ),
    ));

    final TuringClient client = TuringClient(services.hub);
    client.start(
      nickname: '测试者',
      playerToken: 'tk',
      fingerprint: 'fp',
      durationSeconds: 300,
    );
    services.hub.debugEmit(<String, dynamic>{
      'type': 'matched',
      'opponent_name': '对手甲',
      'session_id': 's1',
      'duration': 300,
    });
    await tester.pump();

    navKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => TuringPage(onRequireLogin: () {}, client: client),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final Finder input = find.descendant(
      of: find.byKey(const Key('turing-input')),
      matching: find.byType(EditableText),
    );
    await tester.showKeyboard(input);
    await tester.pump();
    expect(tester.widget<EditableText>(input).focusNode.hasFocus, isTrue);

    // 打开举报面板
    await tester.tap(find.byTooltip('举报对方'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('辱骂 / 人身攻击'), findsOneWidget);

    // 点遮罩关闭
    await tester.tapAt(const Offset(400, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('辱骂 / 人身攻击'), findsNothing);
    // 关掉面板后不该又把键盘弹回来
    expect(tester.widget<EditableText>(input).focusNode.hasFocus, isFalse);

    client.dispose();
  });

  testWidgets('导出海报 = 结果摘要 + 聊天记录全文 + 扫码页脚', (WidgetTester tester) async {
    // 「导出为图片」导出的是**对局海报**，不是结算界面截图
    const TuringResult result = TuringResult(
      isWin: true,
      verdict: '猜对啦！',
      reveal: '对方是：AI',
      totalMessages: 3,
      elapsed: Duration(seconds: 95),
      userGuess: 'ai',
      opponentTruth: 'ai',
      opponentGuess: 'human',
    );
    final List<TuringFeedItem> feed = <TuringFeedItem>[
      TuringFeedItem.text(text: '你好', sender: '对手甲', mine: false),
      TuringFeedItem.text(text: '你是人还是机器', sender: '测试者', mine: true),
      TuringFeedItem.system('双方需 60 秒内互发至少一条消息'),
    ];

    await tester.pumpWidget(await _scope(
      Scaffold(
        body: SingleChildScrollView(
          child: TuringPoster(result: result, feed: feed),
        ),
      ),
      bare: true,
    ));
    await tester.pump();

    // 结果摘要（按对错着色）
    expect(find.text('猜对啦！'), findsOneWidget);
    expect(find.text('对方是：AI'), findsOneWidget);
    expect(find.text('你的判断'), findsOneWidget);
    expect(find.text('对方猜你是'), findsOneWidget);
    // 聊天记录全文（含系统提示）
    expect(find.text('你好'), findsOneWidget);
    expect(find.text('你是人还是机器'), findsOneWidget);
    expect(find.text('双方需 60 秒内互发至少一条消息'), findsOneWidget);
    // 页脚：品牌 + 「扫码来玩」二维码
    expect(find.textContaining('图灵测试（1v1）'), findsOneWidget);
    expect(find.text('扫码来玩'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点「导出为图片」后按钮立刻进入禁用态', (WidgetTester tester) async {
    // 回归：导出前要预热二维码（网络等待），若 setState(_exporting=true)
    // 排在预热之后，这段期间按钮既没禁用、文案也没变，看起来就是「卡了一下」。
    final ({TuringClient client, GlobalKey<NavigatorState> navKey}) t =
        await pumpTuringOnNav(tester);

    await tester.tap(find.text('更多操作'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('导出为图片'), findsOneWidget);

    // 结算页比测试画布长，先滚进视口再点
    await tester.ensureVisible(find.text('导出为图片'));
    await tester.pump();
    await tester.tap(find.text('导出为图片'));
    await tester.pump(); // 只推进一帧：setState 应当已经生效

    expect(find.text('导出中…'), findsOneWidget);
    expect(find.text('导出为图片'), findsNothing);

    // 放掉导出流程里未完成的异步。测试环境没有网络、也没有 path_provider，
    // 二维码加载与写文件都必然失败 —— 这些异常是预期的，取走即可，
    // 否则会被判成测试失败。
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
      tester.takeException();
    }

    t.client.dispose();
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
    // 分享的是累计战绩（总场次/胜/负/胜率），所以入口在数据卡这里，
    // 不在对局结算页
    expect(find.text('分享战绩到聊天室'), findsOneWidget);
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
