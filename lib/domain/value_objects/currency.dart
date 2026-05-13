/// 18 种支持的货币（PRODUCT_SPEC §6.5），单一事实来源。
///
/// 金额在数据库中统一存为整数 minor units（× 100），即「分」。
/// 即便 JPY 在 ISO-4217 中无小数位，本 App 仍按 2 位小数显示规则统一处理。
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.englishName,
    required this.chineseName,
  });

  /// ISO-4217 code，例如 `CAD`、`USD`
  final String code;

  /// 展示符号，例如 `CA$`、`US$`、`¥`
  final String symbol;

  final String englishName;
  final String chineseName;

  static const cad = Currency(code: 'CAD', symbol: r'CA$', englishName: 'Canadian Dollar', chineseName: '加元');
  static const usd = Currency(code: 'USD', symbol: r'US$', englishName: 'US Dollar', chineseName: '美元');
  static const cny = Currency(code: 'CNY', symbol: '¥', englishName: 'Chinese Yuan', chineseName: '人民币');
  static const hkd = Currency(code: 'HKD', symbol: r'HK$', englishName: 'Hong Kong Dollar', chineseName: '港币');
  static const twd = Currency(code: 'TWD', symbol: r'NT$', englishName: 'New Taiwan Dollar', chineseName: '新台币');
  static const jpy = Currency(code: 'JPY', symbol: '¥', englishName: 'Japanese Yen', chineseName: '日元');
  static const krw = Currency(code: 'KRW', symbol: '₩', englishName: 'South Korean Won', chineseName: '韩元');
  static const sgd = Currency(code: 'SGD', symbol: r'S$', englishName: 'Singapore Dollar', chineseName: '新加坡元');
  static const aud = Currency(code: 'AUD', symbol: r'A$', englishName: 'Australian Dollar', chineseName: '澳元');
  static const nzd = Currency(code: 'NZD', symbol: r'NZ$', englishName: 'New Zealand Dollar', chineseName: '新西兰元');
  static const gbp = Currency(code: 'GBP', symbol: '£', englishName: 'British Pound', chineseName: '英镑');
  static const eur = Currency(code: 'EUR', symbol: '€', englishName: 'Euro', chineseName: '欧元');
  static const chf = Currency(code: 'CHF', symbol: 'CHF', englishName: 'Swiss Franc', chineseName: '瑞士法郎');
  static const inr = Currency(code: 'INR', symbol: '₹', englishName: 'Indian Rupee', chineseName: '印度卢比');
  static const thb = Currency(code: 'THB', symbol: '฿', englishName: 'Thai Baht', chineseName: '泰铢');
  static const myr = Currency(code: 'MYR', symbol: 'RM', englishName: 'Malaysian Ringgit', chineseName: '马来西亚林吉特');
  static const php = Currency(code: 'PHP', symbol: '₱', englishName: 'Philippine Peso', chineseName: '菲律宾比索');
  static const vnd = Currency(code: 'VND', symbol: '₫', englishName: 'Vietnamese Dong', chineseName: '越南盾');

  /// 全部支持币种（顺序与 PRODUCT_SPEC §6.5 一致）。
  static const all = <Currency>[
    cad, usd, cny, hkd, twd, jpy, krw, sgd, aud, nzd,
    gbp, eur, chf, inr, thb, myr, php, vnd,
  ];

  static final Map<String, Currency> _byCode = {
    for (final c in all) c.code: c,
  };

  /// 全部支持的 ISO code（用于数据库 CHECK 约束生成）
  static final Set<String> allCodes = _byCode.keys.toSet();

  static bool isSupported(String code) => _byCode.containsKey(code);

  /// 按 code 查找；找不到抛 [ArgumentError]
  static Currency byCode(String code) {
    final c = _byCode[code];
    if (c == null) throw ArgumentError('Unsupported currency: $code');
    return c;
  }

  @override
  String toString() => code;
}
