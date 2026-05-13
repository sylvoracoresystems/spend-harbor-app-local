import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/theme_mode_provider.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final current = ref.watch(themeModeControllerProvider);
    final ctrl = ref.read(themeModeControllerProvider.notifier);

    final options = <(ThemeMode, String)>[
      (ThemeMode.system, l.appearanceSystem),
      (ThemeMode.light, l.appearanceLight),
      (ThemeMode.dark, l.appearanceDark),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAppearance)),
      body: ListView(
        children: [
          for (final (mode, label) in options)
            RadioListTile<ThemeMode>(
              title: Text(label),
              value: mode,
              groupValue: current,
              onChanged: (v) {
                if (v != null) ctrl.set(v);
              },
            ),
        ],
      ),
    );
  }
}
