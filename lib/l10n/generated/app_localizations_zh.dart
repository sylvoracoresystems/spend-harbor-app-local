// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'SpendHarbor';

  @override
  String get themePreviewTitle => '主题预览';

  @override
  String get themeToggleLight => '浅色';

  @override
  String get themeToggleDark => '深色';

  @override
  String get themeToggleSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get tabDashboard => '概览';

  @override
  String get tabStats => '统计';

  @override
  String get tabTransactions => '交易';

  @override
  String get tabSettings => '设置';

  @override
  String get fabAddTransaction => '新建交易';

  @override
  String get newTransactionTitle => '新建交易';

  @override
  String get editTransactionTitle => '编辑交易';

  @override
  String get onboardingTitle => '欢迎使用 SpendHarbor';

  @override
  String get onboardingSubtitle => '纯本地记账，永久属于你。';

  @override
  String get onboardingGetStarted => '开始使用';

  @override
  String get settingsProfile => '个人偏好';

  @override
  String get settingsCategories => '分类管理';

  @override
  String get settingsTags => '标签管理';

  @override
  String get settingsSources => '来源管理';

  @override
  String get settingsBudgets => '预算管理';

  @override
  String get settingsExport => '数据导出';

  @override
  String get settingsImport => '数据导入';

  @override
  String get settingsBackup => '备份与恢复';

  @override
  String get settingsCurrency => '默认货币';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsSecurity => '应用锁';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsLegal => '隐私与条款';

  @override
  String get comingSoon => '即将上线';

  @override
  String get txFieldAmount => '金额';

  @override
  String get txFieldType => '类型';

  @override
  String get txFieldCategory => '分类';

  @override
  String get txFieldSource => '来源';

  @override
  String get txFieldDate => '日期';

  @override
  String get txFieldTags => '标签';

  @override
  String get txFieldNote => '备注';

  @override
  String get txTypeExpense => '支出';

  @override
  String get txTypeIncome => '收入';

  @override
  String get txSave => '保存';

  @override
  String get txDelete => '删除';

  @override
  String get txDeleteConfirmTitle => '删除这笔交易？';

  @override
  String get txDeleteConfirmBody => '将进入回收站，30 天内可恢复。';

  @override
  String get txCancel => '取消';

  @override
  String get txErrAmountRequired => '请输入金额';

  @override
  String get txErrAmountInvalid => '金额必须大于 0';

  @override
  String get txErrCategoryRequired => '请选择分类';

  @override
  String get txErrSourceRequired => '请选择来源';

  @override
  String get txErrCurrencyRequired => '请选择币种';

  @override
  String get txEmptyCategory => '暂无分类';

  @override
  String get txManageCategories => '管理';

  @override
  String get txEmptySource => '暂无来源';

  @override
  String get txNotePlaceholder => '例如：团建午餐';

  @override
  String get txAmountPlaceholder => '0.00';

  @override
  String get txSourcePlaceholder => '来源';

  @override
  String get txTagSearchPlaceholder => '搜索标签（最多 5 个）…';

  @override
  String get txTagNoMatch => '无匹配标签';

  @override
  String txTagMore(int count) {
    return '更多 (+$count)';
  }

  @override
  String get txTagLess => '收起';

  @override
  String get txTagLimitReached => '最多选择 5 个标签';

  @override
  String txTagCreateAction(String name) {
    return '创建 \"$name\"';
  }

  @override
  String get txNoteOptional => '备注（选填）';

  @override
  String get txListEmpty => '本月暂无交易';

  @override
  String txListCount(int count) {
    return '$count 笔';
  }

  @override
  String txFilterAppliedCategory(String name) {
    return '已按分类筛选：$name';
  }

  @override
  String txFilterAppliedTag(String name) {
    return '已按标签筛选：$name';
  }

  @override
  String get txFilterAppliedUntagged => '已筛选：无标签';

  @override
  String get txFilterAppliedDateRange => '已按日期区间筛选';

  @override
  String get txFilterClear => '清除';

  @override
  String get settingsSectionAccount => '账户';

  @override
  String get settingsSectionLibrary => '数据资料';

  @override
  String get settingsSectionDataIO => '导入与备份';

  @override
  String get settingsSectionPreferences => '偏好';

  @override
  String get settingsSectionSecurity => '安全';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get txMonthPrev => '上个月';

  @override
  String get txMonthNext => '下个月';

  @override
  String get dayToday => '今天';

  @override
  String get dayYesterday => '昨天';

  @override
  String selectionTitle(int count) {
    return '已选 $count 项';
  }

  @override
  String get selectionCancel => '取消选择';

  @override
  String get selectionDelete => '删除';

  @override
  String selectionDeleteConfirmTitle(int count) {
    return '删除 $count 笔交易？';
  }

  @override
  String get selectionDeleteConfirmBody => '将进入回收站，30 天内可恢复。';

  @override
  String get dashIncome => '收入';

  @override
  String get dashExpense => '支出';

  @override
  String get dashNet => '净额';

  @override
  String get dashCount => '笔数';

  @override
  String get dashFilterCurrency => '货币';

  @override
  String get dashFilterSource => '来源';

  @override
  String get dashFilterAll => '全部';

  @override
  String get dashPrevMonth => '上个月';

  @override
  String get dashNextMonth => '下个月';

  @override
  String dashOthersBadge(int count) {
    return '+$count';
  }

  @override
  String get dashRecent => '近期';

  @override
  String get dashViewAll => '查看全部';

  @override
  String get dashEmpty => '本月暂无交易，点击 + 新建一笔。';

  @override
  String get dashBudgets => '预算';

  @override
  String get dashBudgetTotal => '总额';

  @override
  String dashBudgetOver(String amount) {
    return '超支 $amount';
  }

  @override
  String get dashBudgetManage => '管理';

  @override
  String get statsFilterCurrency => '货币';

  @override
  String get statsFilterSource => '来源';

  @override
  String get statsFilterAllSources => '全部来源';

  @override
  String get statsPeriodWeek => '周';

  @override
  String get statsPeriodMonth => '月';

  @override
  String get statsPeriodYear => '年';

  @override
  String get statsTrendTitle => '支出概览';

  @override
  String get statsDistCategoryTitle => '分类分布';

  @override
  String get statsDistTagTitle => '标签分布';

  @override
  String get statsTypeExpense => '支出';

  @override
  String get statsTypeIncome => '收入';

  @override
  String get statsDistCenterExpense => '支出';

  @override
  String get statsDistCenterIncome => '收入';

  @override
  String get statsTopTitle => '排行';

  @override
  String get statsTopByCategory => '分类';

  @override
  String get statsTopByTag => '标签';

  @override
  String statsTopCountLabel(int count) {
    return '笔数：$count';
  }

  @override
  String get statsUntagged => '未打标签';

  @override
  String statsTopMoreLink(int n) {
    return '+ 还有 $n 条 · 查看「标签分布」→';
  }

  @override
  String get statsTopMultiTagNote => '* 同一交易可同时属于多个标签，金额合计可能大于实际总和。';

  @override
  String get statsNoData => '暂无数据';

  @override
  String get statsNoTaggedData => '本期无打标签交易';

  @override
  String get statsLoading => '加载中…';

  @override
  String get statsError => '加载失败';

  @override
  String get exportTitle => '数据导出';

  @override
  String get exportSectionTransactions => '交易';

  @override
  String get exportSectionTaxonomy => '分类、标签与来源';

  @override
  String get exportTaxonomyHint => '把所有分类、标签、来源导出到一个 xlsx（3 个工作表）。';

  @override
  String get exportTaxonomyButton => '导出分类配置';

  @override
  String get exportFormatLabel => '格式';

  @override
  String get exportFormatXlsx => 'XLSX';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get exportScopeLabel => '范围';

  @override
  String exportScopeMonth(String month) {
    return '$month';
  }

  @override
  String get exportScopeAll => '全部';

  @override
  String get exportScopeRange => '自定义';

  @override
  String get exportRangeStart => '开始日期';

  @override
  String get exportRangeEnd => '结束日期';

  @override
  String get exportRangeInvalid => '结束日期必须不早于开始日期。';

  @override
  String get exportEmptyRange => '所选日期范围内没有交易。';

  @override
  String get exportButton => '导出交易';

  @override
  String get exportEmptyMonth => '本月暂无交易。';

  @override
  String get exportEmptyAll => '暂无任何交易。';

  @override
  String get exportDone => '已唤起分享面板';

  @override
  String get importTitle => '数据导入';

  @override
  String get importPickFile => '选择文件（xlsx 或 csv）';

  @override
  String get importAllowDuplicatesLabel => '允许重复导入';

  @override
  String get importAllowDuplicatesHint => '即使已存在「同日期 / 类型 / 分类 / 账户 / 金额 / 币种 / 备注」完全相同的交易，也照样写入。';

  @override
  String get importHint => '请选择 SpendHarbor 的 xlsx（交易 / 分类配置）或 CSV 文件。导入交易时缺失的分类/标签/来源会自动新建。';

  @override
  String importTxSummary(int parsed, int imported, int duplicates, int invalid) {
    return '解析 $parsed · 已导入 $imported · 重复 $duplicates · 无效 $invalid';
  }

  @override
  String importTxAutoCreated(int cats, int tags, int srcs) {
    return '自动新建 · $cats 分类 · $tags 标签 · $srcs 来源';
  }

  @override
  String get importTaxonomyConfirmTitle => '替换分类配置？';

  @override
  String get importTaxonomyConfirmBody => '将以所选文件为准覆盖现有分类、标签、来源。文件中没有的项目会被隐藏（已有交易仍保持引用）。';

  @override
  String importTaxonomySummary(int cAdded, int cUpdated, int cDeleted, int tAdded, int tUpdated, int tDeleted, int sAdded, int sUpdated, int sDeleted) {
    return '分类 +$cAdded ~$cUpdated -$cDeleted · 标签 +$tAdded ~$tUpdated -$tDeleted · 来源 +$sAdded ~$sUpdated -$sDeleted';
  }

  @override
  String get backupTitle => '备份与恢复';

  @override
  String get backupExportHint => '把数据完整快照保存为 .shbak 文件。';

  @override
  String get backupExportButton => '导出备份';

  @override
  String get backupRestoreHint => '从 .shbak 文件恢复，将**完全替换**当前所有数据。';

  @override
  String get backupRestoreButton => '从备份恢复';

  @override
  String get backupRestoreConfirmTitle => '替换全部数据？';

  @override
  String get backupRestoreConfirmBody => '当前的分类、标签、来源、预算和交易将被备份中的数据替换。此操作不可撤销。';

  @override
  String get backupRestoreDone => '已完成恢复';

  @override
  String backupVersionMismatch(int found, int expected) {
    return '备份版本 $found 无法恢复（期望 $expected）。';
  }

  @override
  String get backupNever => '你还没备份过，点这里开始备份。';

  @override
  String backupOverdue(int days) {
    return '已 $days 天未备份，建议立即备份。';
  }

  @override
  String backupRecent(int days) {
    return '上次备份于 $days 天前。';
  }

  @override
  String get profileFieldNickname => '昵称';

  @override
  String get profileNicknameHint => '仅用于本机问候与头像缩写，不会上传。';

  @override
  String profileGreeting(String nickname) {
    return '你好，$nickname';
  }

  @override
  String get appearanceSystem => '跟随系统';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceDark => '深色';

  @override
  String get lockTitle => '应用锁';

  @override
  String get lockEnableToggle => '打开应用需要 PIN';

  @override
  String get lockBiometricToggle => '允许生物识别';

  @override
  String get lockSetPin => '设置 PIN';

  @override
  String get lockChangePin => '修改 PIN';

  @override
  String get lockRemove => '关闭应用锁';

  @override
  String get lockEnterPin => '输入 PIN';

  @override
  String get lockConfirmPin => '确认 PIN';

  @override
  String get lockMismatch => '两次输入不一致';

  @override
  String get lockTooShort => 'PIN 至少 4 位';

  @override
  String get lockWrong => 'PIN 错误';

  @override
  String get lockUnlockTitle => '解锁 SpendHarbor';

  @override
  String get lockUseBiometric => '使用生物识别';

  @override
  String get lockBiometricReason => '解锁 SpendHarbor';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutTagline => '纯本地记账，永久属于你。';

  @override
  String get aboutDescription => 'SpendHarbor Local 的全部数据都保存在你的设备上。无账号、无服务器、无追踪。随时可导出、导入或备份。';

  @override
  String get aboutCreditsTitle => '致谢';

  @override
  String get aboutCreditsBody => '基于 Flutter、Drift、Riverpod、go_router、fl_chart 和 Lucide 图标构建。';

  @override
  String get legalPrivacyTitle => '隐私';

  @override
  String get legalPrivacyBody => 'SpendHarbor Local 不收集也不上传任何个人数据。所有分类、交易、预算和偏好都保留在你的设备上。应用本身不发起任何网络请求。';

  @override
  String get legalTermsTitle => '服务条款';

  @override
  String get legalTermsBody => '本应用按现状提供。请定期备份你的数据；若设备损坏或卸载未备份，开发者无法找回信息。';

  @override
  String get recycleBinTitle => '回收站';

  @override
  String get recycleBinEmpty => '回收站空着。删除的交易会保留 30 天。';

  @override
  String recycleBinDaysLeft(int days) {
    return '剩 $days 天';
  }

  @override
  String get recycleBinRestore => '恢复';

  @override
  String get recycleBinPurge => '彻底删除';

  @override
  String get recycleBinPurgeConfirmTitle => '彻底删除？';

  @override
  String get recycleBinPurgeConfirmBody => '这笔交易将被永久删除且不可恢复。';

  @override
  String get catNewTitle => '新建分类';

  @override
  String get catEditTitle => '编辑分类';

  @override
  String get catFieldName => '名称';

  @override
  String get catFieldType => '类型';

  @override
  String get catFieldIcon => '图标';

  @override
  String get catFieldColor => '颜色';

  @override
  String get catErrNameRequired => '请输入名称';

  @override
  String get catErrNameDuplicate => '已存在同名分类';

  @override
  String get catDeleteConfirmTitle => '删除该分类？';

  @override
  String get catDeleteConfirmBody => '已有交易仍保留对该分类的引用，但此分类将不再出现在选择列表中。';

  @override
  String get catEmptyExpense => '暂无支出分类';

  @override
  String get catEmptyIncome => '暂无收入分类';

  @override
  String get catEmpty => '暂无分类';

  @override
  String get catAdd => '新建分类';

  @override
  String get catSearchHint => '搜索分类';

  @override
  String get colorCustomTitle => '自定义颜色';

  @override
  String get catTypeExpenseBadge => '支出';

  @override
  String get catTypeIncomeBadge => '收入';

  @override
  String get tagNewTitle => '新建标签';

  @override
  String get tagEditTitle => '编辑标签';

  @override
  String get tagErrNameRequired => '请输入名称';

  @override
  String get tagErrNameDuplicate => '已存在同名标签';

  @override
  String get tagDeleteConfirmTitle => '删除该标签？';

  @override
  String get tagDeleteConfirmBody => '已有交易仍保留对该标签的引用，但此标签将不再出现在选择列表中。';

  @override
  String get tagEmpty => '暂无标签';

  @override
  String get tagAdd => '新建标签';

  @override
  String get tagSearchHint => '搜索标签';

  @override
  String get srcNewTitle => '新建来源';

  @override
  String get srcEditTitle => '编辑来源';

  @override
  String get srcFieldCurrency => '币种';

  @override
  String get srcErrNameRequired => '请输入名称';

  @override
  String get srcErrNameDuplicate => '已存在同名来源';

  @override
  String get srcDeleteConfirmTitle => '删除该来源？';

  @override
  String get srcDeleteConfirmBody => '已有交易仍保留对该来源的引用，但此来源将不再出现在选择列表中。';

  @override
  String get srcEmpty => '暂无来源';

  @override
  String get srcAdd => '新建来源';

  @override
  String get budgetNewTitle => '新建预算';

  @override
  String get budgetEditTitle => '编辑预算';

  @override
  String get budgetFieldPeriod => '周期';

  @override
  String get budgetFieldScope => '范围';

  @override
  String get budgetFieldAmount => '金额';

  @override
  String get budgetFieldCurrency => '币种';

  @override
  String get budgetFieldCategory => '分类';

  @override
  String get budgetFieldStartsOn => '起始日';

  @override
  String get budgetPeriodWeek => '周';

  @override
  String get budgetPeriodMonth => '月';

  @override
  String get budgetPeriodYear => '年';

  @override
  String get budgetScopeTotal => '总额';

  @override
  String get budgetScopeCategory => '分类';

  @override
  String get budgetErrAmount => '金额必须大于 0';

  @override
  String get budgetErrCategoryRequired => '请选择分类';

  @override
  String get budgetDeleteConfirmTitle => '删除该预算？';

  @override
  String get budgetDeleteConfirmBody => '该预算将被删除，交易不受影响。';

  @override
  String get budgetEmpty => '暂无预算';

  @override
  String get budgetAdd => '新建预算';

  @override
  String get catFood => '餐饮';

  @override
  String get catTransport => '交通';

  @override
  String get catShopping => '购物';

  @override
  String get catEntertainment => '娱乐';

  @override
  String get catHome => '居家';

  @override
  String get catMedical => '医疗';

  @override
  String get catEducation => '教育';

  @override
  String get catTelecom => '通讯';

  @override
  String get catTravel => '旅行';

  @override
  String get catOther => '其他';

  @override
  String get catSalary => '工资';

  @override
  String get catBonus => '奖金';

  @override
  String get catInvestment => '投资';

  @override
  String get catOtherIncome => '其他收入';

  @override
  String get tagWork => '工作';

  @override
  String get tagPersonal => '私人';

  @override
  String get tagFamily => '家庭';

  @override
  String get tagImportant => '重要';

  @override
  String get tagReimburse => '可报销';

  @override
  String get srcCash => '现金';
}
