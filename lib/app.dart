import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/generated/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';
import 'theme/app_shadows.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class SpendHarborApp extends ConsumerWidget {
  const SpendHarborApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppL10n.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const _ThemePreviewPage(),
    );
  }
}

class _ThemePreviewPage extends StatefulWidget {
  const _ThemePreviewPage();

  @override
  State<_ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<_ThemePreviewPage> {
  Brightness? _override;

  @override
  Widget build(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final effective = _override ?? platformBrightness;
    final theme =
        effective == Brightness.dark ? AppTheme.dark() : AppTheme.light();
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final c = context.appColors;
          return Scaffold(
            appBar: AppBar(
              title: Text(AppL10n.of(context).themePreviewTitle),
              actions: [
                IconButton(
                  tooltip: 'Toggle theme',
                  icon: Icon(effective == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  onPressed: () => setState(() {
                    _override = effective == Brightness.dark
                        ? Brightness.light
                        : Brightness.dark;
                  }),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.x4),
              children: [
                _Card(
                  title: 'Typography',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('H1 Page Title', style: AppTypography.xxxl.copyWith(color: c.actionInk, fontWeight: AppTypography.weightSemibold)),
                      const SizedBox(height: AppSpacing.x2),
                      Text('H2 Section', style: AppTypography.xl.copyWith(color: c.actionInk, fontWeight: AppTypography.weightSemibold)),
                      const SizedBox(height: AppSpacing.x2),
                      Text('Body text — 14sp regular', style: AppTypography.sm.copyWith(color: c.textBody)),
                      const SizedBox(height: AppSpacing.x1),
                      Text('Muted text — 12sp', style: AppTypography.xs.copyWith(color: c.textMuted)),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        r'¥ 1,234.56  (mono tabular)',
                        style: AppTypography.sm.merge(AppTypography.mono).copyWith(color: c.actionInk, fontWeight: AppTypography.weightSemibold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _Card(
                  title: 'Amount colors',
                  child: Row(
                    children: [
                      _AmountChip(label: '+ CA\$120.00', color: c.income, soft: c.incomeSoft),
                      const SizedBox(width: AppSpacing.x3),
                      _AmountChip(label: '- CA\$45.20', color: c.expense, soft: c.expenseSoft),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _Card(
                  title: 'Buttons',
                  child: Wrap(
                    spacing: AppSpacing.x3,
                    runSpacing: AppSpacing.x3,
                    children: [
                      FilledButton(onPressed: () {}, child: const Text('Save')),
                      OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
                      TextButton(onPressed: () {}, child: const Text('Learn more')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: c.expense),
                        onPressed: () {},
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _Card(
                  title: 'Input',
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'e.g. Lunch with team',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _Card(
                  title: 'Surfaces',
                  child: Column(
                    children: [
                      Container(
                        padding: AppSpacing.listItem,
                        decoration: BoxDecoration(
                          color: c.mintSoft,
                          borderRadius: AppRadius.brXl,
                        ),
                        child: Row(
                          children: [
                            Text('DayGroup · Today', style: AppTypography.xs.copyWith(color: c.actionInk, fontWeight: AppTypography.weightSemibold)),
                            const Spacer(),
                            Text('+ CA\$58.00', style: AppTypography.xs.copyWith(color: c.income, fontWeight: AppTypography.weightSemibold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      Container(
                        padding: AppSpacing.card,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: AppRadius.brXl,
                          border: Border.all(color: c.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: Text('Standard card', style: AppTypography.sm.copyWith(color: c.textBody)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.xs.copyWith(
                  color: c.textMuted, fontWeight: AppTypography.weightMedium)),
          const SizedBox(height: AppSpacing.x3),
          child,
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.color, required this.soft});
  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        label,
        style: AppTypography.xs
            .merge(AppTypography.mono)
            .copyWith(color: color, fontWeight: AppTypography.weightSemibold),
      ),
    );
  }
}
