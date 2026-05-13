# SpendHarbor Local — 开发进度（Progress）

> 滚动开发日志。按阶段勾选完成项，记录里程碑、阻塞与决策变更。**每完成一个 Step 更新一次**。
>
> 配套文档：[PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DESIGN_STANDARDS.md](DESIGN_STANDARDS.md) · [TECH_STACK.md](TECH_STACK.md)

---

## 当前状态

- **当前阶段**：Phase 2 — 核心交易链路 MVP
- **当前 Step**：2.1 数据访问基础 ✅；准备进入 2.2 交易表单
- **最近更新**：2026-05-13

---

## Current Work（细粒度进度，新会话先读这一段）

> 这一段记录**当前 Step 内的子任务进度**。每完成一个子项立即勾选；context 即将用尽或用户说「checkpoint」时同步更新。新会话可直接从「下一步接入点」继续。

**当前 Step**：Phase 2 · 2.1 — 数据访问基础 ✅

**子任务**：

- [x] `lib/data/database/app_database_provider.dart`：`appDatabaseProvider` + 5 个 DAO provider + 3 个 stream provider
- [x] `lib/data/seed/seed_locale_from_platform.dart`：平台 locale → SeedLocale
- [x] `main.dart`：启动时创建 DB + 跑 seed（按平台 locale）+ 覆盖 provider
- [x] `widget_test` 适配 DB override；`app_database_provider_test`（3 tests）
- [x] `flutter analyze` + `flutter test` 通过（16 tests）

**下一步接入点**：2.2 交易表单 — 在 `lib/features/transactions/application/` 下建 `transaction_form_controller.dart`（Riverpod `StateNotifier<TransactionFormState>`），`presentation/transaction_form.dart` 替换占位的 `TransactionEditPage`。字段：金额（minor units 输入）、币种（从来源派生）、类型（segmented）、分类（按 type 过滤）、来源（来源决定币种）、日期（默认今天）、标签（多选）、备注。

**已完成 Step 5**：



**子任务**：

- [x] `lib/shared/router/app_router.dart`：go_router + StatefulShellRoute（4 tab）+ 全部 §3.1 路由
- [x] `lib/shared/router/app_shell.dart`：移动端 NavigationBar / 平板 NavigationRail（768pt 断点）
- [x] FAB（设置页隐藏）→ `/transactions/new`
- [x] 占位页：Dashboard / Stats / Transactions / Settings（列表导航到子设置）/ TransactionEdit / Onboarding
- [x] `shared/widgets/placeholder_page.dart` 统一占位样式
- [x] `shared/providers/onboarding_provider.dart`：首次启动标记 + 持久化
- [x] go_router `redirect` 实现 onboarding 流程；`refreshListenable` 桥接 Riverpod
- [x] `app.dart` 切换为 `MaterialApp.router`
- [x] `widget_test` 验证 onboarding 重定向 + 主框架渲染
- [x] `flutter analyze` + `flutter test` 通过（13 tests）

**下一步接入点**：Phase 2 — 在 `lib/features/transactions/` 下实现交易表单（`TransactionEditPage` 替换占位），先建 `application/transaction_form_controller.dart`（Riverpod 状态）与 `presentation/transaction_form.dart`（UI）。

**未提交改动**：Step 5 全部改动均未 commit

**已知阻塞**：无

---

## Phase 1 — 脚手架（Scaffolding）

目标：搭好可运行、可测试、文档齐备的工程骨架，为业务开发铺路。

### Step 1：依赖与目录骨架 ✅

- [x] `pubspec.yaml` 加入核心依赖（riverpod / go_router / drift / intl / lucide_icons / secure_storage / local_auth 等）
- [x] 建立 `lib/` 三层目录（`data` / `domain` / `features` / `shared` / `theme` / `l10n`）
- [x] `main.dart` 切换为 `ProviderScope` + `SpendHarborApp` 占位
- [x] `app.dart` 创建占位 `MaterialApp`
- [x] `test/` 目录镜像 `lib/`
- [x] 编写 `docs/TECH_STACK.md`
- [x] 编写 `docs/PROGRESS.md`（本文）
- [x] `flutter pub get` 验证通过
- [x] `flutter analyze` 0 issues
- [x] `flutter test` 占位 widget 测试通过

### Step 2：设计 token 落地 ✅

- [x] `lib/theme/app_colors.dart`：颜色 token（浅色 + 深色，ThemeExtension）
- [x] `lib/theme/app_spacing.dart`：4pt 网格 + 常用 EdgeInsets 预设
- [x] `lib/theme/app_radius.dart`：圆角常量 + BorderRadius 预设
- [x] `lib/theme/app_typography.dart`：字号阶梯 + 字重 + 等宽 + TextTheme builder
- [x] `lib/theme/app_shadows.dart`：BoxShadow 预设（sm/md/lg）
- [x] `lib/theme/app_theme.dart`：装配 `lightTheme` + `darkTheme`，统一 AppBar/Input/Button/Dialog/Snackbar 风格
- [x] `app.dart` 接入 theme + 临时 Theme Preview 页（含浅/深模式切换按钮）

### Step 3：数据库 Schema + Seed ✅

- [x] drift 数据库 + 5 张表（Category / Tag / Source / Budget / Transaction）
- [x] 多对多表（TransactionTags）
- [x] 软删除字段 + 索引
- [x] 首次启动 seed 默认分类 / 标签 / 来源（按 locale 中英两版）
- [x] `test/data/` 写 DAO 单元测试
- [x] 配置 build_runner，生成 `*.g.dart`

### Step 4：i18n 基础 ✅

- [x] `flutter_localizations` + ARB 文件（en-US / zh-CN）
- [x] `app.dart` 接入 `supportedLocales` + `localizationsDelegates`
- [x] 语言切换的 Riverpod provider + 本地持久化
- [x] 默认分类 `nameKey` ↔ ARB 接通

### Step 5：路由与主框架 ✅

- [x] go_router 配置（按 PRODUCT_SPEC §3.1 路由表）
- [x] `Scaffold` + 底部 4 tab（Dashboard / Stats / Transactions / Settings）
- [x] FAB 占位 → 跳新建交易
- [x] 平板布局：宽度 ≥ 768pt 切换为 NavigationRail（`LayoutBuilder`）
- [x] Onboarding 首次启动判断（读取本地标记）

---

## Phase 2 — 核心交易链路 MVP

目标：新建交易 → 交易列表 → Dashboard 闭环可用。

- [ ] 交易表单（`/transactions/new` 与 `/edit`）：字段、验证、提交
- [ ] 交易列表（`/transactions`）：DayGroup 分组、无限滚动、月份切换
- [ ] 长按进入选择模式 + 批量删除
- [ ] Dashboard：4 张指标卡 + 近期交易
- [ ] 回收站（30 天）

---

## Phase 3 — Taxonomy 与预算

- [ ] 分类管理 CRUD + 同名去重
- [ ] 标签管理 CRUD
- [ ] 来源管理 CRUD（带币种）
- [ ] 预算管理 CRUD + 周期对齐
- [ ] Dashboard 接入预算块

---

## Phase 4 — 统计分析

- [ ] 趋势图（Bar Chart）
- [ ] 分类 / 标签 Donut
- [ ] Top 排行
- [ ] 点击图表跳转交易列表（带筛选）

---

## Phase 5 — 导入 / 导出 / 备份

- [ ] Excel / CSV 导出 → 系统分享面板
- [ ] 数据导入（含冲突合并策略）
- [ ] 一键备份 / 恢复 `.shbak`
- [ ] 备份提醒

---

## Phase 6 — 设置与体验

- [ ] 个人偏好（昵称、头像）
- [ ] 默认货币、语言、外观主题
- [ ] 应用锁（PIN + 生物识别）
- [ ] 关于页、法律页
- [ ] 触感反馈（HapticFeedback）接入

---

## Phase 7 — 打磨与上架

- [ ] App 图标 + 启动页
- [ ] 国际化全量回归（中英 + 200% 字号 + 深色）
- [ ] 多设备 viewport 回归
- [ ] 性能基准（冷启动、Stats 聚合）
- [ ] 隐私清单（Apple Privacy Manifest / Google Data Safety）
- [ ] 应用商店素材（截图、描述）
- [ ] 上架审核

---

## 决策与变更日志

| 日期       | 事项                                              | 备注                                             |
| ---------- | ------------------------------------------------- | ------------------------------------------------ |
| 2026-05-12 | 产品定位调整：移除登录/会员/Admin，全功能终身可用 | 重写 PRODUCT_SPEC v2.0                           |
| 2026-05-12 | 实现平台选定：Flutter（iOS + Android）            | 暂不发布 Web / 桌面端                            |
| 2026-05-12 | DESIGN_STANDARDS 重写为 Flutter 版                | v2.0                                             |
| 2026-05-12 | 完成 Step 1：依赖与目录骨架                       | 新增 TECH_STACK.md / PROGRESS.md                 |
| 2026-05-12 | 完成 Step 2：设计 token 落地                      | `lib/theme/` 6 文件，浅/深主题 + Theme Preview 页 |
| 2026-05-13 | 完成 Step 3：数据库 Schema + Seed                | drift 5 表 + 多对多 + 5 DAO + 中英 seed + 7 单测   |
| 2026-05-13 | 完成 Step 4：i18n 基础                            | en/zh ARB + localeController + nameKey resolver + 12 单测 |
| 2026-05-13 | 完成 Step 5：路由与主框架（Phase 1 收尾）         | go_router StatefulShellRoute + 移动/平板自适应 + onboarding |
| 2026-05-13 | 完成 Phase 2 · 2.1：数据访问基础                  | appDatabaseProvider + DAO/stream providers + 启动 seed     |

---

## 阻塞与待决问题

_无_

---

**维护者**：SpendHarbor 团队
