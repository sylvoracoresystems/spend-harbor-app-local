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
  String get txErrCurrencyRequired => 'Pick a currency';

  @override
  String get txEmptyCategory => 'No categories yet';

  @override
  String get txEmptySource => 'No sources yet';

  @override
  String get txNotePlaceholder => 'e.g. Lunch with team';

  @override
  String get txAmountPlaceholder => '0.00';

  @override
  String get txSourcePlaceholder => 'Source';

  @override
  String get txTagSearchPlaceholder => 'Search tags (max 5)...';

  @override
  String get txTagNoMatch => 'No matching tags';

  @override
  String txTagMore(int count) {
    return 'More (+$count)';
  }

  @override
  String get txTagLess => 'Less';

  @override
  String get txTagLimitReached => 'You can pick up to 5 tags';

  @override
  String get txNoteOptional => 'Note (optional)';

  @override
  String get txListEmpty => 'No transactions this month';

  @override
  String txFilterAppliedCategory(String name) {
    return 'Filtered by category: $name';
  }

  @override
  String txFilterAppliedTag(String name) {
    return 'Filtered by tag: $name';
  }

  @override
  String get txFilterAppliedUntagged => 'Filtered: untagged';

  @override
  String get txFilterAppliedDateRange => 'Filtered by date range';

  @override
  String get txFilterClear => 'Clear';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionLibrary => 'Library';

  @override
  String get settingsSectionDataIO => 'Data';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionAbout => 'About';

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
  String get dashFilterCurrency => 'Currency';

  @override
  String get dashFilterSource => 'Source';

  @override
  String get dashFilterAll => 'All';

  @override
  String get dashPrevMonth => 'Previous month';

  @override
  String get dashNextMonth => 'Next month';

  @override
  String dashOthersBadge(int count) {
    return '+$count';
  }

  @override
  String get dashRecent => 'Recent';

  @override
  String get dashViewAll => 'View all';

  @override
  String get dashEmpty => 'No transactions yet — tap + to add one.';

  @override
  String get dashBudgets => 'Budgets';

  @override
  String get dashBudgetTotal => 'Total';

  @override
  String dashBudgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String get dashBudgetManage => 'Manage';

  @override
  String get statsFilterCurrency => 'Currency';

  @override
  String get statsFilterSource => 'Source';

  @override
  String get statsFilterAllSources => 'All sources';

  @override
  String get statsPeriodWeek => 'Week';

  @override
  String get statsPeriodMonth => 'Month';

  @override
  String get statsPeriodYear => 'Year';

  @override
  String get statsTrendTitle => 'Spending Overview';

  @override
  String get statsDistCategoryTitle => 'Category Distribution';

  @override
  String get statsDistTagTitle => 'Tag Distribution';

  @override
  String get statsTypeExpense => 'Expense';

  @override
  String get statsTypeIncome => 'Income';

  @override
  String get statsDistCenterExpense => 'EXPENSE';

  @override
  String get statsDistCenterIncome => 'INCOME';

  @override
  String get statsTopTitle => 'Top';

  @override
  String get statsTopByCategory => 'Category';

  @override
  String get statsTopByTag => 'Tag';

  @override
  String statsTopCountLabel(int count) {
    return 'Count: $count';
  }

  @override
  String get statsUntagged => 'Untagged';

  @override
  String statsTopMoreLink(int n) {
    return '+ $n more · View all in Tag Distribution →';
  }

  @override
  String get statsTopMultiTagNote => '* A transaction may belong to multiple tags, so totals may exceed the actual sum.';

  @override
  String get statsNoData => 'No data';

  @override
  String get statsNoTaggedData => 'No tagged transactions';

  @override
  String get statsLoading => 'Loading…';

  @override
  String get statsError => 'Failed to load';

  @override
  String get exportTitle => 'Export Data';

  @override
  String exportMonthHint(String month) {
    return 'Exports the currently selected month ($month).';
  }

  @override
  String get exportButton => 'Export CSV';

  @override
  String get exportEmpty => 'No transactions in this month to export.';

  @override
  String get exportDone => 'Share sheet opened';

  @override
  String get importTitle => 'Import Data';

  @override
  String get importPickCsv => 'Pick CSV file';

  @override
  String get importHint => 'Pick a SpendHarbor-format CSV. Rows referencing unknown categories or sources will be skipped.';

  @override
  String importSummary(int parsed, int imported, int duplicates, int invalid) {
    return 'Parsed $parsed · Imported $imported · Duplicates $duplicates · Invalid $invalid';
  }

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupExportHint => 'Save a full snapshot of your data as a .shbak file.';

  @override
  String get backupExportButton => 'Export backup';

  @override
  String get backupRestoreHint => 'Restore from a .shbak file. This replaces ALL current data.';

  @override
  String get backupRestoreButton => 'Restore from backup';

  @override
  String get backupRestoreConfirmTitle => 'Replace all data?';

  @override
  String get backupRestoreConfirmBody => 'Your current categories, tags, sources, budgets, and transactions will be replaced by the backup. This cannot be undone.';

  @override
  String get backupRestoreDone => 'Restore completed';

  @override
  String backupVersionMismatch(int found, int expected) {
    return 'Backup version $found cannot be restored (expected $expected).';
  }

  @override
  String get backupNever => 'You haven\'t backed up yet. Tap to back up now.';

  @override
  String backupOverdue(int days) {
    return 'Last backup $days days ago — consider backing up.';
  }

  @override
  String backupRecent(int days) {
    return 'Last backup $days days ago.';
  }

  @override
  String get profileFieldNickname => 'Nickname';

  @override
  String get profileNicknameHint => 'Used only on your device for greeting and avatar initials.';

  @override
  String profileGreeting(String nickname) {
    return 'Hello, $nickname';
  }

  @override
  String get appearanceSystem => 'Follow system';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get lockTitle => 'App Lock';

  @override
  String get lockEnableToggle => 'Require PIN to open';

  @override
  String get lockBiometricToggle => 'Allow biometrics';

  @override
  String get lockSetPin => 'Set PIN';

  @override
  String get lockChangePin => 'Change PIN';

  @override
  String get lockRemove => 'Turn off app lock';

  @override
  String get lockEnterPin => 'Enter PIN';

  @override
  String get lockConfirmPin => 'Confirm PIN';

  @override
  String get lockMismatch => 'PINs don\'t match';

  @override
  String get lockTooShort => 'PIN must be at least 4 digits';

  @override
  String get lockWrong => 'Incorrect PIN';

  @override
  String get lockUnlockTitle => 'Unlock SpendHarbor';

  @override
  String get lockUseBiometric => 'Use biometrics';

  @override
  String get lockBiometricReason => 'Unlock SpendHarbor';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTagline => 'Track your spending. Fully offline. Yours forever.';

  @override
  String get aboutDescription => 'SpendHarbor Local stores everything on your device. No accounts, no servers, no telemetry. Export, import, and back up your data anytime.';

  @override
  String get aboutCreditsTitle => 'Credits';

  @override
  String get aboutCreditsBody => 'Built with Flutter, Drift, Riverpod, go_router, fl_chart, and Lucide icons.';

  @override
  String get legalPrivacyTitle => 'Privacy';

  @override
  String get legalPrivacyBody => 'SpendHarbor Local does not collect or transmit any personal data. All categories, transactions, budgets, and preferences remain on your device. The app does not connect to the network.';

  @override
  String get legalTermsTitle => 'Terms';

  @override
  String get legalTermsBody => 'The app is provided as-is. You are responsible for backing up your data; the developer cannot recover information lost to device damage or uninstalls without a backup.';

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
  String get catNewTitle => 'New Category';

  @override
  String get catEditTitle => 'Edit Category';

  @override
  String get catFieldName => 'Name';

  @override
  String get catFieldType => 'Type';

  @override
  String get catFieldIcon => 'Icon';

  @override
  String get catFieldColor => 'Color';

  @override
  String get catErrNameRequired => 'Enter a name';

  @override
  String get catErrNameDuplicate => 'A category with this name already exists';

  @override
  String get catDeleteConfirmTitle => 'Delete this category?';

  @override
  String get catDeleteConfirmBody => 'Existing transactions keep their reference but this category will no longer appear in pickers.';

  @override
  String get catEmptyExpense => 'No expense categories yet';

  @override
  String get catEmptyIncome => 'No income categories yet';

  @override
  String get catEmpty => 'No categories yet';

  @override
  String get catAdd => 'Add category';

  @override
  String get catSearchHint => 'Search categories';

  @override
  String get colorCustomTitle => 'Custom color';

  @override
  String get catTypeExpenseBadge => 'EXP';

  @override
  String get catTypeIncomeBadge => 'INC';

  @override
  String get tagNewTitle => 'New Tag';

  @override
  String get tagEditTitle => 'Edit Tag';

  @override
  String get tagErrNameRequired => 'Enter a name';

  @override
  String get tagErrNameDuplicate => 'A tag with this name already exists';

  @override
  String get tagDeleteConfirmTitle => 'Delete this tag?';

  @override
  String get tagDeleteConfirmBody => 'Existing transactions keep their reference but this tag will no longer appear in pickers.';

  @override
  String get tagEmpty => 'No tags yet';

  @override
  String get tagAdd => 'Add tag';

  @override
  String get tagSearchHint => 'Search tags';

  @override
  String get srcNewTitle => 'New Source';

  @override
  String get srcEditTitle => 'Edit Source';

  @override
  String get srcFieldCurrency => 'Currency';

  @override
  String get srcErrNameRequired => 'Enter a name';

  @override
  String get srcErrNameDuplicate => 'A source with this name already exists';

  @override
  String get srcDeleteConfirmTitle => 'Delete this source?';

  @override
  String get srcDeleteConfirmBody => 'Existing transactions keep their reference but this source will no longer appear in pickers.';

  @override
  String get srcEmpty => 'No sources yet';

  @override
  String get srcAdd => 'Add source';

  @override
  String get budgetNewTitle => 'New Budget';

  @override
  String get budgetEditTitle => 'Edit Budget';

  @override
  String get budgetFieldPeriod => 'Period';

  @override
  String get budgetFieldScope => 'Scope';

  @override
  String get budgetFieldAmount => 'Amount';

  @override
  String get budgetFieldCurrency => 'Currency';

  @override
  String get budgetFieldCategory => 'Category';

  @override
  String get budgetFieldStartsOn => 'Starts on';

  @override
  String get budgetPeriodWeek => 'Weekly';

  @override
  String get budgetPeriodMonth => 'Monthly';

  @override
  String get budgetPeriodYear => 'Yearly';

  @override
  String get budgetScopeTotal => 'Total';

  @override
  String get budgetScopeCategory => 'Category';

  @override
  String get budgetErrAmount => 'Amount must be greater than 0';

  @override
  String get budgetErrCategoryRequired => 'Pick a category';

  @override
  String get budgetDeleteConfirmTitle => 'Delete this budget?';

  @override
  String get budgetDeleteConfirmBody => 'This budget will be removed. Transactions stay untouched.';

  @override
  String get budgetEmpty => 'No budgets yet';

  @override
  String get budgetAdd => 'Add budget';

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
