import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// 本地持久化。
///
/// 对应 Web 端 localStorage 里的 `player_token` / 昵称等键；
/// 另外保存主题偏好与设备指纹。
class AppPrefs {
  AppPrefs._(this._prefs);

  static const String _kToken = 'player_token';
  static const String _kNickname = 'player_nickname';
  static const String _kPlayerId = 'player_id';
  static const String _kTheme = 'theme_mode';
  static const String _kFingerprint = 'device_fp';
  static const String _kEmail = 'player_email';

  final SharedPreferences _prefs;

  static AppPrefs? _instance;

  static AppPrefs get instance {
    final AppPrefs? i = _instance;
    if (i == null) {
      throw StateError('AppPrefs 尚未初始化，请先 await AppPrefs.init()');
    }
    return i;
  }

  static Future<AppPrefs> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppPrefs appPrefs = AppPrefs._(prefs);
    _instance = appPrefs;
    appPrefs._ensureFingerprint();
    return appPrefs;
  }

  // ---- 认证 ----

  String? get token {
    final String? t = _prefs.getString(_kToken);
    return (t == null || t.isEmpty) ? null : t;
  }

  bool get isLoggedIn => token != null;

  String? get nickname => _prefs.getString(_kNickname);
  String? get playerId => _prefs.getString(_kPlayerId);
  String? get email => _prefs.getString(_kEmail);

  Future<void> saveSession({
    required String token,
    String? nickname,
    String? playerId,
    String? email,
  }) async {
    await _prefs.setString(_kToken, token);
    if (nickname != null) await _prefs.setString(_kNickname, nickname);
    if (playerId != null) await _prefs.setString(_kPlayerId, playerId);
    if (email != null) await _prefs.setString(_kEmail, email);
  }

  Future<void> updateProfile({String? nickname, String? playerId, String? email}) async {
    if (nickname != null) await _prefs.setString(_kNickname, nickname);
    if (playerId != null) await _prefs.setString(_kPlayerId, playerId);
    if (email != null) await _prefs.setString(_kEmail, email);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kNickname);
    await _prefs.remove(_kPlayerId);
    await _prefs.remove(_kEmail);
  }

  // ---- 主题 ----

  /// 'system' | 'light' | 'dark'
  String get themeMode => _prefs.getString(_kTheme) ?? 'system';

  Future<void> setThemeMode(String mode) => _prefs.setString(_kTheme, mode);

  // ---- 设备指纹 ----

  String get fingerprint => _prefs.getString(_kFingerprint) ?? '';

  void _ensureFingerprint() {
    if (fingerprint.isNotEmpty) return;
    const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final Random rnd = Random.secure();
    final String id = List<String>.generate(
      32,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
    _prefs.setString(_kFingerprint, 'app-$id');
  }
}
