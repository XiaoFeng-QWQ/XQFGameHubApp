import '../../core/net/api_client.dart';
import '../models/account.dart';
import '../models/oauth.dart';

/// 身份与登录相关接口（HTTP 文档 §1、§8）。
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// 通过 Token 查询战绩（`GET /api/generate-player-id`）。
  Future<AccountStats> statsByToken() async {
    final dynamic res = await _client.get('/api/generate-player-id', auth: true);
    return AccountStats.fromJson(asMap(asMap(res)['stats']));
  }

  /// 「代号 + 密码」找回旧账号（`GET /api/generate-player-id?action=recover`）。
  Future<EmailAuthResult> recover({
    required String nickname,
    required String password,
  }) async {
    final dynamic res = await _client.get('/api/generate-player-id', query: <String, dynamic>{
      'action': 'recover',
      'nickname': nickname,
      'password': password,
    });
    final Map<String, dynamic> map = asMap(res);
    return EmailAuthResult(
      token: '${map['token'] ?? ''}',
      nickname: '${map['nickname'] ?? nickname}',
      playerId: map['player_id'] as String?,
    );
  }

  /// 通过昵称 + 密码查询战绩（`GET /api/player-stats`，不依赖 Token）。
  Future<AccountStats> statsByPassword({
    required String nickname,
    required String password,
  }) async {
    final dynamic res = await _client.get('/api/player-stats', query: <String, dynamic>{
      'nickname': nickname,
      'password': password,
    });
    return AccountStats.fromJson(asMap(asMap(res)['stats']));
  }

  /// 发送邮箱验证码（`POST /api/email/send-code`）。
  ///
  /// [scene]：`auth`（登录/注册，无需登录）或 `bind_email`（需登录）。
  /// 返回冷却秒数（默认 60）。
  Future<int> sendEmailCode(String email, {String scene = 'auth'}) async {
    final dynamic res = await _client.postJson(
      '/api/email/send-code',
      <String, dynamic>{'email': email, 'scene': scene},
      auth: scene == 'bind_email',
    );
    return (asMap(res)['cooldown'] as num?)?.toInt() ?? 60;
  }

  /// 邮箱验证码登录 / 注册（`POST /api/email/auth`）。
  Future<EmailAuthResult> emailAuth({
    required String email,
    required String code,
    String? fp,
  }) async {
    final dynamic res = await _client.postJson(
      '/api/email/auth',
      <String, dynamic>{
        'email': email,
        'code': code,
        if (fp != null && fp.isNotEmpty) 'fp': fp,
      },
      auth: false,
    );
    return EmailAuthResult.fromJson(asMap(res));
  }

  /// 修改密码（`GET /api/generate-player-id?action=change_password`）。
  ///
  /// 返回新的 token（旧 token 因签名密钥变化而失效）。
  Future<String> changePasswordLegacy({
    required String oldPassword,
    required String newPassword,
  }) async {
    final dynamic res = await _client.get('/api/generate-player-id', query: <String, dynamic>{
      'action': 'change_password',
      'old_password': oldPassword,
      'new_password': newPassword,
    }, auth: true);
    return '${asMap(res)['token'] ?? ''}';
  }
}
