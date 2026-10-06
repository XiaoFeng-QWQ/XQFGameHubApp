import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/env.dart';

/// 首页在线人数 / 全服公告。
///
/// 与 Web 端 `hub.js` 一致：连 `wss://game.xfcode.top/ws`，
/// 服务端在 onOpen 阶段单发一次 `online_count`；客户端每 25 秒发一次
/// `{"type":"ping"}`，60 秒未收到 `pong` 判定断线并 2 秒后重连。
class OnlineService extends ChangeNotifier {
  OnlineService();

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

  WebSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastPongAt;
  bool _manuallyClosed = false;
  bool _connecting = false;

  int? _onlineCount;

  /// 全服公告（最新的在最前，最多保留 3 条）。
  final List<String> _announcements = <String>[];

  int? get onlineCount => _onlineCount;
  List<String> get announcements => List<String>.unmodifiable(_announcements);
  bool get connected => _socket != null;

  /// 最近一次收到的公告（用于弹幕提示）。
  final StreamController<String> _broadcast = StreamController<String>.broadcast();
  Stream<String> get broadcasts => _broadcast.stream;

  void start() {
    if (OnlineService.disabled) return;
    _manuallyClosed = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_connecting) return;
    if (_socket != null) return;
    _connecting = true;
    try {
      final Uri uri = Uri.parse(
        XqfEnv.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://') + _wsPath,
      );
      final WebSocket socket = await WebSocket.connect(uri.toString())
          .timeout(const Duration(seconds: 12));
      _socket = socket;
      _lastPongAt = DateTime.now();
      _startHeartbeat();
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
    final String type = '${data['type'] ?? ''}';

    if (type == 'pong') {
      _lastPongAt = DateTime.now();
      return;
    }
    if (type == 'online_count') {
      final int count = (data['count'] as num?)?.toInt() ?? 0;
      if (_onlineCount != count) {
        _onlineCount = count;
        notifyListeners();
      }
      return;
    }
    if (type == 'broadcast') {
      final String text = '${data['text'] ?? ''}'.trim();
      if (text.isEmpty) return;
      _announcements.insert(0, text);
      if (_announcements.length > 3) _announcements.removeLast();
      if (!_broadcast.isClosed) _broadcast.add(text);
      notifyListeners();
    }
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
    _broadcast.close();
    super.dispose();
  }
}
