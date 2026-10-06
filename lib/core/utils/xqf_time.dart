/// 全站统一时间工具（Dart 版 XQFTime，行为与 Web 端 `shared.js` 一致）。
///
/// 约定：后端存储 / API / WebSocket 返回的时间字段一律是 Unix **秒级**
/// 时间戳（整数）。展示格式由消费端自行解析。
///
/// 兼容：秒级时间戳、毫秒级时间戳（>= 1e11）、`YYYY-MM-DD HH:mm:ss` 字符串。
/// 无法识别返回 null / 占位符。
class XqfTime {
  const XqfTime._();

  static const int _msThreshold = 100000000000;

  static DateTime? toDate(dynamic value) {
    if (value == null || value == false) return null;
    if (value is DateTime) return value;
    if (value is num) {
      final double n = value.toDouble();
      if (!n.isFinite || n <= 0) return null;
      final int ms = n < _msThreshold ? (n * 1000).round() : n.round();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final String s = value.toString().trim();
    if (s.isEmpty) return null;
    final num? n = num.tryParse(s);
    if (n != null) return toDate(n);
    return DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }

  /// 归一化为 Unix 秒级时间戳；不可识别返回 0。
  static int toEpoch(dynamic value) {
    final DateTime? d = toDate(value);
    return d == null ? 0 : d.millisecondsSinceEpoch ~/ 1000;
  }

  static String _p(int n) => n < 10 ? '0$n' : '$n';

  /// 模板占位符：`YYYY` `MM` `DD` `HH` `mm` `ss`。
  static String format(dynamic value, {String pattern = 'YYYY-MM-DD HH:mm:ss', String fallback = ''}) {
    final DateTime? d = toDate(value);
    if (d == null) return fallback;
    return pattern
        .replaceAll('YYYY', '${d.year}')
        .replaceAll('MM', _p(d.month))
        .replaceAll('DD', _p(d.day))
        .replaceAll('HH', _p(d.hour))
        .replaceAll('mm', _p(d.minute))
        .replaceAll('ss', _p(d.second));
  }

  static String formatDate(dynamic value, {String fallback = '—'}) =>
      format(value, pattern: 'YYYY-MM-DD', fallback: fallback);

  static String formatDateTime(dynamic value, {String fallback = '—'}) =>
      format(value, pattern: 'YYYY-MM-DD HH:mm', fallback: fallback);

  static String formatHm(dynamic value, {String fallback = '—'}) =>
      format(value, pattern: 'HH:mm', fallback: fallback);

  /// 相对时间：刚刚 / N 分钟前 / N 小时前 / N 天前 / YYYY-MM-DD
  static String timeAgo(dynamic value, {String fallback = '—'}) {
    final DateTime? d = toDate(value);
    if (d == null) return fallback;
    final int diff = DateTime.now().difference(d).inSeconds;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return '${diff ~/ 60}分钟前';
    if (diff < 86400) return '${diff ~/ 3600}小时前';
    if (diff < 604800) return '${diff ~/ 86400}天前';
    return formatDate(d);
  }

  /// 时长（秒）→ `m 分 s 秒` / `s 秒`。
  static String duration(dynamic seconds) {
    final int s = (num.tryParse('${seconds ?? 0}') ?? 0).round();
    if (s <= 0) return '—';
    if (s < 60) return '$s 秒';
    final int m = s ~/ 60;
    final int rest = s % 60;
    if (m < 60) return rest == 0 ? '$m 分钟' : '$m 分 $rest 秒';
    final int h = m ~/ 60;
    return '$h小时${m % 60}分';
  }
}
