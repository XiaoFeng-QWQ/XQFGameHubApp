import '../../core/env.dart';

/// 把接口返回的相对路径补全为绝对地址。
String? absoluteUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('//')) return 'https:$path';
  if (path.startsWith('/')) return '${XqfEnv.baseUrl}$path';
  return '${XqfEnv.baseUrl}/$path';
}
