import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/env.dart';

/// 全局唯一的 `wss://…/ws` 连接。
///
/// ⚠️ **为什么必须只有一条**：服务端 `BaseGameHandler::onOpen` 做了 IP 去重
/// （`Server.DenyMultiConnection`，默认开），策略是 last-wins 且**跨入口共享**：
/// 同一 IP 再来一条连接，旧连接会被推送
/// `{"type":"system","text":"已有活跃连接，本页面连接已断开"}` 后关闭。
///
/// 所以在线人数、全服公告、图灵测试对局必须共用这一条连接 ——
/// 各自开一条会互相踢，表现为无限重连。
/// Web 端也是这个结构（一条连接同时跑 `hub.js` 的在线人数和 `script.js` 的对局）。
///
/// 与 Web 端 `WebSocketTransport` 行为对齐：
/// 25 秒发一次 `ping`，60 秒没收到 `pong` 判定断线并 2 秒后重连；
/// 重连时若仍在对局中，带上 `reconnect_session_id` 重放 `join` 恢复对局。
class HubSocket extends ChangeNotifier {
  HubSocket({String? url}) : _url = url ?? _defaultUrl();

  /// Widget 测试环境下置为 true，跳过真实 WebSocket 连接。
  ///
  /// 否则测试结束时仍会有未完成的连接与心跳定时器，
  /// 触发 `A Timer is still pending even after the widget tree was disposed`。
  @visibleForTesting
  static bool disabled = false;

  static const String _wsPath = '/ws';
  static const Duration _heartbeat = Duration(seconds: 25);
  static const Duration _pongTimeout = Duration(seconds: 60);
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const Duration _connectTimeout = Duration(seconds: 12);

  final String _url;

  WebSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastPongAt;
  bool _manuallyClosed = false;
  bool _connecting = false;

  int? _onlineCount;
  final List<String> _announcements = <String>[];

  /// 对局意图：非 null 表示「当前正在对局中」。
  /// 断线重连后用它重放 `join`，否则匹配会从头开始。
  Map<String, dynamic>? _joinIntent;
  String? _sessionId;

  final StreamController<Map<String, dynamic>> _messages =
      StreamController<Map<String, dynamic>>.broadcast();

  static String _defaultUrl() {
    final String base = XqfEnv.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base$_wsPath';
  }

  // ---- 对外只读状态 ----

  int? get onlineCount => _onlineCount;
  List<String> get announcements => List<String>.unmodifiable(_announcements);
  bool get connected => _socket != null;

  /// 最近一次收到的公告（用于弹幕提示）。
  final StreamController<String> _broadcast = StreamController<String>.broadcast();
  Stream<String> get broadcasts => _broadcast.stream;

  /// 全部已解码的服务端消息，供对局等消费者订阅。
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  String? get sessionId => _sessionId;
  bool get inGame => _joinIntent != null;

  // ---- 生命周期 ----

  void start() {
    if (HubSocket.disabled) return;
    _manuallyClosed = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_connecting || _socket != null) return;
    _connecting = true;
    try {
      final WebSocket socket =
          await WebSocket.connect(_url).timeout(_connectTimeout);
      _socket = socket;
      _lastPongAt = DateTime.now();
      _startHeartbeat();
      // 重连恢复：仍在对局中就重放 join（带旧 session）
      _sendJoin();
      socket.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object _) => _onClosed(),
        cancelOnError: true,
      );
    } catch (_) {
      _socket = null;
      _onlineCount = null;
      notifyListeners();
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    dynamic data;
    try {
      data = jsonDecode(raw);
    } catch (_) {
      return;
    }
    if (data is! Map) return;
    final Map<String, dynamic> msg =
        data.map((dynamic k, dynamic v) => MapEntry<String, dynamic>('$k', v));
    final String type = '${msg['type'] ?? ''}';

    if (type == 'pong') {
      _lastPongAt = DateTime.now();
      return;
    }

    // 服务端任何一条带 session_id 的消息都可用于重连恢复
    final dynamic sid = msg['session_id'];
    if (sid is String && sid.isNotEmpty) _sessionId = sid;

    if (type == 'online_count') {
      final int count = (msg['count'] as num?)?.toInt() ?? 0;
      if (_onlineCount != count) {
        _onlineCount = count;
        notifyListeners();
      }
    } else if (type == 'broadcast') {
      final String text = '${msg['text'] ?? ''}'.trim();
      if (text.isNotEmpty) {
        _announcements.insert(0, text);
        if (_announcements.length > 3) _announcements.removeLast();
        if (!_broadcast.isClosed) _broadcast.add(text);
        notifyListeners();
      }
    }

    // 转发给对局消费者（在线人数/公告也转发，消费者自行过滤）
    if (!_messages.isClosed) _messages.add(msg);
  }

  void _onClosed() {
    _socket = null;
    _stopHeartbeat();
    _onlineCount = null;
    notifyListeners();
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) {
      final WebSocket? socket = _socket;
      if (socket == null) return;
      try {
        socket.add(jsonEncode(<String, dynamic>{'type': 'ping'}));
      } catch (_) {
        _onClosed();
        return;
      }
      final DateTime? last = _lastPongAt;
      if (last != null && DateTime.now().difference(last) > _pongTimeout) {
        try {
          socket.close();
        } catch (_) {}
        _onClosed();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_manuallyClosed || _reconnectTimer != null) return;
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectTimer = null;
      _connect();
    });
  }

  // ---- 发送 ----

  /// 发送一条消息；未连接时返回 false（不抛异常，调用方自行提示）。
  bool send(Map<String, dynamic> payload) {
    final WebSocket? socket = _socket;
    if (socket == null) return false;
    try {
      socket.add(jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- 对局意图 ----

  /// 记录对局意图并立即发送 `join`。
  void join(Map<String, dynamic> intent) {
    _joinIntent = Map<String, dynamic>.of(intent);
    _sendJoin();
  }

  void _sendJoin() {
    final Map<String, dynamic>? intent = _joinIntent;
    if (intent == null) return;
    final Map<String, dynamic> payload = <String, dynamic>{
      'type': 'join',
      ...intent,
    };
    final String? sid = _sessionId;
    if (sid != null && sid.isNotEmpty) payload['reconnect_session_id'] = sid;
    send(payload);
  }

  /// 清掉重连用的 session，但保留对局意图。
  ///
  /// 对局结束时调用：避免后台重连又把玩家拉回已结束的对局。
  void clearSession() => _sessionId = null;

  /// 测试专用：把一条服务端消息喂进解析链路，等价于真的收到一帧。
  @visibleForTesting
  void debugEmit(Map<String, dynamic> message) => _onMessage(jsonEncode(message));

  /// 彻底结束对局：清掉意图并通知服务端清理房间状态。
  void leaveGame() {
    _joinIntent = null;
    _sessionId = null;
    send(<String, dynamic>{'type': 'leave'});
  }

  @override
  void dispose() {
    _manuallyClosed = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    if (!_broadcast.isClosed) _broadcast.close();
    if (!_messages.isClosed) _messages.close();
    super.dispose();
  }
}
