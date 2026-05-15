import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final sections = <_SettingsSection>[
      _SettingsSection(l.settingsSectionAccount, [
        _SettingsItem(LucideIcons.user, l.settingsProfile, '/settings/profile',
            swatch: SettingsIconPalette.profile),
      ]),
      _SettingsSection(l.settingsSectionLibrary, [
        _SettingsItem(LucideIcons.shapes, l.settingsCategories,
            '/settings/categories',
            swatch: SettingsIconPalette.categories),
        _SettingsItem(LucideIcons.tag, l.settingsTags, '/settings/tags',
            swatch: SettingsIconPalette.tags),
        _SettingsItem(
            LucideIcons.wallet, l.settingsSources, '/settings/sources',
            swatch: SettingsIconPalette.sources),
        _SettingsItem(
            LucideIcons.target, l.settingsBudgets, '/settings/budgets',
            swatch: SettingsIconPalette.budgets),
      ]),
      _SettingsSection(l.settingsSectionDataIO, [
        _SettingsItem(
            LucideIcons.download, l.settingsExport, '/settings/export',
            swatch: SettingsIconPalette.export),
        _SettingsItem(LucideIcons.upload, l.settingsImport, '/settings/import',
            swatch: SettingsIconPalette.import),
        _SettingsItem(
            LucideIcons.archive, l.settingsBackup, '/settings/backup',
            swatch: SettingsIconPalette.backup),
      ]),
      _SettingsSection(l.settingsSectionPreferences, [
        _SettingsItem(LucideIcons.dollarSign, l.settingsCurrency,
            '/settings/currency',
            swatch: SettingsIconPalette.currency),
        _SettingsItem(
            LucideIcons.languages, l.settingsLanguage, '/settings/language',
            swatch: SettingsIconPalette.language),
        _SettingsItem(LucideIcons.palette, l.settingsAppearance,
            '/settings/appearance',
            swatch: SettingsIconPalette.appearance),
      ]),
      _SettingsSection(l.settingsSectionSecurity, [
        _SettingsItem(
            LucideIcons.lock, l.settingsSecurity, '/settings/security',
            swatch: SettingsIconPalette.security),
      ]),
      _SettingsSection(l.settingsSectionAbout, [
        _SettingsItem(LucideIcons.info, l.settingsAbout, '/settings/about',
            swatch: SettingsIconPalette.about),
        _SettingsItem(LucideIcons.shield, l.settingsLegal, '/settings/legal',
            swatch: SettingsIconPalette.legal),
      ]),
    ];

    return RootPageScaffold(
      title: l.tabSettings,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          0,
          AppSpacing.x4,
          AppSpacing.x4,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x4),
        itemBuilder: (_, i) => _SectionView(section: sections[i]),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});
  final _SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2,
            0,
            AppSpacing.x2,
            AppSpacing.x2,
          ),
          child: Text(
            section.title,
            style: AppTypography.xs.copyWith(
              color: c.textMuted,
              fontWeight: AppTypography.weightSemibold,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.brXl,
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                _ItemRow(item: section.items[i]),
                if (i < section.items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Divider(height: 1, color: c.border),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: item.swatch.bg,
          borderRadius: AppRadius.brLg,
        ),
        alignment: Alignment.center,
        child: Icon(item.icon, size: 18, color: item.swatch.fg),
      ),
      title: Text(item.label,
          style: AppTypography.sm.copyWith(color: c.actionInk)),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () => context.push(item.path),
    );
  }
}

class _SettingsSection {
  const _SettingsSection(this.title, this.items);
  final String title;
  final List<_SettingsItem> items;
}

class _SettingsItem {
  const _SettingsItem(
    this.icon,
    this.label,
    this.path, {
    required this.swatch,
  });
  final IconData icon;
  final String label;
  final String path;
  final IconSwatch swatch;
}
