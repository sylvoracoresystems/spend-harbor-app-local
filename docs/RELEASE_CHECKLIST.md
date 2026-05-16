# Release Checklist — App Store & Google Play

发布前逐项打勾。优先级：**P0 必做**（不做无法上架/会被拒）/ **P1 推荐** / **P2 可选**。

---

## 0. 共通准备

### P0 法律与隐私
- [ ] 写一份 **隐私政策**（即使零网络也必须有公开 URL）。内容要点：不收集、不上传、不追踪任何数据；所有数据存储在用户设备本地；使用了系统级 Face ID / 生物识别仅用于本地解锁。
- [ ] 准备 **服务条款 / EULA**（付费 App 建议有）。
- [ ] 把上述两份文档放到 GitHub Pages / 自建站点 / Notion public page，拿到稳定 URL。

### P0 元数据（中英双语）
- [ ] App 名称（≤ 30 字符，iOS / Android 各自上限不同）
- [ ] 副标题 / 简短描述（30 / 80 字符）
- [ ] 完整描述（4000 字符内）—— 强调「100% 离线、无账号、无广告、无追踪、一次付费终身使用」
- [ ] 关键词（iOS 100 字符，逗号分隔）
- [ ] 应用分类：Finance
- [ ] 年龄分级问卷答案预先想好（无暴力/色情/赌博，4+）

### P0 视觉资产
- [ ] App 图标 1024×1024 PNG（无透明、无圆角，平台自动裁切）
- [ ] iOS 截图：6.7" (iPhone 15 Pro Max) 和 6.9" (iPhone 16 Pro Max) 各 3–8 张；如支持 iPad 另出 12.9"
- [ ] Android 截图：手机 3–8 张 + Feature Graphic 1024×500
- [ ] 中英两套截图（如要做本地化展示）
- [ ] Splash / Launch Screen（建议接入 `flutter_native_splash`）

### P1 版本与签名前置
- [ ] `pubspec.yaml` version 改为正式 `1.0.0+1`
- [ ] 跑一次 `flutter build ipa --analyze-size` 和 `flutter build appbundle --analyze-size`，确认包体合理（< 50 MB 为佳）
- [ ] 真机测试 PIN / 生物识别 / 导入导出 / 多币种 / 深色模式 / 横竖屏

---

## 1. iOS / App Store

### P0 账号与配置
- [ ] 注册 Apple Developer Program（$99/年）
- [ ] App Store Connect 创建 app，Bundle ID `com.sylvora.spendharbor.local`
- [ ] Xcode 自动管理签名（Team 选自己的开发者账号）

### P0 Info.plist 补全（**当前缺失项**）
- [ ] 添加 `NSFaceIDUsageDescription`（你用了 `local_auth`，没这条会闪退或被拒）
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>用于解锁应用，验证仅在本机进行</string>
  ```
- [ ] 添加 `LSApplicationCategoryType`
  ```xml
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.finance</string>
  ```
- [ ] 检查 `CFBundleDisplayName` 是否为最终上架名

### P0 App Privacy 与合规
- [ ] App Privacy 问卷：全部选 **None / 不收集任何数据**
- [ ] Export Compliance：选「Standard encryption only (App Store Standard Encryption)」或在 Info.plist 加 `ITSAppUsesNonExemptEncryption=false`
- [ ] 内容版权声明、广告标识符 IDFA：不使用

### P0 付费与税务
- [ ] App Store Connect → Agreements, Tax, and Banking → 填 Paid Apps 协议、银行账户、税表（W-8BEN）
- [ ] 设置价格层级（Tier）、可售区域
- [ ] 决定是否开 Family Sharing（付费 App 建议开）

### P1 审核辅助
- [ ] 审核备注（Notes for Reviewer）写明：**本应用 100% 离线，无登录、无内购、无追踪。无需 demo 账号**
- [ ] TestFlight 内测 1–2 轮（自己 + 朋友），过 PIN / 数据迁移 / 多设备首次启动

### P2 提升过审率
- [ ] App Preview 视频（30s，可选）
- [ ] 本地化截图（中英两套）

---

## 2. Android / Google Play

### P0 账号与配置
- [ ] 注册 Google Play Console（$25 一次性）
- [ ] 创建 app，包名 `com.sylvora.spendharbor.local`

### P0 签名（**最重要、最易踩坑**）
- [ ] 生成上传 keystore：`keytool -genkey -v -keystore upload-keystore.jks ...`
- [ ] 配置 `android/key.properties` 和 `android/app/build.gradle` 的 `signingConfig`（参考 Flutter 官方 [Build and release Android app](https://docs.flutter.dev/deployment/android)）
- [ ] **keystore 文件 + 密码必须异地多份备份**（丢了就再也无法更新版本，只能下架重发）
- [ ] 启用 Play App Signing（推荐，让 Google 托管真正的发布签名密钥）

### P0 AndroidManifest 与权限审计
- [ ] 当前 manifest 干净（无 `INTERNET`），保持不变。如未来调试加了 `INTERNET` 一定要在发布前移除
- [ ] 添加生物识别权限声明（`local_auth` 需要）：
  ```xml
  <uses-permission android:name="android.permission.USE_BIOMETRIC" />
  ```
- [ ] 检查 `android.permission.READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` 是否被插件隐式引入；若用 SAF / `file_picker` 通常不需要

### P0 build.gradle 配置
- [ ] `targetSdk` ≥ 当年 Play 要求（2026 年大概率 ≥ 35，发布前查 [Play target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878)）
- [ ] `minSdk` 21+ 即可
- [ ] 启用 R8 / minify shrinkResources 减小包体

### P0 Data Safety 表单
- [ ] 全部勾选 **不收集 / 不分享任何数据**
- [ ] 声明数据加密：传输不适用（无网络）、存储——`drift`/sqlite 默认不加密，可加一句「敏感字段如 PIN 经过 SHA-256 哈希」
- [ ] 数据可删除选项：用户可在 App 内清除全部数据 → 勾上

### P0 付费与税务
- [ ] Google Play Console → Setup → Merchant account → 关联 Google Payments、填税表
- [ ] 设置价格、可售国家

### P1 审核辅助
- [ ] 内部测试轨道（Internal Testing）→ 封闭测试（Closed）→ 正式（Production）逐级放量
- [ ] 在 Play Console 「应用内容」逐项填：广告 / 目标受众 / 新闻类 / COVID / 数据安全 / 政府类 / 财务功能

---

## 3. 项目侧待补充工程项

### P0 代码层
- [ ] **iOS**: 补 `NSFaceIDUsageDescription` 到 `ios/Runner/Info.plist`（上文已列）
- [ ] **iOS**: 补 `LSApplicationCategoryType`
- [ ] **Android**: 补 `<uses-permission android:name="android.permission.USE_BIOMETRIC" />` 到 `android/app/src/main/AndroidManifest.xml`
- [ ] **图标**: 替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset` 和 `android/app/src/main/res/mipmap-*`（推荐用 [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) 一键生成）
- [ ] **Splash**: 接入 `flutter_native_splash`，统一品牌色

### P1 体验打磨
- [ ] 接入崩溃日志「手动导出」入口（设置页 → 导出诊断日志 → 邮件发我），不引入任何联网 SDK
- [ ] 检查 onboarding 中是否覆盖：隐私说明、备份提醒、生物识别可选启用
- [ ] ARB 双语对等校验：跑 `flutter gen-l10n` 看 warning；超长字符串小屏不溢出（FittedBox / Expanded 已修过的同类位置注意复用）
- [ ] 深色模式逐页过一遍
- [ ] 大字号（iOS Dynamic Type 最大档 / Android 字体缩放 200%）不破版

### P1 包体与产物
- [ ] iOS `Release` build 跑通：`flutter build ipa`
- [ ] Android AAB build 跑通：`flutter build appbundle`
- [ ] 删除 `assets/` 中未用资源；检查 `pubspec.yaml` 是否声明了多余文件

---

## 4. 发布日动作

- [ ] 提交 iOS for review（一般 24–48h）
- [ ] 提交 Android Production（一般几小时到 7 天）
- [ ] 两边都开「手动发布」开关，等审核通过后选时间统一上线
- [ ] 上线后第一周盯 1 星差评、邮件反馈

---

## 最容易踩的坑（优先排查）

1. **Android keystore 丢失** → 应用永远无法更新版本
2. **iOS Export Compliance 漏勾** → 每次提审都被打回
3. **Play Data Safety 与代码不符** → AndroidManifest 残留 `INTERNET` 会被自动判定收集数据，整页 Data Safety 都要重填
4. **`NSFaceIDUsageDescription` 缺失** → iOS 首次调起生物识别直接 crash
5. **截图比例不对** → 提交时被退回，又得等审核重排
