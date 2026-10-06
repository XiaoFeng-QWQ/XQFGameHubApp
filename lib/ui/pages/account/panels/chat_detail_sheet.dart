import 'package:flutter/material.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/xqf_time.dart';
import '../../../../data/models/chat_history.dart';
import '../../../../data/models/sticker.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/fold_section.dart';
import '../../../widgets/paper.dart';
import 'history_panel.dart';

/// 聊天记录详情弹层（对应 Web 端 `#chat-history-detail-overlay` 的剪贴板抽屉）。
class ChatDetailSheet extends StatefulWidget {
  const ChatDetailSheet({
    super.key,
    required this.item,
    required this.loadDetail,
    required this.loadStickers,
  });

  final ChatHistoryItem item;
  final Future<ChatHistoryDetail> Function() loadDetail;
  final Future<StickerSet> Function() loadStickers;

  @override
  State<ChatDetailSheet> createState() => _ChatDetailSheetState();
}

class _ChatDetailSheetState extends State<ChatDetailSheet> {
  ChatHistoryDetail? _detail;
  Map<String, Sticker> _stickerMap = const <String, Sticker>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ChatHistoryDetail detail = await widget.loadDetail();
      Map<String, Sticker> map = const <String, Sticker>{};
      try {
        final StickerSet set = await widget.loadStickers();
        map = <String, Sticker>{
          for (final Sticker s in <Sticker>[...set.defaults, ...set.mine]) s.id: s,
        };
      } on ApiException {
        // 表情表拿不到不影响文字消息展示
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _stickerMap = map;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final ChatHistoryItem item = widget.item;
    final ChatHistoryDetail? detail = _detail;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      expand: false,
      builder: (BuildContext ctx, ScrollController controller) {
        return Container(
          decoration: BoxDecoration(
            color: p.surfaceWhite,
            border: Border(top: BorderSide(color: p.inkBlack, width: 2)),
            borderRadius: XqfRadii.sheet,
          ),
          child: Column(
            children: <Widget>[
              // 抓手
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.borderLight,
                    borderRadius: XqfRadii.micro,
                  ),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 12, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: p.inkBlack,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: AppIcon('close', size: 18, color: p.inkBlack),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DashedDivider(color: p.borderLight),
              ),
              // 信息行
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    DoodleTag(label: item.guessLabel),
                    if (item.truthLabel.isNotEmpty) DoodleTag(label: item.truthLabel),
                    DoodleTag(label: '${item.messageCount} 条消息'),
                    DoodleTag(label: XqfTime.formatDateTime(item.createdAt)),
                    if (item.resultLabel.isNotEmpty)
                      DoodleTag(label: '结果 ${item.resultLabel}', solid: true),
                  ],
                ),
              ),
              // 消息列表
              Expanded(
                child: _loading
                    ? const LoadingBlock(text: '正在读取聊天记录…')
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: EmptyTip(text: _error!, isError: true),
                          )
                        : detail == null || detail.messages.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: EmptyTip(text: '无聊天消息'),
                              )
                            : ListView.builder(
                                controller: controller,
                                padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                                itemCount: detail.messages.length,
                                itemBuilder: (BuildContext c, int i) => ChatMessageBubble(
                                  message: detail.messages[i],
                                  stickerMap: _stickerMap,
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
