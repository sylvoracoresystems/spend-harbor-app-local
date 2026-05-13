import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/default_currency_provider.dart';

class CurrencyPage extends ConsumerWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final current = ref.watch(defaultCurrencyProvider);
    final ctrl = ref.read(defaultCurrencyProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsCurrency)),
      body: ListView.builder(
        itemCount: Currency.all.length,
        itemBuilder: (context, i) {
          final ccy = Currency.all[i];
          final name = isZh ? ccy.chineseName : ccy.englishName;
          return RadioListTile<String>(
            title: Text('${ccy.code} · ${ccy.symbol}'),
            subtitle: Text(name),
            value: ccy.code,
            groupValue: current,
            onChanged: (v) {
              if (v != null) ctrl.set(v);
            },
          );
        },
      ),
    );
  }
}
