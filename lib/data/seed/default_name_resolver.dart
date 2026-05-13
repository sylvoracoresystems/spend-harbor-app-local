import '../../l10n/generated/app_localizations.dart';

/// 将默认 seed 的 `nameKey` 映射到当前 locale 的本地化字符串。
///
/// 用户重命名后 `nameKey` 会被清空，调用方应直接使用 `name` 字段。
String? resolveDefaultName(AppL10n l, String? nameKey) {
  switch (nameKey) {
    case 'catFood':
      return l.catFood;
    case 'catTransport':
      return l.catTransport;
    case 'catShopping':
      return l.catShopping;
    case 'catEntertainment':
      return l.catEntertainment;
    case 'catHome':
      return l.catHome;
    case 'catMedical':
      return l.catMedical;
    case 'catEducation':
      return l.catEducation;
    case 'catTelecom':
      return l.catTelecom;
    case 'catTravel':
      return l.catTravel;
    case 'catOther':
      return l.catOther;
    case 'catSalary':
      return l.catSalary;
    case 'catBonus':
      return l.catBonus;
    case 'catInvestment':
      return l.catInvestment;
    case 'catOtherIncome':
      return l.catOtherIncome;
    case 'tagWork':
      return l.tagWork;
    case 'tagPersonal':
      return l.tagPersonal;
    case 'tagFamily':
      return l.tagFamily;
    case 'tagImportant':
      return l.tagImportant;
    case 'tagReimburse':
      return l.tagReimburse;
    case 'srcCash':
      return l.srcCash;
    default:
      return null;
  }
}
