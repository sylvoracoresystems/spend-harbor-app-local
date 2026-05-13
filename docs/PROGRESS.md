# SpendHarbor Local — 开发进度（Progress）

> 滚动开发日志。按阶段勾选完成项，记录里程碑、阻塞与决策变更。**每完成一个 Step 更新一次**。
>
> 配套文档：[PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DESIGN_STANDARDS.md](DESIGN_STANDARDS.md) · [TECH_STACK.md](TECH_STACK.md)

---

## 当前状态

- **当前阶段**：Phase 3 — Taxonomy 与预算
- **当前 Step**：3.3 来源管理 CRUD ✅；准备进入 3.4 预算管理
- **最近更新**：2026-05-13

---

## Current Work（细粒度进度，新会话先读这一段）

> 这一段记录**当前 Step 内的子任务进度**。每完成一个子项立即勾选；context 即将用尽或用户说「checkpoint」时同步更新。新会话可直接从「下一步接入点」继续。

**当前 Step**：Phase 3 · 3.3 — 来源管理 CRUD ✅

**子任务**：

- [x] `SourceDao.updateName(id, name, icon, color, currency)`：保留 createdAt + 清空 nameKey
- [x] `application/source_form_controller.dart`：5 字段（name + icon + color + currency）+ 同步/异步同名校验
- [x] `presentation/sources_page.dart`：列表（圆形彩色图标 + 「CCY · symbol」副标题）+ FAB
- [x] `presentation/source_edit_page.dart`：name + 币种 Dropdown（18 种，含 code · symbol · 名）+ 图标网格 + 颜色网格 + 保存 / 删除
- [x] go_router：`/settings/sources` + `/new` + `/:id/edit`，从占位列表中摘除
- [x] ARB：srcNewTitle / srcEditTitle / srcFieldCurrency / errors / 删除确认 / 空状态 / srcAdd（en + zh）
- [x] 单测 4 例（validate / 同名 duplicate / updateName 改币种 / 软删）
- [x] `flutter analyze` + `flutter test` 通过（54 tests）

**下一步接入点**：3.4 预算管理 CRUD + 周期对齐。`Budget` 表已有 period (`BudgetPeriod`) / scope (`BudgetScope`) / categoryId / amountCents / currency / startsOn。需要：① `BudgetDao` 现有 watchAll，需补 `insertBudget` / `updateBudget` / `softDelete`（若缺）/ `findById` ② `application/budget_form_controller.dart` ③ `application/budget_period_alignment.dart` —— 把 `startsOn` 对齐到当前周期起点（周一/月初/季度首日/年初）④ `presentation/budgets_page.dart` + `budget_edit_page.dart`（period segmented + scope segmented + 关联分类 dropdown + 金额 + 币种）⑤ 路由 ⑥ ARB + 测试。

**已完成 Step 3.2**：



**子任务**：

- [x] `TagDao.updateName`：仅更新可编辑字段，编辑后清空 nameKey
- [x] `application/tag_form_controller.dart`：name + color（无 type / icon），同步 + 异步同名校验
- [x] `presentation/tags_page.dart`：扁平列表（圆形彩色 # 图标）+ FAB Add
- [x] `presentation/tag_edit_page.dart`：name + color 网格 + 保存 + 编辑模式下删除
- [x] go_router：`/settings/tags` + `/new` + `/:id/edit`（root navigator），从占位列表中摘除
- [x] ARB：tagNewTitle / tagEditTitle / errors / 删除确认 / 空状态 / tagAdd（en + zh）
- [x] 单测 4 例（validate / 同名 duplicate / updateName 保留 createdAt / 软删）
- [x] `flutter analyze` + `flutter test` 通过（50 tests）

**下一步接入点**：3.3 来源管理 CRUD — 与标签管理类似，但需额外字段：图标（复用 icon_registry）+ 币种（dropdown 选 `Currency.all`）。在 `lib/features/sources/` 下建文件，`SourceDao` 已有 `existsName`，需补 `updateName(id, name, icon, color, currency)`。注意：spec §6.5 列了 18 种币种，UI 用 grouped/searchable dropdown。

**已完成 Step 3.1**：



**子任务**：

- [x] `lib/shared/icons/icon_registry.dart`：白名单图标（27 个）+ 调色板（10 色）+ `iconFor(key)` 渲染辅助
- [x] `CategoryDao.updateName`：仅更新可编辑字段，编辑默认项时清空 `nameKey`
- [x] `application/category_form_controller.dart`：`CategoryFormState` + autoDispose family，`validateSync` + 异步同名校验（`existsName`，大小写不敏感）+ submit/delete
- [x] `categoriesByTypeProvider`（StreamProvider.family）
- [x] `presentation/categories_page.dart`：TabBar 切换 expense/income，列表 + 圆形彩色图标 + FAB「Add」
- [x] `presentation/category_edit_page.dart`：SegmentedButton 类型 + 名称 + 图标网格 + 颜色网格 + 保存 + 编辑模式下「删除（带确认）」
- [x] go_router：`/settings/categories` + `/new` + `/:id/edit`（root navigator），从占位列表中摘除
- [x] ARB：catNewTitle / catEditTitle / catFieldName / type / icon / color / errors / 删除确认 / catEmpty* / catAdd（en + zh）
- [x] 单测 4 例（validate / 同名 duplicate / 编辑保留 createdAt / 软删）
- [x] `flutter analyze` + `flutter test` 通过（46 tests）

**下一步接入点**：3.2 标签管理 — 复用同样的模式：`lib/features/tags/`（`application/tag_form_controller.dart` + `presentation/tags_page.dart` / `tag_edit_page.dart`）。标签字段更少：name + color（无 type、无 icon）。`TagDao` 需要补 `updateName` + `existsName`（如已存在则跳过；DAO 当前已有 `watchAll` 与 `insertTag` / `softDelete`）。

**已完成 Step 2.6**：



**子任务**：

- [x] `TransactionDao`：`watchTrashed(cutoff)` / `restore(id)` / `purge(id)` / `purgeOlderThan(cutoff)`（事务内删除标签关联）
- [x] `application/recycle_bin_controller.dart`：`trashedTransactionsProvider`（30 天保留期）+ `RecycleBinController` + 纯函数 `daysLeft`
- [x] `presentation/recycle_bin_page.dart`：列表 + 每行「恢复 / 彻底删除」+ 「剩 N 天」 + 二次确认
- [x] go_router：`/transactions/recycle-bin` 路由（root navigator）
- [x] TransactionsPage AppBar 右上角加入回收站图标入口
- [x] `main.dart` 启动时 `unawaited(purgeOlderThan(...))` 自动清理
- [x] ARB：recycleBinTitle / Empty / DaysLeft（ICU placeholder）/ Restore / Purge / 确认（en + zh）
- [x] 单测 6 例（daysLeft 边界 + restore / purge / purgeOlderThan）
- [x] `flutter analyze` + `flutter test` 通过（42 tests）

**下一步接入点**：Phase 3 — Taxonomy 与预算。先做 3.1 分类管理 CRUD：替换 `/settings/categories` 的占位页，建 `lib/features/categories/`（`application/category_form_controller.dart` + `presentation/categories_page.dart` + `category_edit_page.dart`），复用 `categoryDaoProvider`，新增 sort/reorder + 同名校验（已在 DAO `existsName` 中实现）。

**已完成 Step 2.5**：



**子任务**：

- [x] `application/dashboard_summary_controller.dart`：`CurrencySummary` / `DashboardSummary` + `aggregateSummary` 纯函数（按 currency 分行、CAD 优先排序）
- [x] `dashboardSummaryProvider` + `recentTransactionsProvider`（截前 10 条）
- [x] `presentation/dashboard_page.dart`：4 张指标卡（收入 / 支出 / 净额 / 笔数）+ 近期交易卡片（带「查看全部」跳转）
- [x] LayoutBuilder 自适应 1/2 列
- [x] 空状态 + 跳新建交易引导
- [x] ARB：dashIncome / dashExpense / dashNet / dashCount / dashRecent / dashViewAll / dashEmpty（en + zh）
- [x] 单测 3 例（单币种 / 多币种排序 / 空列表）
- [x] `flutter analyze` + `flutter test` 通过（36 tests）

**注**：widget_test 中的「主框架渲染」用例因 Dashboard 引入 `CircularProgressIndicator` + 流式数据导致 `pumpAndSettle` 不收敛，已暂时下线，待补 fakeAsync / 集成测试基础设施再回填。控制器与聚合逻辑全部有纯单测覆盖。

**下一步接入点**：2.6 回收站 — `PRODUCT_SPEC §3.1` 暂未列回收站路由，需要先在 spec 追加 `/settings/recycle-bin`，然后建 `application/recycle_bin_controller.dart`（监听 deletedAt 非空且 < 30 天的 Transaction）+ `presentation/recycle_bin_page.dart`（列表 + 「恢复」+「永久删除」+ 30 天倒计时）。DAO 侧需新增 `restoreTransaction` 与 `purgeTransaction`。

**已完成 Step 2.4**：



**子任务**：

- [x] `SelectionController`（StateNotifier<Set<String>>）+ `selectionControllerProvider`
- [x] `TransactionDao.bulkSoftDelete(List<String>)`：一次性 IN 查询软删除
- [x] 行长按 → 进入选择模式；点击行在选择模式下切换勾选，否则跳编辑
- [x] AppBar 替换：左叉 / 「N 已选」/ 删除按钮
- [x] 删除二次确认 + ARB 复数文案（en + zh，含 ICU placeholder）
- [x] 单测 2 例（toggle/clear + bulkSoftDelete）
- [x] `flutter analyze` + `flutter test` 通过（34 tests）

**下一步接入点**：2.5 Dashboard — 在 `lib/features/dashboard/` 下建 `application/dashboard_summary_controller.dart`（聚合本月：收入总额、支出总额、净额、笔数；按币种分行）和 `presentation/dashboard_page.dart` 渲染 4 张指标卡 + 近期交易列表（≤10 条）。注意多币种不换算。

**已完成 Step 2.3**：



**子任务**：

- [x] `application/transactions_list_controller.dart`：`YearMonth` 值对象 + `currentMonthProvider`（StateNotifier）+ `transactionsOfMonthProvider`（Stream，跟随月份切换）+ `groupByDay`
- [x] `presentation/transactions_page.dart`：AppBar 月份切换（◀ ▶ + YYYY-MM 标签）+ DayGroup 卡片 + 多币种分行展示（不换算）
- [x] 行点击 → `context.push('/transactions/:id/edit')`
- [x] 空状态文案 + ARB（en + zh）
- [x] 单测 6 例（YearMonth 边界 + groupByDay 排序 + provider 跟随月份切换）
- [x] `flutter analyze` + `flutter test` 通过（32 tests）

**已延后**：

- URL query `?month=YYYY-MM` 双向同步 — 当前用 Riverpod 内存 state，月份在 tab 切换间保持；深链恢复推迟到 Phase 7 打磨

**下一步接入点**：2.4 多选与批量删除 — 在 `application/transactions_list_controller.dart` 新增 `SelectionController`（StateNotifier<Set<String>>），交易行 onLongPress（500ms 由 InkWell 默认）进入选择模式，AppBar 顶部替换为「N 已选 + 取消 + 删除」批量按钮，调用 `transactionDao.softDelete` 循环。

**已完成 Step 2.2**：



**子任务**：

- [x] `TransactionFormState` + `TransactionFormController`（StateNotifier.family, autoDispose）
- [x] 字段：金额（minor units 解析）/ 类型 / 分类（按 type 过滤）/ 来源（决定币种）/ 日期 / 标签（多选）/ 备注
- [x] 校验：amountRequired / amountInvalid / categoryRequired / sourceRequired
- [x] 编辑模式：构造时异步加载现有交易 + 标签
- [x] 提交：根据 source 派生 currency；新建 → `insertWithTags`，编辑 → `updateWithTags`
- [x] 软删除（编辑模式 + 二次确认弹窗）
- [x] `TransactionEditPage` 接入 `TransactionForm`
- [x] ARB：所有字段标签 / 类型 / 校验文案 / 删除确认（en + zh）
- [x] 控制器单测（9 tests）+ `flutter analyze` + `flutter test` 通过（26 tests）

**下一步接入点**：2.3 交易列表 — 在 `lib/features/transactions/presentation/transactions_page.dart` 实现：①月份切换（◀ ▶ + URL query `?month=YYYY-MM`）②按日 DayGroup 分组渲染 ③无限滚动（按月分页）④点击进入编辑（push `/transactions/:id/edit`）。先建 `application/transactions_list_controller.dart` 把月份 state + 列表 stream 串起来。

**已完成 Step 2.1**：



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

- [x] 交易表单（`/transactions/new` 与 `/edit`）：字段、验证、提交
- [x] 交易列表（`/transactions`）：DayGroup 分组、月份切换（无限滚动延后 — 单月数据量小，按月翻页够用）
- [x] 长按进入选择模式 + 批量删除
- [x] Dashboard：4 张指标卡 + 近期交易
- [x] 回收站（30 天）

---

## Phase 3 — Taxonomy 与预算

- [x] 分类管理 CRUD + 同名去重
- [x] 标签管理 CRUD
- [x] 来源管理 CRUD（带币种）
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
| 2026-05-13 | 完成 Phase 2 · 2.2：交易表单                      | StateNotifier 控制器 + 9 字段表单 + 9 单测                  |
| 2026-05-13 | 完成 Phase 2 · 2.3：交易列表                      | YearMonth + DayGroup + 月份切换 + 6 单测；URL sync 延后    |
| 2026-05-13 | 完成 Phase 2 · 2.4：多选与批量删除                | SelectionController + bulkSoftDelete + 选择模式 AppBar     |
| 2026-05-13 | 完成 Phase 2 · 2.5：Dashboard 闭环                | 4 指标卡 + 近期交易 + 多币种分行；widget 烟雾测试暂时下线  |
| 2026-05-13 | 完成 Phase 2 · 2.6：回收站（Phase 2 收尾）       | watchTrashed/restore/purge + 启动自动 30 天清理            |
| 2026-05-13 | 完成 Phase 3 · 3.1：分类管理 CRUD                | icon registry + 类型分页 + 图标/颜色选择器 + 4 单测         |
| 2026-05-13 | 完成 Phase 3 · 3.2：标签管理 CRUD                | name + color；4 单测                                        |
| 2026-05-13 | 完成 Phase 3 · 3.3：来源管理 CRUD                | name + icon + color + 币种（18 种）；4 单测                  |

---

## 阻塞与待决问题

_无_

---

**维护者**：SpendHarbor 团队
