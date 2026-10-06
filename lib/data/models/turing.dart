import 'package:flutter/foundation.dart';

/// 图灵测试对局的阶段。
///
/// 与 Web 端的 5 个 `<section>` 一一对应（landing / matching / chat / result）。
enum TuringPhase {
  /// 落地页：选时长、点「开始匹配」
  landing,

  /// 已发出 join，等待 `matched`
  matching,

  /// 对局中：聊天 + 可判定
  chatting,

  /// 已提交判定，等对方（60 秒倒计时）
  waitingOpponent,

  /// 结果页
  finished,
}

/// 聊天流里的一条内容。
enum TuringFeedKind { text, sticker, system }

@immutable
class TuringFeedItem {
  const TuringFeedItem({
    required this.kind,
    required this.at,
    this.text = '',
    this.sender = '',
    this.mine = false,
    this.stickerId,
    this.stickerName,
    this.stickerUrl,
    this.emphasis = false,
  });

  /// 普通聊天消息。
  factory TuringFeedItem.text({
    required String text,
    required String sender,
    required bool mine,
    DateTime? at,
  }) =>
      TuringFeedItem(
        kind: TuringFeedKind.text,
        text: text,
        sender: sender,
        mine: mine,
        at: at ?? DateTime.now(),
      );

  /// 系统提示（居中斜体）。
  ///
  /// [emphasis] 用于判定通知这类需要醒目的提示。
  factory TuringFeedItem.system(String text, {bool emphasis = false, DateTime? at}) =>
      TuringFeedItem(
        kind: TuringFeedKind.system,
        text: text,
        emphasis: emphasis,
        at: at ?? DateTime.now(),
      );

  factory TuringFeedItem.sticker({
    required String id,
    required String name,
    String? url,
    required String sender,
    required bool mine,
    DateTime? at,
  }) =>
      TuringFeedItem(
        kind: TuringFeedKind.sticker,
        stickerId: id,
        stickerName: name,
        stickerUrl: url,
        sender: sender,
        mine: mine,
        at: at ?? DateTime.now(),
      );

  final TuringFeedKind kind;
  final DateTime at;
  final String text;
  final String sender;
  final bool mine;
  final String? stickerId;
  final String? stickerName;
  final String? stickerUrl;

  /// 系统消息中的强提示（判定通知等）。
  final bool emphasis;
}

/// 一局结束后的结果。
///
/// 文案与判定规则逐条对齐 Web 端 `renderResult()`。
@immutable
class TuringResult {
  const TuringResult({
    required this.isWin,
    required this.verdict,
    required this.reveal,
    required this.totalMessages,
    required this.elapsed,
    this.timeoutReason,
    this.userGuess,
    this.opponentTruth,
    this.opponentGuess,
    this.opponentTag = '',
    this.opponentName = '',
  });

  /// 是否算赢。
  final bool isWin;

  /// 主结论（「猜对啦！」/「对方超时未判定，你赢了！」…）。
  final String verdict;

  /// 副结论（「对方是：AI」/「双方未互发消息，不计入战绩」…）。
  final String reveal;

  final int totalMessages;
  final Duration elapsed;

  /// 非 null 表示不是正常判定结束，取值对应服务端 `timeout.reason`。
  final String? timeoutReason;

  /// `human` / `ai` / null。
  final String? userGuess;
  final String? opponentTruth;
  final String? opponentGuess;

  final String opponentTag;
  final String opponentName;

  bool get isTimeout => timeoutReason != null;

  /// 「你的判断」显示文案。
  String get userGuessLabel => switch (userGuess) {
        'human' => '它是人类',
        'ai' => '它是 AI',
        _ => '未判定',
      };

  /// 「对方身份」显示文案。
  String get opponentTruthLabel => switch (opponentTruth) {
        'human' => '人类',
        'ai' => 'AI',
        _ => '未知',
      };

  /// 「对方猜你是」显示文案。
  String get opponentGuessLabel => switch (opponentGuess) {
        'human' => '人类',
        'ai' => 'AI',
        _ => '未判定',
      };
}
