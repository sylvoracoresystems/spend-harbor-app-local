# Stats 页视觉与交互重构 — 设计文档

- **日期**：2026-05-14
- **归属**：Phase 8 — Stats 视觉重构
- **状态**：设计

---

## 1. 背景

当前 `lib/features/stats/presentation/stats_page.dart` 只支持「单月」视图：按日聚合柱状图 + 分类 / 标签 Donut + Top 5 列表，全部锚在 `currentMonthProvider`。本次重构升级为多粒度（Week / Month / Year）+ 选中桶时间锚点 + 全局币种/来源筛选 + 双 Distribution + Top（Cat/Tag 双视角）。

硬约束沿用项目根：零网络、零账户、多币种不换算、设计 token only、i18n 双语对等。

---

## 2. 文件结构

```
lib/features/stats/
  application/
    stats_filter.dart              # StatsFilter 值对象 + StatsPeriod 枚举
    stats_filter_provider.dart     # StateNotifier，全局筛选 + 选中桶 + 上下文记忆
    stats_buckets.dart             # 纯函数：generateBuckets / bucketLabel / bucketDateRange
    stats_controller.dart          # 派生 Future/Stream providers（重写，废弃旧的）
    stats_top_aggregator.dart      # 纯函数：aggregateTopByCategory / aggregateTopByTag / Top3CategoriesForTag
  presentation/
    stats_page.dart                # 重写：顶层 scroll 组装 4 区块
    widgets/
      stats_filter_bar.dart
      stats_trend_card.dart
      stats_distribution_card.dart
      stats_top_card.dart
      stats_donut.dart
      stats_section_header.dart
      tag_pill.dart                # 抽出通用 tag pill
```

`features/transactions/application/transactions_list_controller.dart`：扩展 `TransactionsFilter` 增加 `dateStartIso` / `dateEndIso` / `tagId` / `untagged` / `sourceId` 字段；列表查询改用 `watchByDateRange` 当 `dateStart+dateEnd` 同时存在。

`shared/router/app_router.dart`：`/transactions` 增加解析 query params `dateStart` / `dateEnd` / `tag` / `untagged` / `source`。

---

## 3. State / Provider 模型

### 3.1 StatsFilter 值对象

```dart
enum StatsPeriod { week, month, year }

@immutable
class StatsFilter {
  final String currency;            // 必须非空
  final String? sourceId;           // null = All sources
  final StatsPeriod period;         // 默认 month
  final DateTime selectedBucketStart;  // period-aligned
  final DateTime rememberedMonthAnchor; // 用于 Month→Week 上下文记忆
  final DateTime rememberedYearAnchor;  // 用于 Year→Month 上下文记忆
}
```

### 3.2 StatsFilterController（StateNotifier）

| 方法 | 行为 |
|---|---|
| `init()` | 异步：① 默认 period=month，selectedBucketStart=当月 1 号，rememberedMonthAnchor=当月，rememberedYearAnchor=当年。② 币种解析：读 prefs `stats.lastCurrency`，无则取「当月（即初始选中桶范围）笔数最多」的币种 → 仍空则 fallback `defaultCurrencyProvider`。 |
| `setPeriod(p)` | 推导新 selectedBucketStart：Month→Week 用 rememberedMonthAnchor 月末所在周一；Year→Month 用 rememberedYearAnchor 的 12 月 1 号；其它情况用今天对齐。 |
| `selectBucket(start)` | period=month 时同步更新 rememberedMonthAnchor；period=year 时同步更新 rememberedYearAnchor。 |
| `setCurrency(c)` | 写 prefs；若 sourceId 不属于新币种 → 重置 null。 |
| `setSourceId(id?)` | 直接设置。 |

### 3.3 派生 providers

| Provider | 输入 | 输出 |
|---|---|---|
| `trendBucketsProvider` | filter.period + anchor + currency + sourceId | `List<TrendBucket>`（6 / 6 / 3 桶，每桶 income/expense cents） |
| `bucketTransactionsProvider` | filter.selectedBucketStart + period + currency + sourceId | `List<Transaction>`（选中桶原始 rows） |
| `categoryDistributionProvider.family(TxType)` | bucketTransactions + type | `(List<CategorySlice>, totalCents)` |
| `tagDistributionProvider.family(TxType)` | bucketTransactions + type + tagsByTx | `(List<TagSlice>, totalCents, untaggedCents)` |
| `topByCategoryProvider.family(TxType)` | bucketTransactions + type + tagsByTx + categories | `List<TopCategoryRow>`（含 tag 频次 + count） |
| `topByTagProvider.family(TxType)` | 同上 | `(List<TopTagRow>, UntaggedRow?)`（含 Top3 categories per tag） |

不变量：
- Trend 不响应 `selectedBucketStart` 变化（仅看 period + anchor）。
- Distribution / Top 全部响应 `selectedBucketStart`。
- Cat Distribution / Tag Distribution / Top 三处的 Expense/Income 切换是 **widget local state**，互不影响。

### 3.4 取数策略

新 DAO 方法（如 `transaction_dao.dart` 暂无则补）：`Future<List<Transaction>> findByDateRange(startIso, endIso)`，复用现有 between 流的同范围查询的一次性 future 版本。Trend 一次取 6 桶并集窗口，按桶 in-memory 分组。Currency + sourceId 在内存层过滤（数据量小）。

---

## 4. 时间桶逻辑

`generateBuckets(period, anchor)`：

| Period | 锚点 | 桶数 | 桶宽度 | 最右桶 |
|---|---|---|---|---|
| Week | `rememberedMonthAnchor` 月末日所在 ISO 周 | 6 | 7 天，周一起点 | anchor 所在周 |
| Month | 今天 | 6 | 月（month-start ~ month-end） | anchor 所在月 |
| Year | 今天 | 3 | 年（1/1 ~ 12/31） | anchor 所在年 |

`bucketLabel(period, bucket, locale)` 用 `intl.DateFormat`：
- Week → `MMMd`（"Mar 1"）
- Month → `MMM`（"Jan"）
- Year → `yyyy`（"2026"）

Range chip 文案（选中桶）：
- Week → `MMM d – MMM d`
- Month → `MMMM yyyy`
- Year → `yyyy`

---

## 5. UI 规格

### 5.1 全局

- 整页 `SingleChildScrollView`，padding vertical=12dp。
- 卡片移动端贴边（horizontal margin=0），圆角 16dp，背景白 + 1px 浅描边 + 轻 shadow。
- 卡片间隔 12dp gap。
- 字号：标题 15sp / 正文 13–14sp / 辅助 10–11sp / 金额 mono font。
- 颜色 token：`colorPrimary`（青绿，action）、`colorIncome` 绿、`colorExpense` 红、`colorPrimarySoft` hover/激活底。

### 5.2 §0 Filter card

- Card padding 12dp。
- 第一行：`Row(Expanded(pillDropdown currency), 8dp, Expanded(pillDropdown source))`。
- 第二行：`SegmentedButton<StatsPeriod>` 占满宽度，3 段等分，激活段 `colorPrimarySoft` 底。

Source dropdown items 派生：`sourcesProvider.where(s => s.currency == filter.currency)`，首项 "All sources" 固定。

### 5.3 §1 Trend card

- 标题行：`Icons.bar_chart` + `statsTrendTitle`。
- range chip：`colorPrimarySoft` 底、6dp 圆角、horizontal 8 / vertical 2、11sp 文字。
- BarChart（fl_chart）：高度 180dp。每桶两根并列柱（绿 income / 红 expense），柱宽 8dp、组间距 24dp。X 轴 label = bucket.label，Y 轴隐藏。
- 点击柱组 → `selectBucket(bucket.start)`；选中态柱组背景描边或浅底矩形高亮。
- Loading → 灰字 "Loading..."；error → 红字（仅本卡）；空 → 6 空柱 + "No data"。

### 5.4 §2 Distribution（两张子卡）

抽 `_DistributionCard<T>` 通用 widget，外部传入 `title` / `donutData` / `buildRow` / `emptyText`。两张卡：Category 与 Tag，各自独立 local `useState<TxType>`。

- 标题行：左 icon+title，右 `SegmentedButton<TxType>`（Expense 红软底 / Income 绿软底）。
- Donut：`PieChart` 外径 80dp / 内径 50dp。Stack 中心叠 `Column(Text 灰色 10sp "EXPENSE"/"INCOME", Text mono 14sp 红/绿 total)`。
- 列表：> 10 项 → `ConstrainedBox(maxHeight: 400)` + 内 `ListView`；否则 `Column`。
- 行点击 → 跳 `/transactions`（详见 §6）。

行 widget：
- Category：`Row(28×28 圆形 category.color icon, 8dp, Expanded(name 截断), amount mono)`。
- Tag：`Row(Container colorBackground=tag.color textWhite pill, Spacer, amount)`。

### 5.5 §3 Top card

顶部 `Row`：`Icons.emoji_events` + 短标题 + `Spacer` + `_TabsCategoryTag`（local `useState<TopMode>`，激活 tab 下划线 2px primary）+ 8dp + `SegmentedButton<TxType>`。

Body：
- **By Category**：`Column` 最多 10 行，每行 3 层：
  1. `Row(28×28 圆 icon, 8dp, Expanded(name), amount mono 大号)`
  2. `Padding(left:36, Wrap(spacing:4, runSpacing:4, tagPills))` — 最多 6 个 tag pill，按出现频次降序，超出 → 末尾灰色 "+N"。
  3. `Padding(left:36, Text("Count: N" 灰 11sp))`
- **By Tag**：每行 3 层：
  1. `Row(大号 tag pill colorBackground=tag.color, Spacer, amount)`
  2. `Padding(left:8, Wrap(catPill: icon+name, 下方再 Text amount))` — Top 3 categories per tag。
  3. `Padding(Text("Count: N"))`
- Untagged 行（仅 By Tag，存在未打标签的交易时）：灰色斜体 pill "Untagged" + amount + count。
- 末尾若总数 > 10：`TextButton("+ N more · View all in Tag Distribution →")` → `Scrollable.ensureVisible(_tagDistKey)`。
- 最底注脚（仅 By Tag）：9sp italic 灰色：`statsTopMultiTagNote`。

### 5.6 Loading / Empty / Error

- 每卡 `AsyncValue.when`。
- 切 filter 用 `valueOrPrevious`（保留旧数据 + 局部 loading）避免整页闪烁。
- Trend 失败显示红字；其它静默 empty。

### 5.7 金额格式化

```dart
String formatSigned(int cents, String currency, TxType type) {
  final abs = (cents.abs() / 100).toStringAsFixed(2);
  final sym = currencySymbol(currency); // 已有 helper
  return type == TxType.expense ? '-$sym$abs' : '$sym$abs';
}
```

UI 处再叠 `TextStyle(fontFamily: monoFont, color: type==expense ? colorExpense : colorIncome)`。

---

## 6. 路由穿透

`TransactionsFilter` 扩展：

```dart
class TransactionsFilter {
  final String? dayIso;
  final String? dateStartIso;
  final String? dateEndIso;
  final String? categoryId;
  final String? tagId;
  final bool untagged;
  final String? sourceId;
}
```

`transactions_list_controller`：当 `dateStartIso + dateEndIso` 同时存在 → 调用 DAO `watchByDateRange(start, end)` 替代 `watchByMonth`；月份切换器若在 range 模式下视为清除 range 后切月。Filter chip 文案：
- `tagId` → `# tagName`
- `untagged` → `Untagged`
- `dateRange` → `Mar 1 – Mar 7`

`/transactions` query params 解析（go_router redirect 或页面 init）：

| Param | 含义 |
|---|---|
| `month=YYYY-MM` | 既有 |
| `day=YYYY-MM-DD` | 既有 |
| `dateStart=YYYY-MM-DD&dateEnd=YYYY-MM-DD` | 新 |
| `category=:id` | 既有 |
| `tag=:id` | 新 |
| `untagged=1` | 新 |
| `source=:id` | 新 |

Stats 穿透传参规则：

| 来源 | 传参 |
|---|---|
| Week 桶点击 + 行点击 | `dateStart`+`dateEnd`+ source + (category/tag/untagged) |
| Month 桶点击 + 行点击 | `month=YYYY-MM` + source + ... |
| Year 桶点击 + 行点击 | `dateStart=YYYY-01-01&dateEnd=YYYY-12-31` + source + ... |

---

## 7. i18n

新增 ARB keys（en + zh 双份）：

```
statsFilterCurrency / statsFilterSource / statsFilterAllSources
statsPeriodWeek / statsPeriodMonth / statsPeriodYear
statsTrendTitle (覆盖)
statsDistCategoryTitle / statsDistTagTitle
statsTypeExpense / statsTypeIncome
statsDistCenterExpense / statsDistCenterIncome
statsTopTitle / statsTopByCategory / statsTopByTag
statsTopCountLabel (ICU "Count: {count}")
statsUntagged
statsTopMoreLink (ICU "+ {n} more · View all in Tag Distribution →")
statsTopMultiTagNote
statsNoData / statsNoTaggedData / statsLoading / statsError
```

继续走现有 `gen-l10n` / ARB 一致性测试。

---

## 8. 测试

纯函数单测（无 UI）：

- `stats_buckets_test.dart`（6）：week 跨年 / month 一般 / year 3 桶 / Month→Week 上下文记忆 / Year→Month 上下文记忆 / label 本地化
- `stats_filter_controller_test.dart`（5）：init 选 dominant currency / init prefs 优先 / setPeriod 推导新 anchor / setCurrency 重置 sourceId / selectBucket 同步上下文锚点
- `stats_top_aggregator_test.dart`（6）：aggregateTopByCategory 金额降序 + tag 频次 + 截 top 10 / aggregateTopByTag 含 untagged / Top 3 cats per tag / Income mode / source filter / multi-tag 全额累加
- `bucket_transactions_filter_test.dart`（4）：currency + source 双过滤 / Untagged 过滤 / dateRange edge / 空集

合计约 21 例新测。

**Verification**：`flutter analyze` 0 + `flutter test` 全绿；手动跑 5 个交互场景：① Period 切换不残留 ② 柱子点击同步 chip + Dist/Top ③ Cat/Tag 行跳列表 ④ Currency 切换 Source 重置 ⑤ Month→Week→Month 上下文记忆。

---

## 9. 关键决策记录

| 决策 | 选项 |
|---|---|
| Week 6 桶规则 | 锚定月份末尾，回溯 6 周（跨月） |
| Top 行数 | 10 |
| Week 桶穿透 | 扩展 TransactionsFilter 增加 dateRange |
| Auto currency 依据 | init 优先 prefs `stats.lastCurrency`；无则取「当前选中桶范围（初次=当月）笔数最多」的币种；仍空则 fallback `defaultCurrencyProvider` |
| Top Tag pills 上限 | 6 个，频次降序，超出 +N |
| 空桶初始行为 | 仍以当前桶为默认，显示 No data |
| Source × Currency 联动 | Source 列表只显示选定币种的 sources |
| Year 桶穿透 | 落到 dateStart=YYYY-01-01 ~ dateEnd=YYYY-12-31（不改 transactions 整年视图） |

---

## 10. 范围之外（YAGNI）

- Quarter 粒度
- 自定义日期范围 picker
- 多币种合并视图（仍按 spec 不换算）
- 导出 Stats 视图截图
- 收藏 / 多筛选预设
