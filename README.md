# SpendHarbor Local

本地离线记账 App。一次付费，终身可用。Flutter（iOS + Android）。

## 核心定位

- **零网络**：不联网、不上传、不追踪。所有数据留在本机。
- **零账户**：无注册、无登录、无会员、无订阅。所有功能对所有用户全量开放，无配额。
- **多币种不换算**：跨币种统计分行展示，永不汇率换算。
- **本地优先**：drift / SQLite 全本地；PIN + 生物识别可选本地解锁；备份/导出走系统分享面板（用户自己掌控数据落点）。

## 主要功能

- 交易管理（CRUD、批量、回收站 30 天）
- 分类 / 标签 / 来源 / 预算（无配额上限）
- Dashboard（指标卡 + 预算进度 + 近期交易；月份/货币/来源过滤）
- 统计（趋势柱状图、分类/标签分布 Donut、Top 排行；周/月/年切换）
- 导入 / 导出（XLSX / CSV 双向，交易与 taxonomy 分别）
- 一键备份 / 恢复（`.shbackup` JSON snapshot）+ 备份提醒
- 应用锁（PIN + 生物识别）、亮/暗主题、中英双语

## 常用命令

```bash
flutter pub get
flutter analyze                                              # 必须 0 issues
flutter test                                                 # 当前 171 tests
dart run build_runner build --delete-conflicting-outputs     # drift 代码生成
flutter run -d ios | -d <android-id>                         # 调试运行
```

发布构建：

```bash
flutter build ipa --release         # iOS
flutter build appbundle --release   # Android (AAB)
```

## 文档

- [docs/PRODUCT_SPEC.md](docs/PRODUCT_SPEC.md) — 产品规格、业务规则、UI/UX 详规
- [docs/DESIGN_STANDARDS.md](docs/DESIGN_STANDARDS.md) — 设计 token、组件规范
- [docs/TECH_STACK.md](docs/TECH_STACK.md) — 技术栈、依赖清单、目录结构
- [docs/PROGRESS.md](docs/PROGRESS.md) — 滚动开发进度（新会话先读 Current Work 段）
- [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) — App Store / Google Play 上架清单
- [CLAUDE.md](CLAUDE.md) — Claude / AI 协作上下文（硬约束与工作流）
