import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = <_SettingsItem>[
      _SettingsItem(LucideIcons.user, l.settingsProfile, '/settings/profile'),
      _SettingsItem(LucideIcons.tag, l.settingsCategories, '/settings/categories'),
      _SettingsItem(LucideIcons.hash, l.settingsTags, '/settings/tags'),
      _SettingsItem(LucideIcons.wallet, l.settingsSources, '/settings/sources'),
      _SettingsItem(LucideIcons.target, l.settingsBudgets, '/settings/budgets'),
      _SettingsItem(LucideIcons.download, l.settingsExport, '/settings/export'),
      _SettingsItem(LucideIcons.upload, l.settingsImport, '/settings/import'),
      _SettingsItem(LucideIcons.archive, l.settingsBackup, '/settings/backup'),
      _SettingsItem(LucideIcons.dollarSign, l.settingsCurrency, '/settings/currency'),
      _SettingsItem(LucideIcons.languages, l.settingsLanguage, '/settings/language'),
      _SettingsItem(LucideIcons.palette, l.settingsAppearance, '/settings/appearance'),
      _SettingsItem(LucideIcons.lock, l.settingsSecurity, '/settings/security'),
      _SettingsItem(LucideIcons.info, l.settingsAbout, '/settings/about'),
      _SettingsItem(LucideIcons.shield, l.settingsLegal, '/settings/legal'),
    ];
    final c = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabSettings),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
        itemBuilder: (context, i) {
          final it = items[i];
          return ListTile(
            leading: Icon(it.icon, color: c.actionInk),
            title: Text(it.label, style: AppTypography.sm.copyWith(color: c.actionInk)),
            trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
            onTap: () => context.push(it.path),
          );
        },
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem(this.icon, this.label, this.path);
  final IconData icon;
  final String label;
  final String path;
}
