import 'package:flutter/material.dart';

import '../core/net/api_client.dart';
import '../core/storage/app_prefs.dart';
import '../data/api/account_api.dart';
import '../data/api/auth_api.dart';

/// 全局服务容器（HTTP 客户端与各领域 API）。
class AppServices {
  AppServices(this.prefs)
      : client = ApiClient(tokenProvider: () => prefs.token) {
    auth = AuthApi(client);
    account = AccountApi(client);
  }

  final AppPrefs prefs;
  final ApiClient client;
  late final AuthApi auth;
  late final AccountApi account;
}

/// 认证状态。
class AuthController extends ChangeNotifier {
  AuthController(this._prefs);

  final AppPrefs _prefs;

  String? _token;
  String? _nickname;
  String? _playerId;
  String? _email;

  String? get token => _token;
  String? get nickname => _nickname;
  String? get playerId => _playerId;
  String? get email => _email;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 设备指纹（用于注册限制 / 战绩恢复）。
  String get fingerprint => _prefs.fingerprint;

  void restore() {
    _token = _prefs.token;
    _nickname = _prefs.nickname;
    _playerId = _prefs.playerId;
    _email = _prefs.email;
    notifyListeners();
  }

  Future<void> signIn({
    required String token,
    String? nickname,
    String? playerId,
    String? email,
  }) async {
    await _prefs.saveSession(
      token: token,
      nickname: nickname,
      playerId: playerId,
      email: email,
    );
    _token = token;
    _nickname = nickname ?? _nickname;
    _playerId = playerId ?? _playerId;
    _email = email ?? _email;
    notifyListeners();
  }

  /// 修改密码后旧 token 失效，用新 token 覆盖会话。
  Future<void> replaceToken(String token) async {
    if (token.isEmpty) return;
    await _prefs.saveSession(token: token, nickname: _nickname, playerId: _playerId);
    _token = token;
    notifyListeners();
  }

  Future<void> updateProfile({String? nickname, String? playerId, String? email}) async {
    await _prefs.updateProfile(nickname: nickname, playerId: playerId, email: email);
    if (nickname != null) _nickname = nickname;
    if (playerId != null) _playerId = playerId;
    if (email != null) _email = email;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _prefs.clearSession();
    _token = null;
    _nickname = null;
    _playerId = null;
    _email = null;
    notifyListeners();
  }
}

/// 主题模式（跟随系统 / 亮色 / 暗色），持久化到本地。
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) : _mode = _parse(_prefs.themeMode);

  final AppPrefs _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  static ThemeMode _parse(String raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _raw(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setThemeMode(_raw(mode));
  }
}

/// 把服务与控制器注入 widget 树。
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required this.auth,
    required this.theme,
    required super.child,
  });

  final AppServices services;
  final AuthController auth;
  final ThemeController theme;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 未挂载');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services || auth != oldWidget.auth || theme != oldWidget.theme;
}
