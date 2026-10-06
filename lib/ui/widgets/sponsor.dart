import 'package:flutter/material.dart';

import '../../core/env.dart';
import '../../core/theme/palette.dart';
import 'app_icon.dart';
import 'image_viewer.dart';

/// 赞助支持弹窗（微信收款码）。
///
/// 原先挂在首页页脚的「赞助支持」入口，现在首页票根与「关于」页都会调用它。
Future<void> showSponsorDialog(BuildContext context) {
  final XqfPalette p = XqfPalette.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: p.overlayBg,
    builder: (BuildContext ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: p.surfaceWhite,
            border: Border.all(color: p.inkBlack, width: 2),
            borderRadius: XqfRadii.panel,
            boxShadow: XqfShadows.panel(p),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppIcon('heart', size: 16, color: p.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '赞助支持',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: p.inkBlack,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: AppIcon('close', size: 18, color: p.inkBlack),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '如果这里让你玩得开心，欢迎请作者喝杯咖啡',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => showInAppImage(
                  ctx,
                  url: XqfEnv.sponsorQrUrl,
                  title: '微信赞助码',
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.inkBlack, width: 2),
                    borderRadius: XqfRadii.window,
                    color: p.surfaceWhite,
                  ),
                  child: Image.network(
                    XqfEnv.sponsorQrUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(
                        child: Text(
                          '二维码加载失败\n点击此处用浏览器打开',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: p.textSubtle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '微信扫一扫 · 金额随意 · 心意最重要',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: p.textSubtle,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
