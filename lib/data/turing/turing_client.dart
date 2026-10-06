import 'dart:async';

import 'package:flutter/foundation.dart';

import '../hub_socket.dart';
import '../models/turing.dart';

/// 图灵测试（1v1）对局客户端。
///
/// 只负责对局状态机，不碰 UI，也**不自己持有 WS 连接** ——
/// 服务端同 IP 全站只允许一条连接（见 [HubSocket]），所以复用全局那一条。
///
/// 行为逐条对齐 Web 端 `GameClient` + `WebSocketTransport`：
/// 判定门槛（开局 10 秒 + 自己发过 ≥1 条）、聊天时间到转 60 秒判定窗口、
/// 对方已判定的通知与倒计时重启、7 种 `timeout.reason` 的结果文案。
class TuringClient extends ChangeNotifier {
  TuringClient(this._hub) {
    _sub = _hub.messages.listen(_onMessage);
  }

  final HubSocket _hub;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _ticker;

  /// 判定按钮解锁的延迟（Web 端为 10 秒）。
  static const Duration judgeUnlockDelay = Duration(seconds: 10);

  /// 判定窗口 / 等待对方的秒数（Web 端为 60 秒）。
  static const int judgeWindowSeconds = 60;

  // ---- 对局状态 ----
  TuringPhase _phase = TuringPhase.landing;
  final List<TuringFeedItem> _feed = <TuringFeedItem>[];
  TuringResult? _result;

  String _opponentName = '';
  String _sessionId = '';
  int _duration = 600;
  int _remaining = 600;

  String? _userGuess;
  String? _opponentTruth;
  bool _judgementAllowed = false;
  bool _judgeWindow = false;
  bool _chatExpired = false;
  DateTime? _startedAt;
  Timer? _unlockTimer;

  int _myMsgCount = 0;
  int _opponentMsgCount = 0;

  // 重放「再来一局」需要的参数
  String _nickname = '';
  String _playerToken = '';
  String _fingerprint = '';

  // 结果页的异步操作状态
  bool _savingHistory = false;
  String? _saveHistoryMessage;
  bool _saveHistoryOk = false;
  int? _savedHistoryId;
  bool _sendingLeaveMessage = false;
  String? _leaveMessageStatus;
  String? _shareRecordMessage;
  bool _shareRecordOk = false;
  String? _reportResult;
  bool _reportOk = false;
  bool _banned = false;
  String? _bannedMessage;
  String? _lastError;

  // ---- 只读状态 ----

  TuringPhase get phase => _phase;
  List<TuringFeedItem> get feed => List<TuringFeedItem>.unmodifiable(_feed);
  TuringResult? get result => _result;
  String get opponentName => _opponentName;
  String get sessionId => _sessionId;
  int get durationSeconds => _duration;
  int get remainingSeconds => _remaining;
  String? get userGuess => _userGuess;
  bool get judged => _userGuess != null;
  bool get judgeWindow => _judgeWindow;
  bool get chatExpired => _chatExpired;
  bool get connected => _hub.connected;
  int? get onlineCount => _hub.onlineCount;
  int get myMessageCount => _myMsgCount;
  int get opponentMessageCount => _opponentMsgCount;
  bool get savingHistory => _savingHistory;
  String? get saveHistoryMessage => _saveHistoryMessage;
  bool get saveHistoryOk => _saveHistoryOk;
  int? get savedHistoryId => _savedHistoryId;
  bool get sendingLeaveMessage => _sendingLeaveMessage;
  String? get leaveMessageStatus => _leaveMessageStatus;

  /// 无限时长（`duration <= 0`）。
  ///
  /// 服务端 `GameTimers::startChatTimer` 对 `duration <= 0` 直接 return，
  /// 不启动聊天定时器、也不会下发「聊天时间到」——由玩家手动判定结束。
  /// 但**开局 60 秒的互发消息检查照常**（`startMutualChatCheck` 是无条件调用的）。
  bool get unlimited => _duration <= 0;

  /// 顶部计时器要显示的文案；无限时长显示 `∞`。
  String get remainingLabel => unlimited && !_judgeWindow
      ? '∞'
      : formatClock(_remaining);

  /// 最近一次「分享战绩」的结果，供 UI 弹完提示后 [clearShareRecordMessage]。
  String? get shareRecordMessage => _shareRecordMessage;
  bool get shareRecordOk => _shareRecordOk;

  void clearShareRecordMessage() {
    if (_shareRecordMessage == null) return;
    _shareRecordMessage = null;
    notifyListeners();
  }

  /// 举报结果（服务端异步回执），供 UI 弹完提示后清空。
  String? get reportResult => _reportResult;
  bool get reportOk => _reportOk;

  void clearReportResult() {
    if (_reportResult == null) return;
    _reportResult = null;
    notifyListeners();
  }

  /// 已被封禁：封禁后不允许再开局（与 Web 端一致）。
  bool get banned => _banned;
  String? get bannedMessage => _bannedMessage;

  /// 最近一条非封禁类错误，供 UI 弹提示后清空。
  String? get lastError => _lastError;

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  /// 输入框是否可用：对局中且聊天时间没到。
  ///
  /// 判定窗口**不**禁用输入 —— Web 端在对方已判定 / 聊天时间到时仍可继续发言，
  /// 只有聊天时间耗尽（`chat_expired` 或「聊天时间到」提示）才收口。
  /// 已提交判定后同理仍可发言（Web 端「只隐藏判定区，输入区保持可见」）。
  bool get inputEnabled =>
      (_phase == TuringPhase.chatting || _phase == TuringPhase.waitingOpponent) &&
      !_chatExpired;

  /// 判定按钮是否可用：开局满 10 秒 + 自己发过至少一条 + 还没判定。
  bool get canJudge =>
      _phase == TuringPhase.chatting &&
      _judgementAllowed &&
      _myMsgCount >= 1 &&
      _userGuess == null;

  /// 判定区提示文案。
  String get judgeHint {
    if (_phase == TuringPhase.waitingOpponent) return '已锁定，等待对方判定…';
    if (canJudge) return '可以锁定你的答案了';
    if (_phase != TuringPhase.chatting) return '';
    final List<String> reasons = <String>[];
    if (!_judgementAllowed) reasons.add('开局 10 秒后');
    if (_myMsgCount < 1) reasons.add('你发送一条消息');
    if (reasons.isEmpty) return '';
    return '${reasons.join(' / ')} 即可判定';
  }

  // ---- 对外动作 ----

  /// 开始匹配。必须登录（[playerToken] 非空），否则服务端无法归因战绩。
  void start({
    required String nickname,
    required String playerToken,
    required String fingerprint,
    required int durationSeconds,
  }) {
    if (_banned) return;
    _nickname = nickname;
    _playerToken = playerToken;
    _fingerprint = fingerprint;
    _duration = durationSeconds;

    _resetGameState();
    _phase = TuringPhase.matching;
    _remaining = durationSeconds;
    notifyListeners();

    _hub.join(<String, dynamic>{
      'nickname': nickname,
      'duration': durationSeconds,
      'fingerprint': fingerprint,
      if (playerToken.isNotEmpty) 'player_token': playerToken,
    });
  }

  /// 「再来一局」：清空对局状态后重新入队。
  void replay() {
    if (_nickname.isEmpty) return;
    start(
      nickname: _nickname,
      playerToken: _playerToken,
      fingerprint: _fingerprint,
      durationSeconds: _duration,
    );
  }

  /// 回到落地页并通知服务端清理对局。
  void reset() {
    _hub.leaveGame();
    _resetGameState();
    _phase = TuringPhase.landing;
    notifyListeners();
  }

  void sendMessage(String raw) {
    final String text = raw.trim();
    if (text.isEmpty || !inputEnabled) return;
    _append(TuringFeedItem.text(text: text, sender: _nickname, mine: true));
    _myMsgCount++;
    _hub.send(<String, dynamic>{'type': 'message', 'text': text});
    notifyListeners();
  }

  void sendSticker({required String id, required String name, String? url}) {
    if (!inputEnabled) return;
    _append(TuringFeedItem.sticker(
      id: id,
      name: name,
      url: url,
      sender: _nickname,
      mine: true,
    ));
    _myMsgCount++;
    _hub.send(<String, dynamic>{'type': 'sticker', 'id': id});
    notifyListeners();
  }

  /// 提交判定。提交后转 [TuringPhase.waitingOpponent]，最多再等 60 秒。
  void judge(String guess, {String tag = ''}) {
    if (!canJudge) return;
    _userGuess = guess;
    _judgeWindow = true;
    _phase = TuringPhase.waitingOpponent;

    // 剩余时间收敛到判定窗口（不超过当前剩余）；
    // 无限时长时 _remaining 是 0，要直接给满 60 秒，否则倒计时不动。
    _remaining = unlimited
        ? judgeWindowSeconds
        : (_remaining < judgeWindowSeconds ? _remaining : judgeWindowSeconds);
    _append(TuringFeedItem.system('你已锁定判断，等待对方判定中…'));
    _startTicker();

    _hub.send(<String, dynamic>{'type': 'judge', 'guess': guess, 'tag': tag});
    notifyListeners();
  }

  void report(String reason) {
    _hub.send(<String, dynamic>{'type': 'report', 'reason': reason});
  }

  void saveHistory() {
    if (_sessionId.isEmpty || _savingHistory) return;
    _savingHistory = true;
    _saveHistoryMessage = null;
    notifyListeners();
    _hub.send(<String, dynamic>{'type': 'save_history', 'session_id': _sessionId});
  }

  void leaveMessage(String text) {
    final String msg = text.trim();
    if (msg.isEmpty || _sendingLeaveMessage) return;
    _sendingLeaveMessage = true;
    _leaveMessageStatus = null;
    notifyListeners();
    _hub.send(<String, dynamic>{'type': 'leave_message', 'text': msg});
  }

  void shareRecord() {
    _hub.send(<String, dynamic>{'type': 'share_record'});
  }

  // ---- 内部 ----

  void _append(TuringFeedItem item) => _feed.add(item);

  void _resetGameState() {
    _ticker?.cancel();
    _ticker = null;
    _unlockTimer?.cancel();
    _unlockTimer = null;

    _feed.clear();
    _result = null;
    _opponentName = '';
    _sessionId = '';
    _userGuess = null;
    _opponentTruth = null;
    _judgementAllowed = false;
    _judgeWindow = false;
    _chatExpired = false;
    _startedAt = null;
    _myMsgCount = 0;
    _opponentMsgCount = 0;
    _savingHistory = false;
    _saveHistoryMessage = null;
    _saveHistoryOk = false;
    _savedHistoryId = null;
    _sendingLeaveMessage = false;
    _leaveMessageStatus = null;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) return;
      _remaining--;
      if (_remaining <= 0) {
        // 时间到只是 UI 层收口，权威结果由服务端 timeout 消息给出
        if (!_judgeWindow) _chatExpired = true;
      }
      notifyListeners();
    });
  }

  // ---- 服务端消息 ----

  void _onMessage(Map<String, dynamic> msg) {
    final String type = '${msg['type'] ?? ''}';
    switch (type) {
      case 'matched':
        _onMatched(msg);
      case 'message':
        _onOpponentMessage(msg);
      case 'system':
        _onSystem(msg);
      case 'judge_notify':
        _onJudgeNotify(msg);
      case 'judged':
        _onJudged(msg);
      case 'timeout':
        _onTimeout(msg);
      case 'sticker':
        _onOpponentSticker(msg);
      case 'save_history_status':
        _onSaveHistoryStatus(msg);
      case 'leave_message_status':
        _onLeaveMessageStatus(msg);
      case 'share_record_status':
        _onShareRecordStatus(msg);
      case 'report_result':
        _reportOk = msg['success'] == true;
        _reportResult = '${msg['message'] ?? (_reportOk ? '举报已提交' : '举报失败')}';
        notifyListeners();
      case 'error':
        _onError(msg);
      case 'banned':
        _onBanned('${msg['text'] ?? msg['message'] ?? ''}');
      default:
        break;
    }
  }

  /// 服务端错误。
  ///
  /// 封禁要单独处理（Web 端判断文案里是否含「封禁」，且排除「无需封禁」），
  /// 否则玩家会在被封后继续尝试开局、每次都被拒。
  void _onError(Map<String, dynamic> msg) {
    final String text = '${msg['message'] ?? msg['text'] ?? ''}';
    if (text.isEmpty) return;
    if (text.contains('封禁') && !text.contains('无需封禁')) {
      _onBanned(text);
      return;
    }
    _lastError = text;
    notifyListeners();
  }

  void _onBanned(String message) {
    _banned = true;
    _bannedMessage = message.isEmpty ? '你已被管理员封禁' : message;
    _ticker?.cancel();
    _ticker = null;
    _unlockTimer?.cancel();
    _unlockTimer = null;
    _hub.leaveGame();
    _resetGameState();
    _phase = TuringPhase.landing;
    notifyListeners();
  }

  void _onMatched(Map<String, dynamic> msg) {
    // 只认匹配中的那一次，避免后台重连触发的 matched 把玩家拽回对局
    if (_phase != TuringPhase.matching) return;

    _opponentName = '${msg['opponent_name'] ?? ''}';
    _sessionId = '${msg['session_id'] ?? ''}';
    _duration = (msg['duration'] as num?)?.toInt() ?? _duration;
    _remaining = _duration;
    _startedAt = DateTime.now();
    _phase = TuringPhase.chatting;

    _feed.clear();
    _feed.add(TuringFeedItem.system('双方需 60 秒内互发至少一条消息，否则判为平局不记战绩'));
    _judgementAllowed = false;
    _judgeWindow = false;
    _chatExpired = false;

    // 无限时长没有聊天倒计时（服务端也不下发「聊天时间到」），
    // 开 ticker 只会空转，这里就不开了；判定窗口由 judge() 再启动。
    if (_duration > 0) _startTicker();
    _unlockTimer?.cancel();
    _unlockTimer = Timer(judgeUnlockDelay, () {
      _judgementAllowed = true;
      notifyListeners();
    });

    notifyListeners();
  }

  void _onOpponentMessage(Map<String, dynamic> msg) {
    if (_phase != TuringPhase.chatting && _phase != TuringPhase.waitingOpponent) return;
    _append(TuringFeedItem.text(
      text: '${msg['text'] ?? ''}',
      sender: '${msg['sender'] ?? _opponentName}',
      mine: false,
    ));
    _opponentMsgCount++;
    notifyListeners();
  }

  void _onSystem(Map<String, dynamic> msg) {
    if (_phase == TuringPhase.landing || _phase == TuringPhase.finished) return;
    final String text = '${msg['text'] ?? ''}';
    if (text.isEmpty) return;
    _append(TuringFeedItem.system(text));

    // 聊天时间到 → 开 60 秒判定窗口
    if (text.contains('聊天时间到')) {
      _judgementAllowed = true;
      _judgeWindow = true;
      _chatExpired = true;
      _remaining = judgeWindowSeconds;
      _startTicker();
    }
    notifyListeners();
  }

  void _onJudgeNotify(Map<String, dynamic> msg) {
    // 已提交判定的人不看这条通知（避免等待倒计时和通知同时显示）
    if (_userGuess != null) return;
    if (_phase != TuringPhase.chatting) return;

    _append(TuringFeedItem.system(
      '⚠ ${msg['message'] ?? '对方已作出判定'}',
      emphasis: true,
    ));
    final int? secs = (msg['seconds_remaining'] as num?)?.toInt();
    if (secs != null && secs > 0) {
      _judgeWindow = true;
      _remaining = secs;
      _startTicker();
    }
    _judgementAllowed = true;
    notifyListeners();
  }

  void _onJudged(Map<String, dynamic> msg) {
    if (_opponentTruth != null) return;
    if (_phase == TuringPhase.landing || _phase == TuringPhase.finished) return;

    _opponentTruth = '${msg['truth'] ?? ''}';
    _sessionId = '${msg['session_id'] ?? _sessionId}';
    _finish(
      timeoutReason: null,
      opponentGuess: msg['opponent_guess'] as String?,
      opponentTag: '${msg['opponent_tag'] ?? ''}',
      opponentName: '${msg['opponent_name'] ?? _opponentName}',
    );
  }

  void _onTimeout(Map<String, dynamic> msg) {
    if (_phase == TuringPhase.landing || _phase == TuringPhase.finished) return;
    final String reason = '${msg['reason'] ?? ''}';

    // 聊天时间到：只收口输入，不是结果
    if (reason == 'chat_expired') {
      _chatExpired = true;
      _remaining = 0;
      _ticker?.cancel();
      _ticker = null;
      notifyListeners();
      return;
    }

    final String? truth = msg['opponent_truth'] as String?;
    if (truth != null && truth.isNotEmpty) _opponentTruth = truth;
    _sessionId = '${msg['session_id'] ?? _sessionId}';
    _finish(
      timeoutReason: _normalizeTimeoutReason(reason),
      opponentName: '${msg['opponent_name'] ?? _opponentName}',
    );
  }

  /// 把服务端的 `timeout.reason` 收敛成结果文案用的词表。
  ///
  /// Web 端在 `_onOpponentTimeout` 里做了同样的转换：
  /// 服务端发 `you_timeout` / `both_timeout`，而 `renderResult` 认的是
  /// `you` / `both`。不转换会掉进 default 分支，把平局显示成「猜错了」。
  static String _normalizeTimeoutReason(String serverReason) => switch (serverReason) {
        'you_timeout' => 'you',
        'both_timeout' => 'both',
        _ => serverReason,
      };

  void _onOpponentSticker(Map<String, dynamic> msg) {
    if (_phase != TuringPhase.chatting && _phase != TuringPhase.waitingOpponent) return;
    final String id = '${msg['id'] ?? ''}';
    if (id.isEmpty) return;
    _append(TuringFeedItem.sticker(
      id: id,
      name: '${msg['name'] ?? ''}',
      url: msg['url'] as String?,
      sender: '${msg['sender'] ?? _opponentName}',
      mine: false,
    ));
    _opponentMsgCount++;
    notifyListeners();
  }

  void _onSaveHistoryStatus(Map<String, dynamic> msg) {
    _savingHistory = false;
    _saveHistoryOk = msg['success'] == true || msg['ok'] == true;
    _saveHistoryMessage = '${msg['message'] ?? (_saveHistoryOk ? '聊天记录已保存' : '保存失败')}';
    final int? id = (msg['id'] as num?)?.toInt();
    if (id != null) _savedHistoryId = id;
    notifyListeners();
  }

  void _onLeaveMessageStatus(Map<String, dynamic> msg) {
    _sendingLeaveMessage = false;
    final bool ok = msg['success'] == true || msg['ok'] == true;
    _leaveMessageStatus = ok ? '留言已发送' : '${msg['message'] ?? '发送失败'}';
    notifyListeners();
  }

  void _onShareRecordStatus(Map<String, dynamic> msg) {
    final bool ok = msg['success'] == true || msg['ok'] == true;
    _shareRecordMessage = '${msg['message'] ?? (ok ? '战绩卡片已分享到聊天室' : '分享失败，请重试')}';
    _shareRecordOk = ok;
    notifyListeners();
  }

  // ---- 结果 ----

  void _finish({
    required String? timeoutReason,
    String? opponentGuess,
    String opponentTag = '',
    String opponentName = '',
  }) {
    _ticker?.cancel();
    _ticker = null;
    _unlockTimer?.cancel();
    _unlockTimer = null;

    if (opponentName.isNotEmpty) _opponentName = opponentName;
    // 对局结束：清掉重连 session，避免后台重连又跳回已结束的对局
    _hub.clearSession();

    final String? userGuess = _userGuess;
    final String? truth = _opponentTruth;

    final bool isTimeout = timeoutReason != null;
    final bool isWin = timeoutReason == 'opponent' ||
        timeoutReason == 'opponent_timeout' ||
        timeoutReason == 'opponent_disconnected' ||
        timeoutReason == 'opponent_left' ||
        (!isTimeout && userGuess != null && userGuess == truth);

    final String truthLabel = switch (truth) {
      'human' => '人类',
      'ai' => 'AI',
      _ => '未知',
    };

    final String verdict = switch (timeoutReason) {
      'opponent' || 'opponent_timeout' => '对方超时未判定，你赢了！',
      'opponent_disconnected' => '对方断开了连接，你赢了！',
      'opponent_left' => '对方主动退出，你赢了！',
      'you' => '你超时未判定，对方赢了...',
      'both' => '双方超时，平局',
      'no_mutual_chat' => '未互发消息，平局不记战绩',
      'opponent_banned' => '对方已被封禁，对局结束',
      _ => isWin ? '猜对啦！' : '猜错了...',
    };

    final String reveal = switch (timeoutReason) {
      'opponent' || 'opponent_timeout' => '对方未能在 60 秒内完成判定',
      'opponent_disconnected' => '对方断开了连接',
      'opponent_left' => '对方主动退出了对局',
      'you' => '你未能在 60 秒内完成判定',
      'both' => '双方均未在 60 秒内完成判定',
      'no_mutual_chat' => '双方未互发消息，不计入战绩',
      _ => '对方是：$truthLabel',
    };

    final DateTime? started = _startedAt;
    _result = TuringResult(
      isWin: isWin,
      verdict: verdict,
      reveal: reveal,
      totalMessages: _myMsgCount + _opponentMsgCount,
      elapsed: started == null ? Duration.zero : DateTime.now().difference(started),
      timeoutReason: timeoutReason,
      userGuess: userGuess,
      opponentTruth: truth,
      opponentGuess: opponentGuess,
      opponentTag: opponentTag,
      opponentName: _opponentName,
    );
    _phase = TuringPhase.finished;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _unlockTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

/// 秒数 → `MM:SS`（负数归零）。
String formatClock(int seconds) {
  final int s = seconds < 0 ? 0 : seconds;
  final String m = (s ~/ 60).toString().padLeft(2, '0');
  final String sec = (s % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}
