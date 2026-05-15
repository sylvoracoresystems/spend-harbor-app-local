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
            fg: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE)),
      ]),
      _SettingsSection(l.settingsSectionLibrary, [
        _SettingsItem(LucideIcons.shapes, l.settingsCategories,
            '/settings/categories',
            fg: const Color(0xFF7C3AED), bg: const Color(0xFFEDE9FE)),
        _SettingsItem(LucideIcons.tag, l.settingsTags, '/settings/tags',
            fg: const Color(0xFFDB2777), bg: const Color(0xFFFCE7F3)),
        _SettingsItem(
            LucideIcons.wallet, l.settingsSources, '/settings/sources',
            fg: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7)),
        _SettingsItem(
            LucideIcons.target, l.settingsBudgets, '/settings/budgets',
            fg: const Color(0xFF059669), bg: const Color(0xFFD1FAE5)),
      ]),
      _SettingsSection(l.settingsSectionDataIO, [
        _SettingsItem(
            LucideIcons.download, l.settingsExport, '/settings/export',
            fg: const Color(0xFF0D9488), bg: const Color(0xFFCCFBF1)),
        _SettingsItem(LucideIcons.upload, l.settingsImport, '/settings/import',
            fg: const Color(0xFF0284C7), bg: const Color(0xFFE0F2FE)),
        _SettingsItem(
            LucideIcons.archive, l.settingsBackup, '/settings/backup',
            fg: const Color(0xFF475569), bg: const Color(0xFFE2E8F0)),
      ]),
      _SettingsSection(l.settingsSectionPreferences, [
        _SettingsItem(LucideIcons.dollarSign, l.settingsCurrency,
            '/settings/currency',
            fg: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7)),
        _SettingsItem(
            LucideIcons.languages, l.settingsLanguage, '/settings/language',
            fg: const Color(0xFF4F46E5), bg: const Color(0xFFE0E7FF)),
        _SettingsItem(LucideIcons.palette, l.settingsAppearance,
            '/settings/appearance',
            fg: const Color(0xFFE11D48), bg: const Color(0xFFFFE4E6)),
      ]),
      _SettingsSection(l.settingsSectionSecurity, [
        _SettingsItem(
            LucideIcons.lock, l.settingsSecurity, '/settings/security',
            fg: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2)),
      ]),
      _SettingsSection(l.settingsSectionAbout, [
        _SettingsItem(LucideIcons.info, l.settingsAbout, '/settings/about',
            fg: const Color(0xFF64748B), bg: const Color(0xFFF1F5F9)),
        _SettingsItem(LucideIcons.shield, l.settingsLegal, '/settings/legal',
            fg: const Color(0xFFEA580C), bg: const Color(0xFFFFEDD5)),
      ]),
    ];

    return RootPageScaffold(
      title: l.tabSettings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x2,
          AppSpacing.x4,
          AppSpacing.x4,
        ),
        children: [
          for (final s in sections) _SectionView(section: s),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x4),
      child: Column(
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
      ),
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
          color: item.bg,
          borderRadius: AppRadius.brLg,
        ),
        alignment: Alignment.center,
        child: Icon(item.icon, size: 18, color: item.fg),
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
    required this.fg,
    required this.bg,
  });
  final IconData icon;
  final String label;
  final String path;
  final Color fg;
  final Color bg;
}
