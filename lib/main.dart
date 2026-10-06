import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/storage/app_prefs.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 状态栏跟随 App 主题（浅色纸面 → 深色图标）。
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final AppPrefs prefs = await AppPrefs.init();
  final AppServices services = AppServices(prefs);
  final AuthController auth = AuthController(prefs)..restore();
  final ThemeController theme = ThemeController(prefs);

  runApp(XqfApp(services: services, auth: auth, theme: theme));
}
