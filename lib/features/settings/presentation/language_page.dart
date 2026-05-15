import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/widgets/root_page_scaffold.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final current = ref.watch(localeControllerProvider);
    final ctrl = ref.read(localeControllerProvider.notifier);

    final options = <(Locale?, String)>[
      (null, l.languageSystem),
      (const Locale('en'), l.languageEnglish),
      (const Locale('zh'), l.languageChinese),
    ];

    return SubPageScaffold(
      title: l.settingsLanguage,
      body: ListView(
        children: [
          for (final (locale, label) in options)
            RadioListTile<String>(
              title: Text(label),
              value: locale?.languageCode ?? 'system',
              groupValue: current?.languageCode ?? 'system',
              onChanged: (_) => ctrl.setLocale(locale),
            ),
        ],
      ),
    );
  }
}
