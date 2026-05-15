import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../transactions/application/transactions_list_controller.dart';
import '../application/dashboard_filter_provider.dart';

/// Dashboard 顶部过滤条：① 月份导航  ② 货币 / 来源下拉。
class DashboardFilterBar extends ConsumerWidget {
  const DashboardFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final ym = ref.watch(currentMonthProvider);
    final filter = ref.watch(dashboardFilterProvider);
    final sourcesAsync = ref.watch(allSourcesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MonthDropdown(ym: ym, l: l, c: c, ref: ref),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: _CurrencyDropdown(
                  value: filter.currency,
                  onChanged: (v) =>
                      ref.read(dashboardFilterProvider.notifier).setCurrency(v),
                  label: l.dashFilterCurrency,
                  allLabel: l.dashFilterAll,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _SourceDropdown(
                  value: filter.sourceId,
                  onChanged: (v) =>
                      ref.read(dashboardFilterProvider.notifier).setSource(v),
                  label: l.dashFilterSource,
                  allLabel: l.dashFilterAll,
                  sources: sourcesAsync.maybeWhen(
                    data: (rows) => rows,
                    orElse: () => const <Source>[],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({
    required this.ym,
    required this.l,
    required this.c,
    required this.ref,
  });
  final YearMonth ym;
  final AppL10n l;
  final AppColors c;
  final WidgetRef ref;

  String _label(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return '${ym.year} 年 ${ym.month} 月';
    }
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthsEn[ym.month - 1]} ${ym.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brXl,
      onTap: () async {
        final picked = await showDialog<YearMonth>(
          context: context,
          builder: (_) => _MonthPickerDialog(initial: ym),
        );
        if (picked != null) {
          ref.read(currentMonthProvider.notifier).set(picked);
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: c.textMuted),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                _label(context),
                style: AppTypography.sm.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: c.textPrimary,
                ),
              ),
            ),
            Icon(LucideIcons.chevronDown, size: 14, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});
  final YearMonth initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  List<String> _monthLabels(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return List.generate(12, (i) => '${i + 1} 月');
    }
    return const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final labels = _monthLabels(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(LucideIcons.chevronLeft, size: 18),
                  color: c.textMuted,
                ),
                Text(
                  '$_year',
                  style: AppTypography.base.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: c.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(LucideIcons.chevronRight, size: 18),
                  color: c.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.x2,
              crossAxisSpacing: AppSpacing.x2,
              childAspectRatio: 1.8,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: labels[m - 1],
                    selected:
                        _year == widget.initial.year && m == widget.initial.month,
                    onTap: () =>
                        Navigator.of(context).pop(YearMonth(_year, m)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.mintTint : Colors.transparent,
            border: Border.all(color: selected ? c.action : c.border),
            borderRadius: AppRadius.brLg,
          ),
          child: Text(
            label,
            style: AppTypography.sm.copyWith(
              color: selected ? c.action : c.textBody,
              fontWeight: selected
                  ? AppTypography.weightSemibold
                  : AppTypography.weightMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.allLabel,
  });
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return _FilterPill(
      icon: LucideIcons.dollarSign,
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          isDense: true,
          value: value,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(allLabel),
            ),
            for (final ccy in Currency.all)
              DropdownMenuItem<String?>(
                value: ccy.code,
                child: Text(ccy.code),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.allLabel,
    required this.sources,
  });
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String allLabel;
  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    // 若当前选中的 id 不在 sources 列表里（来源被删？），回退 null 防止 dropdown crash。
    final safe = value != null && sources.any((s) => s.id == value)
        ? value
        : null;
    return _FilterPill(
      icon: LucideIcons.wallet,
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          isDense: true,
          value: safe,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(allLabel),
            ),
            for (final s in sources)
              DropdownMenuItem<String?>(
                value: s.id,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 单行紧凑外框：左 icon + 内置 dropdown。高度 ~36pt。
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.child,
  });
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.textMuted),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: DefaultTextStyle(
              style: AppTypography.sm.copyWith(color: c.textPrimary),
              child: Semantics(label: label, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
