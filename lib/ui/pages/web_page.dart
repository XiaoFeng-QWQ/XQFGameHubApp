import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/palette.dart';
import '../widgets/app_header.dart';
import '../widgets/app_icon.dart';
import '../widgets/doodle.dart';
import '../widgets/paper.dart';

/// 在 App 内打开一个网页（用户协议、隐私政策、服务器状态、备案、外部玩法…）。
///
/// 之前这些链接一律 `launchUrl` 甩给系统浏览器，用起来很割裂；
/// 现在统一走内置 WebView，站内跳转也留在 App 里，只有用户主动点
/// 「用浏览器打开」才会离开。
Future<void> openInAppWeb(
  BuildContext context, {
  required String url,
  String? title,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InAppWebPage(url: url, title: title),
    ),
  );
}

class InAppWebPage extends StatefulWidget {
  const InAppWebPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<InAppWebPage> createState() => _InAppWebPageState();
}

class _InAppWebPageState extends State<InAppWebPage> {
  late final WebViewController _controller;

  int _progress = 0;
  bool _loading = true;
  bool _canGoBack = false;
  String? _error;
  String? _pageTitle;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (String url) async {
            final bool canGoBack = await _controller.canGoBack();
            final String? title = await _controller.getTitle();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _canGoBack = canGoBack;
              _pageTitle = (title == null || title.trim().isEmpty) ? null : title.trim();
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 只对主文档报错，忽略图片/字体等子资源失败
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = error.description.isEmpty ? '页面加载失败' : error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // 站内跳转一律留在 App 内
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  String get _displayTitle {
    if (widget.title != null && widget.title!.isNotEmpty) return widget.title!;
    if (_pageTitle != null) return _pageTitle!;
    final Uri? uri = Uri.tryParse(widget.url);
    return uri?.host ?? widget.url;
  }

  Future<void> _openExternal() async {
    await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
  }

  /// 网页能后退时先在网页历史里后退，否则退出本页。
  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);

    return PopScope(
      // 网页能后退时，返回键先在网页历史里后退
      canPop: !_canGoBack,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: p.paperBg,
        body: Column(
          children: <Widget>[
            AppHeader(
              title: _displayTitle,
              leading: HeaderIconButton(
                icon: 'arrow-left',
                tooltip: '返回',
                onPressed: _handleBack,
              ),
              actions: <Widget>[
                HeaderIconButton(
                  icon: 'refresh',
                  tooltip: '刷新',
                  onPressed: () => _controller.reload(),
                ),
                const SizedBox(width: 10),
                HeaderIconButton(
                  icon: 'link',
                  tooltip: '用浏览器打开',
                  onPressed: _openExternal,
                ),
              ],
            ),
            // 进度条：加载中显示，完成后淡出
            SizedBox(
              height: 3,
              child: _loading
                  ? LinearProgressIndicator(
                      value: _progress <= 0 ? null : _progress / 100,
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      color: p.inkBlue,
                    )
                  : null,
            ),
            Expanded(
              child: _error != null
                  ? _WebError(
                      message: _error!,
                      url: widget.url,
                      onRetry: () {
                        setState(() {
                          _error = null;
                          _loading = true;
                        });
                        _controller.loadRequest(Uri.parse(widget.url));
                      },
                      onOpenExternal: _openExternal,
                    )
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebError extends StatelessWidget {
  const _WebError({
    required this.message,
    required this.url,
    required this.onRetry,
    required this.onOpenExternal,
  });

  final String message;
  final String url;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return DotGridBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DoodlePanel(
              tone: NoteTone.pink,
              child: Column(
                children: <Widget>[
                  AppIcon('alert', size: 28, color: p.danger),
                  const SizedBox(height: 12),
                  Text(
                    '页面打不开',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: p.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    url,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: p.textAa,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DoodleButton(
                          compact: true,
                          expand: true,
                          onPressed: onRetry,
                          child: const Text('重试'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DoodleButton(
                          compact: true,
                          expand: true,
                          icon: 'link',
                          onPressed: onOpenExternal,
                          child: const Text('浏览器'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
