import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../env.dart';
import 'api_exception.dart';

/// 统一 HTTP 客户端。
///
/// - 自动附带 `Authorization: Bearer <token>`（需要认证的接口）
/// - 自动解包 `{"ok": false, "error": "..."}` / `{"error": "..."}`
/// - 超时与网络异常统一转成 [ApiException]
class ApiClient {
  ApiClient({String? baseUrl, this.tokenProvider})
      : baseUrl = baseUrl ?? XqfEnv.baseUrl;

  final String baseUrl;

  /// 由认证状态提供当前 token；返回 null 表示未登录。
  final String? Function()? tokenProvider;

  final http.Client _client = http.Client();

  Map<String, String> _headers({bool auth = false, Map<String, String>? extra}) {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'XQFGameHub-Android/${XqfEnv.version}',
      ...?extra,
    };
    if (auth) {
      final String? token = tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final Uri base = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: <String, String>{
      ...base.queryParameters,
      for (final MapEntry<String, dynamic> e in query.entries)
        if (e.value != null) e.key: '${e.value}',
    });
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
  }) =>
      _send(() => _client.get(_uri(path, query), headers: _headers(auth: auth)));

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send(() => _client.post(
            _uri(path, query),
            headers: _headers(auth: auth, extra: <String, String>{
              'Content-Type': 'application/json; charset=utf-8',
            }),
            body: jsonEncode(body),
          ));

  Future<dynamic> postForm(
    String path,
    Map<String, String> fields, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send(() => _client.post(
            _uri(path, query),
            headers: _headers(auth: auth, extra: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            }),
            body: fields,
          ));

  /// multipart 上传（头像等）。字段名默认 `file`。
  Future<dynamic> postFile(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
    Map<String, String> fields = const <String, String>{},
    bool auth = true,
  }) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers(auth: auth));
    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
    ));
    return _send(() async {
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(XqfEnv.requestTimeout);
      return http.Response.fromStream(streamed);
    });
  }

  /// 下载二进制内容（头像等）。
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final http.Response res = await _client
          .get(_uri(path, query), headers: _headers())
          .timeout(XqfEnv.requestTimeout);
      if (res.statusCode != 200) {
        throw ApiException('资源不存在', statusCode: res.statusCode);
      }
      return res.bodyBytes;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络');
    } on SocketException {
      throw ApiException('网络不可用，请检查网络连接');
    }
  }

  Future<dynamic> _send(Future<http.Response> Function() run) async {
    late final http.Response res;
    try {
      res = await run().timeout(XqfEnv.requestTimeout);
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络');
    } on SocketException {
      throw ApiException('网络不可用，请检查网络连接');
    } on http.ClientException catch (e) {
      throw ApiException('网络请求失败：${e.message}');
    }

    if (res.statusCode == 401) {
      final dynamic body = _tryDecode(res);
      final String msg = _errorOf(body) ?? '请先登录后再操作';
      throw ApiException(msg, statusCode: 401);
    }
    if (res.statusCode >= 500) {
      throw ApiException('服务器开小差了（${res.statusCode}）', statusCode: res.statusCode);
    }

    final dynamic body = _tryDecode(res);
    if (body == null) {
      throw ApiException('响应解析失败', statusCode: res.statusCode);
    }

    final String? error = _errorOf(body);
    if (error != null && error.isNotEmpty) {
      throw ApiException(error, statusCode: res.statusCode);
    }
    return body;
  }

  dynamic _tryDecode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  String? _errorOf(dynamic body) => parseApiError(body);

  void dispose() => _client.close();
}

/// 解包业务错误。
///
/// 后端有两套结果约定（见《01.HTTP接口文档.md》「通用错误响应」）：
/// - 约定 A：失败为 `{"error": "..."}`，有时配 `{"ok": false}`
/// - 约定 B：失败为 `{"success": false, "message": "..."}`，**没有 `error` 字段**
///
/// 只看 `error` 会把约定 B 的失败当成成功（例如 `POST /api/player/worn-tags`、
/// `POST /api/player-message/hide`、`POST /api/chat-history/collect`），
/// 因此这里把 `success === false` 与 `ok === false` 也统一判为失败。
String? parseApiError(dynamic body) {
  if (body is! Map) return null;

  final dynamic err = body['error'];
  if (err is String && err.isNotEmpty) return err;
  if (err != null) return '$err';

  final dynamic msg = body['message'];
  if (body['success'] == false) {
    return (msg is String && msg.isNotEmpty) ? msg : '操作失败';
  }
  if (body['ok'] == false) {
    return (msg is String && msg.isNotEmpty) ? msg : '操作失败';
  }
  return null;
}

/// 把任意响应安全地读成 Map。
Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry('$k', v));
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}
