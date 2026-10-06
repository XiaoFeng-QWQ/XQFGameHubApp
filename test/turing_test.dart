// 图灵测试（1v1）对局状态机测试。
//
// 不连真实服务端：用 HubSocket.debugEmit 把服务端消息喂进解析链路，
// 覆盖判定门槛、各结束原因的结果文案、以及聊天时间到的收口行为。
//
// 注意：HubSocket.messages 是广播流（异步派发），emit 之后要等一个事件轮次，
// 否则断言会跑在监听器之前。

import 'package:flutter_test/flutter_test.dart';

import 'package:xqf_game_hub/data/hub_socket.dart';
import 'package:xqf_game_hub/data/models/turing.dart';
import 'package:xqf_game_hub/data/turing/turing_client.dart';

/// 喂一条服务端消息，并等它派发到监听器。
Future<void> emit(HubSocket hub, Map<String, dynamic> message) async {
  hub.debugEmit(message);
  await pumpEventQueue();
}

/// 建一个已进入对局的客户端（start → matched）。
Future<({HubSocket hub, TuringClient client})> started() async {
  final HubSocket hub = HubSocket();
  final TuringClient client = TuringClient(hub);
  client.start(
    nickname: '测试者',
    playerToken: 'tk_1',
    fingerprint: 'fp_1',
    durationSeconds: 300,
  );
  await emit(hub, <String, dynamic>{
    'type': 'matched',
    'opponent_name': '对手甲',
    'session_id': 'sess_1',
    'duration': 300,
  });
  return (hub: hub, client: client);
}

void main() {
  setUpAll(() => HubSocket.disabled = true);

  test('start 进入匹配中，matched 后进入对局并给出互发消息规则', () async {
    final HubSocket hub = HubSocket();
    final TuringClient c = TuringClient(hub);
    addTearDown(c.dispose);

    c.start(
      nickname: '测试者',
      playerToken: 'tk_1',
      fingerprint: 'fp_1',
      durationSeconds: 300,
    );
    expect(c.phase, TuringPhase.matching);

    await emit(hub, <String, dynamic>{
      'type': 'matched',
      'opponent_name': '对手甲',
      'session_id': 'sess_1',
      'duration': 300,
    });

    expect(c.phase, TuringPhase.chatting);
    expect(c.opponentName, '对手甲');
    expect(c.sessionId, 'sess_1');
    expect(c.remainingSeconds, 300);
    // 开局第一条是规则提示
    expect(c.feed.single.kind, TuringFeedKind.system);
    expect(c.feed.single.text, contains('60 秒内互发至少一条消息'));
  });

  test('判定门槛：开局未满 10 秒 且 自己没发过消息时不可判定', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    expect(t.client.canJudge, isFalse);
    expect(t.client.judgeHint, contains('开局 10 秒后'));
    expect(t.client.judgeHint, contains('你发送一条消息'));

    // 只发了消息、还没到 10 秒 —— 仍不可判定
    t.client.sendMessage('你好');
    expect(t.client.canJudge, isFalse);

    // 对方先判定会立刻解锁判定窗口（等价于服务端放开）
    await emit(t.hub, <String, dynamic>{
      'type': 'judge_notify',
      'message': '对方已作出判定',
      'seconds_remaining': 60,
    });
    expect(t.client.canJudge, isTrue);
    expect(t.client.judgeHint, '可以锁定你的答案了');
  });

  test('自己判定后转等待对方，双方判定给出对错结论', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    await emit(t.hub, <String, dynamic>{
      'type': 'judge_notify',
      'message': '对方已作出判定',
      'seconds_remaining': 60,
    });
    t.client.sendMessage('你是人还是机器？');
    t.client.judge('ai', tag: '话痨');
    expect(t.client.phase, TuringPhase.waitingOpponent);
    expect(t.client.judged, isTrue);
    // 判定后输入仍可用（Web 端只隐藏判定区）
    expect(t.client.inputEnabled, isTrue);

    await emit(t.hub, <String, dynamic>{
      'type': 'judged',
      'truth': 'ai',
      'opponent_guess': 'human',
      'opponent_tag': '有趣',
      'session_id': 'sess_1',
      'opponent_name': '对手甲',
    });

    final TuringResult r = t.client.result!;
    expect(t.client.phase, TuringPhase.finished);
    expect(r.isWin, isTrue);
    expect(r.verdict, '猜对啦！');
    expect(r.opponentTruthLabel, 'AI');
    expect(r.opponentGuessLabel, '人类');
    expect(r.opponentTag, '有趣');
    expect(r.userGuessLabel, '它是 AI');
    // 1 条自己 + 0 条对方
    expect(r.totalMessages, 1);
  });

  test('猜错时结论为「猜错了...」', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    await emit(t.hub, <String, dynamic>{
      'type': 'judge_notify',
      'message': 'x',
      'seconds_remaining': 60,
    });
    t.client.sendMessage('hi');
    t.client.judge('human');
    await emit(t.hub, <String, dynamic>{
      'type': 'judged',
      'truth': 'ai',
      'session_id': 'sess_1',
    });

    expect(t.client.result!.isWin, isFalse);
    expect(t.client.result!.verdict, '猜错了...');
  });

  test('聊天时间到只收口输入，不产生结果', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    await emit(t.hub, <String, dynamic>{'type': 'timeout', 'reason': 'chat_expired'});
    expect(t.client.phase, TuringPhase.chatting);
    expect(t.client.result, isNull);
    expect(t.client.inputEnabled, isFalse);
  });

  test('系统提示「聊天时间到」开启 60 秒判定窗口', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    await emit(t.hub, <String, dynamic>{'type': 'system', 'text': '聊天时间到，请做出判定'});
    expect(t.client.judgeWindow, isTrue);
    expect(t.client.remainingSeconds, TuringClient.judgeWindowSeconds);
  });

  group('结束原因 → 结果文案', () {
    Future<void> check(
      String reason, {
      required bool win,
      required String containsText,
    }) async {
      final ({HubSocket hub, TuringClient client}) t = await started();
      addTearDown(t.client.dispose);
      await emit(t.hub, <String, dynamic>{
        'type': 'timeout',
        'reason': reason,
        'opponent_truth': 'ai',
        'session_id': 'sess_1',
        'opponent_name': '对手甲',
      });
      expect(t.client.phase, TuringPhase.finished, reason: reason);
      expect(t.client.result!.isWin, win, reason: reason);
      expect(t.client.result!.verdict, contains(containsText), reason: reason);
    }

    test('对方超时未判定 → 赢', () async {
      await check('opponent_timeout', win: true, containsText: '你赢了');
    });

    test('对方断线 → 赢', () async {
      await check('opponent_disconnected', win: true, containsText: '你赢了');
    });

    test('对方主动退出 → 赢', () async {
      await check('opponent_left', win: true, containsText: '你赢了');
    });

    test('自己超时 → 输', () async {
      await check('you_timeout', win: false, containsText: '对方赢了');
    });

    test('双方超时 → 平局', () async {
      await check('both_timeout', win: false, containsText: '平局');
    });

    test('未互发消息 → 平局不记战绩', () async {
      await check('no_mutual_chat', win: false, containsText: '不记战绩');
    });
  });

  test('对手消息进入聊天流并计入条数', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    await emit(t.hub, <String, dynamic>{
      'type': 'message',
      'text': '你好呀',
      'sender': '对手甲',
    });

    final TuringFeedItem last = t.client.feed.last;
    expect(last.kind, TuringFeedKind.text);
    expect(last.text, '你好呀');
    expect(last.mine, isFalse);
    expect(t.client.opponentMessageCount, 1);
  });

  test('未进入对局时忽略对局消息（防止上局残留串台）', () async {
    final HubSocket hub = HubSocket();
    final TuringClient c = TuringClient(hub);
    addTearDown(c.dispose);

    await emit(hub, <String, dynamic>{'type': 'message', 'text': '幽灵消息', 'sender': 'x'});
    expect(c.feed, isEmpty);
    expect(c.phase, TuringPhase.landing);
  });

  test('reset 回到落地页并清空对局状态', () async {
    final ({HubSocket hub, TuringClient client}) t = await started();
    addTearDown(t.client.dispose);

    t.client.sendMessage('hi');
    t.client.reset();

    expect(t.client.phase, TuringPhase.landing);
    expect(t.client.feed, isEmpty);
    expect(t.client.result, isNull);
    expect(t.client.myMessageCount, 0);
  });

  group('封禁与错误', () {
    test('错误里含「封禁」→ 回到落地页且不能再开局', () async {
      final ({HubSocket hub, TuringClient client}) t = await started();
      addTearDown(t.client.dispose);

      await emit(t.hub, <String, dynamic>{
        'type': 'error',
        'message': '您已被管理员封禁',
      });

      expect(t.client.banned, isTrue);
      expect(t.client.phase, TuringPhase.landing);

      // 再点开始匹配应当无效（停在落地页）
      t.client.start(
        nickname: 'x',
        playerToken: 't',
        fingerprint: 'f',
        durationSeconds: 300,
      );
      expect(t.client.phase, TuringPhase.landing);
    });

    test('「无需封禁」不算封禁', () async {
      final ({HubSocket hub, TuringClient client}) t = await started();
      addTearDown(t.client.dispose);

      await emit(t.hub, <String, dynamic>{
        'type': 'error',
        'message': '该玩家无需封禁',
      });
      expect(t.client.banned, isFalse);
    });

    test('普通错误只记 lastError，不影响对局', () async {
      final ({HubSocket hub, TuringClient client}) t = await started();
      addTearDown(t.client.dispose);

      await emit(t.hub, <String, dynamic>{
        'type': 'error',
        'message': '服务器繁忙，请稍后再试',
      });

      expect(t.client.banned, isFalse);
      expect(t.client.lastError, '服务器繁忙，请稍后再试');
      expect(t.client.phase, TuringPhase.chatting);
    });

    test('举报回执写入 reportResult', () async {
      final ({HubSocket hub, TuringClient client}) t = await started();
      addTearDown(t.client.dispose);

      await emit(t.hub, <String, dynamic>{
        'type': 'report_result',
        'success': true,
        'message': '举报已提交',
      });

      expect(t.client.reportResult, '举报已提交');
      expect(t.client.reportOk, isTrue);
      t.client.clearReportResult();
      expect(t.client.reportResult, isNull);
    });
  });

  group('无限时长（duration = 0）', () {
    /// 以 `duration: 0` 进入对局。
    Future<({HubSocket hub, TuringClient client})> startedUnlimited() async {
      final HubSocket hub = HubSocket();
      final TuringClient client = TuringClient(hub);
      client.start(
        nickname: '测试者',
        playerToken: 'tk_1',
        fingerprint: 'fp_1',
        durationSeconds: 0,
      );
      await emit(hub, <String, dynamic>{
        'type': 'matched',
        'opponent_name': '对手甲',
        'session_id': 'sess_1',
        'duration': 0,
      });
      return (hub: hub, client: client);
    }

    test('计时显示 ∞、不跑聊天倒计时、输入可用', () async {
      final ({HubSocket hub, TuringClient client}) t = await startedUnlimited();
      addTearDown(t.client.dispose);

      expect(t.client.unlimited, isTrue);
      expect(t.client.remainingLabel, '∞');
      expect(t.client.remainingSeconds, 0);
      // 不该被本地计时器判成「聊天时间到」
      expect(t.client.chatExpired, isFalse);
      expect(t.client.inputEnabled, isTrue);
    });

    test('判定后仍给满 60 秒判定窗口', () async {
      final ({HubSocket hub, TuringClient client}) t = await startedUnlimited();
      addTearDown(t.client.dispose);

      await emit(t.hub, <String, dynamic>{
        'type': 'judge_notify',
        'message': '对方已作出判定',
        'seconds_remaining': 60,
      });
      t.client.sendMessage('你好');
      expect(t.client.canJudge, isTrue);

      t.client.judge('ai');
      expect(t.client.phase, TuringPhase.waitingOpponent);
      // 无限时长下 _remaining 本来是 0，判定窗口必须直接给满
      expect(t.client.remainingSeconds, 60);
      expect(t.client.remainingLabel, '01:00');
    });

    test('服务端仍会做开局 60 秒互发消息检查（照常按平局处理）', () async {
      final ({HubSocket hub, TuringClient client}) t = await startedUnlimited();
      addTearDown(t.client.dispose);

      await emit(t.hub, <String, dynamic>{
        'type': 'timeout',
        'reason': 'no_mutual_chat',
        'opponent_truth': 'ai',
        'session_id': 'sess_1',
      });

      expect(t.client.phase, TuringPhase.finished);
      expect(t.client.result!.verdict, contains('不记战绩'));
    });
  });
}
