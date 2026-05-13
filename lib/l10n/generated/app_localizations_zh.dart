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
  String get txEmptyCategory => '暂无分类';

  @override
  String get txEmptySource => '暂无来源';

  @override
  String get txNotePlaceholder => '例如：团建午餐';

  @override
  String get txListEmpty => '本月暂无交易';

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
  String get catAdd => '新建分类';

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
