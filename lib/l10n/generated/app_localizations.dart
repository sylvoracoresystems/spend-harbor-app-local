import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// Application display name
  ///
  /// In en, this message translates to:
  /// **'SpendHarbor'**
  String get appName;

  /// No description provided for @themePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Preview'**
  String get themePreviewTitle;

  /// No description provided for @themeToggleLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeToggleLight;

  /// No description provided for @themeToggleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeToggleDark;

  /// No description provided for @themeToggleSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeToggleSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get tabTransactions;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @fabAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get fabAddTransaction;

  /// No description provided for @newTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get newTransactionTitle;

  /// No description provided for @editTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransactionTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SpendHarbor'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your spending. Fully offline. Yours forever.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get settingsTags;

  /// No description provided for @settingsSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get settingsSources;

  /// No description provided for @settingsBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get settingsBudgets;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExport;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImport;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackup;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsSecurity;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get settingsLegal;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @txFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txFieldAmount;

  /// No description provided for @txFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get txFieldType;

  /// No description provided for @txFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get txFieldCategory;

  /// No description provided for @txFieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get txFieldSource;

  /// No description provided for @txFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txFieldDate;

  /// No description provided for @txFieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get txFieldTags;

  /// No description provided for @txFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txFieldNote;

  /// No description provided for @txTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txTypeExpense;

  /// No description provided for @txTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txTypeIncome;

  /// No description provided for @txSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get txSave;

  /// No description provided for @txDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get txDelete;

  /// No description provided for @txDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get txDeleteConfirmTitle;

  /// No description provided for @txDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It will move to the recycle bin for 30 days.'**
  String get txDeleteConfirmBody;

  /// No description provided for @txCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get txCancel;

  /// No description provided for @txErrAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get txErrAmountRequired;

  /// No description provided for @txErrAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get txErrAmountInvalid;

  /// No description provided for @txErrCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get txErrCategoryRequired;

  /// No description provided for @txErrSourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a source'**
  String get txErrSourceRequired;

  /// No description provided for @txEmptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get txEmptyCategory;

  /// No description provided for @txEmptySource.
  ///
  /// In en, this message translates to:
  /// **'No sources yet'**
  String get txEmptySource;

  /// No description provided for @txNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lunch with team'**
  String get txNotePlaceholder;

  /// No description provided for @txListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get txListEmpty;

  /// No description provided for @txMonthPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get txMonthPrev;

  /// No description provided for @txMonthNext.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get txMonthNext;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @selectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionTitle(int count);

  /// No description provided for @selectionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get selectionCancel;

  /// No description provided for @selectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get selectionDelete;

  /// No description provided for @selectionDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} transactions?'**
  String selectionDeleteConfirmTitle(int count);

  /// No description provided for @selectionDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will move to the recycle bin for 30 days.'**
  String get selectionDeleteConfirmBody;

  /// No description provided for @dashIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashIncome;

  /// No description provided for @dashExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashExpense;

  /// No description provided for @dashNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get dashNet;

  /// No description provided for @dashCount.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get dashCount;

  /// No description provided for @dashRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get dashRecent;

  /// No description provided for @dashViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashViewAll;

  /// No description provided for @dashEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet — tap + to add one.'**
  String get dashEmpty;

  /// No description provided for @recycleBinTitle.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get recycleBinTitle;

  /// No description provided for @recycleBinEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here. Deleted transactions stay for 30 days.'**
  String get recycleBinEmpty;

  /// No description provided for @recycleBinDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String recycleBinDaysLeft(int days);

  /// No description provided for @recycleBinRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recycleBinRestore;

  /// No description provided for @recycleBinPurge.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get recycleBinPurge;

  /// No description provided for @recycleBinPurgeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete forever?'**
  String get recycleBinPurgeConfirmTitle;

  /// No description provided for @recycleBinPurgeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This transaction will be permanently removed and cannot be recovered.'**
  String get recycleBinPurgeConfirmBody;

  /// No description provided for @catNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get catNewTitle;

  /// No description provided for @catEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get catEditTitle;

  /// No description provided for @catFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catFieldName;

  /// No description provided for @catFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get catFieldType;

  /// No description provided for @catFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get catFieldIcon;

  /// No description provided for @catFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get catFieldColor;

  /// No description provided for @catErrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get catErrNameRequired;

  /// No description provided for @catErrNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get catErrNameDuplicate;

  /// No description provided for @catDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get catDeleteConfirmTitle;

  /// No description provided for @catDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Existing transactions keep their reference but this category will no longer appear in pickers.'**
  String get catDeleteConfirmBody;

  /// No description provided for @catEmptyExpense.
  ///
  /// In en, this message translates to:
  /// **'No expense categories yet'**
  String get catEmptyExpense;

  /// No description provided for @catEmptyIncome.
  ///
  /// In en, this message translates to:
  /// **'No income categories yet'**
  String get catEmptyIncome;

  /// No description provided for @catAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get catAdd;

  /// No description provided for @tagNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Tag'**
  String get tagNewTitle;

  /// No description provided for @tagEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get tagEditTitle;

  /// No description provided for @tagErrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get tagErrNameRequired;

  /// No description provided for @tagErrNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get tagErrNameDuplicate;

  /// No description provided for @tagDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this tag?'**
  String get tagDeleteConfirmTitle;

  /// No description provided for @tagDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Existing transactions keep their reference but this tag will no longer appear in pickers.'**
  String get tagDeleteConfirmBody;

  /// No description provided for @tagEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagEmpty;

  /// No description provided for @tagAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tagAdd;

  /// No description provided for @srcNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Source'**
  String get srcNewTitle;

  /// No description provided for @srcEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Source'**
  String get srcEditTitle;

  /// No description provided for @srcFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get srcFieldCurrency;

  /// No description provided for @srcErrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get srcErrNameRequired;

  /// No description provided for @srcErrNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A source with this name already exists'**
  String get srcErrNameDuplicate;

  /// No description provided for @srcDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this source?'**
  String get srcDeleteConfirmTitle;

  /// No description provided for @srcDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Existing transactions keep their reference but this source will no longer appear in pickers.'**
  String get srcDeleteConfirmBody;

  /// No description provided for @srcEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sources yet'**
  String get srcEmpty;

  /// No description provided for @srcAdd.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get srcAdd;

  /// No description provided for @budgetNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Budget'**
  String get budgetNewTitle;

  /// No description provided for @budgetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budgetEditTitle;

  /// No description provided for @budgetFieldPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetFieldPeriod;

  /// No description provided for @budgetFieldScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get budgetFieldScope;

  /// No description provided for @budgetFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get budgetFieldAmount;

  /// No description provided for @budgetFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get budgetFieldCurrency;

  /// No description provided for @budgetFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetFieldCategory;

  /// No description provided for @budgetFieldStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get budgetFieldStartsOn;

  /// No description provided for @budgetPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetPeriodWeek;

  /// No description provided for @budgetPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetPeriodMonth;

  /// No description provided for @budgetPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetPeriodYear;

  /// No description provided for @budgetScopeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get budgetScopeTotal;

  /// No description provided for @budgetScopeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetScopeCategory;

  /// No description provided for @budgetErrAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get budgetErrAmount;

  /// No description provided for @budgetErrCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get budgetErrCategoryRequired;

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget?'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This budget will be removed. Transactions stay untouched.'**
  String get budgetDeleteConfirmBody;

  /// No description provided for @budgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetEmpty;

  /// No description provided for @budgetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get budgetAdd;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get catHome;

  /// No description provided for @catMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get catMedical;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catTelecom.
  ///
  /// In en, this message translates to:
  /// **'Telecom'**
  String get catTelecom;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @catBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get catBonus;

  /// No description provided for @catInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get catInvestment;

  /// No description provided for @catOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get catOtherIncome;

  /// No description provided for @tagWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get tagWork;

  /// No description provided for @tagPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get tagPersonal;

  /// No description provided for @tagFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tagFamily;

  /// No description provided for @tagImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get tagImportant;

  /// No description provided for @tagReimburse.
  ///
  /// In en, this message translates to:
  /// **'Reimburse'**
  String get tagReimburse;

  /// No description provided for @srcCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get srcCash;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppL10nEn();
    case 'zh': return AppL10nZh();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
