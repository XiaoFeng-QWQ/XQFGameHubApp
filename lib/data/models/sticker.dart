import '../../core/net/api_client.dart';
import '../../core/utils/url.dart';

/// 表情（`/api/sticker/list`）。
///
/// 线上返回的每一项形如：
/// ```json
/// {"id":"st_xxx","name":"大笑","url":"https://...","created_at":1700000000,"source":"default"}
/// {"id":"us_xxx","name":"","url":"https://...","status":"pending","created_at":1751000000,"source":"mine"}
/// ```
/// 区分「我的表情」优先用 `source`，缺失时回退到 `id` 前缀 `us_`。
/// 自定义表情带 `status`：`pending` 审核中 / `approved` 已通过 / `rejected` 已拒绝。
class Sticker {
  const Sticker({
    required this.id,
    this.name = '',
    this.url = '',
    this.status,
    this.source,
    this.createdAt,
  });

  final String id;
  final String name;
  final String url;
  final String? status;

  /// `default`（默认表情）/ `mine`（我的表情）。
  final String? source;
  final int? createdAt;

  bool get isMine => source != null ? source == 'mine' : id.startsWith('us_');
  bool get isApproved => status == null || status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String? get imageUrl => absoluteUrl(url);

  String get displayName => name.isNotEmpty ? name : id;

  factory Sticker.fromJson(Map<String, dynamic> json) => Sticker(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        url: '${json['url'] ?? ''}',
        status: json['status'] as String?,
        source: json['source'] as String?,
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}

/// `/api/sticker/list` 的分组结果。
class StickerSet {
  const StickerSet({this.defaults = const <Sticker>[], this.mine = const <Sticker>[]});

  final List<Sticker> defaults;
  final List<Sticker> mine;

  factory StickerSet.fromJson(Map<String, dynamic> json) {
    final List<Sticker> all = asList(json['stickers'])
        .map((dynamic e) => Sticker.fromJson(asMap(e)))
        .toList();
    return StickerSet(
      defaults: all.where((Sticker s) => !s.isMine).toList(),
      mine: all.where((Sticker s) => s.isMine).toList(),
    );
  }
}
