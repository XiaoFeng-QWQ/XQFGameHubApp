import '../../core/net/api_client.dart';
import '../../core/utils/url.dart';

/// 第三方登录绑定（`/api/account/overview` 的 `bindings`）。
class OAuthBinding {
  const OAuthBinding({
    required this.provider,
    required this.providerId,
    this.email,
    this.createdAt,
  });

  final String provider;
  final String providerId;
  final String? email;
  final int? createdAt;

  factory OAuthBinding.fromJson(Map<String, dynamic> json) => OAuthBinding(
        provider: '${json['provider'] ?? ''}',
        providerId: '${json['provider_id'] ?? ''}',
        email: json['email'] as String?,
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}

/// 战绩摘要。
class AccountStats {
  const AccountStats({
    this.totalGames = 0,
    this.winRate = 0,
    this.avgMsgs = 0,
    this.wins,
    this.losses,
    this.draws,
  });

  final int totalGames;
  final int winRate;
  final num avgMsgs;
  final int? wins;
  final int? losses;
  final int? draws;

  factory AccountStats.fromJson(Map<String, dynamic> json) => AccountStats(
        totalGames: (json['total_games'] as num?)?.toInt() ?? 0,
        winRate: (json['win_rate'] as num?)?.toInt() ?? 0,
        avgMsgs: (json['avg_msgs'] as num?) ?? 0,
        wins: (json['wins'] as num?)?.toInt(),
        losses: (json['losses'] as num?)?.toInt(),
        draws: (json['draws'] as num?)?.toInt(),
      );

  static const AccountStats empty = AccountStats();
}

/// `/api/account/overview` 响应。
class AccountOverview {
  const AccountOverview({
    required this.playerId,
    required this.nickname,
    this.email,
    this.discriminator,
    this.createdAt,
    this.lastPlayedAt,
    this.avatar,
    this.wornTags = const <String>[],
    this.wornSpecialTags = const <String>[],
    this.canRename = true,
    this.renameHint = '',
    this.passwordSet = false,
    this.bindings = const <OAuthBinding>[],
    this.stats = AccountStats.empty,
  });

  final String playerId;
  final String nickname;
  final String? email;
  final int? discriminator;
  final int? createdAt;
  final int? lastPlayedAt;
  final String? avatar;
  final List<String> wornTags;
  final List<String> wornSpecialTags;
  final bool canRename;
  final String renameHint;
  final bool passwordSet;
  final List<OAuthBinding> bindings;
  final AccountStats stats;

  String? get avatarUrl => absoluteUrl(avatar);

  factory AccountOverview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> stats = asMap(json['stats']);
    return AccountOverview(
      playerId: '${json['player_id'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      email: json['email'] as String?,
      discriminator: (json['discriminator'] as num?)?.toInt(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      lastPlayedAt: (json['last_played_at'] as num?)?.toInt(),
      avatar: json['avatar'] as String?,
      wornTags: asList(json['worn_tags']).map((dynamic e) => '$e').toList(),
      wornSpecialTags: asList(json['worn_special_tags'])
          .map((dynamic e) => e is Map ? '${e['name'] ?? ''}' : '$e')
          .where((String e) => e.isNotEmpty)
          .toList(),
      canRename: json['can_rename'] as bool? ?? true,
      renameHint: '${json['rename_hint'] ?? ''}',
      passwordSet: json['password_set'] as bool? ?? false,
      bindings: asList(json['bindings'])
          .map((dynamic e) => OAuthBinding.fromJson(asMap(e)))
          .toList(),
      stats: AccountStats.fromJson(stats),
    );
  }
}

/// `/api/account/bot-access` 响应。
class BotAccess {
  const BotAccess({
    required this.state,
    this.nickname,
    this.botKey,
    this.accountId,
    this.statusText,
    this.message,
    this.createdAt,
  });

  /// approved / applied / disabled / none
  final String state;
  final String? nickname;
  final String? botKey;
  final String? accountId;
  final String? statusText;
  final String? message;
  final int? createdAt;

  bool get approved => state == 'approved';
  bool get hasBot => state != 'none';

  factory BotAccess.fromJson(Map<String, dynamic> json) => BotAccess(
        state: '${json['state'] ?? 'none'}',
        nickname: json['nickname'] as String?,
        botKey: json['bot_key'] as String?,
        accountId: json['account_id'] as String?,
        statusText: json['status_text'] as String?,
        message: json['message'] as String?,
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}
