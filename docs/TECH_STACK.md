# SpendHarbor Local — 技术栈与项目结构（Tech Stack）

> 本文为稳定参考文档，记录技术选型、依赖清单及选型理由、目录结构约定。变更频率低；新增/替换依赖须更新本文。
>
> 配套文档：[PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [DESIGN_STANDARDS.md](DESIGN_STANDARDS.md) · [PROGRESS.md](PROGRESS.md)

---

## 1. 总览

| 维度       | 选型                                         |
| ---------- | -------------------------------------------- |
| 语言       | Dart ≥ 3.7                                   |
| 框架       | Flutter（stable channel）                    |
| 目标平台   | iOS 15+、iPadOS 15+、Android 8.0+ (API 26+)  |
| 架构       | feature-first 分层（domain / data / presentation） |
| 状态管理   | Riverpod                                     |
| 路由       | go_router                                    |
| 本地数据库 | Drift（SQLite）                              |
| 国际化     | flutter_localizations + intl + ARB           |
| 主题       | Material 3 + 自定义 ThemeExtension           |

---

## 2. 依赖清单与选型理由

### 2.1 运行时依赖（`dependencies`）

| 包                            | 版本       | 用途                                     | 选型理由                                                       |
| ----------------------------- | ---------- | ---------------------------------------- | -------------------------------------------------------------- |
| `flutter_localizations`       | sdk        | Flutter 官方多语言基础                   | 必选                                                           |
| `cupertino_icons`             | ^1.0.8     | iOS 风格图标（小范围使用）               | 工程默认                                                       |
| `flutter_riverpod`            | ^2.5.1     | 状态管理 + 依赖注入                      | 编译期安全、可测试、与异步天然友好；比 Provider/Bloc 更轻量    |
| `go_router`                   | ^14.2.7    | 声明式路由 + 深链                        | Flutter 官方维护；路径集中配置，便于状态保留                   |
| `drift`                       | ^2.20.0    | 类型安全 SQLite ORM                      | 类型安全、迁移友好、跨平台；优于 `sqflite`                     |
| `drift_flutter`               | ^0.2.0     | drift 的 Flutter 集成                    | 自动选择 native executor                                       |
| `sqlite3_flutter_libs`        | ^0.5.24    | 内置 SQLite 静态库                       | 保证各平台 SQLite 版本一致                                     |
| `path_provider`               | ^2.1.4     | 获取 App 沙盒目录                        | 用于定位数据库文件                                             |
| `path`                        | ^1.9.0     | 路径拼接工具                             | 标准库                                                         |
| `flutter_secure_storage`      | ^9.2.2     | 加密键值存储                             | 存放 App 锁 PIN；iOS Keychain / Android EncryptedSharedPreferences |
| `local_auth`                  | ^2.3.0     | 生物识别（Face ID / Touch ID / 指纹）    | 配合 App 锁                                                    |
| `intl`                        | any        | 国际化、日期、数字格式化                 | 由 `flutter_localizations` 钉版本                              |
| `lucide_icons`                | ^0.257.0   | Lucide 图标集                            | DESIGN_STANDARDS 指定的唯一图标库                              |
| `material_symbols_icons`      | ^4.2928.1  | Material Symbols 可变图标字体             | 仅用于底部导航；支持 weight/fill 调节，描边比 Lucide 更细       |
| `collection`                  | ^1.18.0    | 集合工具（groupBy、firstWhereOrNull）    | 常用                                                           |
| `uuid`                        | ^4.5.0     | 本地实体主键生成                         | 避免依赖自增 ID，便于导入合并                                  |
| `shared_preferences`          | ^2.3.2     | 非敏感本地偏好（locale、themeMode）      | 比 secure_storage 更轻量；敏感数据仍走 secure_storage          |
| `fl_chart`                    | ^0.69.0    | 柱状图 / 环形图（Stats 统计分析）        | 轻量、纯 Flutter、零网络；钉 0.69 避免 1.x 与当前 Flutter SDK 冲突 |
| `csv`                         | ^6.0.0     | CSV 导出 / 导入                          | RFC 4180 引号/逗号处理；纯 Dart 不联网                      |
| `archive`                     | ^4.0.0     | XLSX zip 容器读写（自研最小 xlsx codec） | 已有 image 间接依赖，提升为直接依赖；纯 Dart 不联网          |
| `xml`                         | ^6.5.0     | XLSX SpreadsheetML XML 解析              | 同上；提升为直接依赖                                          |
| `share_plus`                  | ^12.x      | 调起系统分享面板（导出 / 备份分享）       | 跨平台官方维护；通过临时文件 + XFile 分享                    |
| `file_picker`                 | ^11.0.2    | 选择 CSV / XLSX 导入文件                  | 跨平台；11.x 改为 `FilePicker.pickFiles` 静态调用             |
| `crypto`                      | ^3.0.6     | PIN SHA-256 哈希                          | 标准实现；纯 Dart 不联网                                      |

### 2.2 开发时依赖（`dev_dependencies`）

| 包                | 版本    | 用途                                  |
| ----------------- | ------- | ------------------------------------- |
| `flutter_test`    | sdk     | 单元测试 / Widget 测试                |
| `flutter_lints`   | ^5.0.0  | 官方 lint 规则                        |
| `build_runner`    | ^2.4.13 | 代码生成执行器                        |
| `drift_dev`       | ^2.20.0 | drift 表 / DAO 代码生成               |

### 2.3 暂未引入但已规划

| 包                       | 用途             | 何时引入                       |
| ------------------------ | ---------------- | ------------------------------ |
| `flutter_launcher_icons` | 生成 App 图标    | 上架前                         |
| `flutter_native_splash`  | 生成启动页       | 上架前                         |

> 注：原计划用 `excel` / `syncfusion_flutter_xlsio` 处理 .xlsx，但前者与 `flutter_native_splash` 在 `archive` 大版本上冲突，后者商用收费。最终用 `archive` + `xml` 自研 [`xlsx_codec.dart`](../lib/features/data_io/application/xlsx_codec.dart) 实现 OOXML SpreadsheetML 最小子集（仅字符串 / 数字单元格 + sharedStrings + 多 sheet），约 200 行，零冲突且能往返读写示例文件。

### 2.4 明确不引入

- **任何分析 / 广告 / 崩溃追踪 SDK**（Firebase、Sentry、PostHog、Amplitude 等）—— 与「零网络、零追踪」核心定位冲突
- **任何网络 / 鉴权库**（dio、http、retrofit）—— App 不发起任何对外请求
- **OpenAI / LLM 客户端** —— 同上
- **后端代码生成**（freezed、json_serializable）—— 本地数据库 schema 已由 drift 生成；如未来需要 immutable model，可单独评审

---

## 3. 项目目录结构

```
spend-harbor-app-local/
├── android/                # Android 原生工程（Flutter 自动生成）
├── ios/                    # iOS 原生工程
├── lib/
│   ├── main.dart           # 入口：runApp(ProviderScope(SpendHarborApp))
│   ├── app.dart            # MaterialApp + theme + router 装配
│   ├── theme/              # 设计 token（颜色、间距、圆角、字号、阴影）+ ThemeData
│   ├── l10n/               # ARB 文件 + 生成的本地化代码
│   ├── data/               # 数据层
│   │   ├── database/       # drift database 定义、迁移
│   │   ├── daos/           # 每个表/聚合一个 DAO
│   │   └── seed/           # 首次启动默认数据（分类/标签/来源）
│   ├── domain/             # 领域层（纯 Dart，零 Flutter 依赖）
│   │   ├── entities/       # 实体（Transaction、Category、Tag、Source、Budget）
│   │   ├── enums/          # TransactionType、BudgetPeriod、BudgetScope...
│   │   └── value_objects/  # Money、Period、CurrencyCode...
│   ├── features/           # 功能模块（feature-first）
│   │   ├── dashboard/
│   │   │   ├── application/ # 状态、用例（providers）
│   │   │   └── presentation/# Widget、页面
│   │   ├── stats/
│   │   ├── transactions/
│   │   ├── settings/
│   │   └── onboarding/
│   └── shared/             # 跨 feature 复用
│       ├── widgets/        # AppCard、AppPrimaryButton、AmountText...
│       ├── utils/          # 格式化、扩展方法
│       └── router/         # go_router 配置
├── test/                   # 测试镜像 lib/ 结构
│   ├── data/
│   ├── domain/
│   └── features/
├── docs/
│   ├── PRODUCT_SPEC.md
│   ├── DESIGN_STANDARDS.md
│   ├── TECH_STACK.md       # 本文
│   └── PROGRESS.md
└── pubspec.yaml
```

### 3.1 分层依赖方向

```
presentation ──→ application ──→ domain
                                   ↑
              data (drift) ────────┘
```

- **domain** 纯 Dart，不依赖 Flutter / drift
- **data** 依赖 domain（把 drift 表行转为 entity）
- **application** 依赖 domain + data（providers / use cases）
- **presentation** 依赖 application + shared（UI）

不允许反向依赖。

### 3.2 命名约定

- 文件：`snake_case.dart`
- 类型：`PascalCase`
- 常量：`lowerCamelCase`（如 `colorAction`）
- 私有：以 `_` 开头
- Provider：以 `Provider` 结尾（如 `transactionListProvider`）
- DAO：`XxxDao`
- Entity：单数名词（`Transaction`，不是 `Transactions`）

---

## 4. 代码生成

drift 表与 DAO 通过 `build_runner` 生成。约定：

```bash
# 一次性生成
dart run build_runner build --delete-conflicting-outputs

# 持续 watch
dart run build_runner watch --delete-conflicting-outputs
```

生成的 `*.g.dart` 文件**纳入版本控制**（避免新机器首次拉取后无法编译；与 Flutter 社区惯例一致）。

---

## 5. 构建与运行

```bash
flutter pub get                  # 拉依赖
flutter run                      # 默认设备运行
flutter run -d ios               # 指定 iOS 模拟器
flutter run -d <android-id>      # 指定 Android 设备
flutter test                     # 跑单元/widget 测试
flutter analyze                  # 静态分析
flutter format lib test          # 代码格式化
```

发布构建（上架前）：

```bash
flutter build ipa --release      # iOS
flutter build appbundle --release # Android (AAB)
```

---

## 6. 关键决策记录（ADR 摘要）

| 决策                        | 选择                          | 理由                                                  |
| --------------------------- | ----------------------------- | ----------------------------------------------------- |
| 状态管理                    | Riverpod（非 Provider/Bloc）  | 编译期安全、无 BuildContext 限制、官方推荐演进路线    |
| 本地数据库                  | Drift（非 sqflite/Isar/Hive） | SQL 表达力强、类型安全、迁移成熟、社区活跃            |
| 路由                        | go_router                     | 官方维护、声明式、深链友好                            |
| 主键策略                    | UUID v4（非自增 INT）         | 便于导出/导入合并、跨设备语义一致（即使暂不跨设备）   |
| 多币种                      | 不做汇率换算                  | 见 PRODUCT_SPEC §6.5：避免汇率波动失真，统计分行展示  |
| 不引入网络层                | 严格执行                      | 见 PRODUCT_SPEC §1.3：核心隐私承诺                    |
| 代码生成产物纳入 git        | 是                            | 避免新环境构建依赖外部工具版本一致性                  |

如有重大变更（如更换状态管理库），须新增决策记录并更新本文。

---

**文档版本**：v1.0（2026-05-12）
**维护者**：SpendHarbor 团队
