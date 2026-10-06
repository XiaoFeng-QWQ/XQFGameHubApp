/// 全局常量。API 与页面地址与 Web 端同源。
class XqfEnv {
  const XqfEnv._();

  /// 后端基础地址（见《01.HTTP接口文档.md》基础URL）。
  static const String baseUrl = 'https://game.xfcode.top';

  /// 用户协议 / 隐私政策（App 内用外部浏览器打开）。
  static const String agreementUrl = '$baseUrl/agreement';
  static const String privacyUrl = '$baseUrl/privacy';
  static const String sponsorQrUrl =
      'https://pic-node1.xfcode.top/uploads/b2256d6d27db0cf75144beb2f6051272.webp';
  static const String statusUrl = 'https://status.xiaofengqwq.com/';

  static const String appName = 'XQFGameHub';
  static const String appNameCn = 'XQF游戏中心';
  static const String version = '1.0.0';

  static const Duration requestTimeout = Duration(seconds: 25);
}
