import 'package:flutter/material.dart';

import '../../../../core/net/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/xqf_time.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/chat_history.dart';
import '../../../../data/models/sticker.dart';
import '../../../../state/app_state.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/fold_section.dart';
import '../../../widgets/player_avatar.dart';
import 'chat_detail_sheet.dart';

/// 聊天记录回顾（对应 Web 端「聊天记录回顾」面板）。
class HistoryPanel extends StatefulWidget {
  const HistoryPanel({super.key, required this.overview});

  final AccountOverview overview;

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  PagedChatHistory? _data;
  bool _loading = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(1));
  }

  Future<void> _load(int page) async {
    final AppScope scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PagedChatHistory data = await scope.services.account.chatHistory(page: page);
      if (!mounted) return;
      setState(() {
        _data = data;
        _page = data.page;
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

  Future<void> _openDetail(ChatHistoryItem item) async {
    final AppScope scope = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => ChatDetailSheet(
        item: item,
        loadDetail: () => scope.services.account.chatHistoryDetail(item.id),
        loadStickers: () => scope.services.account.stickers(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final PagedChatHistory? data = _data;

    return DoodlePanel(
      tone: NoteTone.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHead(
            title: '聊天记录回顾',
            note: '对局结束时保存',
            titleSize: 15,
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: DotBounce()),
            )
          else if (_error != null)
            EmptyTip(text: _error!, isError: true)
          else if (data == null || data.list.isEmpty)
            const EmptyTip(text: '暂无保存的聊天记录，对局结束后点「保存聊天记录」即可留档')
          else ...<Widget>[
            for (final ChatHistoryItem item in data.list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryRow(item: item, onTap: () => _openDetail(item)),
              ),
            if (data.totalPages > 1) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DoodleButton(
                    compact: true,
                    onPressed: _page > 1 ? () => _load(_page - 1) : null,
                    child: const Text('上一页'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$_page / ${data.totalPages}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: p.textMuted,
                      ),
                    ),
                  ),
                  DoodleButton(
                    compact: true,
                    onPressed: _page < data.totalPages ? () => _load(_page + 1) : null,
                    child: const Text('下一页'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onTap});

  final ChatHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Color resultColor = switch (item.result) {
      'win' => p.success,
      'lose' => p.danger,
      _ => p.textMuted,
    };
    final List<String> meta = <String>[
      item.guessLabel,
      if (item.truthLabel.isNotEmpty) item.truthLabel,
      '${item.messageCount} 条消息',
      XqfTime.formatDateTime(item.createdAt),
      if (item.likes > 0) '❤ ${item.likes}',
    ];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.surfaceWhite,
          border: Border.all(color: p.inkBlack, width: 2),
          borderRadius: XqfRadii.input,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (item.hasTitle) ...<Widget>[
                        AppIcon('tag', size: 13, color: p.inkBlue),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: p.inkBlack,
                          ),
                        ),
                      ),
                      if (item.isPublic) ...<Widget>[
                        const SizedBox(width: 6),
                        DoodleTag(label: '公开', solid: true, fontSize: 10),
                      ],
                    ],
                  ),
                ),
                if (item.resultLabel.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  Text(
                    item.resultLabel,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Text(
              meta.join(' · '),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
                color: p.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 详情弹层里渲染一条消息（供 `chat_detail_sheet.dart` 使用）。
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.stickerMap = const <String, Sticker>{},
  });

  final ChatMessage message;
  final Map<String, Sticker> stickerMap;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final bool right = message.isRight;
    final String? stickerUrl = message.resolvedStickerUrl ??
        (message.stickerId != null
            ? stickerMap[message.stickerId!]?.imageUrl
            : null);

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: right ? p.noteBlue : p.surfaceWhite,
          border: Border.all(color: p.inkBlack, width: 2),
          borderRadius: right
              ? const BorderRadius.only(
                  topLeft: Radius.elliptical(14, 4),
                  topRight: Radius.elliptical(4, 14),
                  bottomLeft: Radius.elliptical(14, 4),
                  bottomRight: Radius.elliptical(4, 4),
                )
              : const BorderRadius.only(
                  topLeft: Radius.elliptical(4, 14),
                  topRight: Radius.elliptical(14, 4),
                  bottomLeft: Radius.elliptical(4, 4),
                  bottomRight: Radius.elliptical(4, 14),
                ),
        ),
        child: Column(
          crossAxisAlignment:
              right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${message.sender} · ${XqfTime.format(message.time, pattern: 'HH:mm:ss', fallback: '')}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: p.textSubtle,
              ),
            ),
            const SizedBox(height: 4),
            if (message.hasSticker)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: StickerImage(url: stickerUrl, size: 72),
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                  color: p.inkBlack,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
