# XQFGameHub · UI / UX 设计准则

> 适用范围：`XQFGameHub/` 安卓客户端（Flutter）
> 与 [README.md](README.md) 的分工：README 讲**有什么、怎么构建**；本文讲**新页面该怎么写**。
> 最后更新：2026-10-07

---

## 0. 一句话原则

**这是一台街机，不是一个网站，也不是一个通用 App。**

视觉上它必须和网页版是同一台机器（同一套 CSS 变量）；
交互上它必须像个 App（主导航、内置浏览器、返回键符合直觉）；
但**"像正常 App"不是目标**，目标是把网页版那套手绘语言，用手机的操作习惯重新摆一遍。

冲突时的优先级：

```
继承的视觉语言  >  手机操作习惯  >  通用 App 惯例
```

举例：底部导航栏在网页版里没有对应物，属于"手机操作习惯"，
所以自造一个，但**必须用手绘语言画**（虚线分隔 + 便签黄胶囊 + 错位阴影），
不能直接拖一个 Material `NavigationBar` 进来。

---

## 1. 硬约束（继承自 Web 端，改了就跟网页版脱钩）

来源：`对面是AI吗/Public/style.css`、`hub.css`、`account.css`。
Flutter 侧唯一入口：`lib/core/theme/palette.dart`。

### 1.1 颜色

**禁止在业务代码里出现十六进制色值。** 一律 `XqfPalette.of(context).xxx`。

亮色 / 暗色两套值逐条对应 CSS 变量，暗色自动生效，不需要任何 `if (isDark)`。

```dart
// ✅
final XqfPalette p = XqfPalette.of(context);
Container(color: p.noteYellow, ...)

// ❌
Container(color: const Color(0xFFFDF5C9), ...)
```

常用语义（完整表见 `palette.dart`）：

| 变量 | 用途 |
| --- | --- |
| `inkBlack` / `inkBlue` | 墨色描边与正文 / 强调与链接 |
| `paperBg` | 页面底（点阵纸的底色） |
| `noteYellow` `notePink` `noteBlue` `noteGreen` | 便签底色（面板、封面、标签） |
| `surfaceWhite` / `surfaceHeader` | 卡片面 / 页头页脚半透明面 |
| `textSecondary` `textMuted` `textSubtle` `textAa` | 文字四级（由深到浅） |
| `borderLight` / `borderLighter` | 虚线分隔 / 横格纸 |
| `dotColor` | 点阵纸的圆点 |
| `danger` `success` `warn` | 语义色 |
| `shadowSm` `shadowMd` `shadowLg` | 阴影三档 |
| `scrim` | 图片 / 头像上的半透明黑遮罩（`rgba(0,0,0,.45)`） |

便签底色的选择有约定，不是随便挑：

- `noteYellow` —— 表单、可操作区域、强调
- `notePink` —— 身份、危险相关、主推
- `noteBlue` —— 信息、绑定、次要设置
- `noteGreen` —— 成功、外部、成就

### 1.2 圆角

**只有 13 个档位**（11 个椭圆圆角 + 2 个规则圆角），
椭圆档位对应 CSS 的 `a b c d / e f g h`。
禁止自己写 `BorderRadius.circular(N)`。

> 唯一豁免：`arcade_art.dart` 里的 `CustomPainter` 坐标 ——
> 那是**插画**（按 Web 端 SVG 的 240×210 坐标系重绘），不是 UI 外框。

| Flutter | 对应 CSS | 用在哪 |
| --- | --- | --- |
| `XqfRadii.hand` | `255px 15px 225px 15px / 15px 225px 15px 255px` | 大卡、Hero、数据小卡 |
| `XqfRadii.button` | `10px 255px 15px 225px / 255px 15px 225px 15px` | `.doodle-btn` |
| `XqfRadii.panel` | `20px 6px 20px 6px / 6px 20px 6px 20px` | 面板、弹窗 |
| `XqfRadii.chip` | `14px 4px 14px 4px / 4px 14px 4px 14px` | 导航胶囊、筛选、票根条 |
| `XqfRadii.window` | `12px 3px 12px 3px / 3px 12px 3px 12px` | 卡带小窗、小方块 |
| `XqfRadii.input` | `8px 3px 8px 3px / 3px 8px 3px 8px` | 输入框、列表行 |
| `XqfRadii.tag` | `10px 3px 10px 3px / 3px 10px 3px 10px` | 标签、虚线药丸 |
| `XqfRadii.stamp` | `4px` | 印章 |
| `XqfRadii.sheet` | `18px`（仅顶部） | 底部抽屉 |
| `XqfRadii.micro` | `3px` | 审核角标、小药丸、拖拽把手 |
| `XqfRadii.circle` | `999px` | 头像、圆形图标按钮 |
| `XqfRadii.bubbleLeft` | `15px 15px 15px 0` | 对局气泡（对手，缺口左下） |
| `XqfRadii.bubbleRight` | `15px 15px 0 15px` | 对局气泡（自己，缺口右下） |

### 1.3 阴影

**一律是 blurRadius = 0 的错位实心阴影**（`box-shadow: Xpx Ypx 0 var(--shadow-*)`）。
禁止用 Material 的 `elevation`，禁止加模糊。

| Flutter | 偏移 | 颜色 | 用在哪 |
| --- | --- | --- | --- |
| `XqfShadows.panel(p)` | (4, 6) | `shadowMd` | 面板、弹窗 |
| `XqfShadows.card(p)` | (2, 4) | `shadowSm` | 玩法卡、票根条 |
| `XqfShadows.chip(p)` | (2, 2) | `shadowMd` | 胶囊、筛选选中态 |
| `XqfShadows.stat(p)` | (3, 4) | `shadowMd` | 数据小卡 |
| `XqfShadows.window(p)` | (2, 2) | `shadowMd` | 卡带小窗 |
| `XqfShadows.soft(p)` | (3, 5) + blur 10 | `shadowMd` | 例外：便签贴纸感 |

### 1.4 图标

- 全部是 **2.2 描边、圆头圆角的线性 SVG**，`viewBox 0 0 24 24`
- 路径直接复用 Web 端 `style.css` 的 `.icon`，集中在 `lib/ui/widgets/app_icon.dart`
- 通过 `ColorFilter.mode(color, BlendMode.srcIn)` 着色

```dart
AppIcon('user', size: 16, color: p.inkBlue)
```

新增图标：从 Web 端 SVG 里**原样拷贝路径**（含 `fill="#000"` 的实心部分），
加进 `AppIcons.all`。**不要自己画一套风格不一致的图标。**

### 1.5 字体

- 全站等宽：`XqfTheme.monoFont = 'monospace'`
- Web 端字体栈是 `Menlo, Consolas, Monaco, Liberation Mono, ui-monospace`，
  Android 上映射到系统 monospace，中文由系统 CJK 字体回退 —— 与浏览器表现一致
- 字距是设计的一部分：区块标题 `letterSpacing: 3`，走马灯 `2`，标签 `1`

### 1.6 禁止项

Web 端 CSS 注释里写死的三条，**在 App 里同样成立**：

> 禁止 emoji / 渐变 / 玻璃拟态

补充（本项目额外约定）：

- ❌ 十六进制色值
- ❌ Material 默认组件直接上屏（`NavigationBar`、`Card`、`FilledButton`、`TextButton`…）——
  要用就得先按手绘语言重画
- ❌ `elevation` / `Material` 阴影
- ❌ 圆角、阴影、颜色的"临时值"
- ✅ 例外 1：`CircularProgressIndicator` / `LinearProgressIndicator`（进度指示无对应物）
- ✅ 例外 2：`Dialog` / `SnackBar` 上显式写 `elevation: 0` ——
  这是**关掉** Material 自带的模糊阴影，好让手绘的错位实心阴影露出来

**自查命令**（提交前跑一下，四条都应该只剩上面的豁免）：

```bash
# 1) 不该有 Material 图标 / 组件
#    注意用 -P 加负向断言，否则 LinkTextButton 会被 TextButton 误伤
grep -rnP "(?<![A-Za-z])(Icons\.|TextButton|FilledButton|ElevatedButton|NavigationBar|OutlinedButton)" \
  lib --include="*.dart" | grep -v "app_icon.dart"

# 2) 不该有硬编码色值
grep -rn "Color(0x" lib --include="*.dart" | grep -v "core/theme/palette.dart"

# 3) 不该有临时圆角（arcade_art 是插画，豁免）
grep -rn "BorderRadius.circular\|Radius.circular" lib --include="*.dart" \
  | grep -v "core/theme/palette.dart" | grep -v "arcade_art.dart"

# 4) 不该有 Material 阴影
grep -rn "elevation: [1-9]" lib --include="*.dart"
```

---

## 2. 自定约定（这些是我拍的，可以推翻，但推翻要同步改本文档）

### 2.1 响应式

**不锁定屏幕方向**，横竖屏自由旋转，靠断点自适应。

| 断点 | 值 | 行为 |
| --- | --- | --- |
| 导航切换 | **720dp** | ≥ 720 用左侧导航栏（`XqfNavRail`），否则底部导航（`XqfBottomBar`） |
| 面板两栏 | **840dp** | 账号页面板 ≥ 840 变两栏，否则单列 |
| 内容最大宽 | 960 / 1040 | 超宽屏居中，避免一行拉到天边 |

网格列数（`XqfBreakpoints.columns`）：

| 宽度 | 列数 |
| --- | --- |
| < 600 | 2 |
| 600–899 | 3 |
| ≥ 900 | 4 |

横屏时底部栏会挤占本就紧张的高度，所以**横屏优先侧栏**。

### 2.2 导航模型

```
AppShell（Scaffold + 导航）
├── 首页   —— 启动器：品牌 + 主推 + 精选玩法 + 服务
├── 玩法   —— 完整目录 + 分类筛选
└── 我的   —— 账号中心
```

- **一级**：三个页签，`IndexedStack` 惰性保活（没访问过的不实例化，避免启动就发请求）
- **二级**：`Navigator.push` 全屏路由（关于页、内置浏览器、图片查看）
- **返回键**：不在首页时先回首页；在网页里先在网页历史里后退；退到底才关页面

信息架构的边界要守住：**首页不重复玩法页的全部内容**（只放 4 张精选 + 「全部玩法 →」），
**玩法页不放账号入口**。

### 2.3 外链与媒体

**外链一律内置 WebView，不甩给系统浏览器。**

```dart
openInAppWeb(context, url: '...', title: '...');   // lib/ui/pages/web_page.dart
showInAppImage(context, url: '...', title: '...'); // lib/ui/widgets/image_viewer.dart
```

内置浏览器的必备行为（已实现，新页面复用即可）：

- 顶部进度条，加载中才显示
- 站内跳转不出 App（`onNavigationRequest` 一律 `navigate`）
- 返回键先在网页历史里后退
- 加载失败有重试页，不是白屏
- 右上角保留「用浏览器打开」兜底

`url_launcher` 只作为兜底存在，**业务代码不应直接调用**（当前仅 3 处，
全在 `web_page.dart` / `image_viewer.dart` 内部）。

### 2.4 折叠与信息密度

- 手机上**一屏滚不到底的页面要分组折叠**。账号页 7 个面板收进
  「内容管理」「账号设置」两组，**默认收起**
- 但**设备级偏好不进折叠分组**：「外观」（主题）与「关于」入口放在分组之外，
  保证未登录时也看得到 —— 折叠分组只在登录后才渲染
- 同一件事的**多种做法**用胶囊 tab 切换，不要堆成多张卡片、也不要塞进折叠区：
  多张卡要滚动才能看全，折叠区要多点一次才展开。已用于登录卡的
  「邮箱验证码 / 账号密码」（`DoodleChoiceChip`，形态同 Web 端 `.acc-sticker-tab`）
- 页头固定不滚（`Column[AppHeader, Expanded(scroll)]`），内容区滚动
- 网页式元素（备案号、协议入口、版权）**不进主滚动流**，收进「关于」页

### 2.5 反馈

**禁止静默失败。**

```dart
try {
  await api.doSomething();
  showTopToast(context, '已保存');
} on ApiException catch (e) {
  if (mounted) showTopToast(context, e.message, isError: true);
}
```

- 顶部提示条 `showTopToast(context, msg, isError: bool)`
- 危险操作前 `showDoodleConfirm(...)`
- 后端有三套失败形态（`error` / `ok:false` / `success:false`），
  已由 `parseApiError` 统一，**不要在业务层自己判断**

占位内容要诚实：未接入的玩法提示「将在后续版本接入」，**不要假装能用**。

### 2.6 动效

现状：`AnimatedContainer` / `AnimatedScale` / `AnimatedRotation` + `SizeTransition`。

| 场景 | 时长 | 曲线 |
| --- | --- | --- |
| 按钮按下反馈 | 110–120ms | 默认 |
| 状态切换（选中、配色） | 150–200ms | `easeOutCubic` |
| 折叠展开 | 200ms | `easeOutCubic` |
| 提示条进出 | 220ms | `easeOutCubic` |

原则：**动效只做状态反馈，不做装饰**。网页版里的旋转（`rotate(-2deg)`）
在手机上改成按下缩放，因为触摸没有 hover。

### 2.7 间距与字号（⚠️ 待收敛，尚未执行）

现状是散的。统计结果：

- 间距用了 `2 3 4 5 6 7 8 9 10 12 14 16 18 22 24 26 28 34`（18 种）
- 字号用了 `9 10 11 12 13 14 15 16 17 18 19 21 22 26`（14 种）

**建议收敛到（新代码请直接用这套）：**

间距 —— 7 档，`4` 的倍数为主：

| 档 | 值 | 用途 |
| --- | --- | --- |
| xxs | 4 | 图标与文字之间 |
| xs | 8 | 同组元素之间 |
| sm | 12 | 列表行内 |
| md | 16 | 页面左右边距、卡片之间 |
| lg | 22 | 面板之间 |
| xl | 28 | 区块之间 |
| xxl | 34 | 大区块之间 |

> `6 / 10 / 14 / 18` 是当前代码里的过渡值，**新代码不再使用**。
> 存量不强制改（改动面约 150 处），等某天顺手统一。

字号 —— 8 档：

| 档 | 值 | 用途 |
| --- | --- | --- |
| 标注 | 10 | 印章、角标 |
| 辅助 | 11 | 元信息、附注、导航标签 |
| 次要 | 12 | 说明文字、次要按钮 |
| 正文 | 13 | 主体文案 |
| 强调正文 | 14 | 输入框、主按钮 |
| 小标题 | 16 | 卡片标题 |
| 组标题 | 19 | 分组标题 |
| 大标题 | 22 | 面板主标题 |
| 品牌 | 26–42 | Hero 大字（按屏宽缩放） |

### 2.8 外观与主题

主题切换**不在页头**，统一收在「我的 → 外观」面板（`AppearancePanel`）。

| 项 | 约定 |
| --- | --- |
| 位置 | 「我的」页，「内容管理 / 账号设置」折叠分组**之外**，与「关于」入口并列 |
| 为什么在外面 | 主题是**设备级偏好**，不是账号偏好；分组只在登录后渲染，放进去未登录就找不到 |
| 三态 | 跟随系统 / 亮色 / 暗色（`ThemeMode.system` 必须可达） |
| 控件 | `DoodleChoiceChip`（与玩法页分类筛选同一形态），**纯文字，不用图标** |
| 持久化 | `ThemeController` → `AppPrefs`，仅本机 |

两条容易踩的：

1. **不要退回二态翻转。** `ThemeController` 一直支持 `ThemeMode.system`，
   但早期页头那颗按钮只写 `light` / `dark`，导致「跟随系统」一旦离开就回不去。
2. **不要在页头重新加按钮。** 那会让 `AppShell` 重新把 `onToggleTheme` /
   `isDark` 下发给每个页面（曾经 3 个页面、6 个构造参数只为了一颗按钮），
   而且每个页签都要重复渲染同一个控件。

> `AppearancePanel` 内部用 `ListenableBuilder` 显式监听 `ThemeController`：
> `AppScope` 只在实例变化时通知，主题模式切换不会触发它。

### 2.9 玩法内页（对局界面）

> 这一节原先在「未定项」里挂着「完全空白」。图灵测试落地时定了第一版，
> 后续玩法（海龟汤 / 棋类 / 聊天室）沿用同一套骨架。

**骨架**：`AppHeader` 固定不滚 + 一个按阶段切换的内容区，
外层是 `DotGridBackground`。阶段的枚举与 UI 一一对应：

| 阶段 | 视图 | 对应 Web 端 |
| --- | --- | --- |
| `landing` | `TuringLandingView` | `#landing-page` |
| `matching` | `TuringMatchingView` | `#matching-page` |
| `chatting` / `waitingOpponent` | `TuringChatView` | `#chat-page` |
| `finished` | `TuringResultView` | `#result-area` |

**全出血，不套卡片。** Web 端是「居中卡片 + 2px 边框 + 阴影 + 限宽 900」，
那是桌面版式 —— 手机上边框和留白会吃掉本就不宽的可视区。
这里只保留四段：**细对手条 / 聊天区 / 判定区 / 输入区**，
宽屏（平板、横屏）才限宽 720 居中，且只限宽、不画框。

**聊天区** —— `RuledPaper(lineHeight: 30, lineColor: chatGrid)` 铺横格纸，占满剩余空间；
气泡左黄右蓝、2px 墨色描边、`XqfRadii.bubbleLeft` / `bubbleRight`、最大宽度 70%；
系统提示居中斜体，需要醒目时（判定通知）用 `danger` 色加粗。
对手信息压成顶部一条细条（连接点 + `对手 ???` + 高亮计时 + 举报），
不照搬 Web 端那个大块 `.chat-header`。

**判定区** —— 深色底 `judgeBg` + 白色文字，两个描边按钮（人类 / AI）。
放在**输入框上方**：Web 端把它压在输入框下面，手机上键盘一弹就被顶掉。
未解锁时只占一条提示的高度，解锁后用 `AnimatedSize`（200ms easeOutCubic）
展开出按钮 —— 这是状态反馈，不是装饰。
**标签默认折叠**成一行小字（`贴个标签（可选）`）：它是可选的次要输入，
常驻会把主要动作（两个判定按钮）往下挤。
判定门槛的文案由客户端算：「开局 10 秒后 / 你发送一条消息 即可判定」。

**键盘与焦点** —— 发送后主动 `unfocus()` 收起键盘：发完一条要等对方回应，
键盘留着会挡住聊天区。

> ⚠️ 底部面板（表情 / 举报）**关闭后要再收一次焦点**。
> `ModalRoute` 在 pop 时会把焦点还给打开前的那个节点（恢复自己的
> `_focusedChild`），打开前那次 `unfocus()` 挡不住 —— 它只是把焦点移到
> scope 上，`_focusedChild` 仍指着输入框，于是面板一关键盘就弹回来。
> 且恢复发生在 pop 之后（可能晚一帧），所以要用 `addPostFrameCallback` 再收。

**结果页** —— 图标 + 结论 + 揭示 + 六项数据（你的判断 / 对方身份 / 对方标签 /
对方猜你是 / 对话条数 / 用时），次要操作收进可折叠的「更多操作」。

三条硬约束：

1. **对局必须复用全局唯一的 WS 连接**（`HubSocket`）。服务端同 IP 全站只保留
   一条连接（last-wins，跨入口共享），自己再开一条会互相踢成无限重连。
2. **不自己画状态机之外的 UI**：判定门槛、超时文案、时间到收口都放
   `TuringClient`，视图只读状态、不做业务判断（便于单测，见
   `test/turing_test.dart`）。
3. **对手昵称在对局中显示为 `???`**，结果页才揭晓 —— 这是玩法本身的信息设计，
   不是占位符。

---

## 3. 未定项（真正的空白，别假装有规范）

| 项 | 状态 |
| --- | --- |
| **横屏下玩法内页怎么排** | 图灵测试是聊天流，横竖屏都自适应、**不锁方向**；棋类（五子棋/围棋）横屏更合适，但**还没做，也没定** |
| **空态 / 错误态 / 加载态的使用规则** | 组件都有（`EmptyTip` / `_WebError` / `LoadingBlock`），但"什么情况用哪种"没规则 |
| **文案语气** | toast 偏口语（「将在后续版本接入，敬请期待」），没统一约定 |
| **无障碍** | 语义标签只在底部导航加了一处，对比度没验过 |
| **间距/字号收敛** | 见 2.7，只有建议没有执行 |

---

## 4. 新页面接入 checklist

写新页面前过一遍：

**结构**

- [ ] 是页签还是一级页面？页签 → 加进 `AppShell._items`；二级 → `Navigator.push`
- [ ] 页头用 `AppHeader`，固定不滚
- [ ] 内容区包 `SingleChildScrollView` + `Center` + `ConstrainedBox(maxWidth: XqfBreakpoints.contentMaxWidth(...))`
- [ ] **不要在页头加主题切换按钮**：主题统一在「我的 → 外观」面板，三态切换，见 2.8
- [ ] 长页面考虑分组折叠

**视觉**

- [ ] 颜色全部走 `XqfPalette.of(context)`，没有十六进制
- [ ] 圆角只用 `XqfRadii.*`，阴影只用 `XqfShadows.*`
- [ ] 图标用 `AppIcon`，路径来自 Web 端
- [ ] 面板用 `DoodlePanel` + 合适的 `NoteTone`
- [ ] 按钮用 `DoodleButton` / `LinkTextButton`
- [ ] 区块标题用 `SectionHead`，分组标题用 `CollapsibleGroup`
- [ ] 分隔用 `DashedDivider` / `DashedBorder`，不要实线

**交互**

- [ ] 外链走 `openInAppWeb`，图片走 `showInAppImage`
- [ ] 网络失败有 `showTopToast(isError: true)`，不静默
- [ ] 危险操作有 `showDoodleConfirm`
- [ ] 异步回调后访问 `context` 前检查 `mounted`
- [ ] 横竖屏都试一遍（旋转模拟器）

**验证**

- [ ] `dart analyze` 无 issue
- [ ] `flutter test` 通过，新页面加冒烟测试（渲染不抛异常 + 关键文案存在）
- [ ] `tools/build_android.sh release` 能出包

---

## 附：改这份文档的时机

出现下面任一情况，**当场改本文档**，不要只改代码：

1. 引入了新的圆角 / 阴影 / 颜色档位 → 改第 1 节
2. 推翻了某个自定约定（断点、导航模型…） → 改第 2 节
3. 填上了某个"未定项" → 从第 3 节移进第 2 节
4. 间距/字号收敛执行了 → 删掉 2.7 的"待收敛"标记
