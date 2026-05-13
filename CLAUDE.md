# SpendHarbor Local — Claude 上下文

本地离线记账 App。付费下载终身使用。**Flutter (iOS + Android)**。

## 硬约束（必须遵守）

- **零网络**：禁止引入 http/dio/firebase/sentry/analytics 等任何联网或追踪 SDK。所有数据留本地。
- **零账户**：无登录/注册/会员/Admin/订阅/计费。所有功能对所有用户全量开放、无配额。
- **多币种不换算**：跨币种统计分行展示，永不汇率换算。
- **设计 token only**：颜色/间距/圆角/字号必须走 `lib/theme/` 常量，禁止字面值。
- **i18n 双语对等**：所有用户可见文案走 ARB，中英两份同步。

## 文档地图（按需读取，不要一次全读）

| 文件                              | 何时读                                                  |
| --------------------------------- | ------------------------------------------------------- |
| `docs/PRODUCT_SPEC.md`            | 实现某个功能 / 不确定业务规则时                         |
| `docs/DESIGN_STANDARDS.md`        | 写 UI / 新组件 / 不确定视觉规范时                       |
| `docs/TECH_STACK.md`              | 加依赖 / 不确定目录结构或分层依赖方向时                 |
| `docs/PROGRESS.md`                | **每次开新会话先读这个**——尤其顶部的「Current Work」段，是细粒度进度与下一步接入点 |

## 目录速查

```
lib/
  main.dart  app.dart
  theme/        # 设计 token + ThemeData
  l10n/         # ARB
  data/         # drift database / daos / seed
  domain/       # 纯 Dart 实体、枚举、值对象
  features/<m>/{application,presentation}
  shared/{widgets,utils,router}
```

分层依赖单向：`presentation → application → domain ← data`。domain 零 Flutter 依赖。

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # drift 代码生成
```

提交前必须 `flutter analyze` 0 issues + `flutter test` 通过。

## 工作流约定

- 改动后必须更新 `docs/PROGRESS.md` 勾选完成项。
- 新增依赖必须更新 `docs/TECH_STACK.md §2`。
- 不要主动创建新文档；用户明确要求才建。
- 不要在代码里加废话注释。

## Checkpoint 机制（防 context 中断）

- 用户说「checkpoint」时：① 跑 `flutter analyze` + `flutter test` 确认可编译 ② 更新 `docs/PROGRESS.md` 的「Current Work」段（勾选已完成子项、更新「下一步接入点」、记录未提交改动） ③ 简短回复确认。
- 完成一个有意义的子任务（一个文件 / 一组测试通过）后，主动提示用户「可以 commit」。
- 新会话恢复时：先 `git status` + `git log --oneline -10` 看代码状态，再读 `docs/PROGRESS.md` 的「Current Work」段，从「下一步接入点」继续。
