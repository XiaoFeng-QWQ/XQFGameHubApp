import '../../core/net/api_client.dart';
import '../models/account.dart';
import '../models/chat_history.dart';
import '../models/oauth.dart';
import '../models/player_message.dart';
import '../models/sticker.dart';
import '../models/tags.dart';

/// 账号中心相关接口（HTTP 文档 §2、§4、§5、§7、§12、§17）。
class AccountApi {
  AccountApi(this._client);

  final ApiClient _client;

  // ---------------------------------------------------------------- 账号总览

  /// `GET /api/account/overview`
  Future<AccountOverview> overview() async {
    final dynamic res = await _client.get('/api/account/overview', auth: true);
    return AccountOverview.fromJson(asMap(res));
  }

  /// `POST /api/account/nickname` → 返回新昵称。
  Future<String> rename(String nickname, {String? fp}) async {
    final dynamic res = await _client.postJson('/api/account/nickname', <String, dynamic>{
      'nickname': nickname,
      if (fp != null && fp.isNotEmpty) 'fp': fp,
    });
    final Map<String, dynamic> map = asMap(res);
    return '${map['nickname'] ?? nickname}';
  }

  /// `POST /api/account/avatar`（multipart，字段名 `file`，≤ 2MB）。
  Future<String?> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final dynamic res = await _client.postFile(
      '/api/account/avatar',
      bytes: bytes,
      filename: filename,
    );
    return asMap(res)['avatar'] as String?;
  }

  /// `POST /api/account/password` → 返回新 token（旧 token 立即失效）。
  Future<String> changePassword({
    required String newPassword,
    String? oldPassword,
  }) async {
    final dynamic res = await _client.postJson('/api/account/password', <String, dynamic>{
      'new_password': newPassword,
      if (oldPassword != null && oldPassword.isNotEmpty) 'old_password': oldPassword,
    });
    final Map<String, dynamic> map = asMap(res);
    return '${map['token'] ?? ''}';
  }

  /// `POST /api/account/email` → 返回绑定后的邮箱。
  Future<String> bindEmail({required String email, required String code}) async {
    final dynamic res = await _client.postJson('/api/account/email', <String, dynamic>{
      'email': email,
      'code': code,
    });
    return '${asMap(res)['email'] ?? email}';
  }

  /// `GET /api/account/bot-access`
  Future<BotAccess> botAccess() async {
    final dynamic res = await _client.get('/api/account/bot-access', auth: true);
    return BotAccess.fromJson(asMap(res));
  }

  // -------------------------------------------------------------------- 标签

  /// `GET /api/player/tags`
  Future<MyTags> myTags() async {
    final dynamic res = await _client.get('/api/player/tags', auth: true);
    return MyTags.fromJson(asMap(res));
  }

  /// `POST /api/player/worn-tags`
  ///
  /// 线上用 `{"success": bool, "message": "..."}` 表达成败（不是 `ok` / `error`），
  /// `success=false` 已由 [ApiClient] 统一转成 `ApiException`，
  /// 这里只负责解析清洗后的最终佩戴结果。
  Future<WornTagsResult> setWornTags({
    required List<String> tags,
    List<String> specialTags = const <String>[],
  }) async {
    final dynamic res = await _client.postJson('/api/player/worn-tags', <String, dynamic>{
      'tags': tags,
      'special_tags': specialTags,
    });
    return WornTagsResult.fromJson(asMap(res));
  }

  // ---------------------------------------------------------------- 聊天记录

  /// `GET /api/chat-history?page=N`
  Future<PagedChatHistory> chatHistory({int page = 1}) async {
    final dynamic res = await _client.get(
      '/api/chat-history',
      query: <String, dynamic>{'page': page},
      auth: true,
    );
    return PagedChatHistory.fromJson(asMap(res));
  }

  /// `GET /api/chat-history/detail?id=N`
  Future<ChatHistoryDetail> chatHistoryDetail(int id) async {
    final dynamic res = await _client.get(
      '/api/chat-history/detail',
      query: <String, dynamic>{'id': id},
      auth: true,
    );
    return ChatHistoryDetail.fromJson(asMap(res));
  }

  /// `POST /api/chat-history/collect`（设置标题 / 公开状态）。
  Future<String?> collectChatHistory({
    required int id,
    String? title,
    bool? isPublic,
  }) async {
    final dynamic res = await _client.postJson('/api/chat-history/collect', <String, dynamic>{
      'id': id,
      'title': ?title,
      'is_public': ?isPublic,
    });
    return asMap(res)['token'] as String?;
  }

  // -------------------------------------------------------------------- 表情

  /// `GET /api/sticker/list`
  Future<StickerSet> stickers() async {
    final dynamic res = await _client.get('/api/sticker/list', auth: true);
    return StickerSet.fromJson(asMap(res));
  }

  /// `POST /api/sticker/upload`（JSON + Base64，解码后 ≤ 2MB）。
  Future<Sticker?> uploadSticker({
    required String base64Data,
    String fileExt = 'png',
  }) async {
    final dynamic res = await _client.postJson('/api/sticker/upload', <String, dynamic>{
      'image_data': base64Data,
      'file_ext': fileExt,
    });
    final dynamic sticker = asMap(res)['sticker'];
    if (sticker is Map) return Sticker.fromJson(asMap(sticker));
    return null;
  }

  /// `POST /api/sticker/delete`
  Future<void> deleteSticker(String stickerId) async {
    await _client.postJson('/api/sticker/delete', <String, dynamic>{'sticker_id': stickerId});
  }

  /// `POST /api/sticker/add-to-mine`
  Future<void> addStickerToMine(String stickerId) async {
    await _client.postJson('/api/sticker/add-to-mine', <String, dynamic>{'sticker_id': stickerId});
  }

  // -------------------------------------------------------------------- 留言

  /// `GET /api/player-messages`
  Future<PlayerMessageBox> messages() async {
    final dynamic res = await _client.get('/api/player-messages', auth: true);
    return PlayerMessageBox.fromJson(asMap(res));
  }

  /// `POST /api/player-message/hide`
  Future<void> hideMessage({required String messageId, required bool hidden}) async {
    await _client.postJson('/api/player-message/hide', <String, dynamic>{
      'message_id': messageId,
      'hidden': hidden,
    });
  }

  /// `POST /api/player-message/settings`
  Future<String> setMessageSettings({required bool allowMessages}) async {
    final dynamic res = await _client.postJson(
      '/api/player-message/settings',
      <String, dynamic>{'allow_messages': allowMessages},
    );
    return '${asMap(res)['message'] ?? '设置已更新'}';
  }

  // ------------------------------------------------------------------- OAuth

  /// `GET /api/oauth/providers`（公开，直接返回数组）。
  Future<List<OAuthProvider>> oauthProviders() async {
    final dynamic res = await _client.get('/api/oauth/providers');
    if (res is List) {
      return res.map((dynamic e) => OAuthProvider.fromJson(asMap(e))).toList();
    }
    return const <OAuthProvider>[];
  }

  /// `GET /api/oauth/bindings`
  Future<List<OAuthBinding>> oauthBindings() async {
    final dynamic res = await _client.get('/api/oauth/bindings', auth: true);
    return asList(asMap(res)['bindings'])
        .map((dynamic e) => OAuthBinding.fromJson(asMap(e)))
        .toList();
  }

  /// `POST /api/oauth/unbind`（form body）
  Future<void> unbindOAuth(String provider) async {
    await _client.postForm('/api/oauth/unbind', <String, String>{'provider': provider});
  }

  /// `POST /api/oauth/sync-avatar`（form body）
  Future<void> syncOAuthAvatar(String provider) async {
    await _client.postForm('/api/oauth/sync-avatar', <String, String>{'provider': provider});
  }

  /// OAuth 授权页地址（在外部浏览器打开，`bind=1` 为绑定模式）。
  String oauthLoginUrl(String provider, {bool bind = false, String? token}) {
    final StringBuffer sb = StringBuffer('/oauth/login/$provider');
    final List<String> params = <String>[];
    if (bind) {
      params.add('bind=1');
      if (token != null && token.isNotEmpty) {
        params.add('token=${Uri.encodeQueryComponent(token)}');
      }
    }
    return params.isEmpty ? sb.toString() : '$sb?${params.join('&')}';
  }
}
