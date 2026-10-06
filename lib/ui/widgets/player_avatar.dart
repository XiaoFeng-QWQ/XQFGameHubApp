import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/utils/url.dart';
import 'app_icon.dart';

/// 玩家头像。
///
/// 对应 Web 端 `.acc-avatar`：圆形、2px 描边、白底、无头像时渲染昵称首字母。
/// 图片来自 `GET /api/avatar/{player_id}`（WebP，支持 ETag 协商缓存）。
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    this.avatarPath,
    this.playerId,
    this.nickname,
    this.size = 72,
    this.version,
    this.showEditMask = false,
  });

  /// `/api/account/overview` 返回的 `avatar` 字段（可能已带 `?v=`）。
  final String? avatarPath;
  final String? playerId;
  final String? nickname;
  final double size;
  final int? version;
  final bool showEditMask;

  String? get _url {
    if (avatarPath != null && avatarPath!.isNotEmpty) return absoluteUrl(avatarPath);
    if (playerId != null && playerId!.isNotEmpty) {
      final String v = version != null ? '?v=$version' : '';
      return '${absoluteUrl('/api/avatar/$playerId')}$v';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final String? url = _url;
    final String initial = (nickname ?? '?').trim().isEmpty
        ? '?'
        : (nickname!.trim().characters.first).toUpperCase();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: p.surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(color: p.inkBlack, width: 2),
              boxShadow: <BoxShadow>[
                BoxShadow(color: p.shadowSm, offset: const Offset(2, 3), blurRadius: 0),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: url == null
                ? _Initial(initial: initial, size: size, color: p.inkBlue)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _Initial(initial: initial, size: size, color: p.inkBlue),
                    loadingBuilder: (BuildContext ctx, Widget child, ImageChunkEvent? e) {
                      if (e == null) return child;
                      return _Initial(initial: initial, size: size, color: p.inkBlue);
                    },
                  ),
          ),
          if (showEditMask)
            Container(
              decoration: BoxDecoration(
                color: p.scrim,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '更换',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial, required this.size, required this.color});

  final String initial;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// 表情图片（表情管理面板用）。
class StickerImage extends StatelessWidget {
  const StickerImage({super.key, required this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    if (url == null || url!.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: AppIcon('image-off', color: p.textAa, size: size * 0.5),
      );
    }
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: AppIcon('image-off', color: p.textAa, size: size * 0.5),
      ),
    );
  }
}
