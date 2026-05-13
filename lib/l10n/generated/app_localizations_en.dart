// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SpendHarbor';

  @override
  String get themePreviewTitle => 'Theme Preview';

  @override
  String get themeToggleLight => 'Light';

  @override
  String get themeToggleDark => 'Dark';

  @override
  String get themeToggleSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageSystem => 'System';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabTransactions => 'Transactions';

  @override
  String get tabSettings => 'Settings';

  @override
  String get fabAddTransaction => 'Add transaction';

  @override
  String get newTransactionTitle => 'New Transaction';

  @override
  String get editTransactionTitle => 'Edit Transaction';

  @override
  String get onboardingTitle => 'Welcome to SpendHarbor';

  @override
  String get onboardingSubtitle => 'Track your spending. Fully offline. Yours forever.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsTags => 'Tags';

  @override
  String get settingsSources => 'Sources';

  @override
  String get settingsBudgets => 'Budgets';

  @override
  String get settingsExport => 'Export Data';

  @override
  String get settingsImport => 'Import Data';

  @override
  String get settingsBackup => 'Backup & Restore';

  @override
  String get settingsCurrency => 'Default Currency';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSecurity => 'App Lock';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLegal => 'Privacy & Terms';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get txFieldAmount => 'Amount';

  @override
  String get txFieldType => 'Type';

  @override
  String get txFieldCategory => 'Category';

  @override
  String get txFieldSource => 'Source';

  @override
  String get txFieldDate => 'Date';

  @override
  String get txFieldTags => 'Tags';

  @override
  String get txFieldNote => 'Note';

  @override
  String get txTypeExpense => 'Expense';

  @override
  String get txTypeIncome => 'Income';

  @override
  String get txSave => 'Save';

  @override
  String get txDelete => 'Delete';

  @override
  String get txDeleteConfirmTitle => 'Delete this transaction?';

  @override
  String get txDeleteConfirmBody => 'It will move to the recycle bin for 30 days.';

  @override
  String get txCancel => 'Cancel';

  @override
  String get txErrAmountRequired => 'Enter an amount';

  @override
  String get txErrAmountInvalid => 'Amount must be greater than 0';

  @override
  String get txErrCategoryRequired => 'Pick a category';

  @override
  String get txErrSourceRequired => 'Pick a source';

  @override
  String get txEmptyCategory => 'No categories yet';

  @override
  String get txEmptySource => 'No sources yet';

  @override
  String get txNotePlaceholder => 'e.g. Lunch with team';

  @override
  String get txListEmpty => 'No transactions this month';

  @override
  String get txMonthPrev => 'Previous month';

  @override
  String get txMonthNext => 'Next month';

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String selectionTitle(int count) {
    return '$count selected';
  }

  @override
  String get selectionCancel => 'Cancel selection';

  @override
  String get selectionDelete => 'Delete';

  @override
  String selectionDeleteConfirmTitle(int count) {
    return 'Delete $count transactions?';
  }

  @override
  String get selectionDeleteConfirmBody => 'They will move to the recycle bin for 30 days.';

  @override
  String get dashIncome => 'Income';

  @override
  String get dashExpense => 'Expense';

  @override
  String get dashNet => 'Net';

  @override
  String get dashCount => 'Transactions';

  @override
  String get dashRecent => 'Recent';

  @override
  String get dashViewAll => 'View all';

  @override
  String get dashEmpty => 'No transactions yet — tap + to add one.';

  @override
  String get recycleBinTitle => 'Recycle Bin';

  @override
  String get recycleBinEmpty => 'Nothing here. Deleted transactions stay for 30 days.';

  @override
  String recycleBinDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get recycleBinRestore => 'Restore';

  @override
  String get recycleBinPurge => 'Delete forever';

  @override
  String get recycleBinPurgeConfirmTitle => 'Delete forever?';

  @override
  String get recycleBinPurgeConfirmBody => 'This transaction will be permanently removed and cannot be recovered.';

  @override
  String get catFood => 'Food';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catHome => 'Home';

  @override
  String get catMedical => 'Medical';

  @override
  String get catEducation => 'Education';

  @override
  String get catTelecom => 'Telecom';

  @override
  String get catTravel => 'Travel';

  @override
  String get catOther => 'Other';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBonus => 'Bonus';

  @override
  String get catInvestment => 'Investment';

  @override
  String get catOtherIncome => 'Other Income';

  @override
  String get tagWork => 'Work';

  @override
  String get tagPersonal => 'Personal';

  @override
  String get tagFamily => 'Family';

  @override
  String get tagImportant => 'Important';

  @override
  String get tagReimburse => 'Reimburse';

  @override
  String get srcCash => 'Cash';
}
