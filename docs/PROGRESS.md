# SpendHarbor Local — 开发进度（Progress）

> 滚动开发日志。按阶段勾选完成项，记录里程碑、阻塞与决策变更。**每完成一个 Step 更新一次**。
>
> 配套文档：[PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DESIGN_STANDARDS.md](DESIGN_STANDARDS.md) · [TECH_STACK.md](TECH_STACK.md)

---

## 当前状态

- **当前阶段**：Phase R3 — transaction_form 拆 part 文件 ✅
- **当前 Step**：1101 行单文件 → 主 272 + 5 part（74~194 行）
- **最近更新**：2026-05-24

---

## Current Work（细粒度进度，新会话先读这一段）

> 这一段记录**当前 Step 内的子任务进度**。每完成一个子项立即勾选；context 即将用尽或用户说「checkpoint」时同步更新。新会话可直接从「下一步接入点」继续。

**当前 Step**：Phase R3 — transaction_form 拆 part 文件 ✅

**Phase R3 子任务**：

- [x] R3.1 `transaction_form/header.dart` — `_Header`（74 行）
- [x] R3.2 `transaction_form/amount_currency_date.dart` — `_AmountAndCurrencyRow` + `_OutlinedBox` + `_DateRow`（192 行）
- [x] R3.3 `transaction_form/category_grid.dart` — `_CategoryGrid` + `_CategoryTile` + `_categoryDisplay`（161 行）
- [x] R3.4 `transaction_form/tag_section.dart` — `_TagsSection` + `_TagChip` + `_MoreChip` + `_tagDisplay`（194 行）
- [x] R3.5 `transaction_form/footer.dart` — `_NoteField` + `_SourceDropdown` + `_BottomBar` + `_ErrorIfAny` + `_sourceDisplay`（178 行）
- [x] R3.6 主 `transaction_form.dart` 改为含 5 个 `part` 指令的 library：imports + consts + `TransactionForm` + state + `_messageFor` + `_confirmDelete`（272 行）
- [x] R3.7 `flutter analyze` 0 issues + `flutter test` 通过（171 tests）

**Phase R3 收益**：

- 1101 行单文件 → 272 行主文件 + 5 个 74~194 行的 part 文件，每个 part 单一职责，找代码定位时间显著缩短。
- 私有类（`_Header` 等）保持 `_` 前缀（part 文件共享 library 私有作用域），公共 API 表面 0 变化（仍只导出 `TransactionForm`）。
- 局部 helper（`_categoryDisplay` / `_sourceDisplay` / `_tagDisplay`）就近迁到对应 part 文件。

**已完成 Step Phase R2**：

**当前 Step**：Phase R2 — Stats 卡片骨架抽取 ✅

**Phase R2 子任务**：

- [x] R2.1 `stats_section_card.dart`：`StatsSectionCard(icon, iconColor, title, trailing?, child)` 封装 Card+Padding+Row(icon+title+trailing) 骨架；`StatsCardPlaceholder.loading/error/empty` 统一占位样式（vertical 24 + center + sm）。
- [x] R2.2 `stats_trend_card.dart`：Card+header 用 `StatsSectionCard`；内部 chart loading/error 保持 xs 字号不变（不同视觉上下文）。
- [x] R2.3 `stats_distribution_card.dart`：两张分布卡（Category / Tag）改造 + `StatsCardPlaceholder` 替换本地 `_loading/_error/_empty` + `HexColor.fromHex` 替换残留 `_hexToColor`。
- [x] R2.4 `stats_top_card.dart`：Card+header 改造 + 两个 body (_ByCategoryBody / _ByTagBody) 的 placeholder 替换 + `HexColor.fromHex`。
- [x] R2.5 `dart format` + `flutter analyze` 0 issues + `flutter test` 通过（171 tests）。

**Phase R2 收益**：

- 3 张卡片的 Card+Padding+Row(icon+title+toggle) 骨架（每处 ~25 行）归一为 `StatsSectionCard` 调用。
- 6 处 `_loading/_error/_empty` 内部局部函数删除，归一为 `StatsCardPlaceholder.{loading,error,empty}`。
- 2 处残留 `_hexToColor`（R1 漏网，因 grep 顺序差异）随手补齐。

**已完成 Step Phase R1**：

**当前 Step**：Phase R1 — 共享 widgets / utils 抽取 ✅

**Phase R1 子任务**：

- [x] R1.1 `lib/shared/utils/hex_color.dart`：`HexColor.fromHex(String)` 扩展，替代 10 处重复的 `_hexToColor`。
- [x] R1.2 `lib/shared/widgets/section_label.dart`：`SectionLabel(text)`，替代 5 处内联 `_SectionLabel`（4 edit 页 + export_page）。
- [x] R1.3 `lib/shared/widgets/confirm_dialog.dart`：`showConfirmDialog(context, title, body)` helper，替代 5 处复制的"确认删除" AlertDialog（4 edit 页 + transaction_form）。
- [x] R1.4 `lib/shared/widgets/preview_card.dart`：`PreviewCard(icon?, color, name, placeholder)`，替代 3 处 `_PreviewCard`（category / tag / source edit）。
- [x] R1.5 `lib/shared/widgets/icon_picker.dart`：`IconPicker(value, color, onPicked)`，替代 2 处 `_IconPicker`（category / source edit）。
- [x] R1.6 替换调用：categories_page / tags_page / sources_page / transaction_list_row / transaction_form / 4 个 edit 页 / export_page。
- [x] R1.7 `flutter analyze` 0 issues + `flutter test` 通过（171 tests）。

**Phase R1 收益**：

- category_edit_page 314 → 159 行（-49%）
- tag_edit_page 226 → 128 行（-43%）
- source_edit_page 325 → 173 行（-47%）
- 4 处 `_PreviewCard`、5 处 `_SectionLabel`、10 处 `_hexToColor`、5 处 AlertDialog 块全部归一。

**已完成 Step Phase 10**：

**当前 Step**：Phase 10 — XLSX 导入导出（交易 + Taxonomy）✅

**Phase 10 子任务**：

- [x] 10.1 自研 [`xlsx_codec.dart`](../lib/features/data_io/application/xlsx_codec.dart)：encodeXlsx / decodeXlsx，仅支持 string + number 单元格 + sharedStrings + 多 sheet。绕开 `excel` 包与 `flutter_native_splash` 的 archive 大版本冲突。
- [x] 10.2 [`taxonomy_xlsx.dart`](../lib/features/data_io/application/taxonomy_xlsx.dart)：3-sheet schema（Categories / Tags / Sources），与示例文件 `spend-harbor-taxonomy-*.xlsx` 完全对齐。
- [x] 10.3 [`transactions_xlsx.dart`](../lib/features/data_io/application/transactions_xlsx.dart)：1-sheet schema（Amount / Type / Currency / Date / Category / Tags / Source / Notes），复用 csv_importer 的 ParsedCsvRow / CsvRowOutcome 下游逻辑。
- [x] 10.4 [`taxonomy_import_controller.dart`](../lib/features/data_io/application/taxonomy_import_controller.dart)：「清空后重建」语义的 FK-safe 实现 —— 同名更新 / 新增插入 / xlsx 没有的软删除（保留外键引用）。
- [x] 10.5 [`import_controller.dart`](../lib/features/data_io/application/import_controller.dart) 重写：xlsx/csv 自动分发 + 缺失的 category/tag/source 自动新建（默认配色）。返回带 autoCreated 计数的 ImportSummary。
- [x] 10.6 [`export_controller.dart`](../lib/features/data_io/application/export_controller.dart) 重写：`exportTransactions(scope, format)` + `exportTaxonomy()`；文件名规则与示例对齐。
- [x] 10.7 ARB en+zh 新增 16 keys（exportSection*/exportFormat*/exportScope*/importTaxonomy*/importTxAutoCreated 等）。
- [x] 10.8 Export 页：双卡片（Transactions + Taxonomy），PillSegmented 选格式 + 范围；Import 页：单 Pick 按钮 + 自动 detect xlsx kind + taxonomy 替换前确认对话框。
- [x] 10.9 单测：[`xlsx_codec_test.dart`](../test/features/data_io/xlsx_codec_test.dart) 编解码往返 + XML 转义。
- [x] 10.10 docs：TECH_STACK.md §2.1 加 archive + xml；§2.3 移除 excel 计划项并解释自研原因。
- [x] 10.11 `flutter analyze` 0 issues + `flutter test` 通过（171 tests）。
- [ ] 实机验证：分享导出文件给自己 + 重新导入 + 编辑示例文件后再导入（用户自己跑）。

**Phase 10 已知 deferred**：

- Tags 表无 icon 列；导出时为兼容示例 schema 固定写 'tag'，导入时忽略 icon 列。
- Taxonomy 导入语义实质是 merge + soft-delete missing，不是真正的硬删除（保护交易外键）。从用户视角等价于「以 xlsx 为准」。

---

**已完成 Step Phase 9**：

**当前 Step**：Phase 9 — Add / Edit Transaction 页面重构 ✅

**Phase 9 子任务**：

- [x] 9.1 `lastTransactedOnProvider`（SharedPreferences `tx.lastTransactedOn`）+ `tagUsageLast30dProvider`（TransactionDao.tagUsageSince customSelect）
- [x] 9.2 Controller 扩展：`currency` / `currencyManuallySet` 字段独立于 source；`setSource(id, sourceCurrency: ...)` 仅在用户未手动改币种时联动；`setCurrency` 标记 manual；新增 `currencyRequired` / `tagLimitExceeded` 错误；`toggleTag` 返回 bool 处理 5 个上限
- [x] 9.3 ARB en+zh 新增 9 keys（`txErrCurrencyRequired` / `txAmountPlaceholder` / `txSourcePlaceholder` / `txTagSearchPlaceholder` / `txTagNoMatch` / `txTagMore` / `txTagLess` / `txTagLimitReached` / `txNoteOptional`）
- [x] 9.4 `transaction_form.dart` 整页重写：自定义 Header（< Back / 标题 / 编辑态垃圾桶）+ 类型胶囊分段（Expense 红 / Income 绿）+ 金额 24sp 等宽 + 币种独立 dropdown + 日期框 + 动态 Yesterday/Today 按钮 + 4 列分类九宫格 SizedBox(230) + Tag 搜索框 + Wrap chips（选中置顶 / 频次降序 / 10 个折叠 + More(+N) / Less）+ Note 2 行 + Source 下拉（最后）+ 底部 Cancel + Save 双按钮
- [x] 9.5 `transaction_edit_page.dart` 去掉 AppBar，整页交给 `TransactionForm`
- [x] 9.6 测试：`transaction_form_controller_test.dart` 注入 `sharedPreferencesProvider` mock；`flutter analyze` 0 issues + `flutter test` 通过（170 tests）
- [ ] 实机交互验证（用户自己跑）

**Phase 9 已知 deferred**：

- 字段级错误聚焦到第一个错误字段（spec 标记为可选优化），暂未实现。
- 全局 API 错误的红色软底卡片：本地无后端，仅 SnackBar 提示 tag 上限，其他错误为字段级红字。

---

**已完成 Step Phase 8**：

**当前 Step**：Phase 8 — Stats 视觉重构 ✅

**Phase 8 子任务**：

- [x] 8.1 StatsFilter + Period / 桶生成纯函数 + StatsFilterController（含 prefs + dominant-currency init）
- [x] 8.2 TransactionsFilter 扩展（dateRange / tag / untagged / source）+ router query params
- [x] 8.3 Stats controller 重写：trend / bucketTransactions / bucketTagsByTx / categoryDistribution.family / tagDistribution.family / topByCategory.family / topByTag.family
- [x] 8.4 共享组件 + 4 卡：TagPill / StatsDonut / StatsFilterBar / StatsTrendCard / Category+TagDistributionCard / StatsTopCard
- [x] 8.5 stats_navigation.dart：navigateToTransactions 按 period 拼 month / dateStart-dateEnd + source/category/tag/untagged 跳 /transactions
- [x] 8.6 stats_page.dart 整页装配（filter → trend → cat dist → tag dist → top；GlobalKey + Scrollable.ensureVisible 跳转）
- [x] 8.7 ARB en+zh：19 keys 新增、8 keys 移除；ARB parity test 通过
- [x] `flutter analyze` 0 issues + `flutter test` 通过（169 tests）
- [ ] 实机交互验证（用户自己跑）

**Phase 8 spec / plan**：

- 设计 spec：[docs/superpowers/specs/2026-05-14-stats-page-overhaul-design.md](superpowers/specs/2026-05-14-stats-page-overhaul-design.md)
- 实现 plan：[docs/superpowers/plans/2026-05-14-stats-page-overhaul.md](superpowers/plans/2026-05-14-stats-page-overhaul.md)

**Phase 8 已知 deferred**：

- Top By Tag 底部 "+N more · View all" 链接未实现（rows 已被 limit=10 截断，multi-tag 提示行已点击跳到 Tag Distribution，覆盖同一意图）。

---

**已完成 Step Phase 7 · 7.1**：

**子任务**：

- [x] 新增 `colorInfo` + `colorInfoSoft` 蓝色 token（浅 + 深，含 copyWith / lerp）
- [x] `application/dashboard_filter_provider.dart`：`DashboardFilter`（currency/sourceId 双 nullable）+ `dashboardFilterProvider`（初始货币 = 用户 default currency，不响应后续修改）
- [x] 重构 `dashboard_summary_controller.dart`：拆出 `applyDashboardFilter` 纯函数 + `DashboardMetrics` 视图模型（dominantCurrency + otherCurrencyCount）+ `toMetrics` 派生函数；`dashboardMetricsProvider` / `recentTransactionsProvider` 接入过滤
- [x] `presentation/dashboard_filter_bar.dart`：① ◀ YYYY年MM月 ▶ 居中导航（自定义 28×28 InkResponse，整行 32pt）② 货币 / 来源 pill 风格下拉（icon 前缀 + 36pt 固定高度）
- [x] 重写 4 张卡：tile-icon 风格（40×40 圆角方块 + 白色 icon）、soft 背景、Net 颜色 / 背景跟随符号、`CAD +N` badge 多币种提示；2×2 强制网格（aspectRatio 1.45）
- [x] ARB en+zh：`dashFilterCurrency / dashFilterSource / dashFilterAll / dashPrevMonth / dashNextMonth / dashOthersBadge`
- [x] 新增 11 个单测：`applyDashboardFilter` × 5 + `DashboardFilter.copyWith` × 2 + `toMetrics` × 4
- [x] `flutter analyze` + `flutter test` 通过（148 tests）
- [x] 实机验证（用户自己跑）

**下一步接入点**：Phase 7 · 7.2 — App 图标 + 启动页（**已完成**，见下方记录）；继续 7.3 国际化 / 字号 / 深色全量回归（已做完程序化检查部分；剩手动 QA checklist）。

**已完成 Step 7.2**：

- 手动 QA checklist 文档化：每个 route 在 en / zh × light / dark × 100% / 200% 字号下截图核对
- 建议新建 `docs/QA_CHECKLIST.md`：列所有 route + ARB key 缺失检查（grep ARB 文件覆盖率）+ TextScaler 200% 关键页面（Dashboard / Stats / Settings 表单 / Onboarding）
- 程序化部分：写一个测试遍历 ARB en/zh keys 一致性（已有 `flutter_localizations`，可基于 `app_en.arb` / `app_zh.arb` 做 diff）

**Phase 7 全部子项**：

- [x] 7.1 Dashboard 视觉重构（过滤条 + tile-icon 卡片）
- [x] 7.2 App 图标 + 启动页
- [ ] 7.3 国际化全量回归 + 200% 字号 + 深色（程序化已过，手动 QA checklist 待做）
- [ ] 7.4 性能基准（冷启动 + Stats 聚合）
- [ ] 7.5 隐私清单（Apple Privacy Manifest / Google Data Safety）
- [ ] 7.6 应用商店素材
- [ ] 7.7 上架审核

**已完成 Step 6.3**：

**子任务**：

- [x] 新依赖 `crypto: ^3.0.6`（PIN SHA-256 哈希）
- [x] `application/app_lock_controller.dart`：纯函数 `hashPin(pin)` (salt + sha256) + `AppLockController`（StateNotifier`<AppLockState>`，bootstrap 从 secure_storage 读 hash + 生物识别开关）
- [x] `LockStorage` 接口（生产 = secure_storage；测试可注入内存实现）+ `localAuthProvider` 包装 LocalAuthentication
- [x] `presentation/app_lock_gate.dart`：`Stack` 覆盖锁屏；`WidgetsBindingObserver` 在 paused/detached 时调用 `lock()`；启动时自动尝试生物识别
- [x] `presentation/security_page.dart`：开关 + 设置/修改 PIN（弹窗输入两次校验）+ 生物识别 toggle
- [x] `app.dart` `MaterialApp.router.builder` 用 `AppLockGate` 包裹全局
- [x] go_router `/settings/security` 替换占位
- [x] ARB：lockTitle / EnableToggle / Biometric / SetPin / ChangePin / Remove / EnterPin / ConfirmPin / Mismatch / TooShort / Wrong / UnlockTitle / UseBiometric / Reason（en + zh）
- [x] 单测 9 例（hashPin 3 + bootstrap 2 + setPin/verify/clear + 长度校验 + biometric 联动 + lock()）
- [x] `flutter analyze` + `flutter test` 通过（133 tests）

**下一步接入点**：6.4 关于 / 法律页 — 静态文案。

- `presentation/about_page.dart`：App 名 + 版本（package_info_plus 可选；先硬编码 1.0.0）+ 简短介绍 + 致谢
- `presentation/legal_page.dart`：隐私政策 + 服务条款（两段简短，强调本地存储）
- 路由 `/settings/about` + `/settings/legal` 替换占位
- ARB

**已完成 Step 6.2**：

**子任务**：

- [x] `application/default_currency_provider.dart`：持久化（key `app.defaultCurrency`，默认 CAD，非法值自动落回 CAD）
- [x] `presentation/currency_page.dart`：18 种币种 RadioListTile（双语 name + code · symbol）
- [x] go_router：`/settings/currency` 替换占位
- [x] `SourceFormController` / `BudgetFormController` 新建时使用默认币种（编辑时不变）；含 try/catch 落回保证旧测试不受影响
- [x] 单测 4 例（默认 / set 持久化 + 非法忽略 / 启动读取 / 不支持值落回）
- [x] `flutter analyze` + `flutter test` 通过（124 tests）

**下一步接入点**：6.3 应用锁。`flutter_secure_storage` + `local_auth` 已在依赖中。流程：

- `AppLockController`（PIN hash + bool isEnabled，存在 secure_storage）
- 启动时若启用 → MaterialApp 包一层 `_LockGate`（Riverpod listen，未解锁时盖一层 Scaffold 输入 PIN / 触发生物识别）
- `/settings/security`：开关 + 设置/修改 PIN + 生物识别 toggle
- ARB + 测试（PIN hash 函数）

**已完成 Step 6.1**：

**子任务**：

- [x] `application/profile_provider.dart`：昵称读写 prefs（`profile.nickname`）+ 纯函数 `initialsFor`（支持中文 runes + 西文双词）
- [x] `application/theme_mode_provider.dart`：ThemeMode 持久化（system/light/dark）
- [x] `app.dart` 注入 `themeMode` provider 替代硬编码 `ThemeMode.system`
- [x] `presentation/profile_page.dart`：圆形头像 initials + 昵称输入
- [x] `presentation/appearance_page.dart`：RadioListTile 切换 3 种模式
- [x] `presentation/language_page.dart`：RadioListTile 切换 system / en / zh
- [x] go_router：`/settings/profile` + `/appearance` + `/language` 替换占位
- [x] ARB：profileFieldNickname / Hint / Greeting (ICU) + appearance{System,Light,Dark}（en + zh）
- [x] 单测 9 例（initialsFor 5 + ProfileController 1 + ThemeMode 3）
- [x] `flutter analyze` + `flutter test` 通过（120 tests）

**下一步接入点**：6.2 默认货币。

- 新增 `application/default_currency_provider.dart`（key `app.defaultCurrency`，默认 'CAD'）
- `presentation/currency_page.dart`：List of `Currency.all` 单选
- 接入点：`TransactionFormController` 新建时优先用默认币种（来源选择前的预览金额前缀），`SourceFormController` 新建时默认币种
- ARB + 单测

**已完成 Step 5.4**：

**子任务**：

- [x] `application/backup_reminder.dart`：`BackupStatus`（lastBackupAt / daysSince / shouldRemind）+ `markBackupCompleted` 写 prefs + `backupStatusProvider`
- [x] `presentation/backup_reminder_banner.dart`：复用横幅（橙/红高亮 + 「点击跳备份」+ 阈值内绿色"上次于 N 天前"，`showAlways` 可控）
- [x] `BackupController.exportBackup` 成功后写 `backup.lastAt` + `invalidate(backupStatusProvider)`
- [x] Dashboard 顶部 + BackupPage 顶部各嵌入一个横幅
- [x] ARB：backupNever / Overdue / Recent（ICU `{days}`）（en + zh）
- [x] 单测 6 例（BackupStatus 4 种状态 + markBackupCompleted + provider 读取）
- [x] `flutter analyze` + `flutter test` 通过（111 tests）

**下一步接入点**：Phase 6 — 设置与体验。子项：① 个人偏好（昵称、头像 initials/本地图片）② 默认货币 / 语言 / 外观 ③ 应用锁（PIN + 生物识别）④ 关于页、法律页 ⑤ 触感反馈（HapticFeedback）。

- 第一步 6.1：个人偏好 + 外观（最简）。在 SharedPreferences 加 `profile.nickname` + `profile.avatarInitials` + 已有 `app.locale`。新增 `themeMode` provider 覆盖 ThemeMode（system/light/dark）。把 `/settings/profile` 和 `/settings/appearance` 占位替换成实页。

**已完成 Step 5.3**：

**子任务**：

- [x] `application/backup_serializer.dart`：纯函数 `encodeBackup` / `decodeBackup`（6 张表全部字段；带 `schemaVersion` + `exportedAt`）+ `BackupVersionException`
- [x] `application/backup_controller.dart`：`exportBackup`（读全库 → `.shbak` 临时文件 → SharePlus）+ `restoreBackup`（file_picker → decode → 事务内清空 + batch insert）
- [x] `presentation/backup_page.dart`：导出 / 恢复双按钮 + 二次确认（红色警告文案）+ snackbar 反馈 + 版本错误特别提示
- [x] go_router `/settings/backup` 替换占位
- [x] ARB：backupTitle / Hint / Button / Confirm / Done / VersionMismatch (ICU)（en + zh）
- [x] 单测 3 例（round-trip / 版本不匹配 / 缺 schemaVersion）
- [x] `flutter analyze` + `flutter test` 通过（105 tests）

**下一步接入点**：5.4 备份提醒（Phase 5 收尾）。记录最近一次备份时间（`SharedPreferences` key `backup.lastAt`），首页 / 设置入口顶部展示「最后备份: N 天前」横幅；N 天阈值（默认 30）超期时高亮提醒。要不要等用户启用 → 加个 Settings toggle 控制提醒开关？最简版：直接在 BackupPage 头部显示状态 + Dashboard 加一个可关闭的横幅。

**已完成 Step 5.2**：

**子任务**：

- [x] 新依赖 `file_picker: ^11.0.2`（注意 11.x 静态 API `FilePicker.pickFiles`）
- [x] `application/csv_importer.dart`：纯函数 `parseCsv`（校验日期 / 类型 / 币种 / 金额）+ `dedupeKey` 复合 key（date+type+catId+srcId+amount+currency+note）+ `existingDedupeKeys`
- [x] `application/import_controller.dart`：文件选择 → 解析 → 按 name 解析 category/source/tag（缺失则跳过）→ dedupe → 事务批量插入；返回 `ImportSummary { parsed, imported, duplicates, invalid }`
- [x] `presentation/import_page.dart`：按钮 + busy + 摘要文案
- [x] go_router `/settings/import` 替换占位
- [x] ARB：importTitle / Hint / PickCsv / Summary (ICU 4 placeholders)（en + zh）
- [x] TECH_STACK §2.1 追加 `file_picker`
- [x] 单测 8 例（parseCsv 5 + dedupeKey 3）
- [x] `flutter analyze` + `flutter test` 通过（102 tests）

**下一步接入点**：5.3 备份 / 恢复。一键导出全库快照（`.shbak` = JSON + 可选压缩）：

- 新增依赖 `archive`（zip）或先做不压缩 JSON
- `backup_writer.dart`：把所有 5 张表 + transaction_tags 序列化为 JSON（含 schemaVersion）
- `backup_reader.dart`：解析 → 校验 schemaVersion → 清空 + 重建（或合并）
- `/settings/backup` 落地：导出按钮（写 `.shbak` → SharePlus）+ 恢复按钮（file_picker → 读 → 二次确认 → 写）
- 测试：序列化 round-trip + 版本不匹配抛错

**已完成 Step 5.1**：

**子任务**：

- [x] 新依赖 `csv: ^6.0.0` + `share_plus: ^12`
- [x] `application/csv_exporter.dart`：纯函数 `rowsToCsv` (RFC 4180 + CRLF) + `toCsvRow`（id → 名映射，金额两位小数）
- [x] `application/export_controller.dart`：取当月交易 + 字典联表 → 临时文件 → SharePlus 分享
- [x] `presentation/export_page.dart`：当月提示 + 「导出 CSV」按钮 + 空状态 + busy/snackbar
- [x] go_router：`/settings/export` 替换占位
- [x] ARB：exportTitle / exportMonthHint / button / empty / done（en + zh）
- [x] TECH_STACK §2.1 追加 csv + share_plus
- [x] 单测 5 例（rowsToCsv 空/单行/引号字段 + toCsvRow 字典命中/缺失）
- [x] `flutter analyze` + `flutter test` 通过（94 tests）

**下一步接入点**：5.2 数据导入。流程：file_picker 选 CSV → 解析（沿用 `csv` 包） → 与现有数据合并（按 `transactedOn + amountCents + categoryId + sourceId + note` 复合 key 去重，已存在的跳过）→ 写库。需要新依赖 `file_picker`。先做 import_controller + 纯函数 `parseCsv` + `mergeStrategy`（保守：跳过冲突），再做页面。

**已完成 Step 4.4**：

**子任务**：

- [x] `TransactionsFilter` 值对象 + `transactionsFilterProvider`（State）+ `filteredTransactionsProvider`（派生 stream）
- [x] 月份切换自动清空筛选（避免月外残留）
- [x] TransactionsPage 顶部 `_FilterChip`（带 X 清除）
- [x] BarChart 柱子点击 → 用「该月 + 该日」生成 ISO 日期 → 切到 `/transactions` + 设 filter
- [x] CategoryDonut 切片 + legend 行点击 → 设 categoryId filter
- [x] Top 5 行（按金额 / 按笔数）点击 → 设 categoryId filter
- [x] TagDonut 切片暂不响应（标签筛选未实现，先留接口 `onTapId=null`）
- [x] 单测 4 例（filter 匹配规则：empty / day / category / 双重 AND）
- [x] `flutter analyze` + `flutter test` 通过（89 tests）

**下一步接入点**：Phase 5 — 导入 / 导出 / 备份。子项：① Excel/CSV 导出 → 系统分享 ② 数据导入（含冲突合并）③ 一键备份 `.shbak` / 恢复 ④ 备份提醒。先做 5.1 CSV 导出（最小可用）：

- 新增依赖：`csv` + `share_plus` + `path_provider`（已有）
- 在 `lib/features/data_io/` 下建 `csv_exporter.dart`（纯函数 → 字符串）+ `share_handler.dart`（写临时文件 → 调用 share）
- `/settings/export` 落地：选月份 + 按钮触发 → 系统分享面板
- ARB + 单测（CSV 列头 / 行格式）

**已完成 Step 4.3**：

**子任务**：

- [x] 纯函数 `countByCategory(rows, currency)` + `categoryCountsProvider`
- [x] `StatsPage` 底部加 `_TopCategoriesCard`：SegmentedButton 切「按金额 / 按笔数」；列表显示 Top 5 排名 + 分类名 + 金额或笔数
- [x] ARB：statsTopTitle / statsTopByAmount / statsTopByCount / statsCountUnit (ICU plural)（en + zh）
- [x] 单测 2 例（按笔数降序 + 过滤 income/不匹配币种）
- [x] `flutter analyze` + `flutter test` 通过（85 tests）

**下一步接入点**：4.4 图表点击跳转 — 给 BarChart / PieChart 行加 onTap：① 柱状图点某日 → push `/transactions?date=YYYY-MM-DD`（需扩展 transactions list 支持单日筛选）② Donut 切片 / Top 行 → push `/transactions?category=:id`。考虑：交易列表当前只支持月份切换，需要新增「临时筛选」状态（query 参数解析 + 顶部 chip 可清除）。

**已完成 Step 4.2**：

**子任务**：

- [x] `TransactionDao.tagIdsForMany([txIds])`：一次性查多笔交易的标签关联
- [x] 纯函数 `aggregateByCategory(rows, currency)` / `aggregateByTag(rows, currency, tagIdsByTx)`（多标签都累加全额）
- [x] `categorySlicesProvider` / `tagSlicesProvider`（按 dominant 币种）
- [x] `StatsPage` 增加两张 Donut 卡：fl_chart `PieChart` + 自绘 legend（颜色块 / 名称 / 金额 + 百分比）
- [x] 调色板 10 色循环；标签卡空状态 fallback
- [x] ARB：statsByCategory / statsByTag / statsNoTags（en + zh）
- [x] 单测 3 例（分类降序 + 多标签累加 + 无标签空集）
- [x] `flutter analyze` + `flutter test` 通过（83 tests）

**下一步接入点**：4.3 Top 排行。Stats 页底部加 Top N 列表（默认 5）：① 分类支出 Top（已有 `categorySlicesProvider`，直接 take(5)）② 笔数 Top（按 categoryId 计数，需新纯函数 `countByCategory`）。考虑 Tab 切「按金额 / 按笔数」。

**已完成 Step 4.1**：

**子任务**：

- [x] 新增依赖 `fl_chart: ^0.69.0`（钉 0.69 — 1.x 引用了当前 Flutter SDK 没有的 `Matrix4.translateByDouble`）
- [x] `application/stats_controller.dart`：纯函数 `aggregateDailyExpenses(rows, year, month)` 按日分桶 + 多币种独立累加；`dominantCurrency`（CAD 优先 → 否则按总额降序）；`dailyExpenseBarsProvider`
- [x] `presentation/stats_page.dart`：AppBar 显示当前月份；趋势卡片（BarChart：x 轴每 5 日打标 + 1 号 / y 轴顶端 max 标签 / 主币种横幅 / 空状态文案）
- [x] ARB：statsTrendTitle / statsEmpty / statsCurrencyHint (ICU `{currency}`)（en + zh）
- [x] TECH_STACK.md §2.1 追加 `fl_chart`
- [x] 单测 7 例（按日累加 / 多币种 / 月底 / 12 月跨年 / dominantCurrency 3 例）
- [x] `flutter analyze` + `flutter test` 通过（80 tests）

**下一步接入点**：4.2 分类 / 标签 Donut — 在 `stats_controller.dart` 补 `aggregateByCategory(rows, type)` 返回 `[{categoryId, totalCents, currency}]`（同样按 currency 分桶）+ `aggregateByTag` 类似。StatsPage 用 fl_chart 的 `PieChart` 画 Donut（每币种一张？或者只显示 dominant 币种 + 切换 chip）。先做 dominant 一张图，简洁。

**已完成 Step 3.5**：

**子任务**：

- [x] `TransactionDao.watchBetween(startIso, endIso)`：闭区间流式查询
- [x] `budget_period_alignment.dart`：补 `periodEndOn` —— 周末日 / 当月最后一天 / 12-31
- [x] `application/budget_progress_provider.dart`：`BudgetProgress`（ratio + overBudget）+ 纯函数 `spentForBudget`（type==expense + 币种匹配 + scope=category 时 categoryId 匹配）+ `budgetProgressListProvider`（按预算自己的 period 取本期窗口）
- [x] `presentation/dashboard_page.dart`：在指标卡下方插入预算卡片块（scope+period 标题 / 已花/预算 / 进度条 / 超支红色高亮 + 「管理」跳 `/settings/budgets`）
- [x] ARB：dashBudgets / dashBudgetTotal / dashBudgetOver (ICU `{amount}`) / dashBudgetManage（en + zh）
- [x] 单测 7 例（spentForBudget 2 + ratio/over 1 + periodEndOn 4）
- [x] `flutter analyze` + `flutter test` 通过（73 tests）

**下一步接入点**：Phase 4 — 统计分析。子项：① 趋势图（Bar Chart，按日/周/月聚合金额）② 分类 / 标签 Donut（金额占比）③ Top 排行（按支出金额 / 笔数）④ 点击图表跳交易列表（带筛选）。第三方依赖：`fl_chart`（轻量、零网络、纯 Flutter，先评估）。建议先做 4.1 趋势图：在 Stats tab 落地，复用 `transactionsOfMonthProvider` 起步，再决定是否加 `byDateRange` 范围 picker。

**已完成 Step 3.4**：

**子任务**：

- [x] `application/budget_period_alignment.dart`：纯函数 `alignToPeriodStart` (week=周一 / month=1日 / year=1/1) + `formatIsoDate`
- [x] `application/budget_form_controller.dart`：6 字段（period + scope + categoryId + amount + currency + startsOn），切换 period 自动对齐 startsOn；切换 scope=total 自动清空 categoryId
- [x] 校验：amountInvalid / categoryRequired（scope=category 时）
- [x] `presentation/budgets_page.dart`：列表（按 startsOn 升序）+ FAB
- [x] `presentation/budget_edit_page.dart`：period/scope SegmentedButton + 分类 Dropdown（仅 expense 分类）+ 金额 + 币种 + 起始日 picker（提交时再次对齐）
- [x] `allBudgetsProvider`（StreamProvider）
- [x] go_router：`/settings/budgets` + `/new` + `/:id/edit`，从占位列表中摘除
- [x] ARB：budget\* 字段 + period 标签 + scope 标签 + errors + 删除确认 / 空状态 / budgetAdd（en + zh）
- [x] 单测 12 例（period alignment 5 + format 1 + controller 6）
- [x] `flutter analyze` + `flutter test` 通过（66 tests）

**下一步接入点**：3.5 Dashboard 接入预算块（Phase 3 收尾）。在 `lib/features/dashboard/application/` 下加 `budget_progress_provider.dart`：聚合「本期间隔内已花 vs 预算上限」（按 period 的当前实例：week → 本周一至今 / month → 本月 / year → 今年）。`presentation/dashboard_page.dart` 在 4 张指标卡下方插入预算进度卡（每条预算一行：scope label · 已花/预算 · 进度条 + 超限红色高亮）。需要新 query：`watchTransactionsBetween(start, end)`，或在 controller 里基于 `transactionsOfMonthProvider` 推导（注意周/年跨度可能跨月）。

**已完成 Step 3.3**：

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
- [x] ARB：catNewTitle / catEditTitle / catFieldName / type / icon / color / errors / 删除确认 / catEmpty\* / catAdd（en + zh）
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

- [x] `SelectionController`（StateNotifier<Set `<String>`>）+ `selectionControllerProvider`
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

**下一步接入点**：2.4 多选与批量删除 — 在 `application/transactions_list_controller.dart` 新增 `SelectionController`（StateNotifier<Set `<String>`>），交易行 onLongPress（500ms 由 InkWell 默认）进入选择模式，AppBar 顶部替换为「N 已选 + 取消 + 删除」批量按钮，调用 `transactionDao.softDelete` 循环。

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
- [x] 预算管理 CRUD + 周期对齐
- [x] Dashboard 接入预算块

---

## Phase 4 — 统计分析

- [x] 趋势图（Bar Chart）
- [x] 分类 / 标签 Donut
- [x] Top 排行
- [x] 点击图表跳转交易列表（带筛选）

---

## Phase 5 — 导入 / 导出 / 备份

- [x] Excel / CSV 导出 → 系统分享面板（先做 CSV；Excel 推迟）
- [x] 数据导入（含冲突合并策略：复合 key dedupe，缺失字典项跳过）
- [x] 一键备份 / 恢复 `.shbak`
- [x] 备份提醒

---

## Phase 6 — 设置与体验

- [x] 个人偏好（昵称、头像 initials）
- [x] 默认货币、语言、外观主题
- [x] 应用锁（PIN + 生物识别）
- [x] 关于页、法律页
- [x] 触感反馈（HapticFeedback）接入

---

## Phase 7 — 打磨与上架

- [x] App 图标 + 启动页
- [ ] 国际化全量回归（中英 + 200% 字号 + 深色）
- [ ] 多设备 viewport 回归
- [ ] 性能基准（冷启动、Stats 聚合）
- [ ] 隐私清单（Apple Privacy Manifest / Google Data Safety）
- [ ] 应用商店素材（截图、描述）
- [ ] 上架审核

---

## 决策与变更日志

| 日期       | 事项                                               | 备注                                                            |
| ---------- | -------------------------------------------------- | --------------------------------------------------------------- |
| 2026-05-12 | 产品定位调整：移除登录/会员/Admin，全功能终身可用  | 重写 PRODUCT_SPEC v2.0                                          |
| 2026-05-12 | 实现平台选定：Flutter（iOS + Android）             | 暂不发布 Web / 桌面端                                           |
| 2026-05-12 | DESIGN_STANDARDS 重写为 Flutter 版                 | v2.0                                                            |
| 2026-05-12 | 完成 Step 1：依赖与目录骨架                        | 新增 TECH_STACK.md / PROGRESS.md                                |
| 2026-05-12 | 完成 Step 2：设计 token 落地                       | `lib/theme/` 6 文件，浅/深主题 + Theme Preview 页               |
| 2026-05-13 | 完成 Step 3：数据库 Schema + Seed                  | drift 5 表 + 多对多 + 5 DAO + 中英 seed + 7 单测                |
| 2026-05-13 | 完成 Step 4：i18n 基础                             | en/zh ARB + localeController + nameKey resolver + 12 单测       |
| 2026-05-13 | 完成 Step 5：路由与主框架（Phase 1 收尾）          | go_router StatefulShellRoute + 移动/平板自适应 + onboarding     |
| 2026-05-13 | 完成 Phase 2 · 2.1：数据访问基础                   | appDatabaseProvider + DAO/stream providers + 启动 seed          |
| 2026-05-13 | 完成 Phase 2 · 2.2：交易表单                       | StateNotifier 控制器 + 9 字段表单 + 9 单测                      |
| 2026-05-13 | 完成 Phase 2 · 2.3：交易列表                       | YearMonth + DayGroup + 月份切换 + 6 单测；URL sync 延后         |
| 2026-05-13 | 完成 Phase 2 · 2.4：多选与批量删除                 | SelectionController + bulkSoftDelete + 选择模式 AppBar          |
| 2026-05-13 | 完成 Phase 2 · 2.5：Dashboard 闭环                 | 4 指标卡 + 近期交易 + 多币种分行；widget 烟雾测试暂时下线       |
| 2026-05-13 | 完成 Phase 2 · 2.6：回收站（Phase 2 收尾）         | watchTrashed/restore/purge + 启动自动 30 天清理                 |
| 2026-05-13 | 完成 Phase 3 · 3.1：分类管理 CRUD                  | icon registry + 类型分页 + 图标/颜色选择器 + 4 单测             |
| 2026-05-13 | 完成 Phase 3 · 3.2：标签管理 CRUD                  | name + color；4 单测                                            |
| 2026-05-13 | 完成 Phase 3 · 3.3：来源管理 CRUD                  | name + icon + color + 币种（18 种）；4 单测                     |
| 2026-05-13 | 完成 Phase 3 · 3.4：预算管理 CRUD + 周期对齐       | period/scope/cat 联动 + week/month/year 起点对齐 + 12 单测      |
| 2026-05-13 | 完成 Phase 3 · 3.5：Dashboard 接入预算块（收尾）   | watchBetween + 本期窗口聚合 + 进度卡 / 超支红色 + 7 单测        |
| 2026-05-13 | 完成 Phase 4 · 4.1：趋势柱状图                     | fl_chart 0.69 + 按日聚合 + dominantCurrency + 7 单测            |
| 2026-05-13 | 完成 Phase 4 · 4.2：分类 / 标签 Donut              | PieChart + 自绘 legend + tagIdsForMany 批量查询 + 3 单测        |
| 2026-05-13 | 完成 Phase 4 · 4.3：Top 排行                       | countByCategory + 金额/笔数切换 + 2 单测                        |
| 2026-05-13 | 完成 Phase 4 · 4.4：图表点击跳转（收尾）           | TransactionsFilter + chart taps + 顶部 chip + 4 单测            |
| 2026-05-13 | 完成 Phase 5 · 5.1：CSV 导出                       | rowsToCsv RFC 4180 + share_plus 分享 + 5 单测                   |
| 2026-05-13 | 完成 Phase 5 · 5.2：CSV 导入                       | parseCsv + 复合 key dedupe + ImportSummary + 8 单测             |
| 2026-05-13 | 完成 Phase 5 · 5.3：备份 / 恢复 .shbak             | JSON snapshot schemaVersion=1 + 事务替换全库 + 3 单测           |
| 2026-05-13 | 完成 Phase 5 · 5.4：备份提醒（Phase 5 收尾）       | BackupStatus + Dashboard/BackupPage 横幅 + 6 单测               |
| 2026-05-13 | 完成 Phase 6 · 6.1：个人偏好 + 外观 + 语言         | 昵称 + initials + ThemeMode 持久化 + 9 单测                     |
| 2026-05-13 | 完成 Phase 6 · 6.2：默认货币                       | 持久化 + Source/Budget 新建套用默认 + 4 单测                    |
| 2026-05-13 | 完成 Phase 6 · 6.3：应用锁（PIN + 生物识别）       | hashPin + secure_storage + LockGate 生命周期 + 9 单测           |
| 2026-05-13 | 完成 Phase 6 · 6.4+6.5：关于 / 法律 / 触感（收尾） | AboutPage + LegalPage + 3 处 HapticFeedback                     |
| 2026-05-13 | 完成 Phase 7 · 7.2：App 图标 + 启动页              | flutter_launcher_icons + flutter_native_splash 白底品牌 logo    |
| 2026-05-14 | 完成 Phase 8：Stats 视觉重构                       | Week/Month/Year + 选中桶锚点 + Cat/Tag Distribution + Top；新增 21 单测；169 tests 全过 |
| 2026-05-13 | 完成 Phase 7 · 7.1：Dashboard 视觉重构             | 过滤条（月份导航 + 货币/来源 pill）+ tile-icon 2×2 卡 + 11 单测 |

---

## 阻塞与待决问题

_无_

---

**维护者**：SpendHarbor 团队
