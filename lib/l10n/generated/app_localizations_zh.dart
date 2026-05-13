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
