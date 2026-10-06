
/// OAuth 提供商（`/api/oauth/providers`，直接返回数组）。
class OAuthProvider {
  const OAuthProvider({required this.key, required this.name});

  final String key;
  final String name;

  factory OAuthProvider.fromJson(Map<String, dynamic> json) => OAuthProvider(
        key: '${json['key'] ?? ''}',
        name: '${json['name'] ?? ''}',
      );
}

/// OAuth 待建号信息（`/api/oauth/pending-info`）。
class OAuthPendingInfo {
  const OAuthPendingInfo({
    required this.provider,
    this.email,
    this.nickname,
  });

  final String provider;
  final String? email;
  final String? nickname;

  factory OAuthPendingInfo.fromJson(Map<String, dynamic> json) => OAuthPendingInfo(
        provider: '${json['provider'] ?? ''}',
        email: json['email'] as String?,
        nickname: json['nickname'] as String?,
      );
}

/// 邮箱验证码登录 / 注册结果（`/api/email/auth`）。
class EmailAuthResult {
  const EmailAuthResult({
    required this.token,
    required this.nickname,
    this.playerId,
    this.email,
    this.isNew = false,
  });

  final String token;
  final String nickname;
  final String? playerId;
  final String? email;
  final bool isNew;

  factory EmailAuthResult.fromJson(Map<String, dynamic> json) => EmailAuthResult(
        token: '${json['token'] ?? ''}',
        nickname: '${json['nickname'] ?? ''}',
        playerId: json['player_id'] as String?,
        email: json['email'] as String?,
        isNew: json['is_new'] == true,
      );
}
