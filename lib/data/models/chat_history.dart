import '../../core/net/api_client.dart';
import '../../core/utils/url.dart';

/// 聊天记录列表项。
///
/// 字段以线上实现为准（`Public/account/account.js` 的实际消费）：
/// `id` / `title` / `player_name` / `opponent_name` / `player_guess` /
/// `opponent_truth` / `message_count` / `result` / `is_public` / `likes` /
/// `created_at`。文档里更精简的写法同样兼容。
class ChatHistoryItem {
  const ChatHistoryItem({
    required this.id,
    this.title,
    this.playerName = '',
    this.opponentName = '',
    this.playerGuess = '',
    this.opponentTruth = '',
    this.messageCount = 0,
    this.result = '',
    this.isPublic = false,
    this.likes = 0,
    this.duration,
    this.createdAt,
  });

  final int id;
  final String? title;
  final String playerName;
  final String opponentName;

  /// 'human' | 'ai'
  final String playerGuess;

  /// 'human' | 'ai'
  final String opponentTruth;
  final int messageCount;

  /// 'win' | 'lose' | 'draw'
  final String result;
  final bool isPublic;
  final int likes;
  final int? duration;
  final int? createdAt;

  bool get hasTitle => title != null && title!.trim().isNotEmpty;

  String get displayTitle =>
      hasTitle ? title!.trim() : '$playerName vs $opponentName';

  String get resultLabel => switch (result) {
        'win' => '胜',
        'lose' => '负',
        'draw' => '平',
        _ => '',
      };

  String get guessLabel => switch (playerGuess) {
        'human' => '猜人类',
        'ai' => '猜AI',
        _ => '未判定',
      };

  String get truthLabel => switch (opponentTruth) {
        'human' => '对方是人类',
        'ai' => '对方是AI',
        _ => '',
      };

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) => ChatHistoryItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        playerName: '${json['player_name'] ?? ''}',
        opponentName: '${json['opponent_name'] ?? ''}',
        playerGuess: '${json['player_guess'] ?? json['guess'] ?? ''}',
        opponentTruth: '${json['opponent_truth'] ?? json['truth'] ?? ''}',
        messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
        result: '${json['result'] ?? ''}',
        isPublic: json['is_public'] == true,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as num?)?.toInt(),
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}

/// 分页结果。
class PagedChatHistory {
  const PagedChatHistory({
    this.list = const <ChatHistoryItem>[],
    this.total = 0,
    this.page = 1,
    this.pageSize = 10,
  });

  final List<ChatHistoryItem> list;
  final int total;
  final int page;
  final int pageSize;

  int get totalPages => pageSize <= 0 ? 1 : ((total + pageSize - 1) ~/ pageSize).clamp(1, 999);

  factory PagedChatHistory.fromJson(Map<String, dynamic> json) => PagedChatHistory(
        list: asList(json['list'])
            .map((dynamic e) => ChatHistoryItem.fromJson(asMap(e)))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        pageSize: ((json['page_size'] ?? json['per_page']) as num?)?.toInt() ?? 10,
      );
}

/// 对局中的一条消息。
class ChatMessage {
  const ChatMessage({
    required this.side,
    this.text = '',
    this.sender = '',
    this.time,
    this.stickerId,
    this.stickerName,
    this.stickerUrl,
  });

  /// 'right'（自己）/ 'left'（对手）
  final String side;
  final String text;
  final String sender;
  final dynamic time;
  final String? stickerId;
  final String? stickerName;
  final String? stickerUrl;

  bool get isRight => side == 'right';
  bool get hasSticker => stickerId != null && stickerId!.isNotEmpty;

  /// 表情地址：优先用消息内自带的 url，否则交由调用方用表情表补齐。
  String? get resolvedStickerUrl => absoluteUrl(stickerUrl);

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        side: '${json['side'] ?? 'left'}',
        text: '${json['text'] ?? ''}',
        sender: '${json['sender'] ?? ''}',
        time: json['time'] ?? json['created_at'],
        stickerId: json['sticker_id'] as String?,
        stickerName: json['sticker_name'] as String?,
        stickerUrl: json['sticker_url'] as String?,
      );
}

/// `/api/chat-history/detail` 响应。
class ChatHistoryDetail {
  const ChatHistoryDetail({
    required this.id,
    this.title,
    this.playerName = '',
    this.opponentName = '',
    this.playerGuess = '',
    this.opponentTruth = '',
    this.result = '',
    this.messages = const <ChatMessage>[],
    this.createdAt,
  });

  final int id;
  final String? title;
  final String playerName;
  final String opponentName;
  final String playerGuess;
  final String opponentTruth;
  final String result;
  final List<ChatMessage> messages;
  final int? createdAt;

  factory ChatHistoryDetail.fromJson(Map<String, dynamic> json) => ChatHistoryDetail(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        playerName: '${json['player_name'] ?? ''}',
        opponentName: '${json['opponent_name'] ?? ''}',
        playerGuess: '${json['player_guess'] ?? json['guess'] ?? ''}',
        opponentTruth: '${json['opponent_truth'] ?? json['truth'] ?? ''}',
        result: '${json['result'] ?? ''}',
        messages: asList(json['messages'])
            .map((dynamic e) => ChatMessage.fromJson(asMap(e)))
            .toList(),
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}
