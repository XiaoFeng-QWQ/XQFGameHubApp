import '../../core/net/api_client.dart';

/// 一条玩家标签。
///
/// 线上 `/api/player/tags` 的真实结构是对象数组：
/// ```json
/// {"tag": "刘小枫", "count": 0, "is_special": 1}
/// ```
/// 而文档里写的是纯字符串数组，这里两种都兼容。
class PlayerTag {
  const PlayerTag({
    required this.name,
    this.count = 0,
    this.isSpecial = false,
  });

  final String name;

  /// 该标签被对手打出的次数（仅普通标签有意义）。
  final int count;

  /// 是否为官方特殊称号。
  final bool isSpecial;

  bool get isNormal => !isSpecial;

  factory PlayerTag.fromJson(dynamic raw) {
    if (raw is Map) {
      final Map<String, dynamic> json = asMap(raw);
      final dynamic flag = json['is_special'];
      return PlayerTag(
        name: '${json['tag'] ?? json['name'] ?? ''}',
        count: (json['count'] as num?)?.toInt() ?? 0,
        isSpecial: flag == true || flag == 1 || flag == '1',
      );
    }
    return PlayerTag(name: '$raw');
  }
}

/// 特殊 / 官方称号。
///
/// 线上 `special` 是**字符串数组**（`["刘小枫", "国庆限定"]`），
/// 文档里则是 `[{"name": "新年快乐", "icon": "🎉"}]`，两种都支持。
class SpecialTag {
  const SpecialTag({required this.name, this.icon});

  final String name;
  final String? icon;

  factory SpecialTag.fromJson(dynamic raw) {
    if (raw is Map) {
      final Map<String, dynamic> json = asMap(raw);
      return SpecialTag(
        name: '${json['name'] ?? json['tag'] ?? ''}',
        icon: json['icon'] as String?,
      );
    }
    return SpecialTag(name: '$raw');
  }
}

/// `/api/player/tags` 响应。
class MyTags {
  const MyTags({
    this.tags = const <PlayerTag>[],
    this.worn = const <String>[],
    this.special = const <SpecialTag>[],
    this.wornSpecial = const <String>[],
    this.max = 3,
  });

  /// 全部标签（含特殊称号，用 [PlayerTag.isSpecial] 区分）。
  final List<PlayerTag> tags;

  /// 当前佩戴的普通标签。
  final List<String> worn;

  /// 官方特殊称号列表。
  final List<SpecialTag> special;

  /// 当前佩戴的特殊称号。
  final List<String> wornSpecial;

  /// 普通标签与特殊称号**各自**最多可佩戴的数量（互不占用名额）。
  final int max;

  List<PlayerTag> get normalTags =>
      tags.where((PlayerTag t) => t.isNormal && t.name.isNotEmpty).toList();

  /// 特殊称号：优先用 `special` 字段；缺失时回退到 `tags` 里 `is_special` 的条目。
  List<SpecialTag> get specialTags {
    if (special.isNotEmpty) {
      return special.where((SpecialTag t) => t.name.isNotEmpty).toList();
    }
    return tags
        .where((PlayerTag t) => t.isSpecial && t.name.isNotEmpty)
        .map((PlayerTag t) => SpecialTag(name: t.name))
        .toList();
  }

  bool get isEmpty => normalTags.isEmpty && specialTags.isEmpty;

  factory MyTags.fromJson(Map<String, dynamic> json) => MyTags(
        tags: asList(json['tags'])
            .map(PlayerTag.fromJson)
            .where((PlayerTag t) => t.name.isNotEmpty)
            .toList(),
        worn: asList(json['worn']).map((dynamic e) => '$e').toList(),
        special: asList(json['special'])
            .map(SpecialTag.fromJson)
            .where((SpecialTag t) => t.name.isNotEmpty)
            .toList(),
        wornSpecial: asList(json['worn_special'])
            .map((dynamic e) => e is Map ? '${asMap(e)['name'] ?? ''}' : '$e')
            .where((String e) => e.isNotEmpty)
            .toList(),
        max: (json['max'] as num?)?.toInt() ?? 3,
      );
}

/// `POST /api/player/worn-tags` 响应。
///
/// 线上返回 `{"success": true, "worn": [...], "worn_special": [...], "message": "..."}`，
/// 注意用的是 `success` 而不是 `ok`，因此不能只依赖 `ApiClient` 的通用错误解包。
class WornTagsResult {
  const WornTagsResult({
    required this.success,
    this.worn = const <String>[],
    this.wornSpecial = const <String>[],
    this.message = '',
  });

  final bool success;
  final List<String> worn;
  final List<String> wornSpecial;
  final String message;

  factory WornTagsResult.fromJson(Map<String, dynamic> json) => WornTagsResult(
        success: json['success'] == true || json['ok'] == true,
        worn: asList(json['worn']).map((dynamic e) => '$e').toList(),
        wornSpecial: asList(json['worn_special']).map((dynamic e) => '$e').toList(),
        message: '${json['message'] ?? ''}',
      );
}
