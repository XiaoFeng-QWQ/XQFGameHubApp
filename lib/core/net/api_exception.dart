/// 业务错误。
///
/// 后端约定：绝大多数接口即使失败也返回 HTTP 200，正文形如
/// `{"error": "..."}` 或 `{"ok": false, "error": "..."}`，
/// 这里统一转换成异常抛出，UI 层只需 catch 后展示 [message]。
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isAuthError =>
      message.contains('token') ||
      message.contains('登录') ||
      message.contains('凭证') ||
      statusCode == 401;

  @override
  String toString() => message;
}
