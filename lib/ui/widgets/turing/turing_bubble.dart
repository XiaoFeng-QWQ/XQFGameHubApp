import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../data/models/turing.dart';
import '../app_icon.dart';

/// 对局聊天流里的一条内容。
///
/// 对应 Web 端 `.bubble` / `.bubble-left` / `.bubble-right` / `.sys-msg`：
/// 对手是便签黄、缺口在左下；自己是便签蓝、缺口在右下；
/// 系统提示居中斜体，[TuringFeedItem.emphasis] 的用危险色加粗。
class TuringBubble extends StatelessWidget {
  const TuringBubble({super.key, required this.item});

  final TuringFeedItem item;

  @override
  Widget build(BuildContext context) {
    if (item.kind == TuringFeedKind.system) return _SystemLine(item: item);

    final XqfPalette p = XqfPalette.of(context);
    final bool mine = item.mine;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          return Container(
            constraints: BoxConstraints(maxWidth: c.maxWidth * 0.7),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: mine ? p.noteBlue : p.noteYellow,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: mine ? XqfRadii.bubbleRight : XqfRadii.bubbleLeft,
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${item.sender} (${_clock(item.at)})',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.kind == TuringFeedKind.sticker)
                  _StickerBody(item: item)
                else
                  Text(
                    item.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      height: 1.4,
                      color: p.inkBlack,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StickerBody extends StatelessWidget {
  const _StickerBody({required this.item});

  final TuringFeedItem item;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final String? url = item.stickerUrl;
    if (url == null || url.isEmpty) {
      return Text(
        '[表情${item.stickerName == null || item.stickerName!.isEmpty ? '' : '：${item.stickerName}'}]',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: p.textSubtle,
        ),
      );
    }
    return ClipRRect(
      borderRadius: XqfRadii.micro,
      child: Image.network(
        url,
        width: 96,
        height: 96,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            AppIcon('image-off', size: 28, color: p.textSubtle),
      ),
    );
  }
}

/// 系统提示：居中斜体一行。
class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.item});

  final TuringFeedItem item;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          item.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.5,
            fontStyle: FontStyle.italic,
            fontWeight: item.emphasis ? FontWeight.bold : FontWeight.normal,
            color: item.emphasis ? p.danger : p.textSubtle,
          ),
        ),
      ),
    );
  }
}

String _clock(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
