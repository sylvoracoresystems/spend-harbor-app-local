# SpendHarbor Local — UI/UX 设计标准（Design Standards）

> **目的**：本文是 SpendHarbor Local 的设计与实现标准。新功能、新页面、新组件必须遵守本规范，确保产品视觉与交互一致性。
>
> **实现平台**：Flutter（iOS / iPadOS / Android）。所有 widget、theme、token 命名以 Flutter/Dart 为准。
>
> **配套文档**：完整功能描述见 [PRODUCT_SPEC.md](PRODUCT_SPEC.md)。

---

## 目录

1. [设计原则](#1-设计原则)
2. [设计 Token（颜色/字体/尺寸/圆角/阴影）](#2-设计-token)
3. [布局与栅格](#3-布局与栅格)
4. [响应式断点与适配规则](#4-响应式断点与适配规则)
5. [组件规范](#5-组件规范)
6. [交互规范](#6-交互规范)
7. [文案规范](#7-文案规范)
8. [国际化设计要求](#8-国际化设计要求)
9. [可访问性（A11y）](#9-可访问性-a11y)
10. [动效规范](#10-动效规范)
11. [图标与插画规范](#11-图标与插画规范)
12. [反模式（Don't）](#12-反模式)
13. [新功能上线 Checklist](#13-新功能上线-checklist)

---

## 1. 设计原则

### 1.1 核心原则（按优先级）

1. **零摩擦优先**：核心动作（添加交易）≤ 2 次点击可达
2. **真实感数据**：所有空态、loading、错误必须有专属设计；占位内容不能造假
3. **金额永远清晰**：颜色 + 符号双编码，不依赖单一感官
4. **多币种平等**：UI 不假设主币种，按用户实际数据展示
5. **触控与无障碍可达**：所有交互元素均通过 `Semantics` 暴露给读屏；触控目标 ≥ 44pt
6. **离线优雅降级**：本地写入/读取失败显示重试，不卡死

### 1.2 设计哲学

- **少即是多**：不为还没用上的功能预留入口
- **直接编辑优于跳转**：列表项可点击编辑，不跳详情页
- **本地化先于翻译**：先想中文用户怎么用，再做英文版

---

## 2. 设计 Token

设计 Token 是一套**统一命名的数值常量**（颜色、字号、间距、圆角等），所有 widget 必须通过 token 引用，**禁止硬编码字面值**。建议在 `lib/theme/` 下集中定义：

```
lib/theme/
  app_colors.dart      // 颜色 token
  app_spacing.dart     // 间距 token
  app_radius.dart      // 圆角 token
  app_typography.dart  // 字号/字重 token
  app_theme.dart       // 装配为 ThemeData（浅色 + 深色）
```

### 2.1 颜色系统

#### 2.1.1 品牌色（Action / Mint 系）

| Token              | 浅色      | 深色      | 用途                                  |
| ------------------ | --------- | --------- | ------------------------------------- |
| `colorAction`      | `#10b981` | `#10b981` | 主按钮、active tab、FAB、链接         |
| `colorActionHover` | `#059669` | `#34d399` | 按下/高亮态                           |
| `colorActionInk`   | `#064e3b` | `#a7f3d0` | 页面标题、强调文本                    |
| `colorMint`        | `#7ae8a6` | `#34d399` | 装饰主绿（少用）                      |
| `colorMintSoft`    | `#e8fbf1` | `#064e3b` | DayGroup 背景、卡片次背景             |
| `colorMintTint`    | `#cff5dd` | `#065f46` | 边框、分隔线                          |
| `colorBgMint`      | `#f6fbf8` | `#0b1410` | 全局页面背景                          |

#### 2.1.2 业务语义色

| Token              | 浅色      | 深色      | 用途                       | 使用规则        |
| ------------------ | --------- | --------- | -------------------------- | --------------- |
| `colorIncome`      | `#19c17d` | `#34d399` | 收入金额、收入柱、增长指标 | 必须配 `+` 符号 |
| `colorIncomeSoft` | `#dcfce7` | `#064e3b` | 收入背景标签               | —               |
| `colorExpense`     | `#f06262` | `#f87171` | 支出金额、删除按钮、错误   | 必须配 `-` 符号 |
| `colorExpenseSoft` | `#fee2e2` | `#7f1d1d` | 支出背景标签、错误条背景   | —               |

#### 2.1.3 中性色阶

| Token            | 浅色      | 深色      | 用途                       |
| ---------------- | --------- | --------- | -------------------------- |
| `colorTextPrimary` | `#0f172a` | `#e2e8f0` | 主标题极少使用（用 Ink 替代） |
| `colorTextBody`    | `#334155` | `#cbd5e1` | 列表正文、卡片标题         |
| `colorTextMuted`   | `#64748b` | `#94a3b8` | 次要文本（备注、来源、时间）|
| `colorTextHint`    | `#94a3b8` | `#64748b` | placeholder                |
| `colorBorder`      | `#e2e8f0` | `#1e293b` | 默认边框                   |
| `colorBorderSoft`  | `#f1f5f9` | `#0f172a` | 极浅分隔线                 |
| `colorSurfacePress` | `#f1f5f9` | `#1e293b` | 按下/选中态背景            |

#### 2.1.4 数据可视化调色板

- **图表 12 色循环**：定义在 `lib/theme/chart_palette.dart`，所有 Bar/Donut 图表共用
- **分类哈希调色板**（`CATEGORY_PALETTE`）：12 色，按分类 `id` 哈希取色，用于分类圆形图标背景

新增图表必须使用同一套调色板，**禁止自创色**。

#### 2.1.5 主题装配

```dart
final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.bgMint,
  colorScheme: ColorScheme.light(
    primary: AppColors.action,
    onPrimary: Colors.white,
    error: AppColors.expense,
    // ...
  ),
  textTheme: AppTypography.textTheme,
);
```

通过 `Theme.of(context).extension<AppColors>()` 访问扩展 token。

### 2.2 字体

#### 2.2.1 字族

默认使用系统字体（不引入额外 webfont/资源字体）：

- iOS：`SF Pro Text` / `PingFang SC`（自动）
- Android：`Roboto` / `Noto Sans CJK`（自动）

由 Flutter 默认 fallback 链处理中英文混排。

#### 2.2.2 等宽字体

- 用途：所有金额展示（保证小数位对齐）
- iOS：`SF Mono`
- Android：`Roboto Mono`
- Flutter API：`TextStyle(fontFeatures: [FontFeature.tabularFigures()])` 或 `fontFamily: 'monospace'`

#### 2.2.3 字号阶梯

| Token       | 像素 | 行高 | 用途                         |
| ----------- | ---- | ---- | ---------------------------- |
| `textXs`    | 12   | 16   | 备注、来源名、时间戳、徽章   |
| `textSm`    | 14   | 20   | 列表正文、按钮文字、表单输入 |
| `textBase`  | 16   | 24   | 表单输入（首选）、段落       |
| `textLg`    | 18   | 28   | 卡片标题                     |
| `textXl`    | 20   | 28   | 区块标题                     |
| `text2xl`   | 24   | 32   | 指标卡数字、子页面 H2        |
| `text3xl`   | 30   | 36   | 页面 H1                      |

实现：

```dart
class AppTypography {
  static const xs   = TextStyle(fontSize: 12, height: 16/12);
  static const sm   = TextStyle(fontSize: 14, height: 20/14);
  static const base = TextStyle(fontSize: 16, height: 24/16);
  // ...
}
```

#### 2.2.4 字重

| Token         | FontWeight | 用途                           |
| ------------- | ---------- | ------------------------------ |
| `weightNormal`   | `w400` | 正文                           |
| `weightMedium`   | `w500` | 次要强调                       |
| `weightSemibold` | `w600` | 标题、按钮、列表项主名称       |
| `weightBold`     | `w700` | 仅在徽章、净额数字等强对比场景 |

### 2.3 间距系统

基于 **4pt 网格**。所有 `EdgeInsets` 必须取自该网格，禁止 `5`、`13` 等任意值。

```dart
class AppSpacing {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
}
```

#### 2.3.1 内边距标准

| 场景                 | EdgeInsets                                  |
| -------------------- | ------------------------------------------- |
| 紧凑列表项           | `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` |
| 标准卡片             | `EdgeInsets.all(16)` 或 `EdgeInsets.all(24)` |
| 大卡片（Dashboard）  | `EdgeInsets.all(24)`                        |
| 模态框/底部抽屉      | `EdgeInsets.all(24)`                        |
| 输入框               | `EdgeInsets.symmetric(horizontal: 12, vertical: 10)` |
| 按钮（标准）         | `EdgeInsets.symmetric(horizontal: 16, vertical: 10)` |
| 按钮（紧凑）         | `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`  |

#### 2.3.2 间距标准

| 场景             | 数值（pt） |
| ---------------- | ---------- |
| 区块之间垂直间距 | 24         |
| 卡片之间         | 16         |
| 列表项之间       | 8          |
| 网格紧凑         | 12         |
| 网格标准         | 16         |

### 2.4 圆角

| Token          | 像素 | 场景                           |
| -------------- | ---- | ------------------------------ |
| `radiusFull`   | 9999 | 头像、分类图标背景、徽章       |
| `radiusLg`     | 8    | 输入框                         |
| `radiusXl`     | 12   | 标准卡片、按钮                 |
| `radius2xl`    | 16   | 模态框、大卡片、底部抽屉       |

**禁止使用** 4、6 等中间值，保持系统紧凑。

### 2.5 阴影

Flutter 中使用 `BoxShadow`（不要 `Material elevation` 默认值，统一以 token 控制）：

| Token       | BoxShadow                                                         | 用途                  |
| ----------- | ----------------------------------------------------------------- | --------------------- |
| `shadowSm`  | `blurRadius: 2, offset: (0,1), color: black 4%`                   | 静态卡片              |
| `shadowMd`  | `blurRadius: 6, offset: (0,2), color: black 6%`                   | 按下提升、下拉触发    |
| `shadowLg`  | `blurRadius: 16, offset: (0,8), color: black 10%`                 | 模态框、底部抽屉、tooltip |

---

## 3. 布局与栅格

### 3.1 容器最大宽度（用于平板/横屏）

通过 `ConstrainedBox` 限制：

- **主内容区**（Dashboard、Stats、Transactions）：`maxWidth: 1200`
- **设置/管理**：`maxWidth: 1024`
- **表单页**：`maxWidth: 576`（居中）

手机端不需要约束，使用全宽。

### 3.2 主布局结构

- 手机：`Scaffold` + `BottomNavigationBar` + `FloatingActionButton`
- 平板：`Scaffold` 顶部使用 `AppBar` + 自定义水平 tab；可考虑 `NavigationRail` 作为侧栏

#### 3.2.1 内容布局

- 手机：单列堆叠（`Column` + `SingleChildScrollView` 或 `ListView`）
- 平板：根据宽度自适应 1–2 列网格（`GridView` / `LayoutBuilder`）

#### 3.2.2 指标卡布局

- 手机：`GridView.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12)`
- 平板：`crossAxisCount: 4`（通过 `LayoutBuilder` 判断宽度切换）

#### 3.2.3 设置页布局

- 手机：列表导航，进入子页全屏，顶部 `AppBar` 带返回按钮（系统自带）
- 平板：左侧 `NavigationRail` 或自定义 sidebar（260pt）+ 右侧主区

### 3.3 安全区与外边距

- 页面横向 padding：手机 `16`，平板 `24`
- 顶部留白：依赖 `SafeArea`（自动处理刘海/状态栏）
- 底部留白：依赖 `SafeArea` + 额外 `bottom: 96`（留给 FAB + 底部 tab）

### 3.4 根 tab 页统一外壳（Dashboard / Stats / Transactions / Settings）

四个根 tab 必须使用 `RootPageScaffold`（[lib/shared/widgets/root_page_scaffold.dart](../lib/shared/widgets/root_page_scaffold.dart)），保证视觉一致：

| 维度          | 规则                                                                              |
| ------------- | --------------------------------------------------------------------------------- |
| Scaffold 背景 | `c.bgMint`（来自 theme 默认；root tab 不允许覆盖为 `surface`）                    |
| AppBar 背景   | `c.bgMint`（来自 theme），`elevation = 0`，`scrolledUnderElevation = 0`           |
| 标题          | `centerTitle: true`，字号 `AppTypography.lg`，`weightSemibold`                    |
| 二级头        | 走 `pageHeader` slot（filter bar / period segmented），不带额外 padding           |
| 自定义 AppBar | 走 `customAppBar`（如 Transactions 选中模式）                                     |
| 空态          | 用 `RootPageEmpty(text: ...)` 渲染，文案统一 `AppTypography.sm` + `c.textMuted`   |

**页面内容布局两种模式**（写进 PR 描述里说明用哪种）：

- **卡片型**（Dashboard / Stats / Settings）：外层 padding `AppSpacing.x4`（`x3` 仅 Stats 因图表需要更大水平空间），内容由独立 `Container` / 卡片组成；卡片间距 `AppSpacing.x4–x6`；卡片背景 `c.surface`，圆角 `AppRadius.brXl`，`Border.all(color: c.border)`。
- **列表型**（Transactions / Categories / Tags 等管理页）：外层 padding `0`，行级 padding `AppSpacing.x3` 或走 `ListTile` 默认；列表行不带圆角，依赖分组 header（如 `_DayHeader`）切片。

二级头（`pageHeader`）与 body 之间不留额外间距，由 body 顶部 padding 控制。

详情页（带返回按钮）保持 `centerTitle: false`（theme 默认），避免标题与返回箭头视觉冲突。

---

## 4. 响应式断点与适配规则

### 4.1 断点表（基于 `MediaQuery.of(context).size.width`）

| 名称   | 阈值（pt） | 主要受众       |
| ------ | ---------- | -------------- |
| phone  | < 600      | 手机竖屏       |
| phoneL | 600 – 767  | 大手机 / 折叠屏|
| tablet | 768 – 1023 | 平板           |
| tabletL| ≥ 1024     | 平板横屏       |

建议封装一个 `Responsive.of(context)` 工具类：

```dart
enum FormFactor { phone, phoneL, tablet, tabletL }

extension ResponsiveContext on BuildContext {
  FormFactor get formFactor { /* by width */ }
  bool get isTablet => formFactor.index >= FormFactor.tablet.index;
}
```

### 4.2 关键适配规则

#### 4.2.1 导航分界线：768pt

- `< 768`：`BottomNavigationBar` + `FloatingActionButton`
- `≥ 768`：顶部水平菜单 + AppBar 内 "+ Add" 按钮

#### 4.2.2 列表 vs 表格

移动 App 不使用真正的「表格」。即便平板端，多列数据也用 `Card` 列表展示。表格风格仅在「分类管理」「申请审批」此类管理类页面（本 App 已无管理类页面）使用。

#### 4.2.3 字号自适应

- 标题：手机 `text2xl`，平板 `text3xl`
- 金额：始终 `textSm` + 等宽，不随屏幕放大

#### 4.2.4 系统动态字体

必须支持 iOS Dynamic Type / Android Font Scale。Flutter 默认通过 `MediaQuery.textScaleFactor` 处理，**禁止**在 `MaterialApp` 全局锁死字号。

### 4.3 测试要求

新页面必须在以下设备/尺寸测试：

- iPhone SE（375×667，小屏 iOS）
- iPhone 15（393×852，标准 iOS）
- iPhone 15 Pro Max（430×932，大屏 iOS）
- Pixel 7（412×915，标准 Android）
- iPad Mini（744×1133）
- iPad Pro 11"（834×1194）

并在 **深色模式 + 200% 字号** 下回归一次。

---

## 5. 组件规范

> 所有示例为 Flutter widget 伪代码，实际实现可封装为 `AppButton`、`AppTextField` 等通用组件。

### 5.1 按钮

#### 5.1.1 类型

| 类型      | 视觉                                          | 用途                       |
| --------- | --------------------------------------------- | -------------------------- |
| Primary   | 实心 `colorAction` 白字                       | 主操作（保存、提交、确认） |
| Secondary | 边框 + `colorAction` 文字 + 透明底            | 次要操作（取消、返回）     |
| Danger    | 实心 `colorExpense` 白字                      | 删除、重置 App、清空数据   |
| Ghost     | 透明底 + `colorTextBody`，按下 `colorSurfacePress` | 工具栏图标按钮、tab 项 |
| Icon-only | 圆形（`radiusFull`）                          | FAB、关闭按钮              |

#### 5.1.2 尺寸

| 尺寸          | 高度 | 内边距                               | 字号        |
| ------------- | ---- | ------------------------------------ | ----------- |
| Standard      | 40   | `horizontal: 16`                     | `textSm`    |
| Compact       | 32   | `horizontal: 12`                     | `textXs`    |
| Large（极少） | 48   | `horizontal: 24`                     | `textBase`  |

#### 5.1.3 状态

- `enabled`：常规
- `disabled`：透明度 50% + 禁止点击（`onPressed: null`）
- `loading`：禁用 + 文案改 "Saving..." / "Loading..."（**不替换为纯 spinner**）
- `pressed`：使用 `colorActionHover`

#### 5.1.4 一页一个 Primary

每个页面（不含弹出层）最多一个 Primary 按钮，避免视觉竞争。

### 5.2 表单输入

#### 5.2.1 标准 TextField

使用 `TextField` + 自定义 `InputDecoration`：

```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.action, width: 2),
    ),
  ),
)
```

#### 5.2.2 Label 必须可见

- 禁止使用 `hintText` 替代 label
- Label 放在 input 上方，`textXs` + `weightMedium`，颜色 `colorTextBody`
- 必填字段在 label 后加红色 `*`

#### 5.2.3 错误态

- 字段下方红字：`textXs`，颜色 `colorExpense`
- 边框变红 + 文字同时显示（不只换边框，无障碍）
- 通过 `Semantics(label: error, ...)` 暴露给读屏

#### 5.2.4 下拉选择

- 使用 `DropdownButtonFormField`（Material）或 `CupertinoPicker`（iOS 风格）
- App 范围内统一选择一种风格，不混用
- 推荐 Material 风格，跨平台一致

### 5.3 卡片

#### 5.3.1 标准卡片

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
    boxShadow: [AppShadows.sm],
  ),
  padding: EdgeInsets.all(16),
  child: ...,
)
```

#### 5.3.2 强调卡片（选中态）

边框宽度 2pt，颜色 `colorAction`，背景 `colorMintSoft`。

#### 5.3.3 卡片不嵌套卡片

最多 2 层嵌套（外层卡片 + 内部小卡）。如需 3 层，重新设计。

### 5.4 列表

#### 5.4.1 列表项基础

```dart
InkWell(
  onTap: ...,
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      // 图标 / 文字 / 右侧操作，gap = 12
    ]),
  ),
)
```

- 高度由内容决定，不固定
- 项之间使用 `Divider(height: 1, color: AppColors.borderSoft)` 或 8pt 间距

#### 5.4.2 分组标题（DayGroup）

背景 `colorMintSoft`，文字 13pt + `weightSemibold` + `colorActionInk`，内边距水平 16 / 垂直 10。

#### 5.4.3 列表项右侧操作

- 右对齐多行：`Column(crossAxisAlignment: CrossAxisAlignment.end, ...)`
- 间距 `gap: 2`（紧凑）

### 5.5 徽章（Badge）

| 用途                 | 实现                                                                          |
| -------------------- | ----------------------------------------------------------------------------- |
| 标签（彩色背景白字） | `Container` 圆角全圆，水平内边距 10/垂直 2，字号 12 + `weightSemibold`，白字 |
| 计数（如通知数）     | 圆角全圆，背景 `colorExpense`，白字，字号 10                                  |

> 不再有 Premium / Free 等会员徽章。

### 5.6 对话框 / 底部抽屉

#### 5.6.1 触发方式

- 破坏性操作（删除、重置 App、覆盖恢复）→ `showDialog` 二次确认
- 编辑类操作（编辑分类、添加预算）→ 全屏页面或 `showModalBottomSheet`，避免嵌套 dialog

#### 5.6.2 视觉

- 居中 dialog：最大宽度 400pt（手机直接撑满 - 32pt）
- 容器：圆角 16，白底，padding 24，阴影 `shadowLg`
- 遮罩：黑色 50% 透明
- 底部抽屉：顶部圆角 16，下方贴底无圆角

#### 5.6.3 操作按钮位置

底部右对齐（iOS）或全宽分布（Android 风格）；从左到右：[Cancel] [Confirm]，Confirm 必须为最右、最强调色。App 内统一采用「右对齐」风格保持一致。

### 5.7 标签页（Tabs）

使用 Flutter `TabBar` + `TabBarView`，或自定义：

- 底部 active 指示线（不要满底色块）
- 指示线颜色 `colorAction`，宽度 2pt
- active 文字 `colorActionInk` + `weightSemibold`
- inactive 文字 `colorTextMuted`

### 5.8 空态

```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(LucideIcons.inbox, size: 48, color: AppColors.textHint),
      SizedBox(height: 12),
      Text(t('transaction.list.empty'), style: TextStyle(color: AppColors.textMuted)),
      SizedBox(height: 12),
      AppButton.primary(...),
    ],
  ),
)
```

### 5.9 加载状态

- 全页 loading：居中文字 `Loading...`（颜色 `colorTextMuted`）或骨架屏
- 行内 loading：按钮文字改 "Saving..." / "Loading..."
- 骨架屏：使用 `shimmer` 包，背景 `colorBorderSoft → colorBorder`
- **禁止**全屏 `CircularProgressIndicator` 大转圈

### 5.10 错误状态

- 字段级：见 §5.2.3
- 页面级 banner：顶部贴边，背景 `colorExpenseSoft`，文字 `colorExpense`，padding 水平 16 / 垂直 8
- 全页报错：图标 + 文字 + 重试按钮

---

## 6. 交互规范

### 6.1 点击反馈

- 使用 `InkWell` / `Ink` 提供 Material ripple；iOS 风格则用 `CupertinoButton` 或自定义按下透明度变化
- 状态动画时长 150ms

### 6.2 长按

- 长按阈值 **500ms**（通过 `GestureDetector(onLongPress: ...)` 或 `InkWell(onLongPress: ...)`）
- 仅在交易列表页使用，触发批量选择模式
- 长按触发后短暂 haptic feedback（`HapticFeedback.mediumImpact()`）

### 6.3 滚动

- 列表使用 `ListView.builder`（懒加载）；超长列表用 `ListView.separated` 或第三方虚拟化
- 无限滚动：底部接近时（`ScrollController` 监听）请求下一页
- 加载中显示 sentinel 区域（小高度文字 "Loading more..."）
- 下拉刷新：`RefreshIndicator` 包裹（iOS 风格用 `CupertinoSliverRefreshControl`）

### 6.4 表单提交

#### 6.4.1 防止重复提交

按钮在异步操作期间必须 `onPressed: null`（disabled）。

#### 6.4.2 验证时机

- 失焦验证（`onFocusChange` / `TextField.onEditingComplete`）：必填、格式
- 提交验证（`onPressed`）：业务规则、跨字段
- 不在每次 `onChanged` 实时显示错误（打扰）

#### 6.4.3 提交后

- 成功：返回上一页或跳转；成功 toast/snackbar 不超过 1.8s
- 失败：保持表单 + 顶部错误条 + 字段级错误

### 6.5 删除确认

- 单条删除：直接软删，`SnackBar` 提供 "Undo" 5 秒（`SnackBarAction`）
- 批量删除：必须二次确认对话框
- 不可逆操作（重置 App、覆盖恢复）：必须二次确认 + 输入特定文字（如 `DELETE`）才可执行

### 6.6 导航

#### 6.6.1 路由

- 推荐使用 `go_router`（声明式、深链友好）或 `Navigator 2.0`
- 全 App 路径在一个 router 配置中集中维护

#### 6.6.2 返回行为

- 手机端：依赖系统返回手势 + AppBar 自动 back 按钮
- 平板端：保留 AppBar back 或面包屑

#### 6.6.3 表单未保存提示

- 使用 `PopScope`（Flutter 3.12+）/ `WillPopScope` 拦截返回，弹出 "Discard changes?" 对话框

#### 6.6.4 状态保留

- 列表页应保留滚动位置 + 筛选条件
- 在 router 层面将筛选条件序列化到 URL query / 路径参数，便于深链恢复

### 6.7 选择模式

- 长按进入；`AppBar` 切换为「已选 N 条」+ 左上 `Close` 退出
- 退出方式：左上关闭按钮 / 取消所有选中

### 6.8 拖放

- 当前不强制实现拖放
- 后续如需实现（如分类排序），使用 `ReorderableListView`，**必须同时**提供「上移/下移」按钮以便无障碍用户使用

### 6.9 触感反馈（Haptics）

- 长按触发选择模式：`HapticFeedback.mediumImpact()`
- 删除/破坏性操作确认：`HapticFeedback.heavyImpact()`
- 切换 tab / 选中筛选：`HapticFeedback.selectionClick()`
- 表单成功提交：可选 `HapticFeedback.lightImpact()`

---

## 7. 文案规范

### 7.1 语气

- 中文：友好但简洁，不卖萌（不用"哦、哒、嘛"等语气词）
- 英文：直接，主动语态（避免 passive voice）

### 7.2 标点

- 中文：使用全角标点（。，：；！？""）
- 英文：使用半角标点 + 后置空格

### 7.3 数字与货币

- 金额保留 2 位小数（即使为整数）
- 千位分隔符：使用 `Intl.NumberFormat`（依 locale）
- 货币 symbol：使用预定义 symbol 表（如 `CA$`、`US$`、`¥`），非 ISO code（除非空间不够）

### 7.4 错误文案

- 必须告诉用户**做什么**才能解决
- ✅ "Name already exists, try a different one"
- ❌ "Validation error: name conflict"

### 7.5 按钮文案

- 动词开头：Save / Cancel / Delete / Submit
- 中文 2 字优先：保存 / 取消 / 删除 / 提交
- 不用「确定/确认」（含义模糊），用具体动作如「删除/保存」

### 7.6 标题层级

- 页面 H1：唯一一个，描述当前页面（如「分类管理」）
- 区块标题：名词短语（如 "Recent Transactions"）
- 卡片小标题：使用 `weightSemibold` 即可，无需 H 标签

---

## 8. 国际化设计要求

### 8.1 双语完整对等

- 所有用户可见文字必须有 i18n key（推荐 `flutter_localizations` + `intl` + ARB 文件）
- 不允许英文界面残留中文（或反之）
- 默认分类的 `nameKey` 必须在两份 ARB 中都有

### 8.2 文案长度容忍

- 中英文长度差异最大可达 1.5×
- 按钮、列表项必须在 zh-CN 和 en-US 下都不溢出（在 200% 字号下也不能截断关键信息）
- 测试：英文最长字符串、中文最长字符串各跑一遍

### 8.3 切换无重启

- 通过 `Locale` 切换（`MaterialApp.locale` + 顶层状态管理），无需重启 App
- 切换后所有 widget 立即重建

### 8.4 日期与数字

- 日期：使用 `intl` 包 `DateFormat.yMMMd(locale)`
  - en-US：`Apr 26, 2026`
  - zh-CN：`2026年4月26日`
- 数字：金额格式与货币 symbol 保持一致，不切换 symbol

### 8.5 双向文本（RTL）

- 当前不支持 RTL（阿拉伯语、希伯来语）
- 如未来需支持，所有布局必须使用 `EdgeInsetsDirectional` / `AlignmentDirectional`，避免硬编码 `left/right`

---

## 9. 可访问性（A11y）

### 9.1 触控目标尺寸

- 所有可点击元素命中区 ≥ **44×44pt**
- 小图标按钮使用 `IconButton(iconSize: 24, padding: EdgeInsets.all(12))` 保证总尺寸

### 9.2 屏幕阅读器（VoiceOver / TalkBack）

- 纯图标按钮必须 `Semantics(label: '...')` 或 `tooltip:`
- 装饰图标 `ExcludeSemantics` 包裹
- 状态变化（成功提示）使用 `SnackBar` 或 `Semantics(liveRegion: true, ...)`

### 9.3 颜色对比度（WCAG 2.1 AA）

- 正文文字 ≥ 4.5:1
- 大字（≥18pt 或 ≥14pt bold）≥ 3:1
- UI 控件（按钮边框、focus 状态）≥ 3:1

### 9.4 颜色非唯一编码

- 收支：颜色 + 符号（+/-）
- 错误：颜色 + 文案 + 图标
- 状态：颜色 + 文字

### 9.5 表单可访问性

- 每个输入框必须配 label（视觉 + 语义）
- 错误使用 `Semantics(label: errorMessage)` 暴露
- 必填字段使用 `Semantics(label: '$label, required', ...)`

### 9.6 焦点管理

- 对话框打开时焦点移入；关闭时返回触发元素
- 使用 `FocusScope` / `autofocus: true` 管理

### 9.7 减少动效

- 检测 `MediaQuery.of(context).disableAnimations`（系统「减弱动态效果」开启时为 `true`）
- `budgetPulse` 等装饰动画在此开关开启时必须关闭

### 9.8 动态字体

- 不在 `MaterialApp` 全局锁死 `textScaleFactor`
- 在 200% 字号下页面不应破版（关键操作不能被截断）

---

## 10. 动效规范

### 10.1 时长

- 微交互（按下、选中）：150ms
- 状态变化（disabled, selected）：200ms
- 对话框/底部抽屉出入：250ms
- 页面切换：使用平台默认（iOS 滑入 / Android fade）

### 10.2 缓动函数

- 默认：`Curves.easeInOut`
- 进入：`Curves.easeOut`
- 退出：`Curves.easeIn`

### 10.3 项目自定义动画

| 名称          | 用途                | 时长    |
| ------------- | ------------------- | ------- |
| `budgetPulse` | 1.04× 脉动          | 1s 循环 |

> 实现：`AnimationController` + `Tween<double>(begin: 1.0, end: 1.04)`，受 `disableAnimations` 控制。

### 10.4 何时不要动画

- 列表追加（无限滚动）：不要逐项动画，影响性能
- 数字变化：不要 count-up，不必要
- 页面切换：使用 Flutter/平台默认，不自定义

---

## 11. 图标与插画规范

### 11.1 图标库

- **唯一图标库**：`lucide_icons` Flutter 包（或 `flutter_lucide`）
- 禁止混用 `Icons.*`（Material）、`CupertinoIcons.*`、自定义 SVG（品牌 logo 除外）
- 集中维护：`lib/theme/icon_registry.dart`

### 11.2 图标尺寸

| 用途         | 尺寸（pt）                              |
| ------------ | --------------------------------------- |
| 列表项内联   | 16                                      |
| 卡片标题     | 20                                      |
| 分类圆形图标 | 20（容器 40×40 `radiusFull`）           |
| FAB          | 24                                      |
| 空态大图标   | 48                                      |

### 11.3 图标颜色

- 装饰图标：`colorTextHint` 或 `colorTextMuted`
- 强调图标：`colorAction` 或对应业务色
- 分类图标：白色（容器使用 hash 取色）

### 11.4 分类/标签/来源图标白名单

集中维护在 `lib/theme/icon_registry.dart`，约 30 个常见图标。新增分类图标需先在 registry 中注册。

### 11.5 插画

- 当前不使用插画（成本与一致性考量）
- 空态使用图标 + 文字
- 后续如需插画，必须统一风格（线性 / 扁平 / 等距），不混用

### 11.6 App 图标与启动页

- App 图标：1024×1024 主图标 + iOS/Android 各尺寸（使用 `flutter_launcher_icons` 生成）
- 启动页（splash）：纯色背景 `colorBgMint` + 中央 logo，避免长动画（使用 `flutter_native_splash`）

---

## 12. 反模式

以下做法**禁止**，PR 中发现必须修改：

### 12.1 视觉反模式

- ❌ 硬编码颜色（如 `Color(0xFF10B981)` 直接出现在 widget 文件中）—— 必须用 token
- ❌ 任意像素值（如 `EdgeInsets.all(13)`）—— 必须取 4pt 网格
- ❌ 自定义 webfont（增加包体）
- ❌ 渐变色（除非 logo 装饰，避免廉价感）
- ❌ 同页面 > 1 个 Primary 按钮
- ❌ 同时使用 `Icons.*` 和 `LucideIcons.*`

### 12.2 交互反模式

- ❌ 只用颜色区分状态（必须配文字/图标）
- ❌ 使用 `hintText` 替代 label
- ❌ 移除焦点高亮（`FocusableActionDetector` 不配可见样式）
- ❌ 自动播放视频/音频
- ❌ 无 loading 状态的异步操作
- ❌ 无确认的破坏性操作
- ❌ 全屏 `CircularProgressIndicator`

### 12.3 文案反模式

- ❌ "Oops! Something went wrong"（无信息量）
- ❌ "Click here" / "点这里"
- ❌ Lorem ipsum 残留
- ❌ TODO / FIXME 出现在用户可见文案
- ❌ 机翻直译

### 12.4 性能反模式

- ❌ 列表 > 50 项不使用 `ListView.builder`（一次性构建全部子 widget）
- ❌ 在 `build()` 中执行昂贵计算（必须使用 `useMemoized` / `select` / `Provider.select`）
- ❌ 直接 `setState()` 触发顶层重建（限制状态范围或使用 Riverpod/Provider/Bloc）
- ❌ 在数据库主线程上做复杂查询（必须用 isolate 或异步 API）
- ❌ 引入庞大依赖（包体增量 > 1MB 需评审）

### 12.5 国际化反模式

- ❌ 字符串拼接代替 ARB 参数化（如 `"Hello " + name`）
- ❌ 假设语言永远是英文（写 `if (locale == 'en')` 而不写其他分支）
- ❌ 自己实现千位/小数格式（必须用 `intl` 包）

### 12.6 安全/隐私反模式

- ❌ 引入任何分析 / 广告 / 追踪 SDK
- ❌ 发起任何对外网络请求（违反「本地离线」核心定位）
- ❌ 将 PIN / 密码以明文写入 `SharedPreferences`（必须使用 `flutter_secure_storage`）

---

## 13. 新功能上线 Checklist

每个新页面/功能合入 main 前必须勾选：

### 13.1 视觉

- [ ] 所有颜色取自 `AppColors`，无 `Color(0xFF...)` 字面值
- [ ] 所有间距取自 `AppSpacing`（4pt 网格）
- [ ] 所有图标来自 `lucide_icons` 或 `icon_registry`
- [ ] 一页一个 Primary 按钮
- [ ] 卡片嵌套不超过 2 层
- [ ] 字号使用标准阶梯（`AppTypography`）
- [ ] 圆角使用标准等级（`radiusLg / radiusXl / radius2xl / radiusFull`）
- [ ] **深色模式**渲染正常

### 13.2 交互

- [ ] 所有按钮有 enabled/disabled/loading/pressed 状态
- [ ] 所有表单字段有 label 与错误态
- [ ] 破坏性操作有二次确认（且关键操作需输入确认词）
- [ ] Loading 状态使用文字/骨架屏，非全屏 spinner
- [ ] 错误状态告诉用户怎么解决
- [ ] 空态有专属设计
- [ ] 单条删除提供 Undo
- [ ] 关键操作触发恰当 haptic feedback

### 13.3 响应式

- [ ] 在 iPhone SE / iPhone 15 / iPhone Pro Max / Pixel / iPad Mini / iPad Pro 6 个设备测试通过
- [ ] 表格风格在手机端降级为卡片
- [ ] 字号在最小屏幕可读（≥12pt）
- [ ] 触控目标 ≥ 44×44pt

### 13.4 国际化

- [ ] 无硬编码中英文字符串（全部走 ARB）
- [ ] zh-CN 和 en-US 都有完整翻译
- [ ] 文案长度差异不破坏布局
- [ ] 日期/数字使用 `intl` 格式化

### 13.5 可访问性

- [ ] 纯图标按钮有 `Semantics` label
- [ ] 颜色对比度 ≥ AA
- [ ] 状态变化使用 `Semantics(liveRegion: true)` 或 SnackBar
- [ ] 200% 字号下不破版
- [ ] 「减弱动态效果」开启时装饰动画停止

### 13.6 性能

- [ ] 列表使用 `ListView.builder`
- [ ] 大依赖按需 lazy import
- [ ] 数据库读写在异步 API / isolate
- [ ] 无 widget rebuild 风暴（DevTools 检查）

### 13.7 数据 & 隐私

- [ ] 无对外网络请求（用 `flutter_network_logger` 或抓包验证）
- [ ] 无第三方追踪 / 分析 SDK
- [ ] 敏感数据（PIN）走 `flutter_secure_storage`
- [ ] 导入/导出文件经过 schema 版本校验

### 13.8 文档

- [ ] [PRODUCT_SPEC.md](PRODUCT_SPEC.md) 中描述新功能（若是新模块）
- [ ] 本文档（DESIGN_STANDARDS.md）如有新 token / 新组件，同步更新

---

## 附录 A：常用代码片段

> 假设已有 `AppColors`、`AppSpacing`、`AppRadius`、`AppTypography` 等 token 类。

### A.1 标准卡片

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppShadows.sm],
      ),
      child: child,
    );
  }
}
```

### A.2 Primary 按钮

```dart
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const AppPrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.action,
          disabledBackgroundColor: AppColors.action.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: AppTypography.sm.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Text(loading ? AppL10n.of(context).commonSaving : label),
      ),
    );
  }
}
```

### A.3 金额展示

```dart
class AmountText extends StatelessWidget {
  final double amount;
  final String currencySymbol;
  final TransactionType type; // income | expense
  const AmountText({super.key, required this.amount, required this.currencySymbol, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = type == TransactionType.income ? AppColors.income : AppColors.expense;
    final sign = type == TransactionType.expense ? '-' : '';
    return Text(
      '$sign$currencySymbol${amount.toStringAsFixed(2)}',
      style: AppTypography.sm.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
```

### A.4 表单字段（带 label 与错误）

```dart
class AppFormField extends StatelessWidget {
  final String label;
  final bool required;
  final String? error;
  final TextEditingController controller;
  const AppFormField({super.key, required this.label, required this.controller, this.required = false, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTypography.xs.copyWith(color: AppColors.textBody, fontWeight: FontWeight.w500),
            children: [
              if (required) TextSpan(text: ' *', style: TextStyle(color: AppColors.expense)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

**文档版本**：v2.0（2026-05-12，Flutter Local 版重写）
**维护者**：SpendHarbor 团队
**生效范围**：本仓库所有 Flutter 代码
**修订流程**：变更需提 PR review；重大变更须同步更新 [PRODUCT_SPEC.md](PRODUCT_SPEC.md)。
