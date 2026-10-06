import '../../core/net/api_client.dart';

/// 对手留言（`/api/player-messages` 的 `messages[]`）。
class PlayerMessage {
  const PlayerMessage({
    required this.id,
    this.from = '',
    this.text = '',
    this.hidden = false,
    this.createdAt,
  });

  final String id;
  final String from;
  final String text;
  final bool hidden;
  final int? createdAt;

  factory PlayerMessage.fromJson(Map<String, dynamic> json) => PlayerMessage(
        id: '${json['id'] ?? ''}',
        from: '${json['from'] ?? ''}',
        text: '${json['text'] ?? ''}',
        hidden: json['hidden'] == true,
        createdAt: (json['created_at'] as num?)?.toInt(),
      );

  PlayerMessage copyWith({bool? hidden}) => PlayerMessage(
        id: id,
        from: from,
        text: text,
        hidden: hidden ?? this.hidden,
        createdAt: createdAt,
      );
}

/// `/api/player-messages` 响应。
class PlayerMessageBox {
  const PlayerMessageBox({
    this.messages = const <PlayerMessage>[],
    this.allowMessages = true,
  });

  final List<PlayerMessage> messages;
  final bool allowMessages;

  factory PlayerMessageBox.fromJson(Map<String, dynamic> json) => PlayerMessageBox(
        messages: asList(json['messages'])
            .map((dynamic e) => PlayerMessage.fromJson(asMap(e)))
            .toList(),
        allowMessages: json['allow_messages'] != false,
      );
}
