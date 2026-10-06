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
| **图灵测试（1v1）** | ✅ **已完成** |
| 海龟汤 / 五子棋 / 围棋 / 聊天室 / 临时聊天 / 社区 / 周报 | ⏳ 后续版本接入 |

玩法入口中，图灵测试已可实际对局（要求先登录）；其余仍提示「将在后续版本接入」，
外部站点（污染卡牌）在 App 内 WebView 打开。

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
- 网页式页脚（ICP 备案等）已移出主滚动流，见「关于」页。
- 主题切换不在页头，见下方「[外观](#账号中心-account)」（「我的」页）。

### 玩法页

- 全部玩法网格（按宽度 2 / 3 / 4 列自适应）+ 分类筛选
  （全部 / 推理对局 / 棋盘竞技 / 聊天社交 / 卡牌对战）。
- 外部站点玩法（污染卡牌）用系统浏览器打开，其余提示后续版本接入。

### 图灵测试（1v1）

第一个真正可玩的玩法。入口：首页主推位「马上开始匹配」，或玩法页「推理对局」。
**要求先登录**（未登录会提示并跳到「我的」页签）——战绩、标签、聊天记录都要归属账号。

四个阶段：**落地 → 匹配 → 对局 → 结果**。

- **落地**：Hero 文案 + 时长选择（10 分钟 / 5 分钟 / **无限**）+ 实时在线人数。
  无限传 `duration: 0`：服务端 `GameTimers::startChatTimer` 对 `duration <= 0`
  直接跳过聊天定时器（不下发「聊天时间到」），由玩家手动判定结束，
  计时器显示 `∞`。**开局 60 秒的互发消息检查照常生效**
  （`startMutualChatCheck` 是无条件调用的），所以「无限」不等于没有约束。

  > ⚠️ 服务端 `Game.AllowedDurations` 是**白名单**（`Config/App.php`）。
  > 本仓库里它是 `[300, 600]`，**不含 `0`** —— 此时 `join` 传 0 会被拒为
  > 「无效的聊天时长」。要用无限时长，得先把 `0` 加进这个列表。
  >
  > 另外 Web 端那个「无限」选项其实是坏的：`parseInt(v) || 600` 会把 `0`
  > 变成 `600`，所以网页上选「无限」实际还是 10 分钟。App 这边直接传 0，
  > 没这个问题。
- **匹配**：三点跳动动画 + 连接状态提示。
- **对局**：**全出血版式**（不是 Web 端那套居中卡片 + 边框 + 阴影）——
  细对手条 + 横格纸聊天区 + 判定区 + 输入区四段。左黄右蓝气泡、2px 墨色描边；
  对手昵称在对局中显示为 `???`，结果页才揭晓；发送后自动收起键盘；
  判定区的标签默认折叠成一行小字。
  输入框复用 `DoodleField`（内嵌表情按钮），表情列表复用 HTTP
  `/api/sticker/list`，选中后走 WS 发 `{type:'sticker', id}`。
- **判定**：深色判定区，「它是人类」/「它是 AI」+ 可选标签。
  **门槛是「开局满 10 秒」且「自己发过 ≥1 条消息」**，未满足时按钮置灰并说明原因。
- **结果**：胜负结论 + 揭示 + 六项数据（你的判断 / 对方身份 / 对方标签 /
  对方猜你是 / 对话条数 / 用时），可折叠的「更多操作」里有
  **导出为图片**、**保存聊天记录**、**给对方留言**，以及「再来一局」。导出走 `RepaintBoundary.toImage` → PNG → 系统分享面板
  （Web 端用 html2canvas，这里不需要重画也不需要 WebView）。

几条实现上值得留意的规则（都在 `TuringClient` 里，有单测锁住）：

- 双方 60 秒内没互发消息 → 判平局、**不记战绩**。
- 聊天时间到 → 自动开 60 秒判定窗口，此时**输入区收口**。
- 已提交判定后**输入仍可用**（Web 端只隐藏判定区），等待对方最多 60 秒。
- 服务端 `timeout.reason` 有 7 种，且 `you_timeout` / `both_timeout` 要先收敛成
  `you` / `both` 才对应得上结果文案（不收敛会把平局显示成「猜错了」）。
- 断线时覆盖一层重连提示，恢复后自动消失；重连会带 `reconnect_session_id` 恢复对局。
- 被封禁（`error` 文案含「封禁」且非「无需封禁」）→ 回到落地页、置灰开局按钮并显示横幅。

> ⚠️ **对局必须复用全局唯一的那条 WS 连接。**
> 服务端 `BaseGameHandler::onOpen` 做了 IP 去重（last-wins，跨 `/ws`、`/ws/lobby`、
> `/ws/board/*` 等所有入口共享），同一 IP 再来一条会把旧连接踢掉。
> 所以原先「首页自己持有一条 `/ws`」的结构改成了全局 `HubSocket`
> （在线人数 / 全服公告 / 对局共用），见 `lib/data/hub_socket.dart`。

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

一张「登录账号」卡 + **两个 tab**（`DoodleChoiceChip`，与 Web 端 `.acc-sticker-tab` 同一形态）：

- **邮箱验证码**（默认）：邮箱验证码登录 / 注册
  （`POST /api/email/send-code` + `POST /api/email/auth`），
  含 60 秒倒计时、邮箱格式校验、注册即同意协议的提示。
- **账号密码**：代号 + 密码登录（`GET /api/generate-player-id?action=recover`）。
  ⚠️ 该接口用 `password_verify` 校验 `password_hash`，而**邮箱注册的账号
  `password_hash` 默认为空串**，所以它只对「已设置密码」的账号有效
  （旧版代号密码账号，或在「账号安全」里设过密码的邮箱账号）——
  卡面文案明确写了这一点，避免用户以为人人可用。
- 第三方登录说明（OAuth 依赖浏览器回调，App 内点开会用内置 WebView 打开网页版账号中心）。

> 与 Web 端的差异：Web 端把「邮箱登录 / 注册」和「找回账号」摆成上下两张卡片，
> App 里合并成一张卡 + tab —— 手机屏窄，两张卡要滚动才能看全，
> 而它们本来就是「同一件事的两种做法」。顺带省掉了原来那个
> 「已有旧账号？」折叠区（要多点一次才展开）。

**已登录**

- **分享战绩到聊天室**：`share_record`（WS）。⚠️ 分享的是**账号累计战绩**
  （总场次 / 胜 / 负 / 胜率），服务端从库里读 `getRecordStats()` 生成卡片防伪造 ——
  所以入口在身份卡的数据卡下方，**不在对局结算页**（放那儿会让人以为是分享本局）。
  账号页的连接没绑定过对局，必须显式带 `player_token`。
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

**外观**（分组之外，登录与否都可见）

- 主题三态：**跟随系统 / 亮色 / 暗色**，偏好持久化到本机。
- 主题是设备级偏好而非账号偏好，因此没有收进「账号设置」折叠分组——
  否则未登录用户找不到它。
- 原先这个开关是页头右上角的一颗亮/暗按钮，**只会二态翻转**：
  默认「跟随系统」，一旦点过就再也回不到该模式（`setMode(ThemeMode.system)`
  没有入口）。改成面板后三态都能选，页头也因此清爽了。

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
| `.hub-filter`（可选中胶囊） | `DoodleChoiceChip`（玩法筛选 / 外观主题共用） |
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
│   │                             player_message / oauth / turing
│   ├── hub_socket.dart           全站唯一的 WS 连接（在线人数 / 公告 / 对局共用）
│   └── turing/
│       └── turing_client.dart    图灵测试对局状态机（纯逻辑，有单测）
├── data/game_catalog.dart        玩法目录（首页精选与玩法页共用）
├── state/app_state.dart          AppServices / AuthController /
│                                 ThemeController / AppScope
└── ui/
    ├── widgets/                  设计系统组件（见上表）
    │   ├── breakpoints.dart      响应式断点
    │   ├── bottom_nav.dart       底部导航 / 侧边导航栏
    │   ├── sponsor.dart          赞助弹窗（首页票根与关于页共用）
    │   ├── image_viewer.dart     全屏图片查看（收款码）
    │   └── turing/               对局专用：聊天气泡 / 表情选择器
    └── pages/
        ├── app_shell.dart        外壳：导航 + 页面栈
        ├── home_page.dart        首页
        ├── games_page.dart       玩法页（含 openGame 入口分发）
        ├── about_page.dart       关于页
        ├── web_page.dart         内置 WebView（外链统一入口）
        ├── turing/               图灵测试：外壳 + 落地 / 匹配 / 对局 / 结果
        └── account/
            ├── account_page.dart     账号中心外壳（加载 / 未登录 / 已登录）
            ├── account_guest.dart    未登录视图（登录卡两个 tab）
            ├── account_hero.dart     身份卡
            ├── appearance_panel.dart 外观（主题三态，登录与否都可见）
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
| `path_provider` | 导出对局图时写临时 PNG |
| `share_plus` | 导出对局图后调起系统分享面板 |
| `flutter_localizations` | 中文系统控件文案 |

---

## 五、接口对照

| 页面 / 功能 | 接口 |
| --- | --- |
| 邮箱验证码 | `POST /api/email/send-code`（`scene=auth` / `bind_email`） |
| 邮箱登录 / 注册 | `POST /api/email/auth` |
| 账号密码登录 / 找回旧账号 | `GET /api/generate-player-id?action=recover` |
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
| 在线人数 / 公告 / 对局 | `wss://game.xfcode.top/ws`（`online_count` / `broadcast` / `ping`） |
| 图灵测试 · 开局 | `join`（`nickname` / `duration` 300\|600 / `fingerprint` / `player_token`） |
| 图灵测试 · 对局 | `message` / `sticker` / `judge`（`guess` + `tag`）/ `report` / `leave` |
| 图灵测试 · 结束 | `save_history` / `leave_message` |
| 分享累计战绩 | `share_record`（WS，需 `player_token`；服务端读库生成卡片） |
| 图灵测试 · 下发 | `matched` / `message` / `system` / `judge_notify` / `judged` / `timeout` / `sticker` / `save_history_status` / `leave_message_status` / `share_record_status` |

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

共 61 个用例，全部通过：

- `test/unit_test.dart` —— `XqfTime` 时间解析 / 格式化、`XqfPalette` 与 CSS 变量
  一致性、`XqfRadii` 与 `border-radius` 简写的对应关系、`parseApiError` 的
  两套结果约定（`error` / `success:false`）、`MyTags` 解析、`ChatHistoryItem` 标签映射。
- `test/widget_test.dart` —— Widget 冒烟测试：设计系统组件（面板 / 按钮 / 标签 /
  印章 / 点阵纸 / 横格纸 / 虚线）、**全部 52 个线性图标的 SVG 解析**、玩法卡、
  账号中心未登录视图（含登录卡的 tab 切换）、身份卡；以及 App 外壳
  （竖屏底部导航 / 宽屏侧栏）、玩法页、关于页（含「赞助支持」走弹窗而非外链、
  客户端信息里的开发协助模型）、折叠分组、「我的」页未登录时的外观三态切换、
  图灵测试落地页（未登录引导 / 已登录开局）、图灵测试退出路径
  （对局中确认后能真的退出、结果页直接退出）、发送消息后自动收起键盘，
  验证渲染不抛异常且关键文案与结构存在。
- `test/turing_test.dart` —— **图灵测试对局状态机**（不连服务端，
  用 `HubSocket.debugEmit` 把服务端消息喂进解析链路）：判定门槛
  （开局 10 秒 + 自己发过消息）、对方已判定解锁、双方判定后的对错结论、
  聊天时间到只收口输入不产生结果、6 种结束原因的结果文案、
  对手消息入流、未开局时忽略幽灵消息、reset 清空状态、
  封禁（含「无需封禁」不误判）与举报回执、无限时长（`∞` 计时 / 不跑聊天倒计时 /
  判定窗口仍给满 60 秒）、判定区标签默认折叠、关闭举报面板后不抢回输入焦点。

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
