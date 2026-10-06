# XQFGameHub · 安卓客户端

`XQFGameHub 游戏中心` 的 Android 客户端，使用 **Flutter** 构建。

视觉风格与 Web 端（`/media/xiaofengqwq/共享文件1/web/wwwroot/Swoole/对面是AI吗`）
**完全一致**：手绘语言 —— 2px 描边、不规则圆角、错位实心阴影、便签底色、点阵纸背景、
等宽字体。手机屏幕更窄，因此版式按移动端重新排布（桌面端的两栏面板收敛为单列、
Hero 的「文案 / 手绘」由左右分栏改为上下堆叠），但配色、圆角、阴影、字距、图标
全部取自同一套变量。

后端接口：`https://game.xfcode.top`，接口契约见
`/media/xiaofengqwq/共享文件1/web/wwwroot/文档站/图灵测试/api接口`。

> **开发说明**：本项目客户端使用 **DeepSeek-V4.1-Flash** 辅助开发，
> 详见文末[「八、开发说明」](#八开发说明)。

---

## 当前进度

| 模块 | 状态 |
| --- | --- |
| 首页（游戏中心） | ✅ 已完成 |
| 账号中心 `/account` | ✅ 已完成 |
| 图灵测试 / 海龟汤 / 五子棋 / 围棋 / 聊天室 / 临时聊天 / 社区 / 周报 | ⏳ 后续版本接入 |

首页与账号中心内的玩法入口目前会提示「将在后续版本接入」，外部站点（污染卡牌）
会直接用系统浏览器打开。

---

## 一、已实现的功能

### App 外壳

- **底部导航（竖屏）/ 左侧导航栏（横屏、平板）**：首页 / 玩法 / 我的。
  宽度 ≥ 720dp 自动改用侧栏，横屏时不再让底部栏挤占本就紧张的高度。
- **不锁定屏幕方向**，横竖屏自适应：面板两栏/单列、玩法网格 2/3/4 列、
  Hero 手绘仅在宽屏出现。
- **返回键**：不在首页时先回到首页，而不是直接退出。
- 页面用 `IndexedStack` 惰性保活，切页签不丢状态、不重复请求。

### 首页

- **街机招牌走马灯**：`NOW PLAYING` + 玩法列表 + 绿色呼吸点（窄屏压成一行）。
- **Hero 横格纸大卡**：品牌大字（荧光笔标线）、副标题、玩法关键词、
  三枚数据（在线玩家 / 玩法数 / 本周对局）、右侧手绘游戏机（`CustomPainter`
  按 Web 端内联 SVG 的 240×210 坐标系重绘）+ `HUMAN?` / `AI?` 标签。
- **在线人数**：真实连接 `wss://game.xfcode.top/ws`，收 `online_count`；
  25 秒心跳 `ping`，60 秒无 `pong` 判定断线并 2 秒后重连；全服公告以顶部
  提示条弹出（与 Web 端 `hub.js` 行为一致）。
- **主推位**：书脊 + 封面带 + 正文 + 「开始匹配」开口按钮的游戏盒。
- **精选玩法**：4 张玩法卡 + 「全部玩法 →」跳转到玩法页签。
- **服务票根条**：全服周报 / 交流社区 / 评价与打分 / 赞助支持。
- **主题切换**：亮色 / 暗色，偏好持久化。
- 网页式页脚（ICP 备案等）已移出主滚动流，见「关于」页。

### 玩法页

- 全部玩法网格（按宽度 2 / 3 / 4 列自适应）+ 分类筛选
  （全部 / 推理对局 / 棋盘竞技 / 聊天社交 / 卡牌对战）。
- 外部站点玩法（污染卡牌）用系统浏览器打开，其余提示后续版本接入。

### 关于页

原页脚内容集中到这里：品牌卡 + 服务与协议（用户协议 / 隐私政策 / 服务器状态 /
赞助支持）+ 客户端信息 + 备案信息（萌ICP备 / 假ICP备）+ 版权。

### 内置浏览器与图片查看

外链不再甩给系统浏览器：

- **`openInAppWeb()`**（`ui/pages/web_page.dart`）—— 用户协议、隐私政策、
  服务器状态、备案页、公开主页、全服周报、网页版账号中心、外部玩法（污染卡牌）
  全部在 App 内用 WebView 打开。带进度条、加载失败重试、站内跳转不出 App、
  返回键先在网页历史里后退。
- **`showInAppImage()`**（`ui/widgets/image_viewer.dart`）—— 赞助收款码
  全屏查看，支持双指缩放。
- 两处都保留「用浏览器打开」作为兜底（WebView 兼容性出问题时仍可用）。

### 账号中心 `/account`

**未登录**

- 邮箱验证码登录 / 注册（`POST /api/email/send-code` + `POST /api/email/auth`），
  含 60 秒倒计时、邮箱格式校验、注册即同意协议的提示。
- 找回旧账号（`GET /api/generate-player-id?action=recover`，折叠区）。
- 第三方登录说明（OAuth 依赖浏览器回调，App 内点开会用内置 WebView 打开网页版账号中心）。

**已登录**

- **身份卡**：头像（点击从相册选择并上传，`POST /api/account/avatar`，≤ 2MB）、
  昵称 + `#编号`、佩戴标签（普通 + 特殊）、编号 / 注册时间 / 最近对局、
  总对局 / 胜率 / 场均发言三连数据卡、公开主页 / 全服周报 / 修改昵称入口。
- **我的标签**：官方称号与普通标签两组，**各自独立受 `max` 上限约束（互不占用名额）**，
  普通标签显示 `×被评价次数`，保存佩戴后以服务端返回的最终状态为准
  （`GET /api/player/tags` + `POST /api/player/worn-tags`）。
- **聊天记录回顾**：分页列表（标题 / 公开徽标 / 胜负 / 猜测与真相 / 消息数 / 点赞），
  点击打开剪贴板抽屉式详情，左右气泡 + 表情图片还原
  （`/api/chat-history` + `/api/chat-history/detail`）。
- **表情管理**：我的表情 / 默认表情两个标签页，多选上传（Base64，≤ 2MB）、
  删除、把默认表情添加到我的表情，审核中 / 已拒绝角标
  （`/api/sticker/*`）。
- **对手留言管理**：允许他人留言开关、留言列表、隐藏 / 显示
  （`/api/player-messages` + `/api/player-message/*`）。
- **第三方绑定**：已绑定列表、同步头像、解绑；新增绑定引导到网页版
  （`/api/oauth/bindings` + `/api/oauth/unbind` + `/api/oauth/sync-avatar`）。
- **邮箱绑定**：当前邮箱展示、新邮箱 + 验证码（`scene=bind_email`）保存
  （`POST /api/account/email`）。
- **账号安全**：修改 / 首次设置密码（`password_set=false` 时免旧密码），
  保存后用返回的新 token 覆盖本地会话；退出登录。

7 个面板收进「内容管理」「账号设置」两个**默认折叠**的分组，避免一屏滚到底；
宽屏（≥ 840dp）自动变两栏。未登录表单限宽 460dp（对齐 Web 端 `#account-guest`）。

---

> **新页面怎么写**、哪些是硬约束哪些可以推翻、间距字号收敛建议、
> 以及接入 checklist，见 [DESIGN.md](DESIGN.md)。下面是 CSS ↔ Flutter 的速查对照。

## 二、设计系统对照表

所有颜色、圆角、阴影都在 `lib/core/theme/palette.dart` 中，
逐条对应 Web 端 `Public/style.css` 的 CSS 变量，暗色主题自动生效。

| Web（style.css / hub.css / account.css） | Flutter |
| --- | --- |
| `:root` / `[data-theme="dark"]` 全部 CSS 变量 | `XqfPalette.light` / `XqfPalette.dark` |
| `.doodle-border`、`.hub-hand`、`.acc-stat` 圆角 | `XqfRadii.hand` |
| `.doodle-btn` 圆角 | `XqfRadii.button` |
| `.acc-panel` 圆角 | `XqfRadii.panel` |
| `.hub-nav-chip` / `.hub-filter` / `.hub-ticket-strip` | `XqfRadii.chip` |
| `.hub-card-window` / `.acc-tag` / `.input-line input` | `XqfRadii.window` / `.tag` / `.input` |
| `box-shadow: 4px 6px 0 var(--shadow-md)` | `XqfShadows.panel` |
| `box-shadow: 2px 4px 0 var(--shadow-sm)` | `XqfShadows.card` |
| `body` 点阵纸背景 | `DotGridBackground` |
| `.hub-hero-card` 横格纸 | `RuledPaper` |
| `border-bottom: 2px dashed` | `DashedDivider` |
| `border: 1.5px dashed` 小药丸 | `DashedBorder` |
| `.doodle-btn` | `DoodleButton` |
| `.acc-panel` | `DoodlePanel` + `NoteTone` |
| `.hub-section-head` / `.acc-group-head` | `SectionHead` / `GroupHead` |
| `.hub-stamp` | `DoodleStamp` |
| `.acc-tag` | `DoodleTag` |
| `.acc-link-btn` | `LinkTextButton` |
| `.input-line input` / `.acc-inline input` | `DoodleField` |
| `.acc-fold` | `FoldSection` |
| `.acc-avatar` | `PlayerAvatar` |
| `.hub-card` / `.hub-box` / `.hub-ticket` | `HubCard` / `HubBox` / `HubTicket` |
| `.dot-bounce` 加载动画 | `DotBounce` / `LoadingBlock` |
| `.acc-group`（分组标题） | `CollapsibleGroup`（手机上默认折叠） |
| `.hub-footer`（网页式页脚） | `AboutPage`（移出主滚动流） |
| `showTopToast()` | `showTopToast()` |
| `.icon`（stroke 2.2 线性图标） | `AppIcon`（复用同一批 SVG 路径） |
| `XQFTime`（shared.js） | `XqfTime`（含秒 / 毫秒 / 字符串兼容） |

字体沿用 Web 端的等宽字体栈（Menlo / Consolas / Monaco / ui-monospace），
Android 上映射到系统 `monospace`，中文由系统 CJK 字体回退，与浏览器表现一致。

---

## 三、目录结构

```
lib/
├── main.dart                     入口：初始化本地存储 / 会话 / 主题
├── app.dart                      MaterialApp + 全局主题 + 字体缩放钳制
├── core/
│   ├── env.dart                  后端地址、协议 / 隐私政策、版本号、开发协助模型
│   ├── storage/app_prefs.dart    token / 昵称 / 主题 / 设备指纹持久化
│   ├── net/
│   │   ├── api_client.dart       统一 HTTP：Bearer、错误解包、超时
│   │   └── api_exception.dart    业务错误（含 isAuthError 判定）
│   ├── theme/
│   │   ├── palette.dart          颜色 / 圆角 / 阴影（对照 CSS 变量）
│   │   └── app_theme.dart        ThemeData（亮色 + 暗色）
│   └── utils/
│       ├── xqf_time.dart         XQFTime 的 Dart 实现
│       └── url.dart              相对地址补全
├── data/
│   ├── api/                      auth_api / account_api（按文档分节）
│   ├── models/                   account / tags / chat_history / sticker /
│   │                             player_message / oauth
│   └── online_service.dart       WebSocket 在线人数 + 全服公告
├── data/game_catalog.dart        玩法目录（首页精选与玩法页共用）
├── state/app_state.dart          AppServices / AuthController /
│                                 ThemeController / AppScope
└── ui/
    ├── widgets/                  设计系统组件（见上表）
    │   ├── breakpoints.dart      响应式断点
    │   ├── bottom_nav.dart       底部导航 / 侧边导航栏
    │   ├── sponsor.dart          赞助弹窗（首页票根与关于页共用）
    │   └── image_viewer.dart     全屏图片查看（收款码）
    └── pages/
        ├── app_shell.dart        外壳：导航 + 页面栈
        ├── home_page.dart        首页
        ├── games_page.dart       玩法页
        ├── about_page.dart       关于页
        ├── web_page.dart         内置 WebView（外链统一入口）
        └── account/
            ├── account_page.dart     账号中心外壳（加载 / 未登录 / 已登录）
            ├── account_guest.dart    未登录视图
            ├── account_hero.dart     身份卡
            └── panels/               标签 / 聊天记录 / 表情 / 留言 /
                                      绑定 / 邮箱 / 安全 + 聊天详情抽屉
```

---

## 四、构建

### ⚠️ 必须通过 ASCII 路径构建

本工程位于含中文的路径下（`…/共享文件1/AndroidApp/XQFGameHub`）。
Gradle / Kotlin 在向编译器传递 source 与 classpath 参数时，会把非 ASCII 字符
转义成 `uXXXX`（`共享文件1` → `u5171u4EABu6587u4EF61`），于是 Kotlin 报错：

```
error: source file or directory not found: /media/…/u5171u4EABu6587u4EF61/…
error: plugin classpath entry points to a non-existent location: …
```

这是 Gradle/Kotlin 对非 ASCII 路径的已知缺陷，无法通过 `file.encoding` 等参数绕过
（`android/settings.gradle.kts` 里已额外修掉 `java.util.Properties` 按 ISO-8859-1
读取 `local.properties` 的问题，那是另一处独立的坑）。

因此构建统一走 `tools/build_android.sh`：它把工程镜像到纯 ASCII 的构建根目录
（默认 `~/.xqf-build/XQFGameHub`）后再编译，产物拷回 `build/app/outputs/flutter-apk/`。
**源码始终留在你放置的位置。**

```bash
# debug
tools/build_android.sh

# release
tools/build_android.sh release

# 清空镜像后重建
tools/build_android.sh debug --clean
```

可用环境变量覆盖路径：

```bash
XQF_BUILD_ROOT=~/build/xqf \
XQF_FLUTTER_SDK=~/flutter-sdk/flutter \
XQF_ANDROID_SDK=~/Android \
tools/build_android.sh debug
```

### 依赖

- Flutter 3.47.6（stable）/ Dart 3.13.5
- Android SDK：platform 36、build-tools 36.0.0、JDK 17+（推荐 21）
- 应用 ID：`com.xiaofengqwq.gamehub`

第三方包（全部来自 pub.dev）：

| 包 | 用途 |
| --- | --- |
| `http` | 与 `game.xfcode.top` 的 HTTP 通信 |
| `shared_preferences` | token / 昵称 / 主题 / 设备指纹持久化（对应 Web 端 localStorage） |
| `flutter_svg` | 复用 Web 端 `style.css` 的 SVG 图标路径 |
| `image_picker` | 头像、表情选择 |
| `webview_flutter` | 内置浏览器：协议、备案、公开主页、外部玩法 |
| `url_launcher` | 兜底：WebView 打不开时用系统浏览器打开 |
| `flutter_localizations` | 中文系统控件文案 |

---

## 五、接口对照

| 页面 / 功能 | 接口 |
| --- | --- |
| 邮箱验证码 | `POST /api/email/send-code`（`scene=auth` / `bind_email`） |
| 邮箱登录 / 注册 | `POST /api/email/auth` |
| 找回旧账号 | `GET /api/generate-player-id?action=recover` |
| 账号总览 | `GET /api/account/overview` |
| 修改昵称 | `POST /api/account/nickname` |
| 上传头像 | `POST /api/account/avatar`（multipart，≤ 2MB） |
| 修改 / 设置密码 | `POST /api/account/password` |
| 绑定邮箱 | `POST /api/account/email` |
| 我的标签 | `GET /api/player/tags` / `POST /api/player/worn-tags` |
| BOT 权限 | `GET /api/account/bot-access` |
| 聊天记录 | `GET /api/chat-history` / `GET /api/chat-history/detail` |
| 表情 | `GET /api/sticker/list`、`POST /api/sticker/upload`、`/delete`、`/add-to-mine` |
| 留言 | `GET /api/player-messages`、`POST /api/player-message/hide`、`/settings` |
| 第三方绑定 | `GET /api/oauth/providers`、`GET /api/oauth/bindings`、`POST /api/oauth/unbind`、`POST /api/oauth/sync-avatar` |
| 在线人数 / 公告 | `wss://game.xfcode.top/ws`（`online_count` / `broadcast` / `ping`） |

后端约定「失败也返回 HTTP 200 + `{"error": "..."}`」，`ApiClient` 会统一转成
`ApiException`，UI 层 catch 后直接 `showTopToast` 展示文案。

> ⚠️ **接口文档曾与线上实现不一致。** 已对照后端源码
> （`GameController.php` / `PlayerStatsRepository.php` / `ChatHistoryRepository.php` /
> `StickerRepository.php`）修正文档，差异如下：
>
> | 接口 | 文档写法 | 线上实际 |
> | --- | --- | --- |
> | `GET /api/player/tags` 的 `tags` | `["理性", "幽默"]` | `[{"tag":"刘小枫","count":0,"is_special":1}]` |
> | `GET /api/player/tags` 的 `special` | `[{"name":"新年快乐","icon":"🎉"}]` | `["刘小枫","国庆限定"]` |
> | `POST /api/player/worn-tags` 响应 | `{"ok": true}` | `{"success": true, "worn": [...], "worn_special": [...], "message": "..."}` |
> | `GET /api/chat-history` 列表项 | `opponent_name` / `truth` / `guess` | `player_name` / `opponent_truth` / `player_guess` / `message_count` / `is_public` / `likes` |
> | `GET /api/chat-history/detail` 消息 | `role` / `content` | `side` / `text` / `sender` / `sticker_id` / `sticker_url` |
>
> 模型层对两种写法都做了兼容解析，并有回归测试锁住
> （`test/unit_test.dart` 的 `MyTags 解析` / `WornTagsResult` / `parseApiError` 分组）。
>
> `ApiClient` 现在同时识别 `error`、`ok:false`、`success:false` 三种失败形态——
> 最后一种是 `POST /api/player/worn-tags` 等写接口的约定，**响应里没有 `error` 字段**，
> 只看 `error` 会把它误判为成功。

---

## 六、测试

```bash
flutter test
```

共 30 个用例，全部通过：

- `test/unit_test.dart` —— `XqfTime` 时间解析 / 格式化、`XqfPalette` 与 CSS 变量
  一致性、`XqfRadii` 与 `border-radius` 简写的对应关系、`parseApiError` 的
  两套结果约定（`error` / `success:false`）、`MyTags` 解析、`ChatHistoryItem` 标签映射。
- `test/widget_test.dart` —— Widget 冒烟测试：设计系统组件（面板 / 按钮 / 标签 /
  印章 / 点阵纸 / 横格纸 / 虚线）、**全部 47 个线性图标的 SVG 解析**、玩法卡、
  账号中心未登录视图、身份卡；以及 App 外壳（竖屏底部导航 / 宽屏侧栏）、
  玩法页、关于页（含「赞助支持」走弹窗而非外链、客户端信息里的开发协助模型）、
  折叠分组，验证渲染不抛异常且关键文案与结构存在。

需要真实后端的页面级测试留待集成测试。

---

## 七、应用图标

`android/app/src/main/res/mipmap-*` 下的启动图标是按 Web 端语言生成的：
便签黄底 + 2px 墨色描边 + 圆角 + 蓝墨四格 logo（带轻微倾斜与抖动），
同时提供 `mipmap-anydpi-v26` 自适应图标（背景 `@color/ic_launcher_background`
= `#FDF5C9`，前景为居中安全区内的 logo）。

启动闪屏 `drawable*/launch_background.xml` 使用纸面底色，
亮色 `#F8F9FA`、暗色 `#121220`，与 `style.css` 的 `--paper-bg` 对齐。

---

## 八、开发说明

本项目客户端（Flutter / Dart）由 **DeepSeek-V4.1-Flash** 辅助开发，涵盖
页面实现、设计系统与 CSS 变量对照、接口对接、模型层兼容解析以及测试编写。

App 内「关于 → 客户端信息」同步展示了这一信息，取值自
`lib/core/env.dart` 的 `XqfEnv.aiModel`，与本文档保持一致：

| 位置 | 展示 |
| --- | --- |
| 关于页 · 客户端信息 | `开发协助` → `DeepSeek-V4.1-Flash` |
| `XqfEnv.aiModel` | `'DeepSeek-V4.1-Flash'` |
| 回归测试 | `test/widget_test.dart` → 「关于页客户端信息展示开发协助模型」 |
